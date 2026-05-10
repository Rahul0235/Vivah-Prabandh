package com.vivahprabandh.service;

import com.vivahprabandh.dto.SettingsResponse;
import com.vivahprabandh.dto.UpdateSettingsRequest;
import com.vivahprabandh.entity.User;
import com.vivahprabandh.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class SettingsService {

    private final UserRepository userRepository;

    // ✅ Get Settings
    public SettingsResponse getSettings(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return new SettingsResponse(
                user.getTheme(),
                user.getEmailNotifications(),
                user.getReminderNotifications(),
                user.getShowContact()
        );
    }

    // ✅ Update Settings
    public SettingsResponse updateSettings(Long userId, UpdateSettingsRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (request.getTheme() != null) {
            user.setTheme(request.getTheme());
        }

        if (request.getEmailNotifications() != null) {
            user.setEmailNotifications(request.getEmailNotifications());
        }

        if (request.getReminderNotifications() != null) {
            user.setReminderNotifications(request.getReminderNotifications());
        }

        if (request.getShowContact() != null) {
            user.setShowContact(request.getShowContact());
        }

        userRepository.save(user);

        return getSettings(userId);
    }
}