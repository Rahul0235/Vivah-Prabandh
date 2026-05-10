package com.vivahprabandh.controller;

import com.vivahprabandh.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminDashboardController {

    private final UserRepository userRepository;
    private final VendorRepository vendorRepository;
    private final VendorBookingRepository vendorBookingRepository;
    private final TaskRepository taskRepository;

    @GetMapping("/dashboard")
    public Map<String, Object> getDashboardStats() {

        Map<String, Object> stats = new HashMap<>();

        stats.put("totalUsers", userRepository.count());
        stats.put("totalVendors", vendorRepository.count());
        stats.put("pendingVendors", vendorRepository.findByStatus("PENDING").size());
        stats.put("totalBookings", vendorBookingRepository.count());
        stats.put("totalTasks", taskRepository.count());

        return stats;
    }
}