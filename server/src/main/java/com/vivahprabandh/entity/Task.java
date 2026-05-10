package com.vivahprabandh.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;

@Entity
@Table(name = "tasks")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Task {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;
    private String description;

    private String status;   // PENDING / IN_PROGRESS / COMPLETED
    private String priority; // LOW / MEDIUM / HIGH

    private LocalDate deadline;

    // 🔗 Linked Event
    @ManyToOne
    @JoinColumn(name = "event_id")
    private Event event;

    // 🔗 Assigned Vendor (optional)
    @ManyToOne
    @JoinColumn(name = "vendor_id")
    private Vendor vendor;
}