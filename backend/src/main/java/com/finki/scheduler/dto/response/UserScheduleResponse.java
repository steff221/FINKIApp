package com.finki.scheduler.dto.response;

import java.util.List;

public record UserScheduleResponse(
    List<ScheduleSlotResponse> slots,
    List<long[]> conflicts
) {}
