package com.vivahprabandh.config;

import com.vivahprabandh.entity.User;
import com.vivahprabandh.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
@RequiredArgsConstructor
public class DataInitializer implements CommandLineRunner {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {

        if (userRepository.findByEmail("rahul@vivah.com").isEmpty()) {

            User admin = User.builder()
                    .name("Admin")
                    .email("rahul@vivah.com")
                    .mobileNumber("9999999999")
                    .password(passwordEncoder.encode("admin123"))
                    .role("ADMIN")
                    .build();

            userRepository.save(admin);

            System.out.println("✅ Admin created: admin@vivah.com / admin123");
        }
    }
}