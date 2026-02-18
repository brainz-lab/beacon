--
-- PostgreSQL database dump
--

\restrict agZBisq3xrXOzX8jgidWCUn6ZlxnTKQnEMsR1XZ0YmZamArB4N53YRmEiZJrgLF

-- Dumped from database version 15.16 (Homebrew)
-- Dumped by pg_dump version 15.16 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- *not* creating schema, since initdb creates it


--
-- Name: timescaledb; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS timescaledb WITH SCHEMA public;


--
-- Name: EXTENSION timescaledb; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION timescaledb IS 'Enables scalable inserts and complex queries for time-series data (Community Edition)';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: vector; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;


--
-- Name: EXTENSION vector; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION vector IS 'vector data type and ivfflat and hnsw access methods';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: alert_rules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.alert_rules (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    monitor_id uuid NOT NULL,
    name character varying NOT NULL,
    enabled boolean DEFAULT true,
    condition_type character varying NOT NULL,
    condition_config jsonb DEFAULT '{}'::jsonb,
    signal_alert_id uuid,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: check_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.check_results (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    monitor_id uuid NOT NULL,
    checked_at timestamp with time zone NOT NULL,
    region text NOT NULL,
    status text NOT NULL,
    response_time_ms integer,
    dns_time_ms integer,
    connect_time_ms integer,
    tls_time_ms integer,
    ttfb_ms integer,
    status_code integer,
    response_size_bytes integer,
    error_message text,
    error_type text,
    ssl_issuer text,
    ssl_expires_at timestamp with time zone,
    ssl_valid boolean,
    resolved_ip text,
    resolved_ips text[]
);


--
-- Name: incident_updates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.incident_updates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    incident_id uuid NOT NULL,
    status character varying NOT NULL,
    message text NOT NULL,
    created_by character varying,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: incidents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.incidents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    monitor_id uuid NOT NULL,
    title character varying NOT NULL,
    status character varying NOT NULL,
    severity character varying DEFAULT 'major'::character varying,
    started_at timestamp(6) without time zone NOT NULL,
    identified_at timestamp(6) without time zone,
    resolved_at timestamp(6) without time zone,
    duration_seconds integer,
    affected_regions character varying[] DEFAULT '{}'::character varying[],
    uptime_impact double precision,
    root_cause text,
    resolution_notes text,
    notified boolean DEFAULT false,
    notified_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: maintenance_windows; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maintenance_windows (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    project_id uuid NOT NULL,
    title character varying NOT NULL,
    description text,
    starts_at timestamp(6) without time zone NOT NULL,
    ends_at timestamp(6) without time zone NOT NULL,
    timezone character varying DEFAULT 'UTC'::character varying,
    monitor_ids uuid[] DEFAULT '{}'::uuid[],
    affects_all_monitors boolean DEFAULT false,
    status character varying DEFAULT 'scheduled'::character varying,
    notify_subscribers boolean DEFAULT true,
    notify_before_minutes integer DEFAULT 60,
    notified boolean DEFAULT false,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.projects (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    platform_project_id uuid,
    api_key character varying NOT NULL,
    ingest_key character varying,
    name character varying,
    settings jsonb DEFAULT '{}'::jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    timezone character varying
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: solid_queue_blocked_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_blocked_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    queue_name character varying NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    concurrency_key character varying NOT NULL,
    expires_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_blocked_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_blocked_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_blocked_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_blocked_executions_id_seq OWNED BY public.solid_queue_blocked_executions.id;


--
-- Name: solid_queue_claimed_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_claimed_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    process_id bigint,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_claimed_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_claimed_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_claimed_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_claimed_executions_id_seq OWNED BY public.solid_queue_claimed_executions.id;


--
-- Name: solid_queue_failed_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_failed_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    error text,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_failed_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_failed_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_failed_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_failed_executions_id_seq OWNED BY public.solid_queue_failed_executions.id;


--
-- Name: solid_queue_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_jobs (
    id bigint NOT NULL,
    queue_name character varying NOT NULL,
    class_name character varying NOT NULL,
    arguments text,
    priority integer DEFAULT 0 NOT NULL,
    active_job_id character varying,
    scheduled_at timestamp(6) without time zone,
    finished_at timestamp(6) without time zone,
    concurrency_key character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_jobs_id_seq OWNED BY public.solid_queue_jobs.id;


--
-- Name: solid_queue_pauses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_pauses (
    id bigint NOT NULL,
    queue_name character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_pauses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_pauses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_pauses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_pauses_id_seq OWNED BY public.solid_queue_pauses.id;


--
-- Name: solid_queue_processes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_processes (
    id bigint NOT NULL,
    kind character varying NOT NULL,
    last_heartbeat_at timestamp(6) without time zone NOT NULL,
    supervisor_id bigint,
    pid integer NOT NULL,
    hostname character varying,
    metadata text,
    created_at timestamp(6) without time zone NOT NULL,
    name character varying NOT NULL
);


--
-- Name: solid_queue_processes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_processes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_processes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_processes_id_seq OWNED BY public.solid_queue_processes.id;


--
-- Name: solid_queue_ready_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_ready_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    queue_name character varying NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_ready_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_ready_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_ready_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_ready_executions_id_seq OWNED BY public.solid_queue_ready_executions.id;


--
-- Name: solid_queue_recurring_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_recurring_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    task_key character varying NOT NULL,
    run_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_recurring_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_recurring_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_recurring_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_recurring_executions_id_seq OWNED BY public.solid_queue_recurring_executions.id;


--
-- Name: solid_queue_recurring_tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_recurring_tasks (
    id bigint NOT NULL,
    key character varying NOT NULL,
    schedule character varying NOT NULL,
    command character varying(2048),
    class_name character varying,
    arguments text,
    queue_name character varying,
    priority integer DEFAULT 0,
    static boolean DEFAULT true NOT NULL,
    description text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_recurring_tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_recurring_tasks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_recurring_tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_recurring_tasks_id_seq OWNED BY public.solid_queue_recurring_tasks.id;


--
-- Name: solid_queue_scheduled_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_scheduled_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    queue_name character varying NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    scheduled_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_scheduled_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_scheduled_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_scheduled_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_scheduled_executions_id_seq OWNED BY public.solid_queue_scheduled_executions.id;


--
-- Name: solid_queue_semaphores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_semaphores (
    id bigint NOT NULL,
    key character varying NOT NULL,
    value integer DEFAULT 1 NOT NULL,
    expires_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_semaphores_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_semaphores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_semaphores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_semaphores_id_seq OWNED BY public.solid_queue_semaphores.id;


--
-- Name: ssl_certificates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ssl_certificates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    monitor_id uuid NOT NULL,
    domain character varying NOT NULL,
    issuer character varying,
    subject character varying,
    serial_number character varying,
    issued_at timestamp(6) without time zone,
    expires_at timestamp(6) without time zone,
    valid boolean DEFAULT true,
    validation_error character varying,
    fingerprint_sha256 character varying,
    public_key_algorithm character varying,
    public_key_bits integer,
    last_checked_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: status_page_monitors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.status_page_monitors (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    status_page_id uuid NOT NULL,
    monitor_id uuid NOT NULL,
    display_name character varying,
    group_name character varying,
    "position" integer DEFAULT 0,
    visible boolean DEFAULT true,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: status_pages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.status_pages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    project_id uuid NOT NULL,
    name character varying NOT NULL,
    slug character varying NOT NULL,
    custom_domain character varying,
    logo_url character varying,
    favicon_url character varying,
    primary_color character varying DEFAULT '#3B82F6'::character varying,
    company_name character varying,
    company_url character varying,
    description text,
    public boolean DEFAULT true,
    show_uptime boolean DEFAULT true,
    show_response_time boolean DEFAULT true,
    show_incidents boolean DEFAULT true,
    uptime_days_shown integer DEFAULT 90,
    allow_subscriptions boolean DEFAULT true,
    subscription_channels character varying[] DEFAULT '{email}'::character varying[],
    current_status character varying DEFAULT 'operational'::character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: status_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.status_subscriptions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    status_page_id uuid NOT NULL,
    email character varying,
    phone character varying,
    webhook_url character varying,
    channel character varying NOT NULL,
    confirmed boolean DEFAULT false,
    confirmation_token character varying,
    confirmed_at timestamp(6) without time zone,
    notify_incidents boolean DEFAULT true,
    notify_maintenance boolean DEFAULT true,
    severity_filter character varying[] DEFAULT '{minor,major,critical}'::character varying[],
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: uptime_monitors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.uptime_monitors (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    project_id uuid NOT NULL,
    name character varying NOT NULL,
    monitor_type character varying NOT NULL,
    enabled boolean DEFAULT true,
    paused boolean DEFAULT false,
    url character varying,
    host character varying,
    port integer,
    interval_seconds integer DEFAULT 60,
    timeout_seconds integer DEFAULT 30,
    regions character varying[] DEFAULT '{nyc}'::character varying[],
    http_method character varying DEFAULT 'GET'::character varying,
    headers jsonb DEFAULT '{}'::jsonb,
    body text,
    expected_status integer DEFAULT 200,
    expected_body character varying,
    follow_redirects boolean DEFAULT true,
    verify_ssl boolean DEFAULT true,
    auth_type character varying,
    auth_config jsonb DEFAULT '{}'::jsonb,
    confirmation_threshold integer DEFAULT 2,
    recovery_threshold integer DEFAULT 2,
    status character varying DEFAULT 'unknown'::character varying,
    last_check_at timestamp(6) without time zone,
    last_up_at timestamp(6) without time zone,
    last_down_at timestamp(6) without time zone,
    consecutive_failures integer DEFAULT 0,
    consecutive_successes integer DEFAULT 0,
    ssl_expiry_at timestamp(6) without time zone,
    ssl_expiry_warn_days integer DEFAULT 30,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_blocked_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_blocked_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_blocked_executions_id_seq'::regclass);


--
-- Name: solid_queue_claimed_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_claimed_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_claimed_executions_id_seq'::regclass);


--
-- Name: solid_queue_failed_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_failed_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_failed_executions_id_seq'::regclass);


--
-- Name: solid_queue_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_jobs ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_jobs_id_seq'::regclass);


--
-- Name: solid_queue_pauses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_pauses ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_pauses_id_seq'::regclass);


--
-- Name: solid_queue_processes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_processes ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_processes_id_seq'::regclass);


--
-- Name: solid_queue_ready_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_ready_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_ready_executions_id_seq'::regclass);


--
-- Name: solid_queue_recurring_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_recurring_executions_id_seq'::regclass);


--
-- Name: solid_queue_recurring_tasks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_tasks ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_recurring_tasks_id_seq'::regclass);


--
-- Name: solid_queue_scheduled_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_scheduled_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_scheduled_executions_id_seq'::regclass);


--
-- Name: solid_queue_semaphores id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_semaphores ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_semaphores_id_seq'::regclass);


--
-- Name: alert_rules alert_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alert_rules
    ADD CONSTRAINT alert_rules_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: incident_updates incident_updates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_updates
    ADD CONSTRAINT incident_updates_pkey PRIMARY KEY (id);


--
-- Name: incidents incidents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incidents
    ADD CONSTRAINT incidents_pkey PRIMARY KEY (id);


--
-- Name: maintenance_windows maintenance_windows_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_windows
    ADD CONSTRAINT maintenance_windows_pkey PRIMARY KEY (id);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: solid_queue_blocked_executions solid_queue_blocked_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_blocked_executions
    ADD CONSTRAINT solid_queue_blocked_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_claimed_executions solid_queue_claimed_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_claimed_executions
    ADD CONSTRAINT solid_queue_claimed_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_failed_executions solid_queue_failed_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_failed_executions
    ADD CONSTRAINT solid_queue_failed_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_jobs solid_queue_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_jobs
    ADD CONSTRAINT solid_queue_jobs_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_pauses solid_queue_pauses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_pauses
    ADD CONSTRAINT solid_queue_pauses_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_processes solid_queue_processes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_processes
    ADD CONSTRAINT solid_queue_processes_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_ready_executions solid_queue_ready_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_ready_executions
    ADD CONSTRAINT solid_queue_ready_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_recurring_executions solid_queue_recurring_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_executions
    ADD CONSTRAINT solid_queue_recurring_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_recurring_tasks solid_queue_recurring_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_tasks
    ADD CONSTRAINT solid_queue_recurring_tasks_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_scheduled_executions solid_queue_scheduled_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_scheduled_executions
    ADD CONSTRAINT solid_queue_scheduled_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_semaphores solid_queue_semaphores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_semaphores
    ADD CONSTRAINT solid_queue_semaphores_pkey PRIMARY KEY (id);


--
-- Name: ssl_certificates ssl_certificates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ssl_certificates
    ADD CONSTRAINT ssl_certificates_pkey PRIMARY KEY (id);


--
-- Name: status_page_monitors status_page_monitors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_page_monitors
    ADD CONSTRAINT status_page_monitors_pkey PRIMARY KEY (id);


--
-- Name: status_pages status_pages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_pages
    ADD CONSTRAINT status_pages_pkey PRIMARY KEY (id);


--
-- Name: status_subscriptions status_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_subscriptions
    ADD CONSTRAINT status_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: uptime_monitors uptime_monitors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.uptime_monitors
    ADD CONSTRAINT uptime_monitors_pkey PRIMARY KEY (id);


--
-- Name: check_results_checked_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX check_results_checked_at_idx ON public.check_results USING btree (checked_at DESC);


--
-- Name: idx_check_results_monitor_region_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_check_results_monitor_region_time ON public.check_results USING btree (monitor_id, region, checked_at DESC);


--
-- Name: idx_check_results_monitor_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_check_results_monitor_time ON public.check_results USING btree (monitor_id, checked_at DESC);


--
-- Name: idx_check_results_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_check_results_status ON public.check_results USING btree (status);


--
-- Name: index_alert_rules_on_condition_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alert_rules_on_condition_type ON public.alert_rules USING btree (condition_type);


--
-- Name: index_alert_rules_on_monitor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alert_rules_on_monitor_id ON public.alert_rules USING btree (monitor_id);


--
-- Name: index_alert_rules_on_monitor_id_and_enabled; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alert_rules_on_monitor_id_and_enabled ON public.alert_rules USING btree (monitor_id, enabled);


--
-- Name: index_incident_updates_on_incident_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incident_updates_on_incident_id ON public.incident_updates USING btree (incident_id);


--
-- Name: index_incident_updates_on_incident_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incident_updates_on_incident_id_and_created_at ON public.incident_updates USING btree (incident_id, created_at);


--
-- Name: index_incidents_on_monitor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incidents_on_monitor_id ON public.incidents USING btree (monitor_id);


--
-- Name: index_incidents_on_monitor_id_and_started_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incidents_on_monitor_id_and_started_at ON public.incidents USING btree (monitor_id, started_at);


--
-- Name: index_incidents_on_monitor_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incidents_on_monitor_id_and_status ON public.incidents USING btree (monitor_id, status);


--
-- Name: index_incidents_on_started_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incidents_on_started_at ON public.incidents USING btree (started_at);


--
-- Name: index_incidents_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incidents_on_status ON public.incidents USING btree (status);


--
-- Name: index_maintenance_windows_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_maintenance_windows_on_project_id ON public.maintenance_windows USING btree (project_id);


--
-- Name: index_maintenance_windows_on_project_id_and_starts_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_maintenance_windows_on_project_id_and_starts_at ON public.maintenance_windows USING btree (project_id, starts_at);


--
-- Name: index_maintenance_windows_on_starts_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_maintenance_windows_on_starts_at ON public.maintenance_windows USING btree (starts_at);


--
-- Name: index_maintenance_windows_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_maintenance_windows_on_status ON public.maintenance_windows USING btree (status);


--
-- Name: index_projects_on_api_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_projects_on_api_key ON public.projects USING btree (api_key);


--
-- Name: index_projects_on_ingest_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_projects_on_ingest_key ON public.projects USING btree (ingest_key);


--
-- Name: index_projects_on_platform_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_projects_on_platform_project_id ON public.projects USING btree (platform_project_id);


--
-- Name: index_solid_queue_blocked_executions_for_maintenance; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_blocked_executions_for_maintenance ON public.solid_queue_blocked_executions USING btree (expires_at, concurrency_key);


--
-- Name: index_solid_queue_blocked_executions_for_release; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_blocked_executions_for_release ON public.solid_queue_blocked_executions USING btree (concurrency_key, priority, job_id);


--
-- Name: index_solid_queue_blocked_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_blocked_executions_on_job_id ON public.solid_queue_blocked_executions USING btree (job_id);


--
-- Name: index_solid_queue_claimed_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_claimed_executions_on_job_id ON public.solid_queue_claimed_executions USING btree (job_id);


--
-- Name: index_solid_queue_claimed_executions_on_process_id_and_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_claimed_executions_on_process_id_and_job_id ON public.solid_queue_claimed_executions USING btree (process_id, job_id);


--
-- Name: index_solid_queue_dispatch_all; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_dispatch_all ON public.solid_queue_scheduled_executions USING btree (scheduled_at, priority, job_id);


--
-- Name: index_solid_queue_failed_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_failed_executions_on_job_id ON public.solid_queue_failed_executions USING btree (job_id);


--
-- Name: index_solid_queue_jobs_for_alerting; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_for_alerting ON public.solid_queue_jobs USING btree (scheduled_at, finished_at);


--
-- Name: index_solid_queue_jobs_for_filtering; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_for_filtering ON public.solid_queue_jobs USING btree (queue_name, finished_at);


--
-- Name: index_solid_queue_jobs_on_active_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_on_active_job_id ON public.solid_queue_jobs USING btree (active_job_id);


--
-- Name: index_solid_queue_jobs_on_class_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_on_class_name ON public.solid_queue_jobs USING btree (class_name);


--
-- Name: index_solid_queue_jobs_on_finished_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_on_finished_at ON public.solid_queue_jobs USING btree (finished_at);


--
-- Name: index_solid_queue_pauses_on_queue_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_pauses_on_queue_name ON public.solid_queue_pauses USING btree (queue_name);


--
-- Name: index_solid_queue_poll_all; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_poll_all ON public.solid_queue_ready_executions USING btree (priority, job_id);


--
-- Name: index_solid_queue_poll_by_queue; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_poll_by_queue ON public.solid_queue_ready_executions USING btree (queue_name, priority, job_id);


--
-- Name: index_solid_queue_processes_on_last_heartbeat_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_processes_on_last_heartbeat_at ON public.solid_queue_processes USING btree (last_heartbeat_at);


--
-- Name: index_solid_queue_processes_on_name_and_supervisor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_processes_on_name_and_supervisor_id ON public.solid_queue_processes USING btree (name, supervisor_id);


--
-- Name: index_solid_queue_processes_on_supervisor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_processes_on_supervisor_id ON public.solid_queue_processes USING btree (supervisor_id);


--
-- Name: index_solid_queue_ready_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_ready_executions_on_job_id ON public.solid_queue_ready_executions USING btree (job_id);


--
-- Name: index_solid_queue_recurring_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_recurring_executions_on_job_id ON public.solid_queue_recurring_executions USING btree (job_id);


--
-- Name: index_solid_queue_recurring_executions_on_task_key_and_run_at; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_recurring_executions_on_task_key_and_run_at ON public.solid_queue_recurring_executions USING btree (task_key, run_at);


--
-- Name: index_solid_queue_recurring_tasks_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_recurring_tasks_on_key ON public.solid_queue_recurring_tasks USING btree (key);


--
-- Name: index_solid_queue_recurring_tasks_on_static; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_recurring_tasks_on_static ON public.solid_queue_recurring_tasks USING btree (static);


--
-- Name: index_solid_queue_scheduled_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_scheduled_executions_on_job_id ON public.solid_queue_scheduled_executions USING btree (job_id);


--
-- Name: index_solid_queue_semaphores_on_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_semaphores_on_expires_at ON public.solid_queue_semaphores USING btree (expires_at);


--
-- Name: index_solid_queue_semaphores_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_semaphores_on_key ON public.solid_queue_semaphores USING btree (key);


--
-- Name: index_solid_queue_semaphores_on_key_and_value; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_semaphores_on_key_and_value ON public.solid_queue_semaphores USING btree (key, value);


--
-- Name: index_ssl_certificates_on_domain; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ssl_certificates_on_domain ON public.ssl_certificates USING btree (domain);


--
-- Name: index_ssl_certificates_on_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ssl_certificates_on_expires_at ON public.ssl_certificates USING btree (expires_at);


--
-- Name: index_ssl_certificates_on_monitor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ssl_certificates_on_monitor_id ON public.ssl_certificates USING btree (monitor_id);


--
-- Name: index_ssl_certificates_on_monitor_id_and_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ssl_certificates_on_monitor_id_and_expires_at ON public.ssl_certificates USING btree (monitor_id, expires_at);


--
-- Name: index_status_page_monitors_on_monitor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_status_page_monitors_on_monitor_id ON public.status_page_monitors USING btree (monitor_id);


--
-- Name: index_status_page_monitors_on_status_page_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_status_page_monitors_on_status_page_id ON public.status_page_monitors USING btree (status_page_id);


--
-- Name: index_status_page_monitors_on_status_page_id_and_group_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_status_page_monitors_on_status_page_id_and_group_name ON public.status_page_monitors USING btree (status_page_id, group_name);


--
-- Name: index_status_page_monitors_on_status_page_id_and_monitor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_status_page_monitors_on_status_page_id_and_monitor_id ON public.status_page_monitors USING btree (status_page_id, monitor_id);


--
-- Name: index_status_page_monitors_on_status_page_id_and_position; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_status_page_monitors_on_status_page_id_and_position ON public.status_page_monitors USING btree (status_page_id, "position");


--
-- Name: index_status_pages_on_custom_domain; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_status_pages_on_custom_domain ON public.status_pages USING btree (custom_domain);


--
-- Name: index_status_pages_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_status_pages_on_project_id ON public.status_pages USING btree (project_id);


--
-- Name: index_status_pages_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_status_pages_on_slug ON public.status_pages USING btree (slug);


--
-- Name: index_status_subscriptions_on_confirmation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_status_subscriptions_on_confirmation_token ON public.status_subscriptions USING btree (confirmation_token);


--
-- Name: index_status_subscriptions_on_status_page_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_status_subscriptions_on_status_page_id ON public.status_subscriptions USING btree (status_page_id);


--
-- Name: index_status_subscriptions_on_status_page_id_and_channel; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_status_subscriptions_on_status_page_id_and_channel ON public.status_subscriptions USING btree (status_page_id, channel);


--
-- Name: index_status_subscriptions_on_status_page_id_and_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_status_subscriptions_on_status_page_id_and_email ON public.status_subscriptions USING btree (status_page_id, email);


--
-- Name: index_uptime_monitors_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_uptime_monitors_on_project_id ON public.uptime_monitors USING btree (project_id);


--
-- Name: index_uptime_monitors_on_project_id_and_enabled; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_uptime_monitors_on_project_id_and_enabled ON public.uptime_monitors USING btree (project_id, enabled);


--
-- Name: index_uptime_monitors_on_project_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_uptime_monitors_on_project_id_and_status ON public.uptime_monitors USING btree (project_id, status);


--
-- Name: index_uptime_monitors_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_uptime_monitors_on_status ON public.uptime_monitors USING btree (status);


--
-- Name: check_results fk_check_results_monitor; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.check_results
    ADD CONSTRAINT fk_check_results_monitor FOREIGN KEY (monitor_id) REFERENCES public.uptime_monitors(id) ON DELETE CASCADE;


--
-- Name: status_pages fk_rails_1300b3079b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_pages
    ADD CONSTRAINT fk_rails_1300b3079b FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: incidents fk_rails_1f1a0d4a09; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incidents
    ADD CONSTRAINT fk_rails_1f1a0d4a09 FOREIGN KEY (monitor_id) REFERENCES public.uptime_monitors(id);


--
-- Name: status_subscriptions fk_rails_28011dddc2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_subscriptions
    ADD CONSTRAINT fk_rails_28011dddc2 FOREIGN KEY (status_page_id) REFERENCES public.status_pages(id);


--
-- Name: solid_queue_recurring_executions fk_rails_318a5533ed; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_executions
    ADD CONSTRAINT fk_rails_318a5533ed FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: solid_queue_failed_executions fk_rails_39bbc7a631; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_failed_executions
    ADD CONSTRAINT fk_rails_39bbc7a631 FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: incident_updates fk_rails_40ece1a4e9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_updates
    ADD CONSTRAINT fk_rails_40ece1a4e9 FOREIGN KEY (incident_id) REFERENCES public.incidents(id);


--
-- Name: status_page_monitors fk_rails_4246077bf7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_page_monitors
    ADD CONSTRAINT fk_rails_4246077bf7 FOREIGN KEY (status_page_id) REFERENCES public.status_pages(id);


--
-- Name: solid_queue_blocked_executions fk_rails_4cd34e2228; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_blocked_executions
    ADD CONSTRAINT fk_rails_4cd34e2228 FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: uptime_monitors fk_rails_4f2a433932; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.uptime_monitors
    ADD CONSTRAINT fk_rails_4f2a433932 FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: solid_queue_ready_executions fk_rails_81fcbd66af; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_ready_executions
    ADD CONSTRAINT fk_rails_81fcbd66af FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: ssl_certificates fk_rails_8c84367aed; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ssl_certificates
    ADD CONSTRAINT fk_rails_8c84367aed FOREIGN KEY (monitor_id) REFERENCES public.uptime_monitors(id);


--
-- Name: solid_queue_claimed_executions fk_rails_9cfe4d4944; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_claimed_executions
    ADD CONSTRAINT fk_rails_9cfe4d4944 FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: maintenance_windows fk_rails_b0a95d7781; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_windows
    ADD CONSTRAINT fk_rails_b0a95d7781 FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: solid_queue_scheduled_executions fk_rails_c4316f352d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_scheduled_executions
    ADD CONSTRAINT fk_rails_c4316f352d FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: status_page_monitors fk_rails_db5fafd935; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_page_monitors
    ADD CONSTRAINT fk_rails_db5fafd935 FOREIGN KEY (monitor_id) REFERENCES public.uptime_monitors(id);


--
-- Name: alert_rules fk_rails_f6e988c0ad; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alert_rules
    ADD CONSTRAINT fk_rails_f6e988c0ad FOREIGN KEY (monitor_id) REFERENCES public.uptime_monitors(id);


--
-- PostgreSQL database dump complete
--

\unrestrict agZBisq3xrXOzX8jgidWCUn6ZlxnTKQnEMsR1XZ0YmZamArB4N53YRmEiZJrgLF

