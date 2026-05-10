package com.vivahprabandh.dto;

import lombok.Data;

@Data
public class EventDetailsRequest {

    private String functionType;
    private String time;
    private String venue;
    private String description;
}