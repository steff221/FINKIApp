package com.finki.scheduler.repository;

import com.finki.scheduler.domain.IngestionLog;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface IngestionLogRepository extends JpaRepository<IngestionLog, Long> {
    Optional<IngestionLog> findTopBySourceOrderByStartedAtDesc(IngestionLog.Source source);
}
