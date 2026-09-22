CREATE SCHEMA IF NOT EXISTS raw;

DROP TABLE IF EXISTS raw.flights;
CREATE TABLE raw.flights (
    year                 SMALLINT,
    month                SMALLINT,
    day_of_month         SMALLINT,
    day_of_week          SMALLINT,
    flight_date          DATE,
    airline              VARCHAR(3),
    tail_number          VARCHAR(10),
    flight_number        INTEGER,
    origin               VARCHAR(3),
    origin_city          TEXT,
    origin_state         VARCHAR(2),
    dest                 VARCHAR(3),
    dest_city            TEXT,
    dest_state           VARCHAR(2),
    distance             REAL,
    crs_dep_time         REAL,
    dep_time             REAL,
    dep_delay            REAL,
    dep_delay_minutes    REAL,
    dep_del15            REAL,
    taxi_out             REAL,
    wheels_off           REAL,
    wheels_on            REAL,
    taxi_in              REAL,
    crs_arr_time         REAL,
    arr_time             REAL,
    arr_delay            REAL,
    arr_delay_minutes    REAL,
    arr_del15            REAL,
    cancelled            REAL,
    cancellation_code    VARCHAR(1),
    diverted             REAL,
    crs_elapsed_time     REAL,
    actual_elapsed_time  REAL,
    air_time             REAL,
    carrier_delay        REAL,
    weather_delay        REAL,
    nas_delay            REAL,
    security_delay       REAL,
    late_aircraft_delay  REAL
);

CREATE TABLE IF NOT EXISTS raw.load_log (
    file_name  TEXT PRIMARY KEY,
    row_count  INTEGER,
    loaded_at  TIMESTAMP DEFAULT now()
);