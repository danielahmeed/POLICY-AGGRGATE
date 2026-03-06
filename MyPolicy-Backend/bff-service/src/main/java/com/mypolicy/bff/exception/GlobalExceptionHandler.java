package com.mypolicy.bff.exception;

import feign.FeignException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.multipart.MaxUploadSizeExceededException;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * Global exception handler for BFF service
 * Handles Feign client errors and other exceptions
 */
@ControllerAdvice
public class GlobalExceptionHandler {

  @ExceptionHandler(FeignException.NotFound.class)
  public ResponseEntity<Map<String, Object>> handleFeignNotFoundException(FeignException.NotFound ex) {
    Map<String, Object> error = new HashMap<>();
    error.put("timestamp", LocalDateTime.now());
    error.put("message", "Resource not found in downstream service");
    error.put("status", HttpStatus.NOT_FOUND.value());
    error.put("details", ex.contentUTF8());

    return new ResponseEntity<>(error, HttpStatus.NOT_FOUND);
  }

  @ExceptionHandler(FeignException.BadRequest.class)
  public ResponseEntity<Map<String, Object>> handleFeignBadRequestException(FeignException.BadRequest ex) {
    Map<String, Object> error = new HashMap<>();
    error.put("timestamp", LocalDateTime.now());
    error.put("message", "Invalid request to downstream service");
    error.put("status", HttpStatus.BAD_REQUEST.value());
    error.put("details", ex.contentUTF8());

    return new ResponseEntity<>(error, HttpStatus.BAD_REQUEST);
  }

  @ExceptionHandler(FeignException.Unauthorized.class)
  public ResponseEntity<Map<String, Object>> handleFeignUnauthorizedException(FeignException.Unauthorized ex) {
    Map<String, Object> error = new HashMap<>();
    error.put("timestamp", LocalDateTime.now());
    error.put("message", "Unauthorized access to downstream service");
    error.put("status", HttpStatus.UNAUTHORIZED.value());

    return new ResponseEntity<>(error, HttpStatus.UNAUTHORIZED);
  }

  @ExceptionHandler(FeignException.class)
  public ResponseEntity<Map<String, Object>> handleFeignException(FeignException ex) {
    Map<String, Object> error = new HashMap<>();
    error.put("timestamp", LocalDateTime.now());
    error.put("message", "Error communicating with downstream service");
    error.put("status", ex.status());
    error.put("details", ex.contentUTF8());

    return new ResponseEntity<>(error, HttpStatus.valueOf(ex.status()));
  }

  @ExceptionHandler(MaxUploadSizeExceededException.class)
  public ResponseEntity<Map<String, Object>> handleMaxUploadSizeExceededException(MaxUploadSizeExceededException ex) {
    Map<String, Object> error = new HashMap<>();
    error.put("timestamp", LocalDateTime.now());
    error.put("message", "File size exceeds maximum allowed size");
    error.put("status", HttpStatus.PAYLOAD_TOO_LARGE.value());

    return new ResponseEntity<>(error, HttpStatus.PAYLOAD_TOO_LARGE);
  }

  @ExceptionHandler(RuntimeException.class)
  public ResponseEntity<Map<String, Object>> handleRuntimeException(RuntimeException ex) {
    Map<String, Object> error = new HashMap<>();
    error.put("timestamp", LocalDateTime.now());
    error.put("message", ex.getMessage());
    error.put("status", HttpStatus.INTERNAL_SERVER_ERROR.value());

    return new ResponseEntity<>(error, HttpStatus.INTERNAL_SERVER_ERROR);
  }

  @ExceptionHandler(MethodArgumentNotValidException.class)
  public ResponseEntity<Map<String, Object>> handleValidationExceptions(MethodArgumentNotValidException ex) {
    Map<String, Object> errors = new HashMap<>();
    errors.put("timestamp", LocalDateTime.now());
    errors.put("status", HttpStatus.BAD_REQUEST.value());

    Map<String, String> fieldErrors = new HashMap<>();
    ex.getBindingResult().getFieldErrors()
        .forEach(error -> fieldErrors.put(error.getField(), error.getDefaultMessage()));

    errors.put("errors", fieldErrors);
    return new ResponseEntity<>(errors, HttpStatus.BAD_REQUEST);
  }

  @ExceptionHandler(Exception.class)
  public ResponseEntity<Map<String, Object>> handleGenericException(Exception ex) {
    Map<String, Object> error = new HashMap<>();
    error.put("timestamp", LocalDateTime.now());
    error.put("message", "An unexpected error occurred");
    error.put("status", HttpStatus.INTERNAL_SERVER_ERROR.value());
    error.put("details", ex.getMessage());

    return new ResponseEntity<>(error, HttpStatus.INTERNAL_SERVER_ERROR);
  }
}
