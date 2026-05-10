package com.vivahprabandh.dto;

import lombok.Data;
import java.time.LocalDate;

@Data
public class UpdateTaskRequest {

    private String title;
    private String description;
    private String status;   // PENDING / IN_PROGRESS / COMPLETED
    private String priority; // LOW / MEDIUM / HIGH
    private LocalDate deadline;
    private Long vendorId;
}