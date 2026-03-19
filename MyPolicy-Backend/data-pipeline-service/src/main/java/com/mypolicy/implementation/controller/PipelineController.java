package com.mypolicy.implementation.controller;

import com.mypolicy.implementation.model.IngestionJob;
import com.mypolicy.implementation.model.FailedLogRecord;
import com.mypolicy.implementation.repository.FailedLogRepository;
import com.mypolicy.implementation.service.IngestionJobService;
import com.mypolicy.implementation.service.PipelineOrchestratorService;
import com.mypolicy.implementation.service.StitchingService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Map;

@Tag(name = "Pipeline", description = "CSV/XLSX upload and pipeline execution")

@RestController
@RequestMapping("/api/pipeline")
public class PipelineController {

    private final PipelineOrchestratorService pipelineOrchestrator;
    private final IngestionJobService ingestionJobService;
    private final FailedLogRepository failedLogRepository;

    public PipelineController(PipelineOrchestratorService pipelineOrchestrator,
                              IngestionJobService ingestionJobService,
                              FailedLogRepository failedLogRepository) {
        this.pipelineOrchestrator = pipelineOrchestrator;
        this.ingestionJobService = ingestionJobService;
        this.failedLogRepository = failedLogRepository;
    }

    @PostMapping("/run")
    public ResponseEntity<Map<String, Object>> runPipeline() {
        StitchingService.StitchingResult result = pipelineOrchestrator.runFullPipeline();
        return ResponseEntity.ok(Map.of(
                "totalProcessed", result.totalProcessed(),
                "matched", result.matched(),
                "unmatched", result.unmatched()
        ));
    }

    @Operation(summary = "Upload CSV/XLSX", description = "Upload a CSV or XLSX file. Click 'Choose File' for file, enter collectionName in the text field.")
    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<Map<String, Object>> uploadCsv(
            @RequestPart("file") @Schema(type = "string", format = "binary", description = "CSV or XLSX file") MultipartFile file,
            @RequestPart("collectionName") @Schema(example = "auto_insurance") String collectionName) throws IOException {
        StitchingService.StitchingResult result = pipelineOrchestrator.uploadAndProcess(file, collectionName);
        return ResponseEntity.ok(Map.of(
                "message", "File uploaded and pipeline executed",
                "collectionName", collectionName,
                "totalProcessed", result.totalProcessed(),
                "matched", result.matched(),
                "unmatched", result.unmatched()
        ));
    }

    @Operation(summary = "Upload CSV/XLSX (async)",
            description = "Upload a CSV or XLSX file and process it asynchronously. Returns a jobId that can be polled for status.")
    @PostMapping(value = "/upload-async", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<Map<String, Object>> uploadAsync(
            @RequestPart("file") @Schema(type = "string", format = "binary", description = "CSV or XLSX file") MultipartFile file,
            @RequestPart("collectionName") @Schema(example = "auto_insurance") String collectionName) throws IOException {

        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("File is empty or null");
        }

        IngestionJob job = ingestionJobService.createQueuedJob(file.getOriginalFilename(), collectionName);
        byte[] bytes = file.getBytes();
        ingestionJobService.processJobAsync(job.getId(), bytes, file.getOriginalFilename(), collectionName);

        return ResponseEntity.accepted().body(Map.of(
                "jobId", job.getId(),
                "status", job.getStatus(),
                "message", job.getMessage()
        ));
    }

    @Operation(summary = "Get ingestion job status",
            description = "Fetch real-time status for an ingestion job (queued / processing / complete / failed).")
    @GetMapping("/jobs/{jobId}")
    public ResponseEntity<Map<String, Object>> getJobStatus(@PathVariable String jobId) {
        IngestionJob job = ingestionJobService.getJob(jobId);
        Map<String, Object> body = new java.util.HashMap<>();
        body.put("jobId", job.getId());
        body.put("fileName", job.getFileName());
        body.put("collectionName", job.getCollectionName());
        body.put("status", job.getStatus());
        body.put("message", job.getMessage());
        body.put("totalProcessed", job.getTotalProcessed() != null ? job.getTotalProcessed() : 0);
        body.put("matched", job.getMatched() != null ? job.getMatched() : 0);
        body.put("unmatched", job.getUnmatched() != null ? job.getUnmatched() : 0);
        body.put("createdAt", job.getCreatedAt());
        body.put("updatedAt", job.getUpdatedAt());
        return ResponseEntity.ok(body);
    }

    @Operation(summary = "Get failed_log entries",
            description = "List recent failed_log entries, optionally filtered by collectionName.")
    @GetMapping("/failed-log")
    public ResponseEntity<java.util.List<java.util.Map<String, Object>>> getFailedLog(
            @RequestParam(value = "collectionName", required = false) String collectionName,
            @RequestParam(value = "limit", required = false, defaultValue = "50") int limit) {

        java.util.List<FailedLogRecord> records = failedLogRepository.findAll();
        java.util.List<java.util.Map<String, Object>> result = new java.util.ArrayList<>();

        for (FailedLogRecord r : records) {
            if (collectionName != null && !collectionName.isBlank()
                    && (r.getSourceCollection() == null || !r.getSourceCollection().equals(collectionName))) {
                continue;
            }
            java.util.Map<String, Object> row = new java.util.HashMap<>();
            row.put("id", r.getId());
            row.put("sourceCollection", r.getSourceCollection());
            row.put("insurer", r.getInsurer());
            row.put("validationErrors", r.getValidationErrors());
            row.put("createdAt", r.getCreatedAt());
            row.put("rawData", r.getRawData());
            result.add(row);
            if (result.size() >= limit) {
                break;
            }
        }

        return ResponseEntity.ok(result);
    }
}
