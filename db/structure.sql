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
-- Name: timescaledb; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS timescaledb WITH SCHEMA public;


--
-- Name: EXTENSION timescaledb; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION timescaledb IS 'Enables scalable inserts and complex queries for time-series data (Community Edition)';


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
-- Name: monitors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.monitors (
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
-- Name: projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.projects (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    platform_project_id uuid NOT NULL,
    api_key character varying NOT NULL,
    ingest_key character varying,
    name character varying,
    settings jsonb DEFAULT '{}'::jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


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
-- Name: monitors monitors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.monitors
    ADD CONSTRAINT monitors_pkey PRIMARY KEY (id);


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
-- Name: index_monitors_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_monitors_on_project_id ON public.monitors USING btree (project_id);


--
-- Name: index_monitors_on_project_id_and_enabled; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_monitors_on_project_id_and_enabled ON public.monitors USING btree (project_id, enabled);


--
-- Name: index_monitors_on_project_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_monitors_on_project_id_and_status ON public.monitors USING btree (project_id, status);


--
-- Name: index_monitors_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_monitors_on_status ON public.monitors USING btree (status);


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
-- Name: check_results fk_check_results_monitor; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.check_results
    ADD CONSTRAINT fk_check_results_monitor FOREIGN KEY (monitor_id) REFERENCES public.monitors(id) ON DELETE CASCADE;


--
-- Name: status_pages fk_rails_1300b3079b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_pages
    ADD CONSTRAINT fk_rails_1300b3079b FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: incidents fk_rails_1f1a0d4a09; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incidents
    ADD CONSTRAINT fk_rails_1f1a0d4a09 FOREIGN KEY (monitor_id) REFERENCES public.monitors(id);


--
-- Name: status_subscriptions fk_rails_28011dddc2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_subscriptions
    ADD CONSTRAINT fk_rails_28011dddc2 FOREIGN KEY (status_page_id) REFERENCES public.status_pages(id);


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
-- Name: monitors fk_rails_4f2a433932; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.monitors
    ADD CONSTRAINT fk_rails_4f2a433932 FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: ssl_certificates fk_rails_8c84367aed; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ssl_certificates
    ADD CONSTRAINT fk_rails_8c84367aed FOREIGN KEY (monitor_id) REFERENCES public.monitors(id);


--
-- Name: maintenance_windows fk_rails_b0a95d7781; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_windows
    ADD CONSTRAINT fk_rails_b0a95d7781 FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: status_page_monitors fk_rails_db5fafd935; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_page_monitors
    ADD CONSTRAINT fk_rails_db5fafd935 FOREIGN KEY (monitor_id) REFERENCES public.monitors(id);


--
-- Name: alert_rules fk_rails_f6e988c0ad; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alert_rules
    ADD CONSTRAINT fk_rails_f6e988c0ad FOREIGN KEY (monitor_id) REFERENCES public.monitors(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

---
--- Drop ts_insert_blocker previously created by pg_dump to avoid pg errors, create_hypertable will re-create it again.
---

DROP TRIGGER IF EXISTS ts_insert_blocker ON public.check_results;
