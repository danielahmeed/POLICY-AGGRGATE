package com.mypolicy.implementation.repository;

import com.mypolicy.implementation.model.FailedLogRecord;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface FailedLogRepository extends MongoRepository<FailedLogRecord, String> {
}

