-- # @todo Reqrite to use environment variables (cf. https://stackoverflow.com/a/70976611)
CREATE ROLE quantumleap LOGIN PASSWORD '*';

CREATE DATABASE quantumleap OWNER quantumleap ENCODING 'UTF8';

\connect quantumleap

CREATE EXTENSION IF NOT EXISTS postgis CASCADE;
CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;
