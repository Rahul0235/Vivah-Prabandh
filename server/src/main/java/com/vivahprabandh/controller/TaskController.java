package com.vivahprabandh.controller;

import com.vivahprabandh.dto.AddTaskRequest;
import com.vivahprabandh.dto.TaskResponse;
import com.vivahprabandh.dto.UpdateTaskRequest;
import com.vivahprabandh.entity.Task;
import com.vivahprabandh.service.TaskService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/tasks")
@RequiredArgsConstructor
public class TaskController {

    private final TaskService taskService;

    // ✅ Page 1 — All Tasks
    @GetMapping
    public List<Task> getTasks(@RequestParam(required = false) Long eventId) {
        return taskService.getTasks(eventId);
    }

    // ✅ Page 2 — Add Task
    @PostMapping
    public TaskResponse addTask(@RequestBody AddTaskRequest request) {
        return taskService.addTask(request);
    }

    // ✅ Page 3 — Get Task Details
    @GetMapping("/{taskId}")
    public TaskResponse getTask(@PathVariable Long taskId) {
        return taskService.getTaskById(taskId);
    }

    // ✅ Page 3 — Update Task (mark complete/pending/edit)
    @PutMapping("/{taskId}")
    public TaskResponse updateTask(
        @PathVariable Long taskId,
        @RequestBody UpdateTaskRequest request
    ) {
        return taskService.updateTask(taskId, request);
    }
}