package com.mypolicy.implementation.repository;

import com.mypolicy.implementation.model.UnmatchedPolicyRecord;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface UnmatchedPolicyRepository extends MongoRepository<UnmatchedPolicyRecord, String> {
}

