package com.vivahprabandh.repository;

import com.vivahprabandh.entity.ReminderLog;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ReminderLogRepository extends JpaRepository<ReminderLog, Long> {

    // Fetch all logs for a specific user, newest first
    List<ReminderLog> findByUserIdOrderBySentAtDesc(Long userId);
}