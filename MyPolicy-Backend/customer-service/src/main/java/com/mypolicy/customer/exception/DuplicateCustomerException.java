package com.mypolicy.customer.exception;

/**
 * Exception thrown when attempting to create a customer with duplicate unique fields
 */
public class DuplicateCustomerException extends RuntimeException {
  
  public DuplicateCustomerException(String message) {
    super(message);
  }

  public DuplicateCustomerException(String field, String value) {
    super(String.format("%s already exists: %s", field, value));
  }
}
