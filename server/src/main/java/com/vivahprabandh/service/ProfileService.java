package com.vivahprabandh.service;

import com.vivahprabandh.dto.ProfileResponse;
import com.vivahprabandh.dto.UpdateProfileRequest;
import com.vivahprabandh.entity.User;
import com.vivahprabandh.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class ProfileService {

    private final UserRepository userRepository;

    // ✅ Get Profile
    public ProfileResponse getProfile(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return new ProfileResponse(
                user.getId(),
                user.getName(),
                user.getEmail(),
                user.getMobileNumber(),
                user.getRole(),
                user.getProfileImageUrl()
        );
    }

    // ✅ Update Profile
    public ProfileResponse updateProfile(Long userId, UpdateProfileRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (request.getName() != null) {
            user.setName(request.getName());
        }

        if (request.getMobileNumber() != null) {
            user.setMobileNumber(request.getMobileNumber());
        }

        if (request.getProfileImageUrl() != null) {
            user.setProfileImageUrl(request.getProfileImageUrl());
        }

        userRepository.save(user);

        return getProfile(userId);
    }
}