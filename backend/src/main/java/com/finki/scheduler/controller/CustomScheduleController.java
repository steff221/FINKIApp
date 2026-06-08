package com.finki.scheduler.controller;

import com.finki.scheduler.domain.User;
import com.finki.scheduler.dto.request.CustomEntryRequest;
import com.finki.scheduler.dto.response.CustomEntryResponse;
import com.finki.scheduler.service.CustomScheduleService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/schedule/custom")
@RequiredArgsConstructor
public class CustomScheduleController {

    private final CustomScheduleService service;

    @GetMapping
    public List<CustomEntryResponse> getAll(@AuthenticationPrincipal User user) {
        return service.getAll(user.getId());
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public CustomEntryResponse create(@AuthenticationPrincipal User user,
                                      @Valid @RequestBody CustomEntryRequest req) {
        return service.create(user.getId(), req);
    }

    @PutMapping("/{id}")
    public CustomEntryResponse update(@AuthenticationPrincipal User user,
                                      @PathVariable Long id,
                                      @Valid @RequestBody CustomEntryRequest req) {
        return service.update(user.getId(), id, req);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@AuthenticationPrincipal User user, @PathVariable Long id) {
        service.delete(user.getId(), id);
    }
}
