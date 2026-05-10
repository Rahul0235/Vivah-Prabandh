package com.vivahprabandh.dto;

import lombok.Data;
import java.time.LocalDate;

@Data
public class AddTaskRequest {

    private String title;
    private String description;
    private String priority;
    private LocalDate deadline;
    private Long eventId;
    private Long vendorId; // optional
}