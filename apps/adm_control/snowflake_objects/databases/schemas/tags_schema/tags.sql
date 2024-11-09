---------------------------------------------------------------------------------------
-- For testing, this script SEPARATES the build steps FROM the variables
---------------------------------------------------------------------------------------
-- SCRIPT:    This script sets up session variables that will be used by build_schema.sql
--        to create database (if not exists), schema, roles and roles hierarchy.  
-- 
--        ADM_CONTROL_DB will be our Account Control database with limited acccess.
--        Schemas include:
--            DEPLOY_SCHEMA   - git repository for EXECUTE IMMEDIATE FROM calls
--            ALERTS_SCHEMA   - to maintain standards around alerting for the account
--            TAGS_SCHEMA     - to maintain standards around tagging for the account
-- 
-- YY-MM-DD WHO          CHANGE DESCRIPTION
---------------------------------------------------------------------------------------
--   To-Do         
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------


SET beNm = 'ADM';               -- Business Entity / Segment
SET dbNm = 'CONTROL';           -- Database Name
SET scNm = 'TAGS_SCHEMA';       -- Schema Name

-- construct the database name and delegated admin role
SET prefixNm = $beNm;
SET dbNm = $prefixNm || '_' || $dbNm;                                                
SET databaseNm = $dbNm || '_DB';
SET schemaNm = $databaseNm || '.' || $scNm;
SET publicSchemaNm = $databaseNm || '.' || 'public';
SET pltfrAdmin  = 'PDE_SYSADMIN_FR';  --- Platform sysadmin,  delegated role granted up to SYSADMIN. Create only once.

SET localfrAdmin  =  $dbNm || '_SYSADMIN_FR';
set pltfrTagAdmin = 'PDE_TAGADMIN_FR';  -- Currently, creation of tags are reserved for PDE_TAGADMIN_FR as a security measure.
                                        -- However, if we decide to change this just grant PDE_TAGADMIN_FR to another role like this:
                                        -- USE ROLE USERADMIN;
                                        -- GRANT ROLE PDE_TAGADMIN_FR TO ROLE MYDATAENGINEERROLE;

-- construct the 3 Access Role SCHEMA LEVEL, for Read, Write & Create
SET sarR =  $dbNm || '_' || $scNm || '_R_AR';  -- READ access role
SET sarW =  $dbNm || '_' || $scNm || '_RW_AR';  -- WRITE access role
SET sarC =  $dbNm || '_' || $scNm || '_FULL_AR';  -- CREATE or FULL access role

SET whNm  = $databaseNm || '_WH';
SET whComment = 'Warehouse for ' || $databaseNm ;   -- comments for warehouse

    
-- construct the 2 Access Role names for Usage and Operate
SET warU = $whNm || '_WU_AR';  -- Monitor & Usage
SET warO = $whNm || '_WO_AR';  -- Operate & Modify (so WH can be resized operationally if needed)


---------------------------------------------------------------------------------
-- build_schema.sql is a generic script to create any schema:
EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/master/apps/build_schema.sql;
---------------------------------------------------------------------------------