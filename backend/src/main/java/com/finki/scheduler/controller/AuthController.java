package com.finki.scheduler.controller;

import com.finki.scheduler.domain.User;
import com.finki.scheduler.dto.request.LoginRequest;
import com.finki.scheduler.dto.request.RegisterRequest;
import com.finki.scheduler.dto.response.AuthResponse;
import com.finki.scheduler.dto.response.MeResponse;
import com.finki.scheduler.repository.UserRepository;
import com.finki.scheduler.security.JwtUtil;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final UserRepository userRepo;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest req) {
        if (userRepo.existsByEmail(req.email())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Email already registered");
        }
        User user = userRepo.save(User.builder()
            .email(req.email())
            .name(req.name())
            .passwordHash(passwordEncoder.encode(req.password()))
            .build());
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(new AuthResponse(jwtUtil.generate(user.getId(), user.getEmail()),
                user.getId(), user.getEmail(), user.getName()));
    }

    @PostMapping("/login")
    public AuthResponse login(@Valid @RequestBody LoginRequest req) {
        User user = userRepo.findByEmail(req.email())
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Bad credentials"));
        if (!passwordEncoder.matches(req.password(), user.getPasswordHash())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Bad credentials");
        }
        return new AuthResponse(jwtUtil.generate(user.getId(), user.getEmail()),
            user.getId(), user.getEmail(), user.getName());
    }

    /**
     * The signed-in account as the server sees it now.
     *
     * <p>A token says who you are but carries none of your details, so a client
     * that signed in before a field existed has no way to learn about it short
     * of making the student log in again. This is that way.
     */
    @GetMapping("/me")
    public MeResponse me(@AuthenticationPrincipal User principal) {
        User user = userRepo.findById(principal.getId())
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Unknown account"));
        return new MeResponse(user.getId(), user.getEmail(), user.getName());
    }
}
