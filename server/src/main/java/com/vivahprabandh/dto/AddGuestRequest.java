package com.vivahprabandh.dto;

import lombok.Data;

@Data
public class AddGuestRequest {

    private String name;
    private String email;   
    private String mobile;
    private String address;
    private String relation;
    private String gender;
    private Long eventId;
}