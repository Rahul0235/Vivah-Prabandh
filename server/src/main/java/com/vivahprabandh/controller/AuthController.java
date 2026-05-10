package com.vivahprabandh.controller;

import com.vivahprabandh.dto.ForgotPasswordRequest;
import com.vivahprabandh.dto.LoginRequest;
import com.vivahprabandh.dto.LoginResponse;
import com.vivahprabandh.dto.RegisterRequest;
import com.vivahprabandh.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

// @CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
        public String register(@RequestBody RegisterRequest request) {
        return authService.register(request);
    }

    @PostMapping("/login")
        public LoginResponse login(@RequestBody LoginRequest request) {
        return authService.login(request);
    }

   @PostMapping("/forgot-password")
       public String forgotPassword(@RequestBody ForgotPasswordRequest request) {
       return authService.forgotPassword(request.getEmail());
    }
}