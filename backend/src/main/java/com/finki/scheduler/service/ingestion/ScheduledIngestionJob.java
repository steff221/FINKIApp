package com.finki.scheduler.service.ingestion;

import com.finki.scheduler.domain.IngestionLog;
import com.finki.scheduler.repository.IngestionLogRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * Scheduled entry points for both ingestion jobs.
 * A simple lock prevents concurrent runs (scheduled + manual trigger).
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ScheduledIngestionJob {

    /** If the last successful run is older than this, run a catch-up on startup. */
    private static final Duration STALE_AFTER = Duration.ofHours(24);

    private final EduPageIngestionService edupageService;
    private final ConsultationScraperService consultationService;
    private final IngestionLogRepository ingestionLogRepo;

    private final AtomicBoolean timetableRunning    = new AtomicBoolean(false);
    private final AtomicBoolean consultationsRunning = new AtomicBoolean(false);

    /**
     * Catch-up safety net: the daily cron jobs only fire if the app is up at
     * 03:00/04:00. If it was down then, the last successful ingestion can be
     * stale. On startup, re-run any source whose latest success is older than
     * {@link #STALE_AFTER} (or has never succeeded). Runs off the startup
     * thread so a slow scrape never delays application readiness.
     */
    @EventListener(ApplicationReadyEvent.class)
    public void catchUpOnStartup() {
        Thread.ofVirtual().name("ingestion-catchup").start(() -> {
            if (isStale(IngestionLog.Source.TIMETABLE))     runTimetable();
            if (isStale(IngestionLog.Source.CONSULTATIONS)) runConsultations();
        });
    }

    private boolean isStale(IngestionLog.Source source) {
        Instant last = ingestionLogRepo
            .findTopBySourceAndStatusOrderByStartedAtDesc(source, IngestionLog.Status.SUCCESS)
            .map(l -> l.getCompletedAt() != null ? l.getCompletedAt() : l.getStartedAt())
            .orElse(null);
        if (last == null) {
            log.info("No successful {} ingestion on record — running startup catch-up.", source);
            return true;
        }
        boolean stale = last.isBefore(Instant.now().minus(STALE_AFTER));
        if (stale) {
            log.info("Last successful {} ingestion was at {} (>{}h ago) — running startup catch-up.",
                source, last, STALE_AFTER.toHours());
        } else {
            log.info("Last successful {} ingestion was at {} — fresh, skipping startup catch-up.", source, last);
        }
        return stale;
    }

    /** Daily at 03:00 — timetable changes rarely; this catches any faculty republish. */
    @Scheduled(cron = "0 0 3 * * *")
    public void scheduledTimetable() {
        runTimetable();
    }

    /** Daily at 04:00 — consultation window shifts every day. */
    @Scheduled(cron = "0 0 4 * * *")
    public void scheduledConsultations() {
        runConsultations();
    }

    public int runTimetable() {
        if (!timetableRunning.compareAndSet(false, true)) {
            log.warn("Timetable ingestion already running; skipping.");
            return -1;
        }
        try {
            log.info("Starting timetable ingestion");
            return edupageService.ingest();
        } finally {
            timetableRunning.set(false);
        }
    }

    public int runConsultations() {
        if (!consultationsRunning.compareAndSet(false, true)) {
            log.warn("Consultation scrape already running; skipping.");
            return -1;
        }
        try {
            log.info("Starting consultation scrape");
            return consultationService.scrape();
        } finally {
            consultationsRunning.set(false);
        }
    }

    public boolean isTimetableRunning()     { return timetableRunning.get(); }
    public boolean isConsultationsRunning() { return consultationsRunning.get(); }
}
