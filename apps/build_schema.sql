-----------------------------------------------------------------------------------
 SCRIPT:    Environment Creation Script

  -- Desc:  generic script showing how to manually maintain privileges to access roles
  --        Below script sets context for naming convention
  --        Creates platform administration roles (platform admin, local admin)
  --        Creates database
  --        creates schema
  --        creates roles (access roles)
  --        creates role heirarchy
  --        grants access to roles (read, read/write, full/create)
  --        creates warehouses
  --        creates warehouse access roles
  --        grants roles for warehouse to access roles
  --       
  --       
  -- 
  -- Note:  The below scripts are account-level roles but COULD be modified to include 
  --        database roles where appropriate
  --        
  --        Also, these are all NON-DESTRUCTIVE, idempotent statements in this script. 
  --        This means it can be run multiple times without destroying existing 
  --        resources.
  --       
  --         
  YY-MM-DD WHO          CHANGE DESCRIPTION
  -------- ------------ -----------------------------------------------------------------
  To-Do         
  ---------------------------------------------------------------------------------------
  -- Right now all these privileges to PROD as well as the lower environments! This is 
  -- not optimal. We would want different (fewer) write privileges in Prod.
  -- To-Do: Come up with something like the Stored Proc that Molex uses to differentiate
  -- between environments when granting privileges to Functional Roles.
  -- Below merely sets up 3 buckets of privileges in 3 generic roles (read/write/create). 
  -- These privileges are then rolled up into a hierarchy.
-----------------------------------------------------------------------------------

---------------------------------------------------------------
-- 1. USERADMIN CREATE the account-level maint functional roles
---------------------------------------------------------------
USE ROLE USERADMIN; 

-- Create roles 
CREATE ROLE IF NOT EXISTS IDENTIFIER($pltfrAdmin);
CREATE ROLE IF NOT EXISTS IDENTIFIER($pltfrTagAdmin);
CREATE ROLE IF NOT EXISTS IDENTIFIER($localfrAdmin);
CREATE ROLE IF NOT EXISTS IDENTIFIER($sarR);
CREATE ROLE IF NOT EXISTS IDENTIFIER($sarW);
CREATE ROLE IF NOT EXISTS IDENTIFIER($sarC);

SELECT $sarR;
---------------------------------------------------------------
-- 2. SECURITYADMIN now wire roles for hierarchy
---------------------------------------------------------------
USE ROLE SECURITYADMIN;

-- to ensure Central Admin has ability to manage the delegated permissions
GRANT ROLE IDENTIFIER($pltfrAdmin) TO ROLE SYSADMIN;
GRANT ROLE IDENTIFIER($localfrAdmin) TO ROLE IDENTIFIER($pltfrAdmin);
GRANT ROLE IDENTIFIER($localfrAdmin) TO ROLE IDENTIFIER($pltfrTagAdmin);
GRANT ROLE IDENTIFIER($sarC) TO ROLE IDENTIFIER($localfrAdmin);
GRANT ROLE IDENTIFIER($sarW) TO ROLE IDENTIFIER($sarC); 
GRANT ROLE IDENTIFIER($sarR) TO ROLE IDENTIFIER($sarW);  
-- Above resolves to something like:
-- GRANT ROLE PDE_SYSADMIN_FR TO ROLE SYSADMIN;
-- GRANT ROLE FIN_CUSTOMER_SYSADMIN TO ROLE PDE_SYSADMIN_FR;
-- GRANT FIN_CUSTOMER_CUST360_FULL_AR TO ROLE FIN_CUSTOMER_SYSADMIN_FR;
-- GRANT ROLE FIN_CUSTOMER_CUST360_RW_AR TO ROLE FIN_CUSTOMER_CUST360_FULL_AR; 
-- GRANT ROLE FIN_CUSTOMER_CUST360_R_AR TO ROLE FIN_CUSTOMER_CUST360_RW_AR;  

-- Optional, Verify:
-- SHOW GRANTS TO ROLE IDENTIFIER($localfrAdmin);

-- Transfer ownership to the SCIM PROVISIONER role  (SailPoint, Azure AD, etc)
/*
GRANT OWNERSHIP ON ROLE IDENTIFIER($localfrAdmin)  TO ROLE IDENTIFIER($scimRl) COPY CURRENT GRANTS;
GRANT OWNERSHIP ON ROLE IDENTIFIER($afrDeploy) TO ROLE IDENTIFIER($scimRl) COPY CURRENT GRANTS;
GRANT OWNERSHIP ON ROLE IDENTIFIER($afrIngest) TO ROLE IDENTIFIER($scimRl) COPY CURRENT GRANTS;
GRANT OWNERSHIP ON ROLE IDENTIFIER($afrTrnfrm) TO ROLE IDENTIFIER($scimRl) COPY CURRENT GRANTS;
GRANT OWNERSHIP ON ROLE IDENTIFIER($afrRead)   TO ROLE IDENTIFIER($scimRl) COPY CURRENT GRANTS;
*/

-------------------------------------------------------------
-- 3. DELEGATED ADMIN CREATE database 
-------------------------------------------------------------
USE ROLE ACCOUNTADMIN;
GRANT CREATE DATABASE ON ACCOUNT TO ROLE IDENTIFIER($pltfrAdmin);

-- create database with platform admin.  
USE ROLE IDENTIFIER($pltfrAdmin);

-- CREATE OR ALTER TABLE {{db}}_DB.silver.Customer (
CREATE DATABASE IF NOT EXISTS {{db}};
-- Below not needed, but shows how to properly transfer ownership of a database to another role:
-- GRANT OWNERSHIP ON DATABASE {{db}} TO ROLE IDENTIFIER($pltfrAdmin) REVOKE CURRENT GRANTS;
USE SCHEMA {{db_scNm}};

GRANT USAGE ON DATABASE {{db}} TO ROLE SECURITYADMIN;

-- Optional, Verify:
-- show databases;

--- Grants for delegated admins;
USE ROLE SECURITYADMIN;

-- SET db = 'FIN_SALES_DB';
-- set scNm = 'SILVER';
-- set mySchema = $db || '.' || $scNm;
USE SCHEMA {{db_scNm}};

-- local admin (owner of schemas)
GRANT USAGE ON DATABASE {{db}} TO ROLE IDENTIFIER($localfrAdmin)  ;
GRANT USAGE ON ALL SCHEMAS in DATABASE {{db}} TO ROLE IDENTIFIER($localfrAdmin)  ;
GRANT CREATE SCHEMA ON DATABASE {{db}} TO ROLE IDENTIFIER($localfrAdmin)  ;       

--- create schema using local sysadmin
USE ROLE IDENTIFIER($localfrAdmin);
CREATE SCHEMA IF NOT EXISTS {{scNm}};
USE SCHEMA {{db_scNm}};

-------------------------------------------------------------
-- 4. DELEGATED ADMIN GRANT schema access roles
-------------------------------------------------------------
use role securityadmin;
USE SCHEMA {{db_scNm}};
 
GRANT USAGE, MONITOR                    ON DATABASE {{db}}                       TO ROLE IDENTIFIER($sarR);
GRANT USAGE, MONITOR                    ON SCHEMA {{scNm}}                               TO ROLE IDENTIFIER($sarR);

GRANT SELECT                            ON ALL TABLES                IN SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarR);
GRANT SELECT                            ON FUTURE TABLES             IN SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarR);
GRANT SELECT                            ON ALL VIEWS                 IN SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarR);
GRANT SELECT                            ON FUTURE VIEWS              IN SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarR);
GRANT USAGE                             ON ALL FUNCTIONS             IN SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarR);
GRANT USAGE                             ON FUTURE FUNCTIONS          IN SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarR);
GRANT SELECT                            ON ALL EXTERNAL TABLES       IN SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarR);
GRANT SELECT                            ON FUTURE EXTERNAL TABLES    IN SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarR);
GRANT SELECT                            ON ALL DYNAMIC TABLES        IN SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarR);
GRANT SELECT                            ON FUTURE DYNAMIC TABLES     IN SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarR);
GRANT SELECT                            ON ALL MATERIALIZED VIEWS    IN SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarR);
GRANT SELECT                            ON FUTURE MATERIALIZED VIEWS IN SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarR);
GRANT USAGE, READ                       ON ALL STAGES                IN SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarR);
GRANT USAGE, READ                       ON FUTURE STAGES             IN SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarR);

-- -- $sarW will inherit all grants from $sarR when hierarchy is built:
GRANT SELECT                            ON ALL STREAMS           IN SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarW);
GRANT SELECT                            ON FUTURE STREAMS        IN SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarW);
GRANT INSERT, UPDATE, DELETE, TRUNCATE  ON ALL TABLES            IN SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarW);
GRANT INSERT, UPDATE, DELETE, TRUNCATE  ON FUTURE TABLES         IN SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarW);
GRANT USAGE                             ON ALL PROCEDURES        IN SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarW);
GRANT USAGE                             ON FUTURE PROCEDURES     IN SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarW);
GRANT USAGE                             ON ALL SEQUENCES         IN SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarW);
GRANT USAGE                             ON FUTURE SEQUENCES      IN SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarW);
GRANT MONITOR, OPERATE                  ON ALL TASKS             IN SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarW);
GRANT MONITOR, OPERATE                  ON FUTURE TASKS          IN SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarW);
GRANT USAGE                             ON ALL FILE FORMATS      IN SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarW);
GRANT USAGE                             ON FUTURE FILE FORMATS   IN SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarW);
GRANT USAGE, READ, WRITE                ON ALL STAGES            IN SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarW);
GRANT USAGE, READ, WRITE                ON FUTURE STAGES         IN SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarW);
GRANT MONITOR, OPERATE                  ON ALL DYNAMIC TABLES    IN SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarW);
GRANT MONITOR, OPERATE                  ON FUTURE DYNAMIC TABLES IN SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarW);
GRANT MONITOR, OPERATE                  ON ALL ALERTS            IN SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarW);
GRANT MONITOR, OPERATE                  ON FUTURE ALERTS         IN SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarW);
GRANT MONITOR, OPERATE                  ON FUTURE PIPES          IN SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarW);

-- $sarC will inherit all grants from $sarW when hierarchy is built:
GRANT CREATE TABLE             ON SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarC);
GRANT CREATE VIEW              ON SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarC);
GRANT CREATE STREAM            ON SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarC);
GRANT CREATE FUNCTION          ON SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarC);
GRANT CREATE PROCEDURE         ON SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarC);
GRANT CREATE SEQUENCE          ON SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarC);
GRANT CREATE TASK              ON SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarC);
GRANT CREATE FILE FORMAT       ON SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarC);
GRANT CREATE STAGE             ON SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarC);
GRANT CREATE EXTERNAL TABLE    ON SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarC);
GRANT CREATE PIPE              ON SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarC);
GRANT CREATE DYNAMIC TABLE     ON SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarC);
GRANT CREATE MATERIALIZED VIEW ON SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarC);
GRANT CREATE STREAMLIT         ON SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarC);
GRANT CREATE ALERT             ON SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarC);
-- WE WANT TO RESERVE CREATE TAG FOR A SPECIAL TAGGING ROLE FOR SECURITY:
-- GRANT CREATE TAG               ON SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarC);
GRANT CREATE MASKING POLICY    ON SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarC);
GRANT CREATE ROW ACCESS POLICY ON SCHEMA {{scNm}}  TO ROLE IDENTIFIER($sarC);
-- PDE_TAGGING_FR IS THE ONLY ROLE IN THE ACCOUNT THAT CAN CREATE TAGS.
-- COULD GRANT TO ANOTHER ROLE IF WE DECIDE TO LIKE THIS:
-- USE ROLE USERADMIN;
-- GRANT ROLE PDE_TAGADMIN_FR TO ROLE MYDATAENGINEER;
USE SCHEMA {{db_scNm}};
GRANT CREATE TAG ON SCHEMA {{scNm}} TO ROLE PDE_TAGADMIN_FR;

-- Optional, review grants:
-- show grants to role IDENTIFIER($sarR);
-- show grants to role IDENTIFIER($sarW);
-- show grants to role IDENTIFIER($sarC);
-- show grants to role IDENTIFIER($localfrAdmin);
-- show grants to role IDENTIFIER($pltfrAdmin);


-------------------------------------------------------------
-- 5. Optional: GRANT schema access roles to DB level access roles, if database roles are utilized
-------------------------------------------------------------
-- simple example below
--GRANT ROLE IDENTIFIER($sarR) TO ROLE << insert role name >>;
--GRANT ROLE IDENTIFIER($sarW) TO ROLE << insert role name >>;
--GRANT ROLE IDENTIFIER($sarC) TO ROLE << insert role name >>;

-------------------------------------------------------------
-- 6. Best practice to always drop the PUBLIC schema
-------------------------------------------------------------
USE SCHEMA {{db_scNm}};
USE ROLE IDENTIFIER($pltfrAdmin); -- DATABASE AND SCHEMAS OWNED BY PLATFORM ADMIN!
DROP SCHEMA IF EXISTS IDENTIFIER($publicSchemaNm); -- Best practice to always drop the PUBLIC schema


-------------------------------------------------------------
-- 7. WAREHOUSE GRANTS
-------------------------------------------------------------
USE SCHEMA {{db_scNm}};
SET whNm  = $databaseNm || '_WH';
SET whComment = 'Warehouse for ' || $databaseNm ;   -- comments for warehouse

    
-- construct the 2 Access Role names for Usage and Operate
SET warU = $whNm || '_WU_AR';  -- Monitor & Usage
SET warO = $whNm || '_WO_AR';  -- Operate & Modify (so WH can be resized operationally if needed)

-- Optional, review context
-- select $whNm warehouse_name, $warU Warehouse_role_Usage, $warO Warehouse_role_wu;

---------------------------------------------------------------
-- 8. CREATE Warehouse
---------------------------------------------------------------
USE ROLE SYSADMIN;
CREATE WAREHOUSE IF NOT EXISTS IDENTIFIER($whNm) WITH
  WAREHOUSE_SIZE                = XSMALL
  INITIALLY_SUSPENDED           = TRUE -- Important to save costs!
  AUTO_RESUME                   = TRUE
  AUTO_SUSPEND                  = 60
  STATEMENT_TIMEOUT_IN_SECONDS  = 1800
  COMMENT                       = $whComment;
  -- TAG (cost_center = 'sales');

-- Assume Delegated Admin, so transfer ownership
-- Can grant to either platform sysadmin or local sysadmin. 
-- -- Grant to local domains if require autonomy in maintaining/managing warehouses.
GRANT OWNERSHIP ON WAREHOUSE IDENTIFIER($whNm) TO ROLE IDENTIFIER($pltfrAdmin);

-- ---------------------------------------------------------------
-- -- 9. USERADMIN create our warehouse roles
-- ---------------------------------------------------------------
USE ROLE USERADMIN;
CREATE ROLE IF NOT EXISTS IDENTIFIER($warU);
CREATE ROLE IF NOT EXISTS IDENTIFIER($warO);

-- ---------------------------------------------------------------
-- -- 10. SECURITYADMIN grants privileges and wire roles hierarchy for warehouse roles
-- ---------------------------------------------------------------
USE ROLE SECURITYADMIN;
GRANT MONITOR, USAGE  ON WAREHOUSE IDENTIFIER($whNm) TO ROLE IDENTIFIER($warU);
GRANT OPERATE, MODIFY ON WAREHOUSE IDENTIFIER($whNm) TO ROLE IDENTIFIER($warO);
--- Create our warehouse role heirarchy
GRANT ROLE IDENTIFIER($warU) TO ROLE IDENTIFIER($warO);
-- Assume Delegated Admin, so transfer ownership of these functional roles
GRANT OWNERSHIP ON ROLE IDENTIFIER($warU) TO ROLE IDENTIFIER($pltfrAdmin) COPY CURRENT GRANTS;
GRANT OWNERSHIP ON ROLE IDENTIFIER($warO) TO ROLE IDENTIFIER($pltfrAdmin) COPY CURRENT GRANTS;

-- Assign warehouse user to functional roles
GRANT ROLE IDENTIFIER($warU) TO ROLE IDENTIFIER($sarR);
GRANT ROLE IDENTIFIER($warU) TO ROLE IDENTIFIER($sarW);
--------------------------------------------------------
-- I feel like Full Engineers should be able to resize a warehouse
GRANT ROLE IDENTIFIER($warO) TO ROLE IDENTIFIER($sarC);
GRANT ROLE IDENTIFIER($warO) TO ROLE IDENTIFIER($localfrAdmin);

---------------------------------------------------------------
-- END SCHEMA CREATION. OPTIONAL, CONTINUE TO TESTS BELOW.
---------------------------------------------------------------

-- USE SCHEMA ADM_CONTROL_DB.DEPLOY;
-- EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/master/apps/adm_control/snowflake_objects/databases/create_test_db.sql

---------------------------------------------------------------
-- 100. TEST
---------------------------------------------------------------
-- Grant all three roles to your user.  Review what is visible.
-- grant role IDENTIFIER($pltfrAdmin) to user <your username>;
-- grant role IDENTIFIER($localfrAdmin) to user <your username>;
-- grant role IDENTIFIER($sarR) to user <your username>;
-- grant role IDENTIFIER($sarW) to user <your username>;
-- grant role IDENTIFIER($sarC) to user <your username>;

-- Uncomment, and use each role and notice what you can see in the database explorer:
-- use role IDENTIFIER($pltfrAdmin);
-- use role IDENTIFIER($localfrAdmin);
-- use role IDENTIFIER($sarC);
-- use role IDENTIFIER($sarW);
-- use role IDENTIFIER($sarR);
-- use role sysadmin;