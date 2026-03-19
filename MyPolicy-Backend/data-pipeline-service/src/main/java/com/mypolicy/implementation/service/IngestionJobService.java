package com.mypolicy.implementation.service;

import com.mypolicy.implementation.model.IngestionJob;
import com.mypolicy.implementation.repository.IngestionJobRepository;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.io.ByteArrayInputStream;
import java.time.Instant;

@Service
public class IngestionJobService {

    private final IngestionJobRepository jobRepository;
    private final PipelineOrchestratorService pipelineOrchestratorService;

    public IngestionJobService(IngestionJobRepository jobRepository,
                               PipelineOrchestratorService pipelineOrchestratorService) {
        this.jobRepository = jobRepository;
        this.pipelineOrchestratorService = pipelineOrchestratorService;
    }

    public IngestionJob createQueuedJob(String fileName, String collectionName) {
        IngestionJob job = new IngestionJob();
        job.setFileName(fileName);
        job.setCollectionName(collectionName);
        job.setStatus("QUEUED");
        job.setMessage("Job queued for processing");
        Instant now = Instant.now();
        job.setCreatedAt(now);
        job.setUpdatedAt(now);
        return jobRepository.save(job);
    }

    public IngestionJob getJob(String jobId) {
        return jobRepository.findById(jobId)
                .orElseThrow(() -> new IllegalArgumentException("Job not found: " + jobId));
    }

    @Async
    public void processJobAsync(String jobId, byte[] fileBytes, String originalFilename, String collectionName) {
        IngestionJob job = getJob(jobId);
        job.setStatus("PROCESSING");
        job.setMessage("Ingestion in progress");
        job.setUpdatedAt(Instant.now());
        jobRepository.save(job);

        try {
            var result = pipelineOrchestratorService.uploadAndProcessStream(
                    new ByteArrayInputStream(fileBytes),
                    originalFilename,
                    collectionName
            );
            job.setStatus("COMPLETE");
            job.setMessage("Ingestion completed successfully");
            job.setTotalProcessed(result.totalProcessed());
            job.setMatched(result.matched());
            job.setUnmatched(result.unmatched());
        } catch (Exception e) {
            job.setStatus("FAILED");
            job.setMessage(e.getMessage());
        }
        job.setUpdatedAt(Instant.now());
        jobRepository.save(job);
    }
}

