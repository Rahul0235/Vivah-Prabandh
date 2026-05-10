package com.vivahprabandh.service;

import com.vivahprabandh.dto.LoginRequest;
import com.vivahprabandh.dto.LoginResponse;
import com.vivahprabandh.dto.RegisterRequest;
import com.vivahprabandh.entity.User;
import com.vivahprabandh.entity.Vendor;
import com.vivahprabandh.repository.UserRepository;
import com.vivahprabandh.repository.VendorRepository;
import com.vivahprabandh.security.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final VendorRepository vendorRepository;

    // ✅ REGISTER
    public String register(RegisterRequest request) {

        String role = request.getRole();

        if ("ADMIN".equalsIgnoreCase(role)) {
            throw new RuntimeException("Admin cannot register.");
        }

        if (role == null || role.isBlank()) {
            role = "USER";
        }

        if (userRepository.findByEmail(request.getEmail()).isPresent()) {
            throw new RuntimeException("Email already exists");
        }

        User user = User.builder()
                .name(request.getName())
                .email(request.getEmail())
                .mobileNumber(request.getMobileNumber())
                .password(passwordEncoder.encode(request.getPassword()))
                .role(role.toUpperCase())
                .build();

        userRepository.save(user);

        if ("VENDOR".equalsIgnoreCase(role)) {
            Vendor vendor = Vendor.builder()
                    .name(request.getName())
                    .email(request.getEmail())
                    .category(request.getCategory())
                    .services(request.getServices())
                    .price(request.getPrice())
                    .location(request.getLocation())
                    .status("PENDING")
                    .available(true)
                    .rating(0.0)
                    .build();

            vendorRepository.save(vendor);
            return "Vendor registered. Waiting for admin approval.";
        }

        return "User registered successfully.";
    }

    // ✅ LOGIN
    public LoginResponse login(LoginRequest request) {

        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("User not found"));

        // 🚫 Block unapproved vendors
        if ("VENDOR".equalsIgnoreCase(user.getRole())) {
            Vendor vendor = vendorRepository.findByEmail(user.getEmail())
                    .orElseThrow(() -> new RuntimeException("Vendor profile not found"));

            if (!"APPROVED".equalsIgnoreCase(vendor.getStatus())) {
                throw new RuntimeException("Vendor not approved by admin");
            }
        }

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new RuntimeException("Invalid password");
        }

        if (request.getRole() == null || request.getRole().isBlank()) {
            throw new RuntimeException("Role is required");
        }

        if (!user.getRole().equalsIgnoreCase(request.getRole())) {
            throw new RuntimeException("Wrong role");
        }

        String token = jwtUtil.generateToken(user.getEmail(), user.getRole());

        // ✅ Now returns id as well
        return new LoginResponse(user.getId(), token, user.getEmail(), user.getRole());
    }

    // Forgot password
    public String forgotPassword(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));
        String token = java.util.UUID.randomUUID().toString();
        return "Password reset token: " + token;
    }
}