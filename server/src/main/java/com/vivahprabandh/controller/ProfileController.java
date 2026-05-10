package com.vivahprabandh.controller;

import com.vivahprabandh.dto.ProfileResponse;
import com.vivahprabandh.dto.UpdateProfileRequest;
import com.vivahprabandh.service.ProfileService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/profile")
@RequiredArgsConstructor
public class ProfileController {

    private final ProfileService profileService;

    // ✅ View Profile (User & Vendor)
    @GetMapping("/{userId}")
    public ProfileResponse getProfile(@PathVariable Long userId) {
        return profileService.getProfile(userId);
    }

    // ✅ Edit Profile
    @PutMapping("/{userId}")
    public ProfileResponse updateProfile(
            @PathVariable Long userId,
            @RequestBody UpdateProfileRequest request
    ) {
        return profileService.updateProfile(userId, request);
    }
}