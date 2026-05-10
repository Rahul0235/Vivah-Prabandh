package com.vivahprabandh.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.time.LocalDate;

@Data
@AllArgsConstructor
public class VendorBookingResponse {

    private Long bookingId;
    private LocalDate bookingDate;
    private String service;
    private String bookingStatus;
    private String paymentStatus;

    private String userName;
    private String userContact;

    private String eventName;
    private String eventLocation;
}