package com.vivahprabandh.dto;

import lombok.Data;

import java.time.LocalDate;

@Data
public class AddExpenseRequest {

    private String category;
    private Double amount;
    private String description;
    private LocalDate date;
    private Long eventId;
}