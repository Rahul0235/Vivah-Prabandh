package com.vivahprabandh.controller;

import com.vivahprabandh.dto.CreateEventRequest;
import com.vivahprabandh.dto.EventDetailsRequest;
import com.vivahprabandh.entity.Event;
import com.vivahprabandh.service.EventService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/events")
@RequiredArgsConstructor
public class EventController {

    private final EventService eventService;

    // ✅ Create Event
    @PostMapping
    public Event createEvent(@RequestBody CreateEventRequest request,
                             java.security.Principal principal) {
        String email = principal.getName();
        return eventService.createEvent(request, email);
    }

    // ✅ Get All Events for a User
    @GetMapping("/user/{userId}")
    public List<Event> getEventsByUser(@PathVariable Long userId) {
        return eventService.getEventsByUserId(userId);
    }

    // ✅ Get Event Details
    @GetMapping("/{id}")
    public Event getEvent(@PathVariable Long id) {
        return eventService.getEventById(id);
    }

    // ✅ Update Event Details
    @PutMapping("/{id}")
    public Event updateEventDetails(@PathVariable Long id,
                                    @RequestBody EventDetailsRequest request) {
        return eventService.updateEventDetails(id, request);
    }
}