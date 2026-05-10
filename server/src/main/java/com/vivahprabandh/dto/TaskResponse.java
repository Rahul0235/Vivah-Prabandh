package com.vivahprabandh.dto;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDate;

@Data
@Builder
public class TaskResponse {

    private Long id;
    private String title;
    private String description;
    private String status;
    private String priority;
    private LocalDate deadline;

    private Long eventId;
    private String eventName;

    private Long vendorId;
    private String vendorName;
}