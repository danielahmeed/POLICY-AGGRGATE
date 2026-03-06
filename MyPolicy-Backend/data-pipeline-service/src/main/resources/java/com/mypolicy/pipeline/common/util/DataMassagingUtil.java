package com.mypolicy.pipeline.common.util;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.Locale;

/**
 * Normalizes formats: integer dates (YYYYMMDD) → LocalDate, currency, status
 * codes.
 * Supports "zero code change" data massaging across heterogeneous insurer
 * formats.
 */
public final class DataMassagingUtil {

  private DataMassagingUtil() {
  }

  /**
   * Converts integer date (e.g. 19881220) to LocalDate.
   */
  public static LocalDate toLocalDate(Integer yyyymmdd) {
    if (yyyymmdd == null)
      return null;
    String s = String.valueOf(yyyymmdd);
    if (s.length() != 8)
      return null;
    try {
      return LocalDate.of(
          Integer.parseInt(s.substring(0, 4)),
          Integer.parseInt(s.substring(4, 6)),
          Integer.parseInt(s.substring(6, 8)));
    } catch (NumberFormatException e) {
      return null;
    }
  }

  /**
   * Converts LocalDate to YYYYMMDD integer for storage.
   */
  public static Integer toYyyymmdd(LocalDate date) {
    if (date == null)
      return null;
    return date.getYear() * 10000 + date.getMonthValue() * 100 + date.getDayOfMonth();
  }

  /**
   * Standardizes currency to BigDecimal (removes commas, handles locale).
   */
  public static BigDecimal normalizeCurrency(Object value) {
    if (value == null)
      return BigDecimal.ZERO;
    if (value instanceof BigDecimal bd)
      return bd;
    if (value instanceof Number n)
      return new BigDecimal(n.toString());

    String s = value.toString().replaceAll("[^0-9.\\-]", "").trim();
    if (s.isEmpty())
      return BigDecimal.ZERO;
    try {
      return new BigDecimal(s);
    } catch (NumberFormatException e) {
      return BigDecimal.ZERO;
    }
  }

  /**
   * Normalizes mobile: strips spaces, keeps digits. Returns as-is if already
   * numeric.
   */
  public static Object normalizeMobile(Object value) {
    if (value == null)
      return null;
    if (value instanceof Number)
      return value;
    String s = value.toString().replaceAll("\\s+", "").replaceAll("[^0-9]", "");
    if (s.isEmpty())
      return null;
    try {
      return Long.parseLong(s);
    } catch (NumberFormatException e) {
      return s;
    }
  }

  /**
   * Normalizes status/type codes to uppercase.
   */
  public static String normalizeStatus(String value) {
    if (value == null || value.isBlank())
      return null;
    return value.trim().toUpperCase(Locale.ROOT);
  }
}
