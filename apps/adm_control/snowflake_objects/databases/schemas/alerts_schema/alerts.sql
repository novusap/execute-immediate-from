-- Prep for running this.
-- Need to push files to an internal stage and run script from there.
-- snow sql -q "create database snowflake_cli_db";
-- snow stage create snowflake_cli_db.public.my_stage;
-- snow stage copy ./schemas/nested_script.sql @snowflake_cli_db.public.my_stage/test_segments/scripts  --overwrite;  

-- snow stage copy ./schemas/00_fin_customer_cust360_schema_setup.sql @snowflake_cli_db.public.my_stage/test_segments/scripts  --overwrite;

-- Once files are in stage then just run from Snowflake CLI:
-- michaeltacker@macOS-V6Q79GW9CG scripts % snow sql -f main.sql

SET beNm = 'ADM';        -- Business Entity / Segment
SET dbNm = 'CONTROL';    -- Database Name
SET scNm = 'ALERTS_SCHEMA';       -- Schema Name

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





EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/master/apps/build_schema.sql;
