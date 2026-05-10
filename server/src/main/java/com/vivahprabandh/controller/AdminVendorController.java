package com.vivahprabandh.controller;

import com.vivahprabandh.entity.Vendor;
import com.vivahprabandh.repository.VendorRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/vendors")
@RequiredArgsConstructor
public class AdminVendorController {

    private final VendorRepository vendorRepository;

    // GET /api/admin/vendors/pending — existing
    @GetMapping("/pending")
    public List<Vendor> getPendingVendors() {
        return vendorRepository.findByStatus("PENDING");
    }

    // GET /api/admin/vendors/all — NEW: returns ALL vendors (Flutter filters client-side)
    @GetMapping("/all")
    public List<Vendor> getAllVendors() {
        return vendorRepository.findAll();
    }

    // PUT /api/admin/vendors/{id}/approve — existing
    @PutMapping("/{id}/approve")
    public String approveVendor(@PathVariable Long id) {
        Vendor vendor = vendorRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Vendor not found"));
        vendor.setStatus("APPROVED");
        vendorRepository.save(vendor);
        return "Vendor approved";
    }

    // PUT /api/admin/vendors/{id}/reject — existing
    @PutMapping("/{id}/reject")
    public String rejectVendor(@PathVariable Long id) {
        Vendor vendor = vendorRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Vendor not found"));
        vendor.setStatus("REJECTED");
        vendorRepository.save(vendor);
        return "Vendor rejected";
    }
}