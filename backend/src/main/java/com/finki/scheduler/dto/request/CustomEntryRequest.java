package com.finki.scheduler.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record CustomEntryRequest(
    @NotBlank String title,
    String professor,
    @NotBlank String entryType,
    @NotNull Integer dayOfWeek,
    @NotBlank String startTime,
    @NotBlank String endTime,
    String room,
    String color
) {}
