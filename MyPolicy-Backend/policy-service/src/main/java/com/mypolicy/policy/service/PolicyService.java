package com.mypolicy.policy.service;

import com.mypolicy.policy.dto.PolicyRequest;
import com.mypolicy.policy.model.Policy;
import com.mypolicy.policy.model.PolicyStatus;

import java.util.List;
import java.util.Optional;

public interface PolicyService {
  Policy createPolicy(PolicyRequest request);

  List<Policy> bulkCreatePolicies(List<PolicyRequest> requests);

  List<Policy> getPoliciesByCustomerId(String customerId);

  List<Policy> getPoliciesByCustomerIdInt(Integer customerId);

  Policy getPolicyById(String id);

  Optional<Policy> findByPolicyNumberAndInsurerId(String policyNumber, String insurerId);

  List<Policy> getAllPolicies();

  Policy updatePolicyStatus(String id, PolicyStatus status);

  void deletePolicy(String id);
}
