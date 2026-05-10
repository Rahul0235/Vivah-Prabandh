package com.vivahprabandh.controller;

import com.vivahprabandh.entity.Vendor;
import com.vivahprabandh.service.VendorService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/vendors")
@RequiredArgsConstructor
public class VendorController {

    private final VendorService vendorService;

    // ✅ Register vendor → PENDING
    @PostMapping("/register")
    public Vendor registerVendor(@RequestBody Vendor vendor) {
        return vendorService.registerVendor(vendor);
    }

    // 🔍 Get vendors by category (only APPROVED)
    @GetMapping("/category/{category}")
    public List<Vendor> getVendorsByCategory(@PathVariable String category) {
        return vendorService.getVendorsByCategory(category);
    }

    // 🔍 Get vendor by ID
    @GetMapping("/{id}")
    public Vendor getVendorById(@PathVariable Long id) {
        return vendorService.getVendorById(id);
    }

    // ✅ Get vendor by email — used to resolve vendor ID from logged-in user email
    @GetMapping("/by-email")
    public Vendor getVendorByEmail(@RequestParam String email) {
        return vendorService.getVendorByEmail(email);
    }
}