package com.vivahprabandh.controller;

import com.vivahprabandh.dto.BookVendorRequest;
import com.vivahprabandh.dto.VendorBookingResponse;
import com.vivahprabandh.entity.VendorBooking;
import com.vivahprabandh.service.VendorBookingService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/vendor-bookings")
@RequiredArgsConstructor
public class VendorBookingController {

    private final VendorBookingService bookingService;

    // ✅ Book Vendor (User)
    @PostMapping
    public VendorBooking bookVendor(@RequestBody BookVendorRequest request) {
        return bookingService.bookVendor(request);
    }

    // ✅ Vendor confirms booking
    @PutMapping("/{id}/confirm")
    public VendorBooking confirmBooking(@PathVariable Long id) {
        return bookingService.updateBookingStatus(id, "CONFIRMED");
    }

    // ❌ Vendor rejects booking
    @PutMapping("/{id}/reject")
    public VendorBooking rejectBooking(@PathVariable Long id) {
        return bookingService.updateBookingStatus(id, "REJECTED");
    }

    // 💰 Vendor marks payment paid
    @PutMapping("/{id}/payment-paid")
    public VendorBooking markPaymentPaid(@PathVariable Long id) {
        return bookingService.updatePaymentStatus(id, "PAID");
    }

    // ✅ Get bookings by vendor (vendor dashboard)
    @GetMapping("/vendor/{vendorId}")
    public List<VendorBookingResponse> getVendorBookings(@PathVariable Long vendorId) {
        return bookingService.getBookingsByVendor(vendorId);
    }

    // ✅ Get bookings by user (booking status page) — ADD THIS
    @GetMapping("/user/{userId}")
    public List<VendorBookingResponse> getUserBookings(@PathVariable Long userId) {
        return bookingService.getBookingsByUser(userId);
    }
}