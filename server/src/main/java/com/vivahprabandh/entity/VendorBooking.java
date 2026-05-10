package com.vivahprabandh.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;

@Entity
@Table(name = "vendor_bookings")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VendorBooking {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private LocalDate bookingDate;

    private String service;

    // ✅ Booking Status
    private String bookingStatus;   // PENDING / CONFIRMED / REJECTED

    private String paymentMethod;   // CASH / ONLINE
    private String paymentStatus;   // PENDING / PAID

    @Column(length = 1000)
    private String notes;

    private String userName;
    private String userContact;
    private String eventLocation;

    @ManyToOne
    @JoinColumn(name = "vendor_id")
    private Vendor vendor;

    @ManyToOne
    @JoinColumn(name = "event_id")
    private Event event;
}