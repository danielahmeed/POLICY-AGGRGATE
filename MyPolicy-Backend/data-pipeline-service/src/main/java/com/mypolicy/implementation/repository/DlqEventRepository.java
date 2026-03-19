package com.mypolicy.implementation.repository;

import com.mypolicy.implementation.model.DlqEvent;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface DlqEventRepository extends MongoRepository<DlqEvent, String> {
}

