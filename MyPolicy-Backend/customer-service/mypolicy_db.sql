--
-- PostgreSQL database dump
--

\restrict x1cneipw48lxX3WUTazdDGKG9KE2x12xiMRhYramdzWbTTpdbHvets6UdjKfdPb

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: customers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customers (
    customer_id character varying(255) NOT NULL,
    address text,
    created_at timestamp(6) without time zone,
    date_of_birth date,
    email character varying(255) NOT NULL,
    first_name character varying(255) NOT NULL,
    last_name character varying(255) NOT NULL,
    mobile_number character varying(255) NOT NULL,
    pan_number character varying(255),
    password_hash character varying(255) NOT NULL,
    status character varying(255) NOT NULL,
    updated_at timestamp(6) without time zone,
    CONSTRAINT customers_status_check CHECK (((status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'INACTIVE'::character varying, 'SUSPENDED'::character varying, 'DELETED'::character varying])::text[])))
);


--
-- Name: insurer_configurations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.insurer_configurations (
    config_id character varying(255) NOT NULL,
    active boolean NOT NULL,
    field_mappings jsonb,
    insurer_id character varying(255) NOT NULL,
    insurer_name character varying(255) NOT NULL,
    updated_at timestamp(6) without time zone
);


--
-- Name: policies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.policies (
    id character varying(255) NOT NULL,
    created_at timestamp(6) without time zone,
    customer_id character varying(255) NOT NULL,
    end_date date,
    insurer_id character varying(255) NOT NULL,
    plan_name character varying(255),
    policy_number character varying(255) NOT NULL,
    policy_type character varying(255) NOT NULL,
    premium_amount numeric(38,2) NOT NULL,
    start_date date,
    status character varying(255),
    sum_assured numeric(38,2) NOT NULL,
    updated_at timestamp(6) without time zone,
    CONSTRAINT policies_status_check CHECK (((status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'EXPIRED'::character varying, 'LAPSED'::character varying, 'PENDING'::character varying, 'CANCELLED'::character varying])::text[])))
);


--
-- Data for Name: customers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.customers (customer_id, address, created_at, date_of_birth, email, first_name, last_name, mobile_number, pan_number, password_hash, status, updated_at) FROM stdin;
6fcd9cf5-9c93-44dd-bafe-c50816dd038e	\N	2026-02-21 13:05:58.837156	\N	rahul@email.com	Rahul	Sharma	9876543210	ABCDE1234F	$2a$10$K33N.RyNlUog/2CDSlTxkOFTLmZr/rgWRC.5r6rexJe7ZNmI6kmEK	ACTIVE	2026-02-21 13:05:58.837156
8a5b108e-bd47-4139-869a-d750b9995fbf	\N	2026-02-25 00:09:07.741396	\N	test2@example.com	Test	User	9876543219	ABCDE1234Z	$2a$10$/1Zircn9q7NZyiohJE45je5oYTR0CNz752M.yUis6Fk2BgJn8LTY6	ACTIVE	2026-02-25 00:09:07.741396
\.


--
-- Data for Name: insurer_configurations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.insurer_configurations (config_id, active, field_mappings, insurer_id, insurer_name, updated_at) FROM stdin;
019a774e-5d99-4687-9f04-d262200b6799	t	{"TERM_LIFE": [{"dataType": "STRING", "required": true, "sourceField": "Policy_No", "targetField": "policyNumber", "defaultValue": null, "transformRule": "uppercase", "transformFunction": null}, {"dataType": "STRING", "required": true, "sourceField": "Insured_Name", "targetField": "customerName", "defaultValue": null, "transformRule": "trim", "transformFunction": null}, {"dataType": "STRING", "required": true, "sourceField": "Email", "targetField": "email", "defaultValue": null, "transformRule": "lowercase", "transformFunction": null}, {"dataType": "STRING", "required": true, "sourceField": "Mobile", "targetField": "mobileNumber", "defaultValue": null, "transformRule": "normalize_mobile", "transformFunction": null}, {"dataType": "DECIMAL", "required": true, "sourceField": "Premium_Amt", "targetField": "premiumAmount", "defaultValue": "0.00", "transformRule": "parse_number", "transformFunction": null}, {"dataType": "DECIMAL", "required": true, "sourceField": "Sum_Assured", "targetField": "sumAssured", "defaultValue": "0.00", "transformRule": "parse_number", "transformFunction": null}, {"dataType": "DATE", "required": true, "sourceField": "Start_Date", "targetField": "startDate", "defaultValue": null, "transformRule": "parse_date", "transformFunction": null}, {"dataType": "DATE", "required": false, "sourceField": "Maturity_Date", "targetField": "endDate", "defaultValue": null, "transformRule": "parse_date", "transformFunction": null}]}	HDFC_LIFE	HDFC Life Insurance	2026-02-24 14:26:30.850035
\.


--
-- Data for Name: policies; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.policies (id, created_at, customer_id, end_date, insurer_id, plan_name, policy_number, policy_type, premium_amount, start_date, status, sum_assured, updated_at) FROM stdin;
4e9c7ba1-1151-41e1-b880-f39ecc649597	2026-02-24 10:30:30.626912	CUST001	2027-01-01	INS001	Premium Health Plan	POL-2026-12345	HEALTH	5000.00	2026-01-01	EXPIRED	500000.00	2026-02-24 11:55:59.22798
\.


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (customer_id);


--
-- Name: insurer_configurations insurer_configurations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.insurer_configurations
    ADD CONSTRAINT insurer_configurations_pkey PRIMARY KEY (config_id);


--
-- Name: policies policies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.policies
    ADD CONSTRAINT policies_pkey PRIMARY KEY (id);


--
-- Name: policies uk31lvsk5v1a3nankd8es44o7q2; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.policies
    ADD CONSTRAINT uk31lvsk5v1a3nankd8es44o7q2 UNIQUE (policy_number, insurer_id);


--
-- Name: customers uk_33fklpyee1eppx1mdo65kc5rl; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT uk_33fklpyee1eppx1mdo65kc5rl UNIQUE (pan_number);


--
-- Name: customers uk_64j2dn17ycwlgr3pttpwna8dw; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT uk_64j2dn17ycwlgr3pttpwna8dw UNIQUE (mobile_number);


--
-- Name: insurer_configurations uk_7tx9oen18wkfcck94ay2pxvln; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.insurer_configurations
    ADD CONSTRAINT uk_7tx9oen18wkfcck94ay2pxvln UNIQUE (insurer_id);


--
-- Name: customers uk_rfbvkrffamfql7cjmen8v976v; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT uk_rfbvkrffamfql7cjmen8v976v UNIQUE (email);


--
-- PostgreSQL database dump complete
--

\unrestrict x1cneipw48lxX3WUTazdDGKG9KE2x12xiMRhYramdzWbTTpdbHvets6UdjKfdPb

