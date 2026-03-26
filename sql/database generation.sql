CREATE DATABASE linkedin_trust_churn;
GO

USE linkedin_trust_churn;
GO

CREATE SCHEMA raw;
GO

CREATE SCHEMA clean;
GO

SELECT count(*) FROM raw.users;
SELECT COUNT(*) FROM raw.user_events;
