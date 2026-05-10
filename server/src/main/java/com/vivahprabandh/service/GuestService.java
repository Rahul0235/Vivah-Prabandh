package com.vivahprabandh.service;

import com.vivahprabandh.dto.AddGuestRequest;
import com.vivahprabandh.dto.GuestDetailsRequest;
import com.vivahprabandh.entity.Event;
import com.vivahprabandh.entity.Guest;
import com.vivahprabandh.repository.EventRepository;
import com.vivahprabandh.repository.GuestRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class GuestService {

    private final GuestRepository guestRepository;
    private final EventRepository eventRepository;
    private final EmailService emailService;  // ✅ ADD THIS

    // 🔹 Add Guest
    public Guest addGuest(AddGuestRequest request) {

        Event event = eventRepository.findById(request.getEventId())
                .orElseThrow(() -> new RuntimeException("Event not found"));

        Guest guest = Guest.builder()
                .name(request.getName())
                .email(request.getEmail())
                .mobile(request.getMobile())
                .address(request.getAddress())
                .relation(request.getRelation())
                .gender(request.getGender())
                .event(event)
                .rsvpStatus("PENDING")
                .build();

        Guest savedGuest = guestRepository.save(guest);

        // ✅ SEND EMAIL INVITATION
        if (savedGuest.getEmail() != null && !savedGuest.getEmail().isEmpty()) {
            System.out.println("Sending email to: " + savedGuest.getEmail());

        emailService.sendInvitationEmail(
            savedGuest.getEmail(),
            savedGuest.getName(),
            event.getName(),
            event.getEventDate().toString(),
            event.getLocation(),
            savedGuest.getId()
          );
        }

        return savedGuest;
    }

    // 🔹 Get Guests with filters
    public List<Guest> getGuests(Long eventId, String name, String gender, String rsvpStatus) {

        if (eventId == null) {
            throw new RuntimeException("eventId is required");
        }

        if (name != null && !name.isEmpty()) {
            return guestRepository.findByEventIdAndNameContainingIgnoreCase(eventId, name);
        }

        if (gender != null && rsvpStatus != null) {
            return guestRepository.findByEventIdAndGenderIgnoreCaseAndRsvpStatusIgnoreCase(eventId, gender, rsvpStatus);
        }

        if (gender != null) {
            return guestRepository.findByEventIdAndGenderIgnoreCase(eventId, gender);
        }

        if (rsvpStatus != null) {
            return guestRepository.findByEventIdAndRsvpStatusIgnoreCase(eventId, rsvpStatus);
        }

        return guestRepository.findByEventId(eventId);
    }

    // 🔹 Get Guest Details
    public Guest getGuestById(Long id) {
        return guestRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Guest not found"));
    }

    // 🔹 Update Guest Details
    public Guest updateGuestDetails(Long id, GuestDetailsRequest request) {

        Guest guest = guestRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Guest not found"));

        guest.setNotes(request.getNotes());
        guest.setSeating(request.getSeating());

        if (request.getRsvpStatus() != null) {
            guest.setRsvpStatus(request.getRsvpStatus());
        }

        return guestRepository.save(guest);
    }
}