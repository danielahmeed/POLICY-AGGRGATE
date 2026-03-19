package com.mypolicy.implementation.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

@Document(collection = "unmatched_policies")
public class UnmatchedPolicyRecord {

    @Id
    private String id;

    private String sourceCollection;
    private String policyId;
    private String insurer;
    private Integer sumAssured;
    private Integer startDate;
    private Integer policyEnd;
    private String pan;
    private Object mobile;
    private String email;
    private Integer dob;

    public String getId() {
        return id;
    }

    public String getSourceCollection() {
        return sourceCollection;
    }

    public void setSourceCollection(String sourceCollection) {
        this.sourceCollection = sourceCollection;
    }

    public String getPolicyId() {
        return policyId;
    }

    public void setPolicyId(String policyId) {
        this.policyId = policyId;
    }

    public String getInsurer() {
        return insurer;
    }

    public void setInsurer(String insurer) {
        this.insurer = insurer;
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
}

