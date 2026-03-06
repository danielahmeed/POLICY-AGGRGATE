package com.mypolicy.customer.service;

import com.mypolicy.customer.dto.AuthResponse;
import com.mypolicy.customer.dto.CustomerRegistrationRequest;
import com.mypolicy.customer.dto.CustomerResponse;
import com.mypolicy.customer.dto.CustomerUpdateRequest;
import com.mypolicy.customer.dto.LoginRequest;

import java.util.Optional;

public interface CustomerService {
  CustomerResponse registerCustomer(CustomerRegistrationRequest request);

  AuthResponse login(LoginRequest request);

  CustomerResponse getCustomerById(String customerId);

  CustomerResponse updateCustomer(String customerId, CustomerUpdateRequest request);

  Optional<CustomerResponse> searchByMobile(String mobile);

  Optional<CustomerResponse> searchByEmail(String email);

  Optional<CustomerResponse> searchByPan(String pan);
}
