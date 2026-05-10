package com.vivahprabandh.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class BudgetOverviewResponse {

    private Double totalBudget;
    private Double totalSpent;
    private Double remainingBudget;
}