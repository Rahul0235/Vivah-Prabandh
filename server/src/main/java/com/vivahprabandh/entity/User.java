package com.vivahprabandh.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;

    @Column(unique = true)
    private String email;

    private String password;

    private String mobileNumber;

    private String role; // USER / VENDOR / ADMIN

    // ✅ Profile Image
    private String profileImageUrl;

    // ✅ Settings (FIXED)
    @Builder.Default
    private String theme = "LIGHT";

    @Builder.Default
    private Boolean emailNotifications = true;

    @Builder.Default
    private Boolean reminderNotifications = true;

    @Builder.Default
    private Boolean showContact = true;

}