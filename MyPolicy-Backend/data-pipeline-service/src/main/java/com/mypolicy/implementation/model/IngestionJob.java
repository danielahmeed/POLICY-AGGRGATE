package com.mypolicy.implementation.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;

@Document(collection = "ingestion_jobs")
public class IngestionJob {

    @Id
    private String id;
    private String fileName;
    private String collectionName;
    private String status; // QUEUED, PROCESSING, COMPLETE, FAILED
    private String message;
    private Integer totalProcessed;
    private Integer matched;
    private Integer unmatched;
    private Instant createdAt;
    private Instant updatedAt;

    public String getId() {
        return id;
    }

    public String getFileName() {
        return fileName;
    }

    public void setFileName(String fileName) {
        this.fileName = fileName;
    }

    public String getCollectionName() {
        return collectionName;
    }

    public void setCollectionName(String collectionName) {
        this.collectionName = collectionName;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public Integer getTotalProcessed() {
        return totalProcessed;
    }

    public void setTotalProcessed(Integer totalProcessed) {
        this.totalProcessed = totalProcessed;
    }

    public Integer getMatched() {
        return matched;
    }

    public void setMatched(Integer matched) {
        this.matched = matched;
    }

    public Integer getUnmatched() {
        return unmatched;
    }

    public void setUnmatched(Integer unmatched) {
        this.unmatched = unmatched;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Instant updatedAt) {
        this.updatedAt = updatedAt;
    }
}

