package com.vivahprabandh.controller;

import com.vivahprabandh.entity.*;
import com.vivahprabandh.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

// @CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {

    private final UserRepository userRepository;
    private final VendorRepository vendorRepository;
    private final EventRepository eventRepository;
    private final VendorBookingRepository vendorBookingRepository;
    private final TaskRepository taskRepository;

    @GetMapping("/users")
    public List<User> getAllUsers() {
        return userRepository.findAll();
    }

    @GetMapping("/vendors")
    public List<Vendor> getAllVendors() {
        return vendorRepository.findAll();
    }

    @GetMapping("/events")
    public List<Event> getAllEvents() {
        return eventRepository.findAll();
    }

    @GetMapping("/bookings")
    public List<VendorBooking> getAllBookings() {
        return vendorBookingRepository.findAll();
    }

    @GetMapping("/tasks")
    public List<Task> getAllTasks() {
        return taskRepository.findAll();
    }
}