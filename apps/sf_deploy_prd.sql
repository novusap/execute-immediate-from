--------------------------------------------------------------------------------------------
--  SCRIPT:    Code from this script updates objects in Snowflake production account.
--             
--             
--
--   YY-MM-DD WHO          CHANGE DESCRIPTION
--   -------- ------------ -----------------------------------------------------------------

--------------------------------------------------------------------------------------------

-- SCHEMAS     

-- *********************************************************
-- Approach 1 - Include SET variables WITH the build code:
-- EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/master/apps/adm_control/snowflake_objects/databases/schemas/tags_schema/tags_build.sql;
-- Results in error:
-- "Unsupported feature 'session variables not supported during object dependencies backfill"
-- *********************************************************


-- *********************************************************
-- Approach 2 - Separate SET variables FROM the build code:
-- Results in error:
-- Uncaught exception of  │
-- │ type 'STATEMENT_ERROR' in file                                               │
-- │ @SNOWFLAKE_GIT_REPO/branches/master/apps/sf_deploy_prd.sql on line 21 at     │
-- │ position 0:                                                                  │
-- │ Cannot perform operation. This session does not have a current database.     │
-- │ Call 'USE DATABASE', or use a qualified name.   
-- *********************************************************
EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/master/apps/adm_control/snowflake_objects/databases/schemas/tags_schema/tags.sql;

-- Add ALERTS schema to ADM_CONTROL_DB database:
EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/master/apps/adm_control/snowflake_objects/databases/schemas/alerts_schema/alerts.sql;



-- The rest of my orchestration would look like this:

-- -- TABLES 
-- EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO (TABLE 1)
-- EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO (TABLE 2)

-- -- VIEWS
-- EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO (VIEW 1)
-- EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO (VIEW 2)

-- -- PROCEDURES
-- EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO (PROC 1)
-- EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO (PROC 2)
