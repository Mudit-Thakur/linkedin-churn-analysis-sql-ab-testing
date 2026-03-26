/* =========================================================
   FILE: 03_feature_engineering.sql
   PURPOSE:
   Build analysis-ready feature layer for churn, trust,
   engagement, friction, and A/B testing
   DATABASE: SQL Server (MSSQL)
========================================================= */

-- =========================================================
-- STEP 0: USE DATABASE
-- =========================================================
USE linkedin_trust_churn;
GO

-- =========================================================
-- STEP 1: CLEAN RESET
-- =========================================================
DROP TABLE IF EXISTS clean.user_features;
DROP TABLE IF EXISTS clean.last_activity;
DROP TABLE IF EXISTS clean.churn;
DROP TABLE IF EXISTS clean.engagement;
DROP TABLE IF EXISTS clean.trust;
DROP TABLE IF EXISTS clean.friction;
DROP TABLE IF EXISTS clean.experiment;
GO

-- =========================================================
-- STEP 2: USER LAST ACTIVITY
-- =========================================================
SELECT
    user_id,
    MAX(event_time) AS last_event_time
INTO clean.last_activity
FROM clean.user_events
GROUP BY user_id;
GO

-- =========================================================
-- STEP 3: CHURN FLAG (FIXED WITH DATA-RELATIVE DATE)
-- =========================================================
SELECT
    u.user_id,
    u.signup_time,
    la.last_event_time,

CASE 
    WHEN la.last_event_time IS NULL THEN 1

    -- New users (first 7 days)
    WHEN DATEDIFF(DAY, u.signup_time, '2025-03-01') <= 7
         AND DATEDIFF(DAY, la.last_event_time, '2025-03-01') > 3 THEN 1

    -- Regular users
    WHEN DATEDIFF(DAY, la.last_event_time, '2025-03-01') > 14 THEN 1

    ELSE 0
END AS churn_flag

INTO clean.churn
FROM clean.final_users u
LEFT JOIN clean.last_activity la
    ON u.user_id = la.user_id;
GO

-- =========================================================
-- STEP 4: ENGAGEMENT FEATURES
-- =========================================================
SELECT
    user_id,
    COUNT(*) AS total_sessions,
    AVG(CAST(session_duration_minutes AS FLOAT)) AS avg_session_duration,
    SUM(events_in_session) AS total_events

INTO clean.engagement
FROM clean.sessions
GROUP BY user_id;
GO

-- =========================================================
-- STEP 5: TRUST SCORE
-- =========================================================
SELECT
    r.user_id,

    (
        (1 - ISNULL(r.bot_score, 0)) * 0.5 +
        (1.0 / (1 + ISNULL(c.spam_messages_received, 0))) * 0.3 +
        (1.0 / (1 + ISNULL(c.irrelevant_jobs_seen, 0))) * 0.2
    ) AS trust_score

INTO clean.trust
FROM raw.risk_signals r   -- change to dbo if needed
LEFT JOIN clean.content_quality c
    ON r.user_id = c.user_id;
GO

-- =========================================================
-- STEP 6: FRICTION (VERIFICATION)
-- =========================================================
SELECT
    r.user_id,

    COUNT(v.attempt_number) AS verification_attempts,
    AVG(CAST(v.latency_seconds AS FLOAT)) AS avg_verification_latency,
    MAX(CAST(v.success_flag AS INT)) AS verification_success

INTO clean.friction
FROM raw.restrictions r
LEFT JOIN raw.verification v
    ON r.user_id = v.user_id
GROUP BY r.user_id;
GO

-- =========================================================
-- STEP 7: EXPERIMENT GROUP
-- =========================================================
SELECT
    user_id,
    experiment_group
INTO clean.experiment
FROM raw.experiments;
GO

-- =========================================================
-- STEP 8: FINAL FEATURE TABLE
-- =========================================================
SELECT
    u.user_id,

    -- USER INFO
    u.signup_time,
    u.profile_completion_pct,
    u.premium_flag,

    -- ENGAGEMENT
    ISNULL(e.total_sessions, 0) AS total_sessions,
    ISNULL(e.avg_session_duration, 0) AS avg_session_duration,
    ISNULL(e.total_events, 0) AS total_events,

    -- TRUST
    ISNULL(t.trust_score, 0) AS trust_score,

    -- CHURN
    ISNULL(c.churn_flag, 1) AS churn_flag,

    -- FRICTION
    ISNULL(f.verification_attempts, 0) AS verification_attempts,
    ISNULL(f.avg_verification_latency, 0) AS avg_verification_latency,

    -- EXPERIMENT
    ex.experiment_group

INTO clean.user_features
FROM clean.final_users u
LEFT JOIN clean.engagement e ON u.user_id = e.user_id
LEFT JOIN clean.trust t ON u.user_id = t.user_id
LEFT JOIN clean.churn c ON u.user_id = c.user_id
LEFT JOIN clean.friction f ON u.user_id = f.user_id
LEFT JOIN clean.experiment ex ON u.user_id = ex.user_id;
GO

-- =========================================================
-- STEP 9: VALIDATION
-- =========================================================
SELECT 
    COUNT(*) AS total_users,
    SUM(churn_flag) AS churned_users
FROM clean.user_features;

SELECT TOP 10 * FROM clean.user_features;
GO