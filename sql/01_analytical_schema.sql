--
-- PostgreSQL database dump
--

\restrict QhpRslsZPVrI4FW6qV3RYUA9zORkpgBwWkh2bBbaj5JeOMi1xKifyvapX8A4JQv

-- Dumped from database version 18.4
-- Dumped by pg_dump version 18.4

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

--
-- Name: analytics; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA analytics;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: dim_content; Type: TABLE; Schema: analytics; Owner: -
--

CREATE TABLE analytics.dim_content (
    content_key bigint NOT NULL,
    content_id bigint NOT NULL,
    title character varying(255) NOT NULL,
    content_type character varying(50),
    genre character varying(100),
    language character varying(50),
    age_rating character varying(20),
    release_date date
);


--
-- Name: dim_content_content_key_seq; Type: SEQUENCE; Schema: analytics; Owner: -
--

CREATE SEQUENCE analytics.dim_content_content_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dim_content_content_key_seq; Type: SEQUENCE OWNED BY; Schema: analytics; Owner: -
--

ALTER SEQUENCE analytics.dim_content_content_key_seq OWNED BY analytics.dim_content.content_key;


--
-- Name: dim_customer; Type: TABLE; Schema: analytics; Owner: -
--

CREATE TABLE analytics.dim_customer (
    customer_key bigint NOT NULL,
    customer_id bigint NOT NULL,
    first_name character varying(100) NOT NULL,
    last_name character varying(100) NOT NULL,
    email character varying(255) NOT NULL,
    registration_date date,
    status character varying(30)
);


--
-- Name: dim_customer_customer_key_seq; Type: SEQUENCE; Schema: analytics; Owner: -
--

CREATE SEQUENCE analytics.dim_customer_customer_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dim_customer_customer_key_seq; Type: SEQUENCE OWNED BY; Schema: analytics; Owner: -
--

ALTER SEQUENCE analytics.dim_customer_customer_key_seq OWNED BY analytics.dim_customer.customer_key;


--
-- Name: dim_date; Type: TABLE; Schema: analytics; Owner: -
--

CREATE TABLE analytics.dim_date (
    date_key integer NOT NULL,
    full_date date NOT NULL,
    day_of_month integer NOT NULL,
    month_number integer NOT NULL,
    month_name character varying(20) NOT NULL,
    quarter_number integer NOT NULL,
    year_number integer NOT NULL
);


--
-- Name: dim_inventory; Type: TABLE; Schema: analytics; Owner: -
--

CREATE TABLE analytics.dim_inventory (
    inventory_key bigint NOT NULL,
    inventory_id bigint NOT NULL,
    content_id bigint NOT NULL,
    content_title character varying(255),
    warehouse_id bigint NOT NULL,
    warehouse_name character varying(150),
    item_condition character varying(50),
    status character varying(30),
    purchase_date date
);


--
-- Name: dim_inventory_inventory_key_seq; Type: SEQUENCE; Schema: analytics; Owner: -
--

CREATE SEQUENCE analytics.dim_inventory_inventory_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dim_inventory_inventory_key_seq; Type: SEQUENCE OWNED BY; Schema: analytics; Owner: -
--

ALTER SEQUENCE analytics.dim_inventory_inventory_key_seq OWNED BY analytics.dim_inventory.inventory_key;


--
-- Name: fact_content_monthly_performance; Type: TABLE; Schema: analytics; Owner: -
--

CREATE TABLE analytics.fact_content_monthly_performance (
    content_performance_key bigint CONSTRAINT fact_content_monthly_performan_content_performance_key_not_null NOT NULL,
    content_key bigint NOT NULL,
    date_key integer NOT NULL,
    total_streams integer DEFAULT 0 NOT NULL,
    rental_count integer DEFAULT 0 NOT NULL,
    revenue_generated numeric(12,2) DEFAULT 0 NOT NULL,
    average_customer_rating numeric(5,2),
    wishlist_addition_count integer DEFAULT 0 CONSTRAINT fact_content_monthly_performan_wishlist_addition_count_not_null NOT NULL
);


--
-- Name: fact_content_monthly_performance_content_performance_key_seq; Type: SEQUENCE; Schema: analytics; Owner: -
--

CREATE SEQUENCE analytics.fact_content_monthly_performance_content_performance_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fact_content_monthly_performance_content_performance_key_seq; Type: SEQUENCE OWNED BY; Schema: analytics; Owner: -
--

ALTER SEQUENCE analytics.fact_content_monthly_performance_content_performance_key_seq OWNED BY analytics.fact_content_monthly_performance.content_performance_key;


--
-- Name: fact_customer_daily_activity; Type: TABLE; Schema: analytics; Owner: -
--

CREATE TABLE analytics.fact_customer_daily_activity (
    customer_activity_key bigint NOT NULL,
    customer_key bigint NOT NULL,
    date_key integer NOT NULL,
    streaming_session_count integer DEFAULT 0 NOT NULL,
    total_streaming_duration integer DEFAULT 0 NOT NULL,
    physical_rental_count integer DEFAULT 0 NOT NULL,
    returned_item_count integer DEFAULT 0 NOT NULL,
    total_amount_spent numeric(12,2) DEFAULT 0 NOT NULL,
    support_ticket_count integer DEFAULT 0 NOT NULL
);


--
-- Name: fact_customer_daily_activity_customer_activity_key_seq; Type: SEQUENCE; Schema: analytics; Owner: -
--

CREATE SEQUENCE analytics.fact_customer_daily_activity_customer_activity_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fact_customer_daily_activity_customer_activity_key_seq; Type: SEQUENCE OWNED BY; Schema: analytics; Owner: -
--

ALTER SEQUENCE analytics.fact_customer_daily_activity_customer_activity_key_seq OWNED BY analytics.fact_customer_daily_activity.customer_activity_key;


--
-- Name: fact_inventory_daily_utilisation; Type: TABLE; Schema: analytics; Owner: -
--

CREATE TABLE analytics.fact_inventory_daily_utilisation (
    inventory_utilisation_key bigint CONSTRAINT fact_inventory_daily_utilisa_inventory_utilisation_key_not_null NOT NULL,
    inventory_key bigint NOT NULL,
    date_key integer NOT NULL,
    rental_count integer DEFAULT 0 NOT NULL,
    return_count integer DEFAULT 0 NOT NULL,
    available_days integer DEFAULT 0 NOT NULL,
    utilisation_percentage numeric(5,2)
);


--
-- Name: fact_inventory_daily_utilisation_inventory_utilisation_key_seq; Type: SEQUENCE; Schema: analytics; Owner: -
--

CREATE SEQUENCE analytics.fact_inventory_daily_utilisation_inventory_utilisation_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fact_inventory_daily_utilisation_inventory_utilisation_key_seq; Type: SEQUENCE OWNED BY; Schema: analytics; Owner: -
--

ALTER SEQUENCE analytics.fact_inventory_daily_utilisation_inventory_utilisation_key_seq OWNED BY analytics.fact_inventory_daily_utilisation.inventory_utilisation_key;


--
-- Name: dim_content content_key; Type: DEFAULT; Schema: analytics; Owner: -
--

ALTER TABLE ONLY analytics.dim_content ALTER COLUMN content_key SET DEFAULT nextval('analytics.dim_content_content_key_seq'::regclass);


--
-- Name: dim_customer customer_key; Type: DEFAULT; Schema: analytics; Owner: -
--

ALTER TABLE ONLY analytics.dim_customer ALTER COLUMN customer_key SET DEFAULT nextval('analytics.dim_customer_customer_key_seq'::regclass);


--
-- Name: dim_inventory inventory_key; Type: DEFAULT; Schema: analytics; Owner: -
--

ALTER TABLE ONLY analytics.dim_inventory ALTER COLUMN inventory_key SET DEFAULT nextval('analytics.dim_inventory_inventory_key_seq'::regclass);


--
-- Name: fact_content_monthly_performance content_performance_key; Type: DEFAULT; Schema: analytics; Owner: -
--

ALTER TABLE ONLY analytics.fact_content_monthly_performance ALTER COLUMN content_performance_key SET DEFAULT nextval('analytics.fact_content_monthly_performance_content_performance_key_seq'::regclass);


--
-- Name: fact_customer_daily_activity customer_activity_key; Type: DEFAULT; Schema: analytics; Owner: -
--

ALTER TABLE ONLY analytics.fact_customer_daily_activity ALTER COLUMN customer_activity_key SET DEFAULT nextval('analytics.fact_customer_daily_activity_customer_activity_key_seq'::regclass);


--
-- Name: fact_inventory_daily_utilisation inventory_utilisation_key; Type: DEFAULT; Schema: analytics; Owner: -
--

ALTER TABLE ONLY analytics.fact_inventory_daily_utilisation ALTER COLUMN inventory_utilisation_key SET DEFAULT nextval('analytics.fact_inventory_daily_utilisation_inventory_utilisation_key_seq'::regclass);


--
-- Name: dim_content dim_content_content_id_key; Type: CONSTRAINT; Schema: analytics; Owner: -
--

ALTER TABLE ONLY analytics.dim_content
    ADD CONSTRAINT dim_content_content_id_key UNIQUE (content_id);


--
-- Name: dim_content dim_content_pkey; Type: CONSTRAINT; Schema: analytics; Owner: -
--

ALTER TABLE ONLY analytics.dim_content
    ADD CONSTRAINT dim_content_pkey PRIMARY KEY (content_key);


--
-- Name: dim_customer dim_customer_customer_id_key; Type: CONSTRAINT; Schema: analytics; Owner: -
--

ALTER TABLE ONLY analytics.dim_customer
    ADD CONSTRAINT dim_customer_customer_id_key UNIQUE (customer_id);


--
-- Name: dim_customer dim_customer_pkey; Type: CONSTRAINT; Schema: analytics; Owner: -
--

ALTER TABLE ONLY analytics.dim_customer
    ADD CONSTRAINT dim_customer_pkey PRIMARY KEY (customer_key);


--
-- Name: dim_date dim_date_full_date_key; Type: CONSTRAINT; Schema: analytics; Owner: -
--

ALTER TABLE ONLY analytics.dim_date
    ADD CONSTRAINT dim_date_full_date_key UNIQUE (full_date);


--
-- Name: dim_date dim_date_pkey; Type: CONSTRAINT; Schema: analytics; Owner: -
--

ALTER TABLE ONLY analytics.dim_date
    ADD CONSTRAINT dim_date_pkey PRIMARY KEY (date_key);


--
-- Name: dim_inventory dim_inventory_inventory_id_key; Type: CONSTRAINT; Schema: analytics; Owner: -
--

ALTER TABLE ONLY analytics.dim_inventory
    ADD CONSTRAINT dim_inventory_inventory_id_key UNIQUE (inventory_id);


--
-- Name: dim_inventory dim_inventory_pkey; Type: CONSTRAINT; Schema: analytics; Owner: -
--

ALTER TABLE ONLY analytics.dim_inventory
    ADD CONSTRAINT dim_inventory_pkey PRIMARY KEY (inventory_key);


--
-- Name: fact_content_monthly_performance fact_content_monthly_performance_pkey; Type: CONSTRAINT; Schema: analytics; Owner: -
--

ALTER TABLE ONLY analytics.fact_content_monthly_performance
    ADD CONSTRAINT fact_content_monthly_performance_pkey PRIMARY KEY (content_performance_key);


--
-- Name: fact_customer_daily_activity fact_customer_daily_activity_pkey; Type: CONSTRAINT; Schema: analytics; Owner: -
--

ALTER TABLE ONLY analytics.fact_customer_daily_activity
    ADD CONSTRAINT fact_customer_daily_activity_pkey PRIMARY KEY (customer_activity_key);


--
-- Name: fact_inventory_daily_utilisation fact_inventory_daily_utilisation_pkey; Type: CONSTRAINT; Schema: analytics; Owner: -
--

ALTER TABLE ONLY analytics.fact_inventory_daily_utilisation
    ADD CONSTRAINT fact_inventory_daily_utilisation_pkey PRIMARY KEY (inventory_utilisation_key);


--
-- Name: fact_content_monthly_performance uq_content_monthly_performance; Type: CONSTRAINT; Schema: analytics; Owner: -
--

ALTER TABLE ONLY analytics.fact_content_monthly_performance
    ADD CONSTRAINT uq_content_monthly_performance UNIQUE (content_key, date_key);


--
-- Name: fact_customer_daily_activity uq_customer_daily_activity; Type: CONSTRAINT; Schema: analytics; Owner: -
--

ALTER TABLE ONLY analytics.fact_customer_daily_activity
    ADD CONSTRAINT uq_customer_daily_activity UNIQUE (customer_key, date_key);


--
-- Name: fact_inventory_daily_utilisation uq_inventory_daily_utilisation; Type: CONSTRAINT; Schema: analytics; Owner: -
--

ALTER TABLE ONLY analytics.fact_inventory_daily_utilisation
    ADD CONSTRAINT uq_inventory_daily_utilisation UNIQUE (inventory_key, date_key);


--
-- Name: fact_content_monthly_performance fk_content_performance_content; Type: FK CONSTRAINT; Schema: analytics; Owner: -
--

ALTER TABLE ONLY analytics.fact_content_monthly_performance
    ADD CONSTRAINT fk_content_performance_content FOREIGN KEY (content_key) REFERENCES analytics.dim_content(content_key);


--
-- Name: fact_content_monthly_performance fk_content_performance_date; Type: FK CONSTRAINT; Schema: analytics; Owner: -
--

ALTER TABLE ONLY analytics.fact_content_monthly_performance
    ADD CONSTRAINT fk_content_performance_date FOREIGN KEY (date_key) REFERENCES analytics.dim_date(date_key);


--
-- Name: fact_customer_daily_activity fk_customer_activity_customer; Type: FK CONSTRAINT; Schema: analytics; Owner: -
--

ALTER TABLE ONLY analytics.fact_customer_daily_activity
    ADD CONSTRAINT fk_customer_activity_customer FOREIGN KEY (customer_key) REFERENCES analytics.dim_customer(customer_key);


--
-- Name: fact_customer_daily_activity fk_customer_activity_date; Type: FK CONSTRAINT; Schema: analytics; Owner: -
--

ALTER TABLE ONLY analytics.fact_customer_daily_activity
    ADD CONSTRAINT fk_customer_activity_date FOREIGN KEY (date_key) REFERENCES analytics.dim_date(date_key);


--
-- Name: fact_inventory_daily_utilisation fk_inventory_utilisation_date; Type: FK CONSTRAINT; Schema: analytics; Owner: -
--

ALTER TABLE ONLY analytics.fact_inventory_daily_utilisation
    ADD CONSTRAINT fk_inventory_utilisation_date FOREIGN KEY (date_key) REFERENCES analytics.dim_date(date_key);


--
-- Name: fact_inventory_daily_utilisation fk_inventory_utilisation_inventory; Type: FK CONSTRAINT; Schema: analytics; Owner: -
--

ALTER TABLE ONLY analytics.fact_inventory_daily_utilisation
    ADD CONSTRAINT fk_inventory_utilisation_inventory FOREIGN KEY (inventory_key) REFERENCES analytics.dim_inventory(inventory_key);


--
-- PostgreSQL database dump complete
--

\unrestrict QhpRslsZPVrI4FW6qV3RYUA9zORkpgBwWkh2bBbaj5JeOMi1xKifyvapX8A4JQv

