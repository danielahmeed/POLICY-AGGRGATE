package com.mypolicy.pipeline.common.model;

import java.math.BigDecimal;
import java.util.Map;

/**
 * Standardized record after metadata mapping. Uses consistent keys regardless
 * of source.
 */
public class StandardizedRecord {

  private String sourceCollection;
  private String originalId;
  private String policyId;
  private BigDecimal premium;
  private Integer sumAssured;
  private Integer startDate;
  private Integer policyEnd;
  private String pan;
  private Object mobile;
  private String email;
  private Integer dob;
  private String insurer;
  private Integer custId;

  public StandardizedRecord() {
  }

  public StandardizedRecord(String sourceCollection, String originalId) {
    this.sourceCollection = sourceCollection;
    this.originalId = originalId;
  }

  public static StandardizedRecord fromMongoDoc(String collectionName, String objectId, Map<String, String> mapping,
      Map<String, Object> doc) {
    StandardizedRecord rec = new StandardizedRecord(collectionName, objectId);

    if (mapping != null && doc != null) {
      rec.policyId = asString(doc.get(mapping.getOrDefault("policy_id", "policyId")));
      rec.premium = toBigDecimal(doc.get(mapping.getOrDefault("premium", "premium")));
      rec.sumAssured = toInt(doc.get(mapping.getOrDefault("sum_assured", "sumAssured")));
      rec.startDate = toInt(doc.get(mapping.getOrDefault("start_date", "startDate")));
      rec.policyEnd = toInt(doc.get(mapping.getOrDefault("policy_end", "policyEnd")));
      rec.pan = asString(doc.get(mapping.getOrDefault("pan", "pan")));
      rec.mobile = doc.get(mapping.getOrDefault("mobile", "mobile"));
      rec.email = asString(doc.get(mapping.getOrDefault("email", "email")));
      rec.dob = toInt(doc.get(mapping.getOrDefault("dob", "dob")));
      rec.insurer = asString(doc.get(mapping.getOrDefault("insurer", "insurer")));
      rec.custId = toInt(doc.get(mapping.getOrDefault("cust_id", "custId")));
    }

    return rec;
  }

  private static String asString(Object o) {
    return o == null ? null : o.toString();
  }

  private static Integer toInt(Object o) {
    if (o == null)
      return null;
    if (o instanceof Number n)
      return n.intValue();
    try {
      return Integer.parseInt(o.toString());
    } catch (NumberFormatException e) {
      return null;
    }
  }

  private static BigDecimal toBigDecimal(Object o) {
    if (o == null)
      return BigDecimal.ZERO;
    if (o instanceof BigDecimal bd)
      return bd;
    if (o instanceof Number n)
      return new BigDecimal(n.toString());
    try {
      return new BigDecimal(o.toString());
    } catch (NumberFormatException e) {
      return BigDecimal.ZERO;
    }
  }

  // Getters and Setters
  public String getSourceCollection() {
    return sourceCollection;
  }

  public void setSourceCollection(String sourceCollection) {
    this.sourceCollection = sourceCollection;
  }

  public String getOriginalId() {
    return originalId;
  }

  public void setOriginalId(String originalId) {
    this.originalId = originalId;
  }

  public String getPolicyId() {
    return policyId;
  }

  public void setPolicyId(String policyId) {
    this.policyId = policyId;
  }

  public BigDecimal getPremium() {
    return premium;
  }

  public void setPremium(BigDecimal premium) {
    this.premium = premium;
  }

  public Integer getSumAssured() {
    return sumAssured;
  }

  public void setSumAssured(Integer sumAssured) {
    this.sumAssured = sumAssured;
  }

  public Integer getStartDate() {
    return startDate;
  }

  public void setStartDate(Integer startDate) {
    this.startDate = startDate;
  }

  public Integer getPolicyEnd() {
    return policyEnd;
  }

  public void setPolicyEnd(Integer policyEnd) {
    this.policyEnd = policyEnd;
  }

  public String getPan() {
    return pan;
  }

  public void setPan(String pan) {
    this.pan = pan;
  }

  public Object getMobile() {
    return mobile;
  }

  public void setMobile(Object mobile) {
    this.mobile = mobile;
  }

  public String getEmail() {
    return email;
  }

  public void setEmail(String email) {
    this.email = email;
  }

  public Integer getDob() {
    return dob;
  }

  public void setDob(Integer dob) {
    this.dob = dob;
  }

  public String getInsurer() {
    return insurer;
  }

  public void setInsurer(String insurer) {
    this.insurer = insurer;
  }

  public Integer getCustId() {
    return custId;
  }

  public void setCustId(Integer custId) {
    this.custId = custId;
  }
}
