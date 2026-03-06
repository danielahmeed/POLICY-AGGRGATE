package com.mypolicy.customer.service;

import com.mypolicy.customer.dto.CustomerCsvImportRequest;
import com.mypolicy.customer.dto.CustomerRegistrationRequest;
import com.mypolicy.customer.model.Customer;
import com.mypolicy.customer.model.CustomerStatus;
import com.mypolicy.customer.repository.CustomerRepository;
import com.opencsv.bean.CsvToBeanBuilder;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.InputStreamReader;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class CsvImportService {

  private final CustomerRepository customerRepository;
  private final PasswordEncoder passwordEncoder;

  /**
   * Import customers from a CSV file
   *
   * @param file the CSV file to import
   * @return ImportResult with success/failure counts and details
   */
  @Transactional
  public ImportResult importCustomersFromCsv(MultipartFile file) {
    ImportResult result = new ImportResult();

    if (file.isEmpty()) {
      result.setSuccess(false);
      result.setErrorMessage("File is empty");
      return result;
    }

    try {
      // Parse CSV using OpenCSV
      InputStreamReader reader = new InputStreamReader(file.getInputStream());

      List<CustomerCsvImportRequest> csvRecords = new CsvToBeanBuilder<CustomerCsvImportRequest>(reader)
          .withType(CustomerCsvImportRequest.class)
          .withIgnoreLeadingWhiteSpace(true)
          .build()
          .parse();

      log.info("Parsed {} records from CSV", csvRecords.size());

      int successCount = 0;
      int failCount = 0;

      for (int i = 0; i < csvRecords.size(); i++) {
        try {
          CustomerCsvImportRequest csvRecord = csvRecords.get(i);

          // Check if customer already exists by email
          if (customerRepository.findByEmail(csvRecord.getCustEmailID()).isPresent()) {
            log.warn("Customer with email {} already exists, skipping row {}",
                csvRecord.getCustEmailID(), i + 2);
            failCount++;
            result.getSkippedEmails().add(csvRecord.getCustEmailID());
            continue;
          }

          // Convert CSV record to registration request
          CustomerRegistrationRequest registrationRequest = csvRecord.toCustomerRegistrationRequest();

          // Build Customer entity
          Customer customer = Customer.builder()
              .firstName(registrationRequest.getFirstName())
              .lastName(registrationRequest.getLastName())
              .email(registrationRequest.getEmail())
              .mobileNumber(registrationRequest.getMobileNumber())
              .panNumber(registrationRequest.getPanNumber())
              .dateOfBirth(registrationRequest.getDateOfBirth())
              .passwordHash(passwordEncoder.encode(registrationRequest.getPassword()))
              .permanentAddressLine1(registrationRequest.getPermanentAddressLine1())
              .permanentAddressLine2(registrationRequest.getPermanentAddressLine2())
              .permanentAddressLine3(registrationRequest.getPermanentAddressLine3())
              .permanentAddressCity(registrationRequest.getPermanentAddressCity())
              .permanentAddressZip(registrationRequest.getPermanentAddressZip())
              .customerAddressZip(registrationRequest.getCustomerAddressZip())
              .status(CustomerStatus.ACTIVE)
              .build();

          customerRepository.save(customer);
          successCount++;
          result.getImportedEmails().add(customer.getEmail());
          log.debug("Successfully imported customer: {}", customer.getEmail());

        } catch (Exception e) {
          failCount++;
          log.error("Error importing row {}: {}", i + 2, e.getMessage(), e);
          result.getFailedRows().add("Row " + (i + 2) + ": " + e.getMessage());
        }
      }

      result.setSuccess(true);
      result.setTotalRecords(csvRecords.size());
      result.setSuccessCount(successCount);
      result.setFailCount(failCount);
      result.setSuccessMessage(String.format("Import completed: %d success, %d failed out of %d records",
          successCount, failCount, csvRecords.size()));

      log.info("CSV import completed: {} success, {} failed", successCount, failCount);

    } catch (Exception e) {
      log.error("Error reading CSV file", e);
      result.setSuccess(false);
      result.setErrorMessage("Error processing CSV file: " + e.getMessage());
    }

    return result;
  }

  /**
   * Result DTO for import operation
   */
  public static class ImportResult {
    private boolean success;
    private String successMessage;
    private String errorMessage;
    private int totalRecords;
    private int successCount;
    private int failCount;
    private List<String> importedEmails = new java.util.ArrayList<>();
    private List<String> skippedEmails = new java.util.ArrayList<>();
    private List<String> failedRows = new java.util.ArrayList<>();

    // Getters and Setters
    public boolean isSuccess() {
      return success;
    }

    public void setSuccess(boolean success) {
      this.success = success;
    }

    public String getSuccessMessage() {
      return successMessage;
    }

    public void setSuccessMessage(String successMessage) {
      this.successMessage = successMessage;
    }

    public String getErrorMessage() {
      return errorMessage;
    }

    public void setErrorMessage(String errorMessage) {
      this.errorMessage = errorMessage;
    }

    public int getTotalRecords() {
      return totalRecords;
    }

    public void setTotalRecords(int totalRecords) {
      this.totalRecords = totalRecords;
    }

    public int getSuccessCount() {
      return successCount;
    }

    public void setSuccessCount(int successCount) {
      this.successCount = successCount;
    }

    public int getFailCount() {
      return failCount;
    }

    public void setFailCount(int failCount) {
      this.failCount = failCount;
    }

    public List<String> getImportedEmails() {
      return importedEmails;
    }

    public void setImportedEmails(List<String> importedEmails) {
      this.importedEmails = importedEmails;
    }

    public List<String> getSkippedEmails() {
      return skippedEmails;
    }

    public void setSkippedEmails(List<String> skippedEmails) {
      this.skippedEmails = skippedEmails;
    }

    public List<String> getFailedRows() {
      return failedRows;
    }

    public void setFailedRows(List<String> failedRows) {
      this.failedRows = failedRows;
    }
  }
}
