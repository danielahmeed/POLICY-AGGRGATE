package com.mypolicy.implementation.service;

import com.mypolicy.implementation.model.DlqEvent;
import com.mypolicy.implementation.repository.DlqEventRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.time.Instant;
import java.util.concurrent.Callable;

@Service
public class DownstreamRetryExecutor {

    private static final Logger log = LoggerFactory.getLogger(DownstreamRetryExecutor.class);

    private final DlqEventRepository dlqEventRepository;

    public DownstreamRetryExecutor(DlqEventRepository dlqEventRepository) {
        this.dlqEventRepository = dlqEventRepository;
    }

    public <T> T executeWithRetry(Callable<T> action, String operation, String payloadSummary) {
        int maxAttempts = 3;
        long backoffMillis = 200L;
        int attempt = 0;
        while (true) {
            attempt++;
            try {
                return action.call();
            } catch (Exception ex) {
                if (attempt >= maxAttempts) {
                    log.error("Downstream operation failed after {} attempts: {}", attempt, operation, ex);
                    sendToDlq(operation, payloadSummary, ex);
                    throw new IllegalStateException("Downstream operation failed after retries: " + operation, ex);
                }
                log.warn("Downstream operation failed (attempt {}/{}): {} - {}",
                        attempt, maxAttempts, operation, ex.getMessage());
                try {
                    Thread.sleep(backoffMillis);
                } catch (InterruptedException ie) {
                    Thread.currentThread().interrupt();
                    sendToDlq(operation, payloadSummary, ex);
                    throw new IllegalStateException("Retry interrupted for operation: " + operation, ex);
                }
                backoffMillis *= 2;
            }
        }
    }

    public void executeVoidWithRetry(Runnable action, String operation, String payloadSummary) {
        executeWithRetry(() -> {
            action.run();
            return null;
        }, operation, payloadSummary);
    }

    private void sendToDlq(String operation, String payloadSummary, Exception ex) {
        DlqEvent event = new DlqEvent();
        event.setOperation(operation);
        event.setPayloadSummary(payloadSummary);
        event.setErrorMessage(ex.getMessage());
        event.setExceptionType(ex.getClass().getName());
        event.setStackTrace(getStackTrace(ex));
        event.setCreatedAt(Instant.now());
        dlqEventRepository.save(event);
    }

    private String getStackTrace(Exception ex) {
        StringWriter sw = new StringWriter();
        ex.printStackTrace(new PrintWriter(sw));
        return sw.toString();
    }
}

