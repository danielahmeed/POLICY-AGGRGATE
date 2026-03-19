package com.mypolicy.implementation.service;

import com.opencsv.CSVReader;
import com.opencsv.exceptions.CsvException;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

/**
 * File processing utilities for ingestion.
 * - CSV: reads headers, converts each row to Map with headers as keys.
 * - XLSX: reads first sheet, uses first row as headers and each subsequent row as a Map.
 * Acts as the first gate for automated validation (non-empty file, headers exist).
 */
@Service
public class FileProcessingService {

    private static final Logger log = LoggerFactory.getLogger(FileProcessingService.class);

    /**
     * Parses CSV from input stream. Uses first row as headers; each subsequent row becomes
     * a Map where keys are column headers and values are the cell contents.
     *
     * @param inputStream CSV input (e.g. from MultipartFile.getInputStream())
     * @return List of Maps, one per data row; empty list if file is empty or invalid
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
                    String key = headers[c];
                    Object value = (c < row.length && row[c] != null) ? row[c].trim() : null;
                    rowMap.put(key, value);
                }
                result.add(rowMap);
            }

            log.info("Parsed {} rows from CSV with {} columns", result.size(), headers.length);
            return result;
        } catch (IOException | CsvException e) {
            log.error("CSV parse failed: {}", e.getMessage());
            throw new IllegalArgumentException("Failed to parse CSV: " + e.getMessage(), e);
        }
    }

    /**
     * Basic row-level validation used before any database writes.
     * Currently checks for completely empty data rows (all values null/blank)
     * and reports them with 1-based row numbers including header offset.
     *
     * @param rows Parsed data rows
     * @return List of human-readable validation error messages
     */
    public List<String> validateRows(List<Map<String, Object>> rows) {
        List<String> errors = new ArrayList<>();
        if (rows == null || rows.isEmpty()) {
            return errors;
        }

        for (int i = 0; i < rows.size(); i++) {
            Map<String, Object> row = rows.get(i);
            boolean allEmpty = row.values().stream()
                    .allMatch(v -> v == null || v.toString().trim().isEmpty());
            if (allEmpty) {
                int csvRowNumber = i + 2; // +1 for header row, +1 for 1-based index
                errors.add("Row " + csvRowNumber + " is empty");
            }
        }

        return errors;
    }

    /**
     * Parses XLSX from input stream. Uses the first sheet, first row as headers; each subsequent
     * row becomes a Map where keys are column headers and values are cell contents.
     *
     * @param inputStream XLSX input (e.g. from MultipartFile.getInputStream())
     * @return List of Maps, one per data row; empty list if file is empty or invalid
     */
    public List<Map<String, Object>> parseXlsx(InputStream inputStream) {
        if (inputStream == null) {
            log.warn("Null input stream for XLSX parse");
            return List.of();
        }

        try (Workbook workbook = new XSSFWorkbook(inputStream)) {
            Sheet sheet = workbook.getNumberOfSheets() > 0 ? workbook.getSheetAt(0) : null;
            if (sheet == null) {
                log.warn("XLSX has no sheets");
                return List.of();
            }

            Iterator<Row> rowIterator = sheet.iterator();
            if (!rowIterator.hasNext()) {
                log.warn("XLSX sheet is empty");
                return List.of();
            }

            Row headerRow = rowIterator.next();
            List<String> headers = new ArrayList<>();
            for (Cell cell : headerRow) {
                headers.add(getCellString(cell).trim());
            }
            if (headers.isEmpty()) {
                log.warn("XLSX has no headers");
                return List.of();
            }

            List<Map<String, Object>> result = new ArrayList<>();
            while (rowIterator.hasNext()) {
                Row dataRow = rowIterator.next();
                Map<String, Object> rowMap = new HashMap<>();
                for (int c = 0; c < headers.size(); c++) {
                    String key = headers.get(c);
                    Cell cell = dataRow.getCell(c);
                    Object value = cell != null ? getCellString(cell).trim() : null;
                    rowMap.put(key, value);
                }
                result.add(rowMap);
            }

            log.info("Parsed {} rows from XLSX with {} columns", result.size(), headers.size());
            return result;
        } catch (IOException e) {
            log.error("XLSX parse failed: {}", e.getMessage());
            throw new IllegalArgumentException("Failed to parse XLSX: " + e.getMessage(), e);
        }
    }

    private String getCellString(Cell cell) {
        if (cell == null) {
            return "";
        }
        return switch (cell.getCellType()) {
            case STRING -> cell.getStringCellValue();
            case NUMERIC -> {
                if (DateUtil.isCellDateFormatted(cell)) {
                    yield cell.getLocalDateTimeCellValue().toLocalDate().toString();
                }
                double value = cell.getNumericCellValue();
                if (value == Math.rint(value)) {
                    long longVal = (long) value;
                    yield Long.toString(longVal);
                }
                yield Double.toString(value);
            }
            case BOOLEAN -> Boolean.toString(cell.getBooleanCellValue());
            case FORMULA -> {
                try {
                    yield cell.getStringCellValue();
                } catch (IllegalStateException ex) {
                    yield Double.toString(cell.getNumericCellValue());
                }
            }
            case BLANK -> "";
            default -> "";
        };
    }
}
