CREATE SCHEMA IF NOT EXISTS events;

CREATE TABLE IF NOT EXISTS events."raw" (
    event_id   VARCHAR(64)    NOT NULL,
    user_id    VARCHAR(64)    NOT NULL,
    event_type VARCHAR(32)    NOT NULL,
    value      DECIMAL(12,2)  DEFAULT 0,
    ts         TIMESTAMP      NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY (event_id)
) DISTKEY(user_id) SORTKEY(ts);

CREATE OR REPLACE VIEW events.vw_daily AS
SELECT DATE_TRUNC('day', ts)   AS date_day,
       event_type,
       COUNT(*)                AS event_count,
       COUNT(DISTINCT user_id) AS unique_users,
       SUM(value)              AS total_revenue
FROM events."raw" 
GROUP BY 1, 2;

CREATE OR REPLACE VIEW events.vw_funnel AS
SELECT DATE_TRUNC('hour', ts)  AS hour_bucket,
       SUM(CASE WHEN event_type='view'     THEN 1 ELSE 0 END) AS views,
       SUM(CASE WHEN event_type='cart'     THEN 1 ELSE 0 END) AS carts,
       SUM(CASE WHEN event_type='purchase' THEN 1 ELSE 0 END) AS purchases,
       SUM(CASE WHEN event_type='purchase' THEN value ELSE 0 END) AS revenue
FROM events."raw" 
GROUP BY 1;

GRANT USAGE ON SCHEMA events TO "IAMR:p1-lambda-exec-dev";

GRANT INSERT, SELECT ON TABLE events."raw" TO "IAMR:p1-lambda-exec-dev";