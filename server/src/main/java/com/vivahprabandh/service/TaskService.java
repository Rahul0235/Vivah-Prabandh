package com.vivahprabandh.service;

import com.vivahprabandh.dto.AddTaskRequest;
import com.vivahprabandh.dto.TaskResponse;
import com.vivahprabandh.dto.UpdateTaskRequest;
import com.vivahprabandh.entity.Event;
import com.vivahprabandh.entity.Task;
import com.vivahprabandh.entity.Vendor;
import com.vivahprabandh.repository.EventRepository;
import com.vivahprabandh.repository.TaskRepository;
import com.vivahprabandh.repository.VendorRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class TaskService {

    private final TaskRepository taskRepository;
    private final EventRepository eventRepository;
    private final VendorRepository vendorRepository;

    // ✅ Page 1 — Get Tasks
    public List<Task> getTasks(Long eventId) {
        if (eventId != null) {
            return taskRepository.findByEventId(eventId);
        }
        return taskRepository.findAll();
    }

    // ✅ Page 2 — Add Task
    public TaskResponse addTask(AddTaskRequest request) {

    Event event = eventRepository.findById(request.getEventId())
            .orElseThrow(() -> new RuntimeException("Event not found"));

    Vendor vendor = null;
    if (request.getVendorId() != null) {
        vendor = vendorRepository.findById(request.getVendorId())
                .orElseThrow(() -> new RuntimeException("Vendor not found"));
    }

    Task task = Task.builder()
            .title(request.getTitle())
            .description(request.getDescription())
            .priority(request.getPriority())
            .deadline(request.getDeadline())
            .status("PENDING")
            .event(event)
            .vendor(vendor)
            .build();

    Task saved = taskRepository.save(task);

    return TaskResponse.builder()
            .id(saved.getId())
            .title(saved.getTitle())
            .description(saved.getDescription())
            .status(saved.getStatus())
            .priority(saved.getPriority())
            .deadline(saved.getDeadline())
            .eventId(event.getId())
            .eventName(event.getName())
            .vendorId(vendor != null ? vendor.getId() : null)
            .vendorName(vendor != null ? vendor.getName() : null)
            .build();
}

// ✅ Get Task Details
public TaskResponse getTaskById(Long taskId) {
    Task task = taskRepository.findById(taskId)
            .orElseThrow(() -> new RuntimeException("Task not found"));

    return TaskResponse.builder()
            .id(task.getId())
            .title(task.getTitle())
            .description(task.getDescription())
            .status(task.getStatus())
            .priority(task.getPriority())
            .deadline(task.getDeadline())
            .eventId(task.getEvent().getId())
            .eventName(task.getEvent().getName())
            .vendorId(task.getVendor() != null ? task.getVendor().getId() : null)
            .vendorName(task.getVendor() != null ? task.getVendor().getName() : null)
            .build();
}

// ✅ Update Task
public TaskResponse updateTask(Long taskId, UpdateTaskRequest request) {

    Task task = taskRepository.findById(taskId)
            .orElseThrow(() -> new RuntimeException("Task not found"));

    if (request.getTitle() != null) {
        task.setTitle(request.getTitle());
    }

    if (request.getDescription() != null) {
        task.setDescription(request.getDescription());
    }

    if (request.getStatus() != null) {
        task.setStatus(request.getStatus());
    }

    if (request.getPriority() != null) {
        task.setPriority(request.getPriority());
    }

    if (request.getDeadline() != null) {
        task.setDeadline(request.getDeadline());
    }

    if (request.getVendorId() != null) {
        Vendor vendor = vendorRepository.findById(request.getVendorId())
                .orElseThrow(() -> new RuntimeException("Vendor not found"));
        task.setVendor(vendor);
    }

    taskRepository.save(task);

    return getTaskById(taskId);
}
}