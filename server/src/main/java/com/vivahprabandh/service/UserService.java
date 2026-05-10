package com.vivahprabandh.service;

import com.vivahprabandh.dto.RegisterRequest;
import com.vivahprabandh.entity.User;
import com.vivahprabandh.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public User registerUser(RegisterRequest request) {

        User user = User.builder()
                .name(request.getName())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .mobileNumber(request.getMobileNumber())   // ✅ added
                .role(request.getRole())                   // ✅ added
                .build();

        return userRepository.save(user);
    }
}