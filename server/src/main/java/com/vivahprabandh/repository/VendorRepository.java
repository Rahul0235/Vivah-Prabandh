package com.vivahprabandh.repository;

import com.vivahprabandh.entity.Vendor;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.List;

public interface VendorRepository extends JpaRepository<Vendor, Long> {

    // 🔹 Admin: pending vendors
    List<Vendor> findByStatus(String status);
    Optional<Vendor> findByEmail(String email);

    // 🔹 User: vendors by category
    List<Vendor> findByCategoryIgnoreCase(String category);

    // 🔹 User: only approved vendors
    List<Vendor> findByCategoryIgnoreCaseAndStatus(String category, String status);

}