package com.vivahprabandh.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class EmailService {

    @Autowired
    private JavaMailSender mailSender;

    public void sendInvitationEmail(String toEmail,
                                String guestName,
                                String eventName,
                                String eventDate,
                                String location,
                                Long guestId) {

    String subject = "Wedding Invitation 💍";

    String acceptLink = "http://localhost:8088/api/rsvp/accept/" + guestId;
    String declineLink = "http://localhost:8088/api/rsvp/decline/" + guestId;

    String body = "Dear " + guestName + ",\n\n"
            + "You are invited to the wedding event:\n\n"
            + "Event: " + eventName + "\n"
            + "Date: " + eventDate + "\n"
            + "Location: " + location + "\n\n"
            + "Please respond:\n"
            + "Accept: " + acceptLink + "\n"
            + "Decline: " + declineLink + "\n\n"
            + "Best regards,\nVivah Prabandh";

    SimpleMailMessage message = new SimpleMailMessage();
    message.setTo(toEmail);
    message.setSubject(subject);
    message.setText(body);

    mailSender.send(message);
  }

  public void sendSimpleEmail(String to, String subject, String body) {
    SimpleMailMessage message = new SimpleMailMessage();
    message.setTo(to);
    message.setSubject(subject);
    message.setText(body);
    mailSender.send(message);
  }
}