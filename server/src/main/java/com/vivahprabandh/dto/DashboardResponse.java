package com.vivahprabandh.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class DashboardResponse {

    private String role;

    // USER fields
    private Integer totalEvents;
    private Double totalBudget;
    private Double spentAmount;
    private Integer upcomingTasks;

    // VENDOR fields
    private Integer pendingBookings;
    private Integer confirmedEvents;
    private Double totalEarnings;
}