package com.vivahprabandh.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class ProfileResponse {

    private Long id;
    private String name;
    private String email;
    private String mobileNumber;
    private String role;
    private String profileImageUrl;
}