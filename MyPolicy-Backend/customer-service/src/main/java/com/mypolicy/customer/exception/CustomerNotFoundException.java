package com.mypolicy.customer.exception;

/**
 * Exception thrown when a customer is not found
 */
public class CustomerNotFoundException extends RuntimeException {
  
  public CustomerNotFoundException(String message) {
    super(message);
  }

  public CustomerNotFoundException(String customerId, String field) {
    super(String.format("Customer not found with %s: %s", field, customerId));
  }
}
