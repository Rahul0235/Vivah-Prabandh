package com.vivahprabandh.dto;

import lombok.Data;

@Data
public class CreateEventRequest {
    private String name;
    private String eventDate;
    private String location;
}