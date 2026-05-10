package com.vivahprabandh.controller;

import com.vivahprabandh.entity.ReminderLog;
import com.vivahprabandh.repository.ReminderLogRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class ReminderController {

    private final ReminderLogRepository reminderLogRepository;

    // GET /api/notifications/{userId}
    @GetMapping("/{userId}")
    public List<ReminderLog> getNotifications(@PathVariable Long userId) {
        return reminderLogRepository.findByUserIdOrderBySentAtDesc(userId);
    }
}