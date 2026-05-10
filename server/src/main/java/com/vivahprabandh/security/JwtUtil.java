package com.vivahprabandh.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.stereotype.Component;

import java.util.Collections;
import java.util.Date;

@Component
public class JwtUtil {

    private final String SECRET_KEY = "vivah_secret_key_12345678901234567890";

    // ✅ Generate token
    public String generateToken(String email, String role) {
        return Jwts.builder()
                .setSubject(email) // ✅ correct for 0.11.x
                .claim("role", role)
                .setIssuedAt(new Date())
                .setExpiration(new Date(System.currentTimeMillis() + 86400000))
                .signWith(SignatureAlgorithm.HS256, SECRET_KEY.getBytes())
                .compact();
    }

    // ✅ Extract email
    public String extractUsername(String token) {
        return extractClaims(token).getSubject();
    }

    // ✅ Extract role
    public String extractRole(String token) {
        return extractClaims(token).get("role", String.class);
    }

    // ✅ Validate token
    public boolean validateToken(String token) {
        return !extractClaims(token).getExpiration().before(new Date());
    }

    // ✅ Create Authentication
    public UsernamePasswordAuthenticationToken getAuthentication(String token) {
        String email = extractUsername(token);
        String role = extractRole(token);

        return new UsernamePasswordAuthenticationToken(
                email,
                null,
                Collections.singletonList(new SimpleGrantedAuthority("ROLE_" + role))
        );
    }

    // 🔒 Helper
    private Claims extractClaims(String token) {
        return Jwts.parser()
                .setSigningKey(SECRET_KEY.getBytes())
                .parseClaimsJws(token)
                .getBody();
    }
}