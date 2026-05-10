package com.vivahprabandh.service;

import com.vivahprabandh.dto.CreateEventRequest;
import com.vivahprabandh.dto.EventDetailsRequest;
import com.vivahprabandh.entity.Event;
import com.vivahprabandh.entity.User;
import com.vivahprabandh.repository.EventRepository;
import com.vivahprabandh.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class EventService {

    private final EventRepository eventRepository;
    private final UserRepository userRepository;

    // 🔹 Create Event
    public Event createEvent(CreateEventRequest request, String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Event event = Event.builder()
                .name(request.getName())
                .eventDate(request.getEventDate())
                .location(request.getLocation())
                .user(user)
                .build();

        return eventRepository.save(event);
    }

    // 🔹 Get All Events for a User
    public List<Event> getEventsByUserId(Long userId) {
        return eventRepository.findByUserId(userId);
    }

    // 🔹 Get Event Details
    public Event getEventById(Long id) {
        return eventRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Event not found"));
    }

    // 🔹 Update Event Details
    public Event updateEventDetails(Long id, EventDetailsRequest request) {
        Event event = eventRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Event not found"));

        event.setFunctionType(request.getFunctionType());
        event.setTime(request.getTime());
        event.setVenue(request.getVenue());
        event.setDescription(request.getDescription());

        return eventRepository.save(event);
    }
}