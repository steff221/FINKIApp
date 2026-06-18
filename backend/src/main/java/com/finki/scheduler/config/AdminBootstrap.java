package com.finki.scheduler.config;

import com.finki.scheduler.domain.User;
import com.finki.scheduler.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.ApplicationArguments;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

/**
 * Ensures an admin account exists on startup. Configured via {@code APP_ADMIN_EMAIL}
 * and {@code APP_ADMIN_PASSWORD}:
 *   - if a user with that email exists, it is promoted to {@link User.Role#ADMIN};
 *   - otherwise, if a password is provided, the account is created with ADMIN.
 * When no admin email is configured the runner is a no-op.
 */
@Component
@RequiredArgsConstructor
public class AdminBootstrap implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(AdminBootstrap.class);

    private final UserRepository userRepo;
    private final PasswordEncoder passwordEncoder;

    @Value("${app.admin.email:}")
    private String adminEmail;

    @Value("${app.admin.password:}")
    private String adminPassword;

    @Override
    public void run(ApplicationArguments args) {
        if (adminEmail == null || adminEmail.isBlank()) {
            log.info("No app.admin.email configured — skipping admin bootstrap.");
            return;
        }
        String email = adminEmail.trim().toLowerCase();

        userRepo.findByEmail(email).ifPresentOrElse(user -> {
            if (user.getRole() != User.Role.ADMIN) {
                user.setRole(User.Role.ADMIN);
                userRepo.save(user);
                log.info("Promoted existing user {} to ADMIN.", email);
            }
        }, () -> {
            if (adminPassword == null || adminPassword.isBlank()) {
                log.warn("Admin email {} not found and no app.admin.password set — cannot create admin.", email);
                return;
            }
            userRepo.save(User.builder()
                .email(email)
                .passwordHash(passwordEncoder.encode(adminPassword))
                .role(User.Role.ADMIN)
                .build());
            log.info("Created admin account {}.", email);
        });
    }
}
