package com.vivahprabandh.service;

import com.vivahprabandh.entity.Vendor;
import com.vivahprabandh.repository.VendorRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class VendorService {

    private final VendorRepository vendorRepository;

    public Vendor registerVendor(Vendor vendor) {
        vendor.setStatus("PENDING");
        return vendorRepository.save(vendor);
    }

    public List<Vendor> getVendorsByCategory(String category) {
        // Only return APPROVED vendors to users
        return vendorRepository.findByCategoryIgnoreCaseAndStatus(category, "APPROVED");
    }

    public Vendor getVendorById(Long id) {
        return vendorRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Vendor not found"));
    }

    // ✅ NEW — resolve vendor entity from email (used by vendor dashboard)
    public Vendor getVendorByEmail(String email) {
        return vendorRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Vendor not found for email: " + email));
    }
}