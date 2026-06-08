package com.finki.scheduler.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RegisterRequest(
    @NotBlank String email,
    @NotBlank @Size(min = 8, max = 100) String password
) {}
