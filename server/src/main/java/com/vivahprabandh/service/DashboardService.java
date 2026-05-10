package com.vivahprabandh.service;

import com.vivahprabandh.dto.DashboardResponse;
import com.vivahprabandh.entity.Event;
import com.vivahprabandh.entity.User;
import com.vivahprabandh.entity.Vendor;
import com.vivahprabandh.entity.VendorBooking;
import com.vivahprabandh.repository.EventRepository;
import com.vivahprabandh.repository.ExpenseRepository;
import com.vivahprabandh.repository.TaskRepository;
import com.vivahprabandh.repository.UserRepository;
import com.vivahprabandh.repository.VendorBookingRepository;
import com.vivahprabandh.repository.VendorRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
public class DashboardService {

    private final UserRepository userRepository;
    private final VendorRepository vendorRepository;
    private final EventRepository eventRepository;
    private final TaskRepository taskRepository;
    private final ExpenseRepository expenseRepository;
    private final VendorBookingRepository vendorBookingRepository;

    public DashboardResponse getDashboard(String email) {

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if ("USER".equalsIgnoreCase(user.getRole())) {
            return buildUserDashboard(user);
        } else if ("VENDOR".equalsIgnoreCase(user.getRole())) {
            return buildVendorDashboard(email);
        }

        throw new RuntimeException("Unknown role: " + user.getRole());
    }

    // ─── USER DASHBOARD ───────────────────────────────────────────────────────

    private DashboardResponse buildUserDashboard(User user) {

        // 1. Total events for this user
        List<Event> userEvents = eventRepository.findByUserId(user.getId());

        int totalEvents = userEvents.size();

        // 2. Total budget = sum of all event budgets
        double totalBudget = userEvents.stream()
                .mapToDouble(e -> e.getTotalBudget() != null ? e.getTotalBudget() : 0.0)
                .sum();

        // 3. Total spent = sum of all expenses across all user events
        double spentAmount = userEvents.stream()
                .flatMap(e -> expenseRepository.findByEventId(e.getId()).stream())
                .mapToDouble(exp -> exp.getAmount() != null ? exp.getAmount() : 0.0)
                .sum();

        // 4. Upcoming tasks = PENDING or IN_PROGRESS tasks with deadline >= today
        int upcomingTasks = (int) userEvents.stream()
                .flatMap(e -> taskRepository.findByEventId(e.getId()).stream())
                .filter(t -> {
                    boolean notCompleted = !"COMPLETED".equalsIgnoreCase(t.getStatus());
                    boolean notOverdue = t.getDeadline() == null || !t.getDeadline().isBefore(LocalDate.now());
                    return notCompleted && notOverdue;
                })
                .count();

        return new DashboardResponse(
                "USER",
                totalEvents,
                totalBudget,
                spentAmount,
                upcomingTasks,
                null,
                null,
                null
        );
    }

    // ─── VENDOR DASHBOARD ─────────────────────────────────────────────────────

    private DashboardResponse buildVendorDashboard(String email) {

        Vendor vendor = vendorRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Vendor not found"));

        List<VendorBooking> allBookings = vendorBookingRepository.findByVendorId(vendor.getId());

        // 1. Pending bookings
        int pendingBookings = (int) allBookings.stream()
                .filter(b -> "PENDING".equalsIgnoreCase(b.getBookingStatus()))
                .count();

        // 2. Confirmed events
        int confirmedEvents = (int) allBookings.stream()
                .filter(b -> "CONFIRMED".equalsIgnoreCase(b.getBookingStatus()))
                .count();

        // 3. Total earnings = sum of expenses linked to confirmed bookings events
        double totalEarnings = allBookings.stream()
                .filter(b -> "CONFIRMED".equalsIgnoreCase(b.getBookingStatus()))
                .flatMap(b -> expenseRepository.findByEventId(b.getEvent().getId()).stream())
                .mapToDouble(e -> e.getAmount() != null ? e.getAmount() : 0.0)
                .sum();

        return new DashboardResponse(
                "VENDOR",
                null,
                null,
                null,
                null,
                pendingBookings,
                confirmedEvents,
                totalEarnings
        );
    }
}