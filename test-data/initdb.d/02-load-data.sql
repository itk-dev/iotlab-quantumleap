-- pg_dump --schema-only --schema="public" --table=etrefrigerator-sensor quantumleap

\connect quantumleap

--
-- Name: etrefrigerator-sensor; Type: TABLE; Schema: public; Owner: quantumleap
--

CREATE TABLE public."etrefrigerator-sensor" (
    entity_id text,
    entity_type text,
    time_index timestamp with time zone NOT NULL,
    fiware_servicepath text,
    __original_ngsi_entity__ jsonb,
    instanceid text,
    appliance text,
    battery bigint,
    department text,
    floor text,
    humidity double precision,
    name text,
    room text,
    temperature double precision
);


ALTER TABLE public."etrefrigerator-sensor" OWNER TO quantumleap;



-- https://oneuptime.com/blog/post/2026-01-25-load-millions-rows-copy-postgresql/view

-- https://oneuptime.com/blog/post/2026-01-25-load-millions-rows-copy-postgresql/view#4-adjust-wal-settings-for-loading
-- Increase checkpoint distance (apply to session or system)
-- SET checkpoint_timeout = '30min';
-- SET max_wal_size = '10GB';

-- Reduce WAL level for this session
SET synchronous_commit = off;

-- https://oneuptime.com/blog/post/2026-01-25-load-millions-rows-copy-postgresql/view#1-drop-indexes-before-loading
-- Load data before adding indexes!

COPY "etrefrigerator-sensor" (
 entity_id,
 entity_type,
 appliance,
 name,
 room,
 department,
 floor,
 time_index,
 battery,
 humidity,
 temperature
)
FROM PROGRAM 'python3 /test-data/generate-data.py \
 "refrigerator-sensor" \
 "refrigerator-sensor:00000000-Milesight" \
 "Fryser" \
 "" \
 "" \
 "" \
 "" \
 "{time.isoformat()}" \
 "{random.randint(0, 100)}" \
 "{round(random.uniform(0.00, 100.00), 2)}" \
 "{round(random.uniform(0.00, 100.00), 2)}" \
 --start-time "2025-01-01" --end-time "2027-01-01" --interval 600 --interval-wobble 30
' WITH (FORMAT csv, LOG_VERBOSITY verbose);

COPY "etrefrigerator-sensor" (
 entity_id,
 entity_type,
 appliance,
 name,
 room,
 department,
 floor,
 time_index,
 battery,
 humidity,
 temperature
)
FROM PROGRAM 'python3 /test-data/generate-data.py \
 "refrigerator-sensor" \
 "refrigerator-sensor:11111111-Milesight" \
 "Fryser" \
 "" \
 "" \
 "" \
 "" \
 "{time.isoformat()}" \
 "{random.randint(0, 100)}" \
 "{round(random.uniform(0.00, 100.00), 2)}" \
 "{round(random.uniform(0.00, 100.00), 2)}" \
 --start-time "2025-01-01" --end-time "2027-01-01" --interval 600 --interval-wobble 30
' WITH (FORMAT csv, LOG_VERBOSITY verbose);

COPY "etrefrigerator-sensor" (
 entity_id,
 entity_type,
 appliance,
 name,
 room,
 department,
 floor,
 time_index,
 battery,
 humidity,
 temperature
)
FROM PROGRAM 'python3 /test-data/generate-data.py \
 "refrigerator-sensor" \
 "refrigerator-sensor:22222222-Milesight" \
 "Fryser" \
 "" \
 "" \
 "" \
 "" \
 "{time.isoformat()}" \
 "{random.randint(0, 100)}" \
 "{round(random.uniform(0.00, 100.00), 2)}" \
 "{round(random.uniform(0.00, 100.00), 2)}" \
 --start-time "2025-01-01" --end-time "2027-01-01" --interval 600 --interval-wobble 30
' WITH (FORMAT csv, LOG_VERBOSITY verbose);


-- https://oneuptime.com/blog/post/2026-01-25-load-millions-rows-copy-postgresql/view#4-adjust-wal-settings-for-loading
-- Reset to defaults
RESET synchronous_commit;

--
-- Name: etrefrigerator-sensor_time_index_idx; Type: INDEX; Schema: public; Owner: quantumleap
--

CREATE INDEX "etrefrigerator-sensor_time_index_idx" ON public."etrefrigerator-sensor" USING btree (time_index DESC);


--
-- Name: ix_etrefrigerator-sensor_eid_and_tx; Type: INDEX; Schema: public; Owner: quantumleap
--

CREATE INDEX "ix_etrefrigerator-sensor_eid_and_tx" ON public."etrefrigerator-sensor" USING btree (entity_id, time_index DESC);


SELECT COUNT(*), MIN(time_index), MAX(time_index) FROM "etrefrigerator-sensor";
