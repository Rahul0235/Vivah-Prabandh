package com.vivahprabandh.repository;

import com.vivahprabandh.entity.Guest;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface GuestRepository extends JpaRepository<Guest, Long> {

    List<Guest> findByEventId(Long eventId);

    List<Guest> findByEventIdAndNameContainingIgnoreCase(Long eventId, String name);

    List<Guest> findByEventIdAndGenderIgnoreCase(Long eventId, String gender);

    List<Guest> findByEventIdAndRsvpStatusIgnoreCase(Long eventId, String rsvpStatus);

    List<Guest> findByEventIdAndGenderIgnoreCaseAndRsvpStatusIgnoreCase(Long eventId, String gender, String rsvpStatus);
}