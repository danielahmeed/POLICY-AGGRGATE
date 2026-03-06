package com.mypolicy.pipeline.matching.service;

import com.mypolicy.pipeline.common.model.StandardizedRecord;
import com.mypolicy.pipeline.matching.dto.CustomerDTO;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Identity Stitching Service. Links policy records to Customer Master using:
 * Rule 1: Match by PAN (refCustItNum)
 * Rule 2: Match by Mobile + DOB
 * Rule 3: Match by Email + DOB
 */
@Service
@RequiredArgsConstructor
public class StitchingService {

  private static final Logger log = LoggerFactory.getLogger(StitchingService.class);

  private final CustomerMatchingRuleService customerMatchingRuleService;

  /**
   * Stitch policies to customers using identity matching rules.
   */
  public StitchingResult stitchPolicies(List<StandardizedRecord> policies) {
    if (policies == null || policies.isEmpty()) {
      return new StitchingResult(0, 0, 0);
    }

    AtomicInteger matched = new AtomicInteger(0);
    AtomicInteger unmatched = new AtomicInteger(0);

    for (StandardizedRecord policy : policies) {
      Optional<CustomerDTO> customer = findCustomer(policy);
      if (customer.isPresent()) {
        matched.incrementAndGet();
        String matchMethod = resolveMatchMethod(policy, customer.get());
        log.info("Policy {} stitched to customer {} via {}",
            policy.getPolicyId(), customer.get().getCustomerId(), matchMethod);
      } else {
        unmatched.incrementAndGet();
        log.warn("No customer match for policy {}", policy.getPolicyId());
      }
    }

    return new StitchingResult(policies.size(), matched.get(), unmatched.get());
  }

  private Optional<CustomerDTO> findCustomer(StandardizedRecord policy) {
    // Try PAN match first
    if (policy.getPan() != null) {
      Optional<CustomerDTO> result = customerMatchingRuleService.findByPan(policy.getPan());
      if (result.isPresent()) {
        log.debug("Found customer via PAN match");
        return result;
      }
    }

    // Try Mobile + DOB match
    if (policy.getMobile() != null && policy.getDob() != null) {
      Optional<CustomerDTO> result = customerMatchingRuleService.findByMobileAndDob(
          policy.getMobile().toString(), policy.getDob());
      if (result.isPresent()) {
        log.debug("Found customer via Mobile+DOB match");
        return result;
      }
    }

    // Try Email + DOB match
    if (policy.getEmail() != null && policy.getDob() != null) {
      Optional<CustomerDTO> result = customerMatchingRuleService.findByEmailAndDob(
          policy.getEmail(), policy.getDob());
      if (result.isPresent()) {
        log.debug("Found customer via Email+DOB match");
        return result;
      }
    }

    return Optional.empty();
  }

  private String resolveMatchMethod(StandardizedRecord policy, CustomerDTO customer) {
    if (customer.getRefCustItNum() != null && customer.getRefCustItNum().equals(policy.getPan())) {
      return "PAN_MATCH";
    }
    if (customer.getRefPhoneMobile() != null && policy.getMobile() != null
        && customer.getDatBirthCust() != null && customer.getDatBirthCust().equals(policy.getDob())) {
      return "MOBILE_DOB_MATCH";
    }
    if (customer.getCustEmailID() != null && customer.getCustEmailID().equals(policy.getEmail())
        && customer.getDatBirthCust() != null && customer.getDatBirthCust().equals(policy.getDob())) {
      return "EMAIL_DOB_MATCH";
    }
    return "UNKNOWN";
  }

  /**
   * Stitching result record.
   */
  public record StitchingResult(int totalProcessed, int matched, int unmatched) {
  }
}
