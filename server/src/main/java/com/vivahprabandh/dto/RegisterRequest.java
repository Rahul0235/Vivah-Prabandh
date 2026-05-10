package com.vivahprabandh.dto;

import lombok.Data;

@Data
public class RegisterRequest {

    private String name;
    private String email;
    private String password;
    private String mobileNumber;
    private String role;

    // 👇 Vendor fields (optional for USER)
    private String category;
    private String services;
    private Double price;
    private String location;
}