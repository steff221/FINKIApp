package com.finki.scheduler.service.ingestion;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.concurrent.atomic.AtomicBoolean;

/**
 * Scheduled entry points for both ingestion jobs.
 * A simple lock prevents concurrent runs (scheduled + manual trigger).
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ScheduledIngestionJob {

    private final EduPageIngestionService edupageService;
    private final ConsultationScraperService consultationService;

    private final AtomicBoolean timetableRunning    = new AtomicBoolean(false);
    private final AtomicBoolean consultationsRunning = new AtomicBoolean(false);

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
