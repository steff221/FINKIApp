package com.finki.scheduler.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

/**
 * Sends operational alerts (e.g. a scraper that failed or returned 0 records)
 * to a configured webhook. The payload carries both {@code content} (Discord)
 * and {@code text} (Slack) keys so a standard incoming webhook from either
 * service works without extra configuration.
 *
 * <p>When no webhook URL is configured the alert is only logged, so the feature
 * is a safe no-op in local/dev environments. Delivery never throws — an alert
 * problem must never break the ingestion that triggered it.
 */
@Slf4j
@Service
public class AlertService {

    @Value("${app.alerts.webhook-url:}")
    private String webhookUrl;

    private final HttpClient http = HttpClient.newBuilder()
        .connectTimeout(Duration.ofSeconds(10))
        .build();

    /** A degraded-but-not-failed condition, e.g. a scrape that stored 0 records. */
    public void warn(String message) {
        send("⚠️ " + message);
    }

    /** A hard failure, e.g. a scrape that threw. */
    public void error(String message) {
        send("🔴 " + message);
    }

    private void send(String text) {
        if (webhookUrl == null || webhookUrl.isBlank()) {
            log.warn("[alert] {} (no app.alerts.webhook-url configured)", text);
            return;
        }
        try {
            String json = "{\"content\":\"" + escape(text) + "\",\"text\":\"" + escape(text) + "\"}";
            HttpRequest req = HttpRequest.newBuilder()
                .uri(URI.create(webhookUrl))
                .timeout(Duration.ofSeconds(10))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(json))
                .build();
            HttpResponse<String> res = http.send(req, HttpResponse.BodyHandlers.ofString());
            if (res.statusCode() >= 300) {
                log.warn("Alert webhook returned HTTP {}: {}", res.statusCode(), res.body());
            }
        } catch (Exception e) {
            // Never let an alerting problem propagate into the caller.
            log.warn("Failed to deliver alert '{}': {}", text, e.getMessage());
        }
    }

    private static String escape(String s) {
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n");
    }
}
