package com.vivahprabandh.dto;

import lombok.Data;

@Data
public class UpdateSettingsRequest {

    private String theme;
    private Boolean emailNotifications;
    private Boolean reminderNotifications;
    private Boolean showContact;
}