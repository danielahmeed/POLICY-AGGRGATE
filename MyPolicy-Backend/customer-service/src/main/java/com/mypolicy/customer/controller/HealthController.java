package com.mypolicy.customer.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@RestController
public class HealthController {

  @Value("${server.port}")
  private String serverPort;

  @Value("${spring.datasource.url}")
  private String databaseUrl;

  @GetMapping({ "/", "/health", "/api/health" })
  public ResponseEntity<Map<String, Object>> health() {
    Map<String, Object> response = new HashMap<>();
    response.put("status", "UP");
    response.put("service", "Customer Service");
    response.put("version", "0.0.1-SNAPSHOT");
    response.put("timestamp", LocalDateTime.now());
    response.put("port", serverPort);
    response.put("database", extractDatabaseType(databaseUrl));

    Map<String, String> endpoints = new HashMap<>();
    endpoints.put("register", "POST /api/v1/customers/register");
    endpoints.put("login", "POST /api/v1/customers/login");
    endpoints.put("h2-console", "GET /h2-console");

    response.put("availableEndpoints", endpoints);

    return ResponseEntity.ok(response);
  }

  private String extractDatabaseType(String url) {
    if (url == null)
      return "Unknown";
    if (url.contains("postgresql"))
      return "PostgreSQL";
    if (url.contains("h2"))
      return "H2 In-Memory";
    if (url.contains("mysql"))
      return "MySQL";
    if (url.contains("mongodb"))
      return "MongoDB";
    return "Unknown";
  }
}
