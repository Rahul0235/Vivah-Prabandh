package com.vivahprabandh.controller;

import com.vivahprabandh.dto.AddGuestRequest;
import com.vivahprabandh.dto.GuestDetailsRequest;
import com.vivahprabandh.entity.Guest;
import com.vivahprabandh.service.GuestService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/guests")
@RequiredArgsConstructor
public class GuestController {

    private final GuestService guestService;

    // ✅ Add Guest
    @PostMapping
    public Guest addGuest(@RequestBody AddGuestRequest request) {
        return guestService.addGuest(request);
    }

    // ✅ Guest List
    @GetMapping
    public List<Guest> getGuests(
            @RequestParam Long eventId,
            @RequestParam(required = false) String name,
            @RequestParam(required = false) String gender,
            @RequestParam(required = false) String rsvpStatus) {

        return guestService.getGuests(eventId, name, gender, rsvpStatus);
    }

    // ✅ Get Guest Details
    @GetMapping("/{id}")
    public Guest getGuest(@PathVariable Long id) {
        return guestService.getGuestById(id);
    }

    // ✅ Update Guest Details
    @PutMapping("/{id}")
    public Guest updateGuest(@PathVariable Long id,
                             @RequestBody GuestDetailsRequest request) {
        return guestService.updateGuestDetails(id, request);
    }
}