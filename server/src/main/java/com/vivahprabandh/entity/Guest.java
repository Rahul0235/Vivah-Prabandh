package com.vivahprabandh.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "guests")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Guest {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    private String mobile;
    private String address;
    private String relation;
    private String gender;
    private String email;

    @Column(nullable = false)
    private String rsvpStatus;

    @Column(length = 1000)
    private String notes;

    private String seating;

    @ManyToOne
    @JoinColumn(name = "event_id")
    private Event event;

    // ✅ Set default before saving
    @PrePersist
    public void setDefaultRsvp() {
        if (this.rsvpStatus == null) {
            this.rsvpStatus = "PENDING";
        }
    }
}