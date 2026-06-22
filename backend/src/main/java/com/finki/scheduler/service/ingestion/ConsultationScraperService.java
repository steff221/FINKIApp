package com.finki.scheduler.service.ingestion;

import com.finki.scheduler.domain.*;
import com.finki.scheduler.repository.*;
import com.finki.scheduler.service.matching.NameNormalizer;
import com.finki.scheduler.service.matching.TeacherMatcherService;
import com.finki.scheduler.service.parsing.MacDateParser;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Scrapes professor consultation slots from consultations.finki.ukim.mk.
 *
 * Index page → /display/{username} for each professor.
 * Slots are concrete dated entries for the next 6 days; refreshed daily.
 * A politeness delay of ${consultations.scrape-delay-ms} ms is added between pages.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ConsultationScraperService {

    @Value("${consultations.base-url}")
    private String baseUrl;
    @Value("${consultations.scrape-delay-ms}")
    private long delayMs;
    @Value("${consultations.user-agent}")
    private String userAgent;

    private final TeacherRepository teacherRepo;
    private final ConsultationSlotRepository consultationSlotRepo;
    private final IngestionLogRepository logRepo;
    private final MacDateParser dateParser;
    private final NameNormalizer nameNormalizer;
    private final TeacherMatcherService matcherService;

    @Transactional
    public int scrape() {
        IngestionLog entry = logRepo.save(IngestionLog.builder()
            .source(IngestionLog.Source.CONSULTATIONS)
            .status(IngestionLog.Status.RUNNING)
            .build());

        int totalSlots = 0;
        try {
            List<ProfessorRef> professors = scrapeIndex();
            log.info("Found {} professors on the consultations index", professors.size());

            for (ProfessorRef prof : professors) {
                try {
                    Thread.sleep(delayMs);
                    int saved = scrapeProfessorPage(prof);
                    totalSlots += saved;
                } catch (InterruptedException ie) {
                    Thread.currentThread().interrupt();
                    throw new RuntimeException("Scraper interrupted", ie);
                } catch (Exception e) {
                    log.warn("Failed to scrape /display/{}: {}", prof.username(), e.getMessage());
                }
            }

            // After all consultation teachers are stored, run the matcher
            matcherService.matchAll();

            entry.setStatus(IngestionLog.Status.SUCCESS);
            entry.setRecordCount(totalSlots);
            entry.setCompletedAt(Instant.now());
            logRepo.save(entry);
            log.info("Consultation scrape complete: {} slots stored", totalSlots);
            return totalSlots;

        } catch (Exception e) {
            log.error("Consultation scrape failed", e);
            entry.setStatus(IngestionLog.Status.FAILURE);
            entry.setErrorMessage(e.getMessage());
            entry.setCompletedAt(Instant.now());
            logRepo.save(entry);
            throw new RuntimeException("Consultation scrape failed: " + e.getMessage(), e);
        }
    }

    // ── Index page ────────────────────────────────────────────────────────────

    private List<ProfessorRef> scrapeIndex() throws Exception {
        Document doc = Jsoup.connect(baseUrl + "/")
            .userAgent(userAgent)
            .timeout(10_000)
            .get();

        List<ProfessorRef> refs = new ArrayList<>();
        // Each professor entry has an <a href="/display/{username}"> inside or near an <h5>
        Elements links = doc.select("a[href^=/display/]");
        for (Element link : links) {
            String username = link.attr("href").replace("/display/", "").trim();
            if (username.isBlank()) continue;

            // The professor name is in the closest h5, or in the link's parent h5
            Element h5 = link.closest("h5");
            String displayName = h5 != null ? h5.ownText().trim() : "";
            refs.add(new ProfessorRef(username, displayName));
        }
        return refs;
    }

    // ── Professor page ────────────────────────────────────────────────────────

    private int scrapeProfessorPage(ProfessorRef prof) throws Exception {
        Document doc = Jsoup.connect(baseUrl + "/display/" + prof.username())
            .userAgent(userAgent)
            .timeout(10_000)
            .get();

        // Resolve display name from <h2> if index gave us nothing
        String cyrillicName = prof.displayName();
        Elements h2s = doc.select("h2");
        if (!h2s.isEmpty()) cyrillicName = h2s.first().text().trim();

        Teacher teacher = resolveTeacher(prof.username(), cyrillicName);

        // Delete old slots before writing new ones
        consultationSlotRepo.deleteByTeacherId(teacher.getId());

        // Each consultation is a card; fields are labelled info-items keyed by icon:
        //   fa-calendar-alt → date, fa-clock → time, fa-door-open → room,
        //   fa-clipboard-list → instructions.
        Elements cards = doc.select("div.consultation-card");
        if (cards.isEmpty() || doc.text().contains("Нема закажани")) {
            log.debug("No upcoming slots for {}", prof.username());
            return 0;
        }

        int count = 0;
        for (Element card : cards) {
            try {
                String dateStr = infoItemValue(card, "i.fa-calendar-alt");
                String timeStr = infoItemValue(card, "i.fa-clock");
                if (dateStr == null || timeStr == null) continue;

                LocalDate date = dateParser.parseDate(dateStr);
                LocalTime[] times = dateParser.parseTimeRange(timeStr);
                String room = infoItemValue(card, "i.fa-door-open");
                String instructions = infoItemValue(card, "i.fa-clipboard-list");

                consultationSlotRepo.save(ConsultationSlot.builder()
                    .teacher(teacher)
                    .date(date)
                    .startTime(times[0])
                    .endTime(times[1])
                    .room(room == null || room.isEmpty() ? null : room)
                    .instructions(instructions == null || instructions.isEmpty() ? null : instructions)
                    .build());
                count++;
            } catch (Exception e) {
                log.warn("Skipping malformed card for {}: {}", prof.username(), e.getMessage());
            }
        }
        return count;
    }

    /**
     * Returns the value of a card's info-item identified by its icon, e.g. the
     * date for {@code i.fa-calendar-alt}. The value is the first {@code <span>}
     * after the {@code <strong>} label (relative-time badges come after it).
     */
    private String infoItemValue(Element card, String iconSelector) {
        Element item = card.selectFirst("div.info-item:has(" + iconSelector + ")");
        if (item == null) return null;
        Element span = item.selectFirst("div > span");
        return span == null ? null : span.text().trim();
    }

    private Teacher resolveTeacher(String username, String cyrillicName) {
        return teacherRepo.findByConsultationUsername(username).orElseGet(() -> {
            Teacher t = Teacher.builder()
                .consultationUsername(username)
                .cyrillicName(cyrillicName)
                .canonicalName(nameNormalizer.normalize(cyrillicName))
                .build();
            return teacherRepo.save(t);
        });
    }

    private record ProfessorRef(String username, String displayName) {}
}
