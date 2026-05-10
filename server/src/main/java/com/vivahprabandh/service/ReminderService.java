package com.vivahprabandh.service;

import com.vivahprabandh.entity.ReminderLog;
import com.vivahprabandh.entity.Task;
import com.vivahprabandh.entity.User;
import com.vivahprabandh.repository.ReminderLogRepository;
import com.vivahprabandh.repository.TaskRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class ReminderService {

    private final TaskRepository taskRepository;
    private final EmailService emailService;
    private final ReminderLogRepository reminderLogRepository;

    // 🔔 Runs daily at 8 AM
    @Scheduled(cron = "0 0 8 * * ?")
    public void sendTaskReminders() {

        LocalDate tomorrow = LocalDate.now().plusDays(1);
        LocalDate today    = LocalDate.now();

        List<Task> upcomingTasks = taskRepository.findByDeadline(tomorrow);
        List<Task> overdueTasks  = taskRepository.findByDeadlineBefore(today);

        upcomingTasks.forEach(task -> {
            User user    = task.getEvent().getUser();
            String email   = user.getEmail();
            String subject = "Reminder: Task Due Tomorrow";
            String body    = "Task: " + task.getTitle() +
                             "\nDeadline: " + task.getDeadline();

            emailService.sendSimpleEmail(email, subject, body);

            // ✅ Log the reminder
            reminderLogRepository.save(ReminderLog.builder()
                    .recipientEmail(email)
                    .subject(subject)
                    .body(body)
                    .type("UPCOMING")
                    .taskTitle(task.getTitle())
                    .sentAt(LocalDateTime.now())
                    .user(user)
                    .build());
        });

        overdueTasks.forEach(task -> {
            User user    = task.getEvent().getUser();
            String email   = user.getEmail();
            String subject = "Overdue Task Alert";
            String body    = "Task: " + task.getTitle() +
                             "\nDeadline was: " + task.getDeadline();

            emailService.sendSimpleEmail(email, subject, body);

            // ✅ Log the reminder
            reminderLogRepository.save(ReminderLog.builder()
                    .recipientEmail(email)
                    .subject(subject)
                    .body(body)
                    .type("OVERDUE")
                    .taskTitle(task.getTitle())
                    .sentAt(LocalDateTime.now())
                    .user(user)
                    .build());
        });
    }
}