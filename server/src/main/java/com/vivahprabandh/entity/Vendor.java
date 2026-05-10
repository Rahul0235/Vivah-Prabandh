package com.vivahprabandh.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "vendors")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Vendor {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;

    private String category;

    @Builder.Default
    @Column(nullable = false)
    private String status = "PENDING";   // PENDING / APPROVED / REJECTED

    @Column(unique = true)
    private String email;

    @Column(length = 1000)
    private String services;

    private Double price;

    private String contact;

    private String location;

    private Boolean available;

    private Double rating;
}