package com.mypolicy.policy.service.impl;

import com.mypolicy.policy.dto.PolicyRequest;
import com.mypolicy.policy.exception.DuplicatePolicyException;
import com.mypolicy.policy.exception.PolicyNotFoundException;
import com.mypolicy.policy.model.Policy;
import com.mypolicy.policy.model.PolicyStatus;
import com.mypolicy.policy.repository.PolicyRepository;
import com.mypolicy.policy.service.PolicyService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class PolicyServiceImpl implements PolicyService {

  private final PolicyRepository repository;

  @Override
  public Policy createPolicy(PolicyRequest request) {
    // Check for duplicate policy
    repository.findByPolicyNumberAndInsurerId(request.getPolicyNumber(), request.getInsurerId())
        .ifPresent(existing -> {
          throw new DuplicatePolicyException(request.getPolicyNumber(), request.getInsurerId());
        });

    Policy policy = Policy.builder()
        .id(java.util.UUID.randomUUID().toString())
        .customerId(request.getCustomerId())
        .insurerId(request.getInsurerId())
        .policyNumber(request.getPolicyNumber())
        .policyType(request.getPolicyType())
        .planName(request.getPlanName())
        .premiumAmount(request.getPremiumAmount())
        .sumAssured(request.getSumAssured())
        .startDate(request.getStartDate())
        .endDate(request.getEndDate())
        .status(PolicyStatus.valueOf(request.getStatus()))
        .sourceCollection(request.getSourceCollection())
        .matchMethod(request.getMatchMethod())
        .encryptedPan(request.getEncryptedPan())
        .encryptedMobile(request.getEncryptedMobile())
        .encryptedEmail(request.getEncryptedEmail())
        .createdAt(LocalDateTime.now())
        .updatedAt(LocalDateTime.now())
        .build();

    return repository.save(policy);
  }

  @Override
  public List<Policy> bulkCreatePolicies(List<PolicyRequest> requests) {
    List<Policy> created = new java.util.ArrayList<>();
    for (PolicyRequest request : requests) {
      Optional<Policy> existing = repository.findByPolicyNumberAndInsurerId(
          request.getPolicyNumber(), request.getInsurerId());
      if (existing.isPresent()) {
        // Skip duplicates in bulk mode
        continue;
      }
      Policy policy = Policy.builder()
          .id(java.util.UUID.randomUUID().toString())
          .customerId(request.getCustomerId())
          .insurerId(request.getInsurerId())
          .policyNumber(request.getPolicyNumber())
          .policyType(request.getPolicyType())
          .planName(request.getPlanName())
          .premiumAmount(request.getPremiumAmount())
          .sumAssured(request.getSumAssured())
          .startDate(request.getStartDate())
          .endDate(request.getEndDate())
          .status(PolicyStatus.valueOf(request.getStatus()))
          .sourceCollection(request.getSourceCollection())
          .matchMethod(request.getMatchMethod())
          .encryptedPan(request.getEncryptedPan())
          .encryptedMobile(request.getEncryptedMobile())
          .encryptedEmail(request.getEncryptedEmail())
          .createdAt(LocalDateTime.now())
          .updatedAt(LocalDateTime.now())
          .build();
      created.add(repository.save(policy));
    }
    return created;
  }

  @Override
  public List<Policy> getPoliciesByCustomerId(String customerId) {
    return repository.findByCustomerId(customerId);
  }

  @Override
  public List<Policy> getPoliciesByCustomerIdInt(Integer customerId) {
    return repository.findByCustomerId(String.valueOf(customerId));
  }

  @Override
  public Policy getPolicyById(String id) {
    return repository.findById(id)
        .orElseThrow(() -> new PolicyNotFoundException(id, "id"));
  }

  @Override
  public Optional<Policy> findByPolicyNumberAndInsurerId(String policyNumber, String insurerId) {
    return repository.findByPolicyNumberAndInsurerId(policyNumber, insurerId);
  }

  @Override
  public List<Policy> getAllPolicies() {
    return repository.findAll();
  }

  @Override
  public Policy updatePolicyStatus(String id, PolicyStatus status) {
    Policy policy = repository.findById(id)
        .orElseThrow(() -> new PolicyNotFoundException(id, "id"));

    policy.setStatus(status);
    policy.setUpdatedAt(LocalDateTime.now());

    return repository.save(policy);
  }

  @Override
  public void deletePolicy(String id) {
    if (!repository.existsById(id)) {
      throw new PolicyNotFoundException(id, "id");
    }
    repository.deleteById(id);
  }
}
