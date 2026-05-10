package com.vivahprabandh.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class CategoryExpenseDTO {
    private String category;
    private Double totalAmount;
}