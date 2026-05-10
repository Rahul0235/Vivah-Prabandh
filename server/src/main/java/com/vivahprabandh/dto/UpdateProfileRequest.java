package com.vivahprabandh.dto;

import lombok.Data;

@Data
public class UpdateProfileRequest {

    private String name;
    private String mobileNumber;
    private String profileImageUrl;
}