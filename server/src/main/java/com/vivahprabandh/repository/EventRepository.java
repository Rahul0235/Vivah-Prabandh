package com.vivahprabandh.repository;

import com.vivahprabandh.entity.Event;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface EventRepository extends JpaRepository<Event, Long> {

    List<Event> findByUserId(Long userId);

}