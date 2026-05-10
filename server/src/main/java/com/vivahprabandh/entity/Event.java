package com.vivahprabandh.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "events")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Event {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // Basic Info
    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String eventDate;

    @Column(nullable = false)
    private String location;

    private Double totalBudget;

    // Event Details
    private String functionType;
    private String time;
    private String venue;

    @Column(length = 1000)
    private String description;

    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user;
}