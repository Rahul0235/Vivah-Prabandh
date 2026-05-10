package com.vivahprabandh.repository;

import com.vivahprabandh.entity.VendorBooking;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface VendorBookingRepository extends JpaRepository<VendorBooking, Long> {

    List<VendorBooking> findByEventId(Long eventId);

    List<VendorBooking> findByVendorId(Long vendorId);

    List<VendorBooking> findByEventUserId(Long userId);

}