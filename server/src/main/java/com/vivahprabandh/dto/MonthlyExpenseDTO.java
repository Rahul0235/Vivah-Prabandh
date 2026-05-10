package com.vivahprabandh.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class MonthlyExpenseDTO {
    private String month;
    private Double totalAmount;
}