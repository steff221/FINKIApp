package com.finki.scheduler.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Lightweight in-memory fixed-window rate limiter for the unauthenticated auth
 * endpoints, to blunt brute-force and account-spam attempts. Keyed by client IP.
 *
 * Good enough for a single-instance deployment; a multi-instance setup should
 * move this to a shared store (Redis) or the reverse proxy.
 */
@Component
public class RateLimitFilter extends OncePerRequestFilter {

    private static final int    MAX_REQUESTS  = 10;        // per window, per IP
    private static final long   WINDOW_MILLIS = 60_000L;   // 1 minute

    private record Counter(long windowStart, AtomicInteger count) {}

    private final Map<String, Counter> buckets = new ConcurrentHashMap<>();

    @Override
    protected boolean shouldNotFilter(HttpServletRequest req) {
        return !req.getRequestURI().startsWith("/api/auth/");
    }

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res,
                                    FilterChain chain) throws ServletException, IOException {
        String ip = clientIp(req);
        long now = System.currentTimeMillis();

        Counter counter = buckets.compute(ip, (k, existing) -> {
            if (existing == null || now - existing.windowStart() >= WINDOW_MILLIS) {
                return new Counter(now, new AtomicInteger(0));
            }
            return existing;
        });

        if (counter.count().incrementAndGet() > MAX_REQUESTS) {
            res.setStatus(429); // Too Many Requests
            res.setHeader("Retry-After",
                String.valueOf((WINDOW_MILLIS - (now - counter.windowStart())) / 1000));
            res.setContentType("application/json");
            res.getWriter().write("{\"error\":\"Too many requests, please try again later.\"}");
            return;
        }

        chain.doFilter(req, res);
    }

    private String clientIp(HttpServletRequest req) {
        String forwarded = req.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isBlank()) {
            return forwarded.split(",")[0].trim();
        }
        return req.getRemoteAddr();
    }
}
