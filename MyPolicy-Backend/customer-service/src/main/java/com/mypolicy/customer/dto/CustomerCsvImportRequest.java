package com.mypolicy.customer.dto;

import com.opencsv.bean.CsvBindByName;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;

@Data
@NoArgsConstructor
public class CustomerCsvImportRequest {

  @CsvBindByName(column = "customerId")
  private String customerId;

  @CsvBindByName(column = "customerFullName")
  private String customerFullName;

  @CsvBindByName(column = "refPhoneMobile")
  private String refPhoneMobile;

  @CsvBindByName(column = "datBirthCust")
  private String datBirthCust;

  @CsvBindByName(column = "custEmailID")
  private String custEmailID;

  @CsvBindByName(column = "refCustItNum")
  private String refCustItNum;

  @CsvBindByName(column = "txtPermadrAdd1")
  private String txtPermadrAdd1;

  @CsvBindByName(column = "txtPermadrAdd2")
  private String txtPermadrAdd2;

  @CsvBindByName(column = "txtPermadrAdd3")
  private String txtPermadrAdd3;

  @CsvBindByName(column = "txtPermadrZip")
  private String txtPermadrZip;

  @CsvBindByName(column = "txtCustadrZip")
  private String txtCustadrZip;

  @CsvBindByName(column = "namPermadrCity")
  private String namPermadrCity;

  /**
   * Converts CSV row to CustomerRegistrationRequest
   */
  public CustomerRegistrationRequest toCustomerRegistrationRequest() {
    CustomerRegistrationRequest request = new CustomerRegistrationRequest();

    // Split full name
    String[] nameParts = customerFullName.split(" ", 2);
    request.setFirstName(nameParts[0]);
    request.setLastName(nameParts.length > 1 ? nameParts[1] : "");

    request.setEmail(custEmailID);
    request.setMobileNumber(refPhoneMobile);
    request.setPanNumber(refCustItNum);

    // Parse date (YYYYMMDD format from CSV)
    try {
      if (datBirthCust != null && !datBirthCust.isEmpty()) {
        String dateStr = datBirthCust;
        LocalDate dob = LocalDate.parse(dateStr, DateTimeFormatter.ofPattern("yyyyMMdd"));
        request.setDateOfBirth(dob);
      }
    } catch (Exception e) {
      // Skip invalid dates
    }

    // Address fields
    request.setPermanentAddressLine1(txtPermadrAdd1);
    request.setPermanentAddressLine2(txtPermadrAdd2);
    request.setPermanentAddressLine3(txtPermadrAdd3);
    request.setPermanentAddressCity(namPermadrCity);
    request.setPermanentAddressZip(txtPermadrZip);
    request.setCustomerAddressZip(txtCustadrZip);

    // Default password - should be changed on first login
    request.setPassword("DefaultPassword@123");

    return request;
  }
}
