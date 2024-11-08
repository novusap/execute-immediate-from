
SET beNm = 'ADM';        -- Business Entity / Segment
SET dbNm = 'CONTROL';    -- Database Name
SET scNm = 'DEPLOY';       -- Schema Name

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
-- SET whComment = 'MyWarehouse' || $databaseNm ;   -- comments for warehouse
SET whComment = 'Warehouse_for' || $databaseNm ;   -- comments for warehouse

    
-- construct the 2 Access Role names for Usage and Operate
SET warU = $whNm || '_WU_AR';  -- Monitor & Usage
SET warO = $whNm || '_WO_AR';  -- Operate & Modify (so WH can be resized operationally if needed)


----------------------------------
--- MUST PARAMETERIZE THE PATH ---
----------------------------------


-- EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/master/apps/adm_control/snowflake_objects/warehouses/adm_control_wh_build.sql USING (whNm => $whNm, whComment => $whComment, pltfrAdmin => $pltfrAdmin);

EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/master/apps/adm_control/snowflake_objects/databases/adm_control_db_build.sql;
-- snow sql -f "./apps/adm_control/snowflake_objects/databases/adm_control_db_build.sql.sql;"
-- snow sql -f "./apps/adm_control/snowflake_objects/databases/adm_control_db/git_integration.sql;"
EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/master/apps/adm_control/snowflake_objects/databases/adm_control_db/working_git_integration.sql;

-- EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/master/apps/adm_control/snowflake_objects/warehouses/adm_control_wh_build.sql;
-- EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/{{ENV}}/apps/generic_schema_script.sql;
-- apps/adm_control/snowflake_objects/databases/adm_control_db/schemas/schema_deploy.sql
-- /Users/michaeltacker/PycharmProjects/snowflake-demo/apps/adm_control/snowflake_objects/databases/adm_control_db/adm_control_db_build.sql
