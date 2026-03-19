package com.mypolicy.policy.repository;

import com.mypolicy.policy.model.Policy;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;
import java.util.Optional;

public interface PolicyRepository extends MongoRepository<Policy, String> {
  List<Policy> findByCustomerId(String customerId);

  List<Policy> findByCustomerIdAndSourceCollectionIsNotNull(String customerId);

  Optional<Policy> findByPolicyNumberAndInsurerId(String policyNumber, String insurerId);
}
