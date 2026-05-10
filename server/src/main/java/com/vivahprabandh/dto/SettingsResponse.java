package com.vivahprabandh.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class SettingsResponse {

    private String theme;
    private Boolean emailNotifications;
    private Boolean reminderNotifications;
    private Boolean showContact;
}