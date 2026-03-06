package com.mypolicy.pipeline.processing.service;

import com.opencsv.CSVReader;
import com.opencsv.exceptions.CsvException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * CSV file processing: reads headers, converts each row to Map with headers as
 * keys.
 * Acts as the first gate for automated validation (non-empty file, headers
 * exist).
 */
@Service
public class FileProcessingService {

  private static final Logger log = LoggerFactory.getLogger(FileProcessingService.class);

  /**
   * Parses CSV from input stream. Uses first row as headers; each subsequent row
   * becomes
   * a Map where keys are column headers and values are the cell contents.
   *
   * @param inputStream CSV input (e.g. from MultipartFile.getInputStream())
   * @return List of Maps, one per data row; empty list if file is empty or
   *         invalid
   */
  public List<Map<String, Object>> parseCsv(InputStream inputStream) {
    if (inputStream == null) {
      log.warn("Null input stream for CSV parse");
      return List.of();
    }

    try (CSVReader reader = new CSVReader(new InputStreamReader(inputStream, StandardCharsets.UTF_8))) {
      List<String[]> allRows = reader.readAll();
      if (allRows == null || allRows.isEmpty()) {
        log.warn("CSV file is empty");
        return List.of();
      }

      String[] headers = allRows.get(0);
      if (headers == null || headers.length == 0) {
        log.warn("CSV has no headers");
        return List.of();
      }

      // Trim header names
      for (int i = 0; i < headers.length; i++) {
        headers[i] = headers[i] != null ? headers[i].trim() : "";
      }

      List<Map<String, Object>> result = new ArrayList<>();
      for (int r = 1; r < allRows.size(); r++) {
        String[] row = allRows.get(r);
        Map<String, Object> rowMap = new HashMap<>();

        for (int c = 0; c < headers.length; c++) {
          String headerKey = headers[c];
          Object cellValue = (c < row.length && row[c] != null) ? row[c].trim() : null;
          if (cellValue != null && cellValue.toString().isEmpty())
            cellValue = null;
          rowMap.put(headerKey, cellValue);
        }

        result.add(rowMap);
      }

      log.info("CSV parsed successfully: {} header(s), {} data row(s)", headers.length, result.size());
      return result;
    } catch (IOException | CsvException e) {
      log.error("CSV parse error", e);
      return List.of();
    }
  }
}
