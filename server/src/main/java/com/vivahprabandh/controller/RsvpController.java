package com.vivahprabandh.controller;

import com.vivahprabandh.entity.Guest;
import com.vivahprabandh.repository.GuestRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/rsvp")
@RequiredArgsConstructor
public class RsvpController {

    private final GuestRepository guestRepository;

    @GetMapping("/accept/{guestId}")
    public String acceptInvite(@PathVariable Long guestId) {

        Guest guest = guestRepository.findById(guestId)
                .orElseThrow(() -> new RuntimeException("Guest not found"));

        guest.setRsvpStatus("ACCEPTED");
        guestRepository.save(guest);

        return "Thank you! You accepted the invitation.";
    }

    @GetMapping("/decline/{guestId}")
    public String declineInvite(@PathVariable Long guestId) {

        Guest guest = guestRepository.findById(guestId)
                .orElseThrow(() -> new RuntimeException("Guest not found"));

        guest.setRsvpStatus("DECLINED");
        guestRepository.save(guest);

        return "You declined the invitation.";
    }
}