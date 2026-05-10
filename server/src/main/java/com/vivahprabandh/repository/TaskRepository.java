package com.vivahprabandh.repository;

import com.vivahprabandh.entity.Task;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

import java.time.LocalDate;

public interface TaskRepository extends JpaRepository<Task, Long> {

    List<Task> findByEventId(Long eventId);

    List<Task> findByDeadline(LocalDate date);
    List<Task> findByDeadlineBefore(LocalDate date);

}