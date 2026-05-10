package com.vivahprabandh.controller;

import com.vivahprabandh.dto.BudgetOverviewResponse;
import com.vivahprabandh.service.BudgetService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/budget")
@RequiredArgsConstructor
public class BudgetController {

    private final BudgetService budgetService;

    @GetMapping("/overview")
    public BudgetOverviewResponse getOverview(@RequestParam Long eventId) {
        return budgetService.getBudgetOverview(eventId);
    }
}