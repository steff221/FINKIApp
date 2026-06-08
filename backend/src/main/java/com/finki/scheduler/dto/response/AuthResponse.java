package com.finki.scheduler.dto.response;

public record AuthResponse(String token, Long userId, String email) {}
