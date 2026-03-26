/* =========================================================
   FILE: 01_data_cleaning.sql
   PURPOSE:
   Clean messy raw data and create analysis-ready tables
   DATABASE: SQL Server (MSSQL)
========================================================= */

-- =========================================================
-- STEP 0: USE DATABASE
-- =========================================================
USE linkedin_trust_churn;
GO

-- =========================================================
-- STEP 1: CREATE CLEAN SCHEMA (IF NOT EXISTS)
-- =========================================================
IF NOT EXISTS (
    SELECT 1 FROM sys.schemas WHERE name = 'clean'
)
BEGIN
    EXEC('CREATE SCHEMA clean');
END
GO

-- =========================================================
-- STEP 2: CLEAN USERS (DEDUP + STRING FIX)
-- =========================================================
DROP TABLE IF EXISTS clean.users;
GO

WITH dedup_users AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY user_id 
               ORDER BY signup_time
           ) AS rn
    FROM raw.users   -- ⚠️ change to dbo.users if needed
),

clean_users AS (
    SELECT
        user_id,
        signup_time,

        ISNULL(profile_completion_pct, 0) AS profile_completion_pct,
        premium_flag,

        LOWER(
            LTRIM(RTRIM(
                REPLACE(REPLACE(username, '*',''), '@','')
            ))
        ) AS clean_username,

        LOWER(LTRIM(RTRIM(email))) AS clean_email

    FROM dedup_users
    WHERE rn = 1
)

SELECT *
INTO clean.users
FROM clean_users;
GO

-- =========================================================
-- STEP 3: EMAIL DOMAIN EXTRACTION
-- =========================================================
DROP TABLE IF EXISTS clean.user_email_features;
GO

SELECT
    user_id,
    clean_email,

    CASE 
        WHEN CHARINDEX('@', clean_email) > 0 THEN
            RIGHT(clean_email, LEN(clean_email) - CHARINDEX('@', clean_email))
        ELSE NULL
    END AS email_domain

INTO clean.user_email_features
FROM clean.users;
GO

-- =========================================================
-- STEP 4: CLEAN USER EVENTS
-- =========================================================
DROP TABLE IF EXISTS clean.user_events;
GO

SELECT
    event_id,
    user_id,
    event_time,

    LOWER(LTRIM(RTRIM(event_type))) AS clean_event_type,
    LOWER(LTRIM(RTRIM(device_type))) AS device_type,
    LTRIM(RTRIM(geo_location)) AS geo_location

INTO clean.user_events
FROM raw.user_events;   -- ⚠️ change to dbo.user_events if needed
GO

-- =========================================================
-- STEP 5: CLEAN CONTENT QUALITY (REMOVE SYMBOLS)
-- =========================================================
DROP TABLE IF EXISTS clean.content_quality;
GO

SELECT
    user_id,

    TRY_CAST(
        REPLACE(REPLACE(REPLACE(spam_messages_received, '$',''), '@',''), '*','')
        AS INT
    ) AS spam_messages_received,

    TRY_CAST(
        REPLACE(REPLACE(REPLACE(irrelevant_jobs_seen, '$',''), '@',''), '*','')
        AS INT
    ) AS irrelevant_jobs_seen,

    low_match_recommendations

INTO clean.content_quality
FROM raw.content_quality;  -- ⚠️ change if needed
GO

-- =========================================================
-- STEP 6: EMAIL QUALITY FLAG
-- =========================================================
DROP TABLE IF EXISTS clean.email_quality;
GO

SELECT
    user_id,
    clean_email,

    CASE 
        WHEN clean_email LIKE '%@@%' THEN 'invalid'
        WHEN clean_email NOT LIKE '%@%.%' THEN 'invalid'
        ELSE 'valid'
    END AS email_quality

INTO clean.email_quality
FROM clean.users;
GO

-- =========================================================
-- STEP 7: FINAL USER TABLE
-- =========================================================
DROP TABLE IF EXISTS clean.final_users;
GO

SELECT
    u.user_id,
    u.signup_time,
    u.profile_completion_pct,
    u.premium_flag,
    u.clean_username,
    u.clean_email,
    e.email_domain

INTO clean.final_users
FROM clean.users u
LEFT JOIN clean.user_email_features e
    ON u.user_id = e.user_id;
GO

-- =========================================================
-- STEP 8: VALIDATION
-- =========================================================
SELECT COUNT(*) AS users_count FROM clean.users;
SELECT COUNT(*) AS events_count FROM clean.user_events;
SELECT COUNT(*) AS content_count FROM clean.content_quality;
SELECT COUNT(*) AS final_users_count FROM clean.final_users;
GO