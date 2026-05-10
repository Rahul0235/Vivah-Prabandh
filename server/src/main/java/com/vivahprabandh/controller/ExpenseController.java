package com.vivahprabandh.controller;

import com.vivahprabandh.dto.AddExpenseRequest;
import com.vivahprabandh.entity.Expense;
import com.vivahprabandh.service.ExpenseService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

import com.vivahprabandh.dto.CategoryExpenseDTO;
import com.vivahprabandh.dto.MonthlyExpenseDTO;

@RestController
@RequestMapping("/api/expenses")
@RequiredArgsConstructor
public class ExpenseController {

    private final ExpenseService expenseService;

    // ✅ Add Expense
    @PostMapping
    public Expense addExpense(@RequestBody AddExpenseRequest request) {
        return expenseService.addExpense(request);
    }

    // ✅ Expense History with Filters
    @GetMapping
    public List<Expense> getExpenses(
            @RequestParam Long eventId,
            @RequestParam(required = false) String category,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {

        return expenseService.getExpenses(eventId, category, startDate, endDate);
    }
    // 📊 Pie Chart Data
    @GetMapping("/analytics/category")
    public List<CategoryExpenseDTO> getCategoryAnalytics(@RequestParam Long eventId) {
       return expenseService.getCategoryAnalytics(eventId);
    }

// 📊 Bar Chart Data
    @GetMapping("/analytics/monthly")
    public List<MonthlyExpenseDTO> getMonthlyAnalytics(@RequestParam Long eventId) {
        return expenseService.getMonthlyAnalytics(eventId);
    }
}