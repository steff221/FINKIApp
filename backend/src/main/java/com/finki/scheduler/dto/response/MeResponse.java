package com.finki.scheduler.dto.response;

/** The signed-in account, without a token — the caller already has one. */
public record MeResponse(Long userId, String email, String name) {}
