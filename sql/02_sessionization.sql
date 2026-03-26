/* =========================================================
   FILE: 02_sessionization.sql
   PURPOSE:
   Convert event-level data into session-level data
   DATABASE: SQL Server (MSSQL)
========================================================= */

-- =========================================================
-- STEP 0: USE DATABASE
-- =========================================================
USE linkedin_trust_churn;
GO

-- =========================================================
-- STEP 1: DROP EXISTING TABLES (SAFE RESET)
-- =========================================================
DROP TABLE IF EXISTS clean.sessionized_events;
DROP TABLE IF EXISTS clean.sessions;
GO

-- =========================================================
-- STEP 2: CREATE SESSIONIZED EVENTS
-- LOGIC:
-- New session if:
--   - First event OR
--   - Time gap > 30 minutes
-- =========================================================

WITH ordered_events AS (
    SELECT
        user_id,
        event_time,
        clean_event_type,

        LAG(event_time) OVER (
            PARTITION BY user_id 
            ORDER BY event_time
        ) AS prev_event_time

    FROM clean.user_events
    WHERE event_time IS NOT NULL
),

time_diff AS (
    SELECT *,
        DATEDIFF(
            MINUTE,
            prev_event_time,
            event_time
        ) AS minutes_since_last_event
    FROM ordered_events
),

session_flag AS (
    SELECT *,
        CASE 
            WHEN prev_event_time IS NULL THEN 1
            WHEN minutes_since_last_event > 30 THEN 1
            ELSE 0
        END AS new_session_flag
    FROM time_diff
),

session_id_calc AS (
    SELECT *,
        SUM(new_session_flag) OVER (
            PARTITION BY user_id 
            ORDER BY event_time
            ROWS UNBOUNDED PRECEDING
        ) AS session_id
    FROM session_flag
)

SELECT
    user_id,
    event_time,
    clean_event_type,
    prev_event_time,
    minutes_since_last_event,
    new_session_flag,
    session_id
INTO clean.sessionized_events
FROM session_id_calc;
GO

-- =========================================================
-- STEP 3: CREATE SESSION-LEVEL TABLE
-- =========================================================

SELECT
    user_id,
    session_id,

    MIN(event_time) AS session_start,
    MAX(event_time) AS session_end,

    DATEDIFF(
        MINUTE,
        MIN(event_time),
        MAX(event_time)
    ) AS session_duration_minutes,

    COUNT(*) AS events_in_session

INTO clean.sessions
FROM clean.sessionized_events
GROUP BY user_id, session_id;
GO

-- =========================================================
-- STEP 4: VALIDATION
-- =========================================================

-- Check data exists
SELECT COUNT(*) AS total_events FROM clean.sessionized_events;
SELECT COUNT(*) AS total_sessions FROM clean.sessions;

-- Preview
SELECT TOP 10 * FROM clean.sessionized_events;
SELECT TOP 10 * FROM clean.sessions;
GO