package com.vivahprabandh.controller;

import com.vivahprabandh.dto.DashboardResponse;
import com.vivahprabandh.service.DashboardService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class DashboardController {

    private final DashboardService dashboardService;

    @GetMapping("/dashboard")
    public DashboardResponse getDashboard(HttpServletRequest request) {
        String email = (String) request.getAttribute("email");
        return dashboardService.getDashboard(email);
    }
}