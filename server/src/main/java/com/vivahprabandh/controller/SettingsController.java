package com.vivahprabandh.controller;

import com.vivahprabandh.dto.SettingsResponse;
import com.vivahprabandh.dto.UpdateSettingsRequest;
import com.vivahprabandh.service.SettingsService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/settings")
@RequiredArgsConstructor
public class SettingsController {

    private final SettingsService settingsService;

    // ✅ Get Settings
    @GetMapping("/{userId}")
    public SettingsResponse getSettings(@PathVariable Long userId) {
        return settingsService.getSettings(userId);
    }

    // ✅ Update Settings
    @PutMapping("/{userId}")
    public SettingsResponse updateSettings(
            @PathVariable Long userId,
            @RequestBody UpdateSettingsRequest request
    ) {
        return settingsService.updateSettings(userId, request);
    }
}