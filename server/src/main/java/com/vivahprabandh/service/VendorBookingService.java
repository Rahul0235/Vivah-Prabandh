package com.vivahprabandh.service;

import com.vivahprabandh.dto.BookVendorRequest;
import com.vivahprabandh.dto.VendorBookingResponse;
import com.vivahprabandh.entity.Event;
import com.vivahprabandh.entity.Vendor;
import com.vivahprabandh.entity.VendorBooking;
import com.vivahprabandh.repository.EventRepository;
import com.vivahprabandh.repository.VendorBookingRepository;
import com.vivahprabandh.repository.VendorRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class VendorBookingService {

    private final VendorBookingRepository bookingRepository;
    private final VendorRepository vendorRepository;
    private final EventRepository eventRepository;

    public VendorBooking bookVendor(BookVendorRequest request) {
        Vendor vendor = vendorRepository.findById(request.getVendorId())
                .orElseThrow(() -> new RuntimeException("Vendor not found"));
        Event event = eventRepository.findById(request.getEventId())
                .orElseThrow(() -> new RuntimeException("Event not found"));

        VendorBooking booking = VendorBooking.builder()
                .vendor(vendor)
                .event(event)
                .bookingDate(request.getBookingDate())
                .service(request.getService())
                .paymentMethod(request.getPaymentMethod())
                .notes(request.getNotes())
                .userName(request.getUserName())
                .userContact(request.getUserContact())
                .eventLocation(request.getEventLocation())
                .bookingStatus("PENDING")
                .paymentStatus("PENDING")
                .build();

        return bookingRepository.save(booking);
    }

    public VendorBooking updateBookingStatus(Long id, String status) {
        VendorBooking booking = bookingRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Booking not found"));
        booking.setBookingStatus(status);
        return bookingRepository.save(booking);
    }

    public VendorBooking updatePaymentStatus(Long id, String status) {
        VendorBooking booking = bookingRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Booking not found"));
        booking.setPaymentStatus(status);
        return bookingRepository.save(booking);
    }

    public List<VendorBookingResponse> getBookingsByVendor(Long vendorId) {
        return bookingRepository.findByVendorId(vendorId)
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    // ✅ NEW — used by booking status page
    public List<VendorBookingResponse> getBookingsByUser(Long userId) {
        return bookingRepository.findByEventUserId(userId)
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    private VendorBookingResponse toResponse(VendorBooking b) {
        return new VendorBookingResponse(
                b.getId(),
                b.getBookingDate(),
                b.getService(),
                b.getBookingStatus(),
                b.getPaymentStatus(),
                b.getUserName(),
                b.getUserContact(),
                b.getEvent() != null ? b.getEvent().getName() : null,
                b.getEventLocation()
        );
    }
}