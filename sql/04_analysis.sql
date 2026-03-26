-- Active: 1772513695978@@127.0.0.1@1433
/* =========================================================
   FILE: 04_analysis.sql
   PURPOSE:
   Answer business questions:
   - Does restriction increase churn?
   - Does friction impact retention?
   - Which A/B experiment performs better?
   - How trust impacts engagement
   DATABASE: SQL Server (MSSQL)
========================================================= */

-- =========================================================
-- STEP 0: USE DATABASE
-- =========================================================
USE linkedin_trust_churn;
GO

-- =========================================================
-- STEP 1: CHURN vs RESTRICTION
-- =========================================================
SELECT
    CASE 
        WHEN r.user_id IS NOT NULL THEN 'restricted'
        ELSE 'not_restricted'
    END AS user_type,

    COUNT(*) AS total_users,

    AVG(CAST(u.churn_flag AS FLOAT)) AS churn_rate

FROM clean.user_features u
LEFT JOIN raw.restrictions r  
    ON u.user_id = r.user_id

GROUP BY 
    CASE 
        WHEN r.user_id IS NOT NULL THEN 'restricted'
        ELSE 'not_restricted'
    END;
GO

-- =========================================================
-- STEP 2: FRICTION IMPACT ON CHURN
-- =========================================================
SELECT
    verification_attempts,

    COUNT(*) AS users,

    AVG(CAST(churn_flag AS FLOAT)) AS churn_rate

FROM clean.user_features
GROUP BY verification_attempts
ORDER BY verification_attempts;
GO

-- =========================================================
-- STEP 3: A/B TEST PERFORMANCE
-- =========================================================
SELECT
    experiment_group,

    COUNT(*) AS users,

    AVG(CAST(churn_flag AS FLOAT)) AS churn_rate,
    AVG(total_sessions) AS avg_sessions,
    AVG(avg_session_duration) AS avg_session_duration

FROM clean.user_features
GROUP BY experiment_group;
GO

-- =========================================================
-- STEP 4: TRUST vs ENGAGEMENT
-- =========================================================
SELECT
    CAST(ROUND(trust_score, 1) AS FLOAT) AS trust_bucket,

    COUNT(*) AS users,

    AVG(total_sessions) AS avg_sessions,
    AVG(avg_session_duration) AS avg_session_duration,
    AVG(CAST(churn_flag AS FLOAT)) AS churn_rate

FROM clean.user_features
GROUP BY CAST(ROUND(trust_score, 1) AS FLOAT)
ORDER BY trust_bucket;
GO

-- =========================================================
-- STEP 5: RESTRICTION + FRICTION COMBINED IMPACT
-- =========================================================
SELECT
    CASE 
        WHEN r.user_id IS NOT NULL THEN 'restricted'
        ELSE 'not_restricted'
    END AS user_type,

    CASE 
        WHEN verification_attempts >= 2 THEN 'high_friction'
        ELSE 'low_friction'
    END AS friction_level,

    COUNT(*) AS users,

    AVG(CAST(u.churn_flag AS FLOAT)) AS churn_rate

FROM clean.user_features u
LEFT JOIN raw.restrictions r
    ON u.user_id = r.user_id

GROUP BY
    CASE 
        WHEN r.user_id IS NOT NULL THEN 'restricted'
        ELSE 'not_restricted'
    END,
    CASE 
        WHEN verification_attempts >= 2 THEN 'high_friction'
        ELSE 'low_friction'
    END;
GO

-- =========================================================
-- STEP 6: TOP CHURN DRIVER SEGMENTS
-- =========================================================
SELECT TOP 10
    experiment_group,
    verification_attempts,
    CAST(ROUND(trust_score,1) AS FLOAT) AS trust_bucket,

    COUNT(*) AS users,

    AVG(CAST(churn_flag AS FLOAT)) AS churn_rate

FROM clean.user_features
GROUP BY 
    experiment_group,
    verification_attempts,
    CAST(ROUND(trust_score,1) AS FLOAT)

ORDER BY churn_rate DESC;
GO

-- =========================================================
-- STEP 7: EXPORT DATA FOR EXCEL (OPTIONAL)
-- =========================================================
-- Use this for dashboarding

SELECT *
FROM clean.user_features;
GO

use linkedin_trust_churn;
go
SELECT COUNT(*) FROM clean.user_features;
SELECT TOP 10 * FROM clean.user_features;

SELECT 
    COUNT(*) AS users,
    SUM(churn_flag) AS churned_users
FROM clean.user_features;

SELECT 
    MIN(event_time) AS min_date,
    MAX(event_time) AS max_date
FROM clean.user_events;

SELECT 
    COUNT(*) AS users,
    SUM(churn_flag) AS churned
FROM clean.user_features;

SELECT * FROM clean.user_features;


