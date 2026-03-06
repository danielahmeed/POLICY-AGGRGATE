package com.mypolicy.customer.dto;

import com.mypolicy.customer.model.CustomerStatus;
import lombok.Builder;
import lombok.Data;
import java.time.LocalDate;

@Data
@Builder
public class CustomerResponse {
  private String customerId;
  private String firstName;
  private String lastName;
  private String email;
  private String mobileNumber;
  private String panNumber;
  private LocalDate dateOfBirth;

  // Address fields (CSV mapping)
  private String permanentAddressLine1;
  private String permanentAddressLine2;
  private String permanentAddressLine3;
  private String permanentAddressCity;
  private String permanentAddressZip;
  private String customerAddressZip;

  // Legacy field
  private String address;
  private CustomerStatus status;
}
