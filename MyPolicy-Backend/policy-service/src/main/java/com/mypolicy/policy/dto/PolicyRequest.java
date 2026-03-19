package com.mypolicy.policy.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;

@Data
public class PolicyRequest {
  @NotBlank(message = "Customer ID is required")
  private String customerId;

  @NotBlank(message = "Insurer ID is required")
  private String insurerId;

  @NotBlank(message = "Policy number is required")
  private String policyNumber;

  @NotBlank(message = "Policy type is required")
  private String policyType;

  private String planName;

  @NotNull(message = "Premium amount is required")
  @Positive(message = "Premium amount must be positive")
  private BigDecimal premiumAmount;

  @NotNull(message = "Sum assured is required")
  @Positive(message = "Sum assured must be positive")
  private BigDecimal sumAssured;

  private LocalDate startDate;
  private LocalDate endDate;

  @NotBlank(message = "Status is required")
  private String status;

  // Stitching metadata (set by Data Pipeline)
  private String sourceCollection;
  private String matchMethod;
  private String encryptedPan;
  private String encryptedMobile;
  private String encryptedEmail;
}
