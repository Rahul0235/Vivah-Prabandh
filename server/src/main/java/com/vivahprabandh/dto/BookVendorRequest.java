package com.vivahprabandh.dto;

import lombok.Data;

import java.time.LocalDate;

@Data
public class BookVendorRequest {

    private Long vendorId;
    private Long eventId;
    private LocalDate bookingDate;
    private String service;
    private String paymentMethod;  // CASH / ONLINE
    private String notes;
    private String userName;
    private String userContact;
    private String eventLocation;
}