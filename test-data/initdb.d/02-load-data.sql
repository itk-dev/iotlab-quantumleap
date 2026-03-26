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

--
-- Name: etrefrigerator-sensor_time_index_idx; Type: INDEX; Schema: public; Owner: quantumleap
--

CREATE INDEX "etrefrigerator-sensor_time_index_idx" ON public."etrefrigerator-sensor" USING btree (time_index DESC);


--
-- Name: ix_etrefrigerator-sensor_eid_and_tx; Type: INDEX; Schema: public; Owner: quantumleap
--

CREATE INDEX "ix_etrefrigerator-sensor_eid_and_tx" ON public."etrefrigerator-sensor" USING btree (entity_id, time_index DESC);


-- docker run --rm --volume $PWD:/app --workdir /app python:3 python generate-etrefrigerator-sensor.py

COPY public."etrefrigerator-sensor" (entity_id, entity_type, time_index, fiware_servicepath, __original_ngsi_entity__, instanceid, appliance, battery, department, floor, humidity, name, room, temperature)
FROM '/docker-entrypoint-initdb.d/etrefrigerator-sensor.csv' DELIMITER ',' CSV;
