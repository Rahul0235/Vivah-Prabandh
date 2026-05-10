package com.vivahprabandh.service;

import com.vivahprabandh.dto.AddExpenseRequest;
import com.vivahprabandh.entity.Event;
import com.vivahprabandh.entity.Expense;
import com.vivahprabandh.repository.EventRepository;
import com.vivahprabandh.repository.ExpenseRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;

import com.vivahprabandh.dto.CategoryExpenseDTO;
import com.vivahprabandh.dto.MonthlyExpenseDTO;

@Service
@RequiredArgsConstructor
public class ExpenseService {

    private final ExpenseRepository expenseRepository;
    private final EventRepository eventRepository;

    // 🔹 Add Expense
    public Expense addExpense(AddExpenseRequest request) {

        Event event = eventRepository.findById(request.getEventId())
                .orElseThrow(() -> new RuntimeException("Event not found"));

        Expense expense = Expense.builder()
                .category(request.getCategory())
                .amount(request.getAmount())
                .description(request.getDescription())
                .date(request.getDate())
                .event(event)
                .build();

        return expenseRepository.save(expense);
    }

    // 🔹 Get Expenses with Filters
    public List<Expense> getExpenses(Long eventId, String category,
                                     LocalDate startDate, LocalDate endDate) {

        if (category != null && startDate != null && endDate != null) {
            return expenseRepository.findByEventIdAndCategoryIgnoreCaseAndDateBetween(
                    eventId, category, startDate, endDate);
        }

        if (category != null) {
            return expenseRepository.findByEventIdAndCategoryIgnoreCase(eventId, category);
        }

        if (startDate != null && endDate != null) {
            return expenseRepository.findByEventIdAndDateBetween(eventId, startDate, endDate);
        }

        return expenseRepository.findByEventId(eventId);
    }
    // 🔹 Category-wise spending (Pie Chart)
    public List<CategoryExpenseDTO> getCategoryAnalytics(Long eventId) {
        return expenseRepository.getCategoryWiseExpenses(eventId);
    }

// 🔹 Monthly spending (Bar Chart)
public List<MonthlyExpenseDTO> getMonthlyAnalytics(Long eventId) {

    List<Object[]> results = expenseRepository.getMonthlyExpensesRaw(eventId);

    return results.stream()
            .map(r -> new MonthlyExpenseDTO(
                    (String) r[0],
                    ((Number) r[1]).doubleValue()
            ))
            .toList();
    }
}