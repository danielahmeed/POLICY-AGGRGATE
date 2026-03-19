package com.mypolicy.implementation.repository;

import com.mypolicy.implementation.model.IngestionJob;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface IngestionJobRepository extends MongoRepository<IngestionJob, String> {
}

