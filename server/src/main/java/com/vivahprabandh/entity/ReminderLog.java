package com.vivahprabandh.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "reminder_logs")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReminderLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String recipientEmail;

    private String subject;

    @Column(length = 1000)
    private String body;

    private String type;  // UPCOMING / OVERDUE

    private String taskTitle;

    private LocalDateTime sentAt;

    // Link back to user so we can fetch per-user history
    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user;
}