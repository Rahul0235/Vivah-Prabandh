package com.vivahprabandh.service;

import com.vivahprabandh.dto.BudgetOverviewResponse;
import com.vivahprabandh.entity.Event;
import com.vivahprabandh.entity.Expense;
import com.vivahprabandh.repository.EventRepository;
import com.vivahprabandh.repository.ExpenseRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class BudgetService {

    private final EventRepository eventRepository;
    private final ExpenseRepository expenseRepository;

    public BudgetOverviewResponse getBudgetOverview(Long eventId) {

        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new RuntimeException("Event not found"));

        Double totalBudget = event.getTotalBudget() != null ? event.getTotalBudget() : 0.0;

        List<Expense> expenses = expenseRepository.findByEventId(eventId);

        Double totalSpent = expenses.stream()
                .mapToDouble(Expense::getAmount)
                .sum();

        Double remaining = totalBudget - totalSpent;

        return new BudgetOverviewResponse(totalBudget, totalSpent, remaining);
    }
}