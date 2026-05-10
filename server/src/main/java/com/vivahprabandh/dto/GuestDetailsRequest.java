package com.vivahprabandh.dto;

import lombok.Data;

@Data
public class GuestDetailsRequest {

    private String notes;
    private String seating;
    private String rsvpStatus; // ACCEPTED / PENDING / DECLINED
}