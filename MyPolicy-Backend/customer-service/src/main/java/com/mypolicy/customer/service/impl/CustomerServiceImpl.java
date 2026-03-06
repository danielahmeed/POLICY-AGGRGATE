package com.mypolicy.customer.service.impl;

import com.mypolicy.customer.dto.CustomerRegistrationRequest;
import com.mypolicy.customer.dto.CustomerResponse;
import com.mypolicy.customer.dto.CustomerUpdateRequest;
import com.mypolicy.customer.dto.LoginRequest;
import com.mypolicy.customer.exception.CustomerNotFoundException;
import com.mypolicy.customer.exception.DuplicateCustomerException;
import com.mypolicy.customer.exception.InvalidCredentialsException;
import com.mypolicy.customer.model.Customer;
import com.mypolicy.customer.model.CustomerStatus;
import com.mypolicy.customer.repository.CustomerRepository;
import com.mypolicy.customer.service.CustomerService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class CustomerServiceImpl implements CustomerService {

  private final CustomerRepository customerRepository;
  private final org.springframework.security.crypto.password.PasswordEncoder passwordEncoder;
  private final com.mypolicy.customer.security.JwtService jwtService;

  @Override
  @Transactional
  public CustomerResponse registerCustomer(CustomerRegistrationRequest request) {
    if (customerRepository.existsByEmail(request.getEmail())) {
      throw new DuplicateCustomerException("Email", request.getEmail());
    }
    if (customerRepository.existsByMobileNumber(request.getMobileNumber())) {
      throw new DuplicateCustomerException("Mobile number", request.getMobileNumber());
    }

    Customer customer = new Customer();
    customer.setFirstName(request.getFirstName());
    customer.setLastName(request.getLastName());
    customer.setEmail(request.getEmail());
    customer.setMobileNumber(request.getMobileNumber());
    customer.setPasswordHash(passwordEncoder.encode(request.getPassword()));
    customer.setPanNumber(request.getPanNumber());
    customer.setDateOfBirth(request.getDateOfBirth());
    customer.setAddress(request.getAddress());
    customer.setStatus(CustomerStatus.ACTIVE);

    Customer saved = customerRepository.save(customer);
    return mapToResponse(saved);
  }

  @Override
  public com.mypolicy.customer.dto.AuthResponse login(LoginRequest request) {
    Customer customer = customerRepository.findByEmail(request.getEmail())
        .orElseThrow(() -> new InvalidCredentialsException());

    if (!passwordEncoder.matches(request.getPassword(), customer.getPasswordHash())) {
      throw new InvalidCredentialsException();
    }

    String token = jwtService.generateToken(customer.getEmail());
    return new com.mypolicy.customer.dto.AuthResponse(token, mapToResponse(customer));
  }

  @Override
  public CustomerResponse getCustomerById(String customerId) {
    return customerRepository.findById(customerId)
        .map(this::mapToResponse)
        .orElseThrow(() -> new CustomerNotFoundException(customerId, "id"));
  }

  @Override
  @Transactional
  public CustomerResponse updateCustomer(String customerId, CustomerUpdateRequest request) {
    Customer customer = customerRepository.findById(customerId)
        .orElseThrow(() -> new CustomerNotFoundException(customerId, "id"));

    // Update only non-null fields
    if (request.getFirstName() != null && !request.getFirstName().isEmpty()) {
      customer.setFirstName(request.getFirstName());
    }

    if (request.getLastName() != null && !request.getLastName().isEmpty()) {
      customer.setLastName(request.getLastName());
    }

    if (request.getEmail() != null && !request.getEmail().isEmpty()) {
      // Check if new email is already taken by another customer
      customerRepository.findByEmail(request.getEmail()).ifPresent(existing -> {
        if (!existing.getCustomerId().equals(customerId)) {
          throw new DuplicateCustomerException("Email", request.getEmail());
        }
      });
      customer.setEmail(request.getEmail());
    }

    if (request.getMobileNumber() != null && !request.getMobileNumber().isEmpty()) {
      // Check if new mobile is already taken by another customer
      customerRepository.findByMobileNumber(request.getMobileNumber()).ifPresent(existing -> {
        if (!existing.getCustomerId().equals(customerId)) {
          throw new DuplicateCustomerException("Mobile number", request.getMobileNumber());
        }
      });
      customer.setMobileNumber(request.getMobileNumber());
    }

    if (request.getPanNumber() != null && !request.getPanNumber().isEmpty()) {
      // Check if new PAN is already taken by another customer
      customerRepository.findByPanNumber(request.getPanNumber()).ifPresent(existing -> {
        if (!existing.getCustomerId().equals(customerId)) {
          throw new DuplicateCustomerException("PAN number", request.getPanNumber());
        }
      });
      customer.setPanNumber(request.getPanNumber());
    }


    if (request.getDateOfBirth() != null && !request.getDateOfBirth().isEmpty()) {
      LocalDate dob = LocalDate.parse(request.getDateOfBirth());
      customer.setDateOfBirth(dob);
    }

    if (request.getAddress() != null && !request.getAddress().isEmpty()) {
      customer.setAddress(request.getAddress());
    }

    Customer updated = customerRepository.save(customer);
    return mapToResponse(updated);
  }

  @Override
  public Optional<CustomerResponse> searchByMobile(String mobile) {
    return customerRepository.findByMobileNumber(mobile)
        .map(this::mapToResponse);
  }

  @Override
  public Optional<CustomerResponse> searchByEmail(String email) {
    return customerRepository.findByEmail(email)
        .map(this::mapToResponse);
  }

  @Override
  public Optional<CustomerResponse> searchByPan(String pan) {
    return customerRepository.findByPanNumber(pan)
        .map(this::mapToResponse);
  }

  private CustomerResponse mapToResponse(Customer c) {
    return CustomerResponse.builder()
        .customerId(c.getCustomerId())
        .firstName(c.getFirstName())
        .lastName(c.getLastName())
        .email(c.getEmail())
        .mobileNumber(c.getMobileNumber())
        .status(c.getStatus())
        .panNumber(c.getPanNumber())
        .dateOfBirth(c.getDateOfBirth())
        .address(c.getAddress())
        .build();
  }
}
