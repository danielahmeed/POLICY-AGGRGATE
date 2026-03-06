package com.mypolicy.customer.security;

import com.mypolicy.customer.model.Customer;
import com.mypolicy.customer.repository.CustomerRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.ArrayList;

/**
 * Custom UserDetailsService implementation for loading customer details
 * Required by Spring Security for authentication
 */
@Service
@RequiredArgsConstructor
public class CustomUserDetailsService implements UserDetailsService {

  private final CustomerRepository customerRepository;

  @Override
  public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
    Customer customer = customerRepository.findByEmail(email)
        .orElseThrow(() -> new UsernameNotFoundException("Customer not found with email: " + email));

    // Return Spring Security User object
    return User.builder()
        .username(customer.getEmail())
        .password(customer.getPasswordHash())
        .authorities(new ArrayList<>()) // Empty authorities for now, add roles later if needed
        .accountExpired(false)
        .accountLocked(false)
        .credentialsExpired(false)
        .disabled(false)
        .build();
  }
}
