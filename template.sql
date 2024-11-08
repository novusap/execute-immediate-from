/****************************************************************************************\
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

  --        CLEAN UP scripts

  -- 
  -- Note:  The below scripts are account-level roles and can be modified to include 
  --        database roles where appropriate

  
  YY-MM-DD WHO          CHANGE DESCRIPTION
  -------- ------------ -----------------------------------------------------------------

\****************************************************************************************/

---------------------------------------------------------------
-- 0. INPUT the components of the names and other parameters
---------------------------------------------------------------
SET beNm = 'FINANCE';           -- Business Entity
SET evNm = 'DEV';               -- Environment Name (Dev | Tst | Prd)
SET dbNm = 'CUSTOMER';          -- Data Product Name
SET znNm = 'CUR';               -- Zone Name (RAW | EDW | ADW | Curated)
SET scNm = 'CUST360';

-- construct the database name and delegated admin role
SET prefixNm = $evNm || IFF(($znNm = ''), '', '_' || $znNm) || IFF(($beNm = ''), '', '_' || $beNm);
SET dbNm = $prefixNm;                                                --  If Domain defined at account level, append:  || IFF(($dbNm = ''), '', '_' || $dbNm ); 
SET databaseNm = $dbNm || '_DB';
SET schemaNm = $databaseNm || '.' || $scNm;
SET publicSchemaNm = $databaseNm || '.' || 'public';
SET pltfrAdmin  = 'PDE_SYSADMIN';                                     --- Platform sysadmin,  delegated role granted up to SYSADMIN. Create only once.
--SET localfrAdmin  = $prefixNm || '_SYSADMIN';                        --- Local sysadmin,  delegated role granted up to Platform sysadmin
SET localfrAdmin  =  $evNm || IFF(($beNm = ''), '', '_' || $beNm) || '_SYSADMIN';

/* ----- Account RBAC Heirarchy -------------------------
    -- Note: the below script includes account-level roles, and may be modified to include database roles.

    ACCOUNTADMIN
        SECURITYADMIN
        SYSADMIN
            PLATFORM_SYSADMIN   (grants, create tasks, notifications, create database, create schema,  access/grants to a GOVERNANCE DB, PLATFORM_DB - contain the account_usage views persisted locally, 
                                    write reporting, governance reporting, platform management, replication management, fail-over DR,  )
                LOCAL_SYSADMIN   (create tags in database only, manage users, manage grants create local tags, apply policies,  DATABASE LEVEL)
                    FULL_AR
                        WR_AR
                            R_AR


 */

-- construct the 3 Access Role SCHEMA LEVEL, for Read, Write & Create
SET sarR =  $dbNm || '_' || $scNm || '_R_AR';  -- READ access role
SET sarW =  $dbNm || '_' || $scNm || '_RW_AR';  -- WRITE access role
SET sarC =  $dbNm || '_' || $scNm || '_FULL_AR';  -- CREATE or FULL access role
--SET sarR =  $dbNm || '_' || $scNm || '_R_AR';  -- READ access role

-- Review context
Select 
    $evNm as Environ_name
    , $beNm as BusinessEntity
    , $znNm as Zone_name
    , $schemaNm as DB_and_Schema_Name      -- fully qualified
    , $databaseNm as Database_name
    , $scNm as SchemaName
    , $pltfrAdmin as Platform_Sysadmin_role
    , $localfrAdmin as local_Sysadmin_role
    , $sarR as Read_Role
    , $sarW as Write_Role
    , $sarC as CreateFULL_Role
    ;


---------------------------------------------------------------
-- 1. USERADMIN CREATE the account-level maint functional roles
---------------------------------------------------------------
USE ROLE USERADMIN; 

-- Create roles 
CREATE ROLE IF NOT EXISTS IDENTIFIER($pltfrAdmin);
CREATE ROLE IF NOT EXISTS IDENTIFIER($localfrAdmin);
CREATE ROLE IF NOT EXISTS IDENTIFIER($sarR);
CREATE ROLE IF NOT EXISTS IDENTIFIER($sarW);
CREATE ROLE IF NOT EXISTS IDENTIFIER($sarC);

show roles;
---------------------------------------------------------------
-- 2. SECURITYADMIN now wire roles for hierarchy
---------------------------------------------------------------
USE ROLE SECURITYADMIN;

-- to ensure Central Admin has ability to manage the delegated permissions
GRANT ROLE IDENTIFIER($pltfrAdmin) TO ROLE SYSADMIN;
GRANT ROLE IDENTIFIER($localfrAdmin) TO ROLE IDENTIFIER($pltfrAdmin);
GRANT ROLE IDENTIFIER($sarC) TO ROLE IDENTIFIER($localfrAdmin);
GRANT ROLE IDENTIFIER($sarW) TO ROLE IDENTIFIER($sarC); 
GRANT ROLE IDENTIFIER($sarR) TO ROLE IDENTIFIER($sarW);  

-- Transfer ownership to the SCIM PROVISIONER role  (SailPoint, Azure AD, etc)
/*
GRANT OWNERSHIP ON ROLE IDENTIFIER($localfrAdmin)  TO ROLE IDENTIFIER($scimRl) COPY CURRENT GRANTS;
GRANT OWNERSHIP ON ROLE IDENTIFIER($afrDeploy) TO ROLE IDENTIFIER($scimRl) COPY CURRENT GRANTS;
GRANT OWNERSHIP ON ROLE IDENTIFIER($afrIngest) TO ROLE IDENTIFIER($scimRl) COPY CURRENT GRANTS;
GRANT OWNERSHIP ON ROLE IDENTIFIER($afrTrnfrm) TO ROLE IDENTIFIER($scimRl) COPY CURRENT GRANTS;
GRANT OWNERSHIP ON ROLE IDENTIFIER($afrRead)   TO ROLE IDENTIFIER($scimRl) COPY CURRENT GRANTS;
*/

show roles;

-------------------------------------------------------------
-- 3. DELEGATED ADMIN CREATE database 
-------------------------------------------------------------
USE ROLE ACCOUNTADMIN;
GRANT CREATE DATABASE ON ACCOUNT TO ROLE IDENTIFIER($pltfrAdmin);

-- create database with platform admin.  Optional:  create with localfrAdmin and transfer ownership to pltfrm sysadmin
USE ROLE IDENTIFIER($pltfrAdmin);
CREATE DATABASE IF NOT EXISTS IDENTIFIER($databaseNm);
USE DATABASE IDENTIFIER($databaseNm);

show databases;

--- Grants for delegated admins;
USE ROLE SECURITYADMIN;
-- platform admin (owner of databases)
GRANT OWNERSHIP ON DATABASE IDENTIFIER($databaseNm) TO ROLE IDENTIFIER($pltfrAdmin) REVOKE CURRENT GRANTS;

-- local admin (owner of schemas)
GRANT USAGE ON DATABASE IDENTIFIER($databaseNm)  TO ROLE IDENTIFIER($localfrAdmin)  ;
GRANT USAGE ON ALL SCHEMAS in DATABASE IDENTIFIER($databaseNm)  TO ROLE IDENTIFIER($localfrAdmin)  ;
GRANT CREATE SCHEMA ON DATABASE IDENTIFIER($databaseNm)  TO ROLE IDENTIFIER($localfrAdmin)  ;       --- optional.  
                    -- above "create schema grant" may be replaced by a stored proc, example: sp_CREATE_SCHEMA(dbname, schemaname);

--- create schema using local sysadmin
USE ROLE IDENTIFIER($localfrAdmin);
CREATE SCHEMA IF NOT EXISTS IDENTIFIER($scNm);
USE SCHEMA IDENTIFIER($scNm);

show databases;
-- local sysadmin is othe owner of the schema and can create tables and insert data.
create or replace table cust_address (id numeric);


-------------------------------------------------------------
-- 4. DELEGATED ADMIN GRANT schema access roles
-------------------------------------------------------------
use role securityadmin;

GRANT USAGE, MONITOR                    ON DATABASE IDENTIFIER($databaseNm)                       TO ROLE IDENTIFIER($sarR);
GRANT USAGE, MONITOR                    ON SCHEMA IDENTIFIER($schemaNm)                               TO ROLE IDENTIFIER($sarR);

GRANT SELECT                            ON ALL TABLES                IN SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarR);
GRANT SELECT                            ON FUTURE TABLES             IN SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarR);
GRANT SELECT                            ON ALL VIEWS                 IN SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarR);
GRANT SELECT                            ON FUTURE VIEWS              IN SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarR);
GRANT USAGE                             ON ALL FUNCTIONS             IN SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarR);
GRANT USAGE                             ON FUTURE FUNCTIONS          IN SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarR);
GRANT SELECT                            ON ALL EXTERNAL TABLES       IN SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarR);
GRANT SELECT                            ON FUTURE EXTERNAL TABLES    IN SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarR);
GRANT SELECT                            ON ALL DYNAMIC TABLES        IN SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarR);
GRANT SELECT                            ON FUTURE DYNAMIC TABLES     IN SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarR);
GRANT SELECT                            ON ALL MATERIALIZED VIEWS    IN SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarR);
GRANT SELECT                            ON FUTURE MATERIALIZED VIEWS IN SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarR);
-- below are grants that may be appropriate, determine if appropriate per organizational requirements
GRANT USAGE, READ                       ON ALL STAGES                IN SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarR);
GRANT USAGE, READ                       ON FUTURE STAGES             IN SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarR);


-- WRITE Access ROLE

GRANT SELECT                            ON ALL STREAMS           IN SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarW);
GRANT SELECT                            ON FUTURE STREAMS        IN SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarW);
GRANT INSERT, UPDATE, DELETE, TRUNCATE  ON ALL TABLES            IN SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarW);
GRANT INSERT, UPDATE, DELETE, TRUNCATE  ON FUTURE TABLES         IN SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarW);
GRANT USAGE                             ON ALL PROCEDURES        IN SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarW);
GRANT USAGE                             ON FUTURE PROCEDURES     IN SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarW);
GRANT USAGE                             ON ALL SEQUENCES         IN SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarW);
GRANT USAGE                             ON FUTURE SEQUENCES      IN SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarW);
GRANT MONITOR, OPERATE                  ON ALL TASKS             IN SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarW);
GRANT MONITOR, OPERATE                  ON FUTURE TASKS          IN SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarW);
GRANT USAGE                             ON ALL FILE FORMATS      IN SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarW);
GRANT USAGE                             ON FUTURE FILE FORMATS   IN SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarW);
GRANT USAGE, READ, WRITE                ON ALL STAGES            IN SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarW);
GRANT USAGE, READ, WRITE                ON FUTURE STAGES         IN SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarW);
GRANT MONITOR, OPERATE                  ON ALL DYNAMIC TABLES    IN SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarW);
GRANT MONITOR, OPERATE                  ON FUTURE DYNAMIC TABLES IN SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarW);
GRANT MONITOR, OPERATE                  ON ALL ALERTS            IN SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarW);
GRANT MONITOR, OPERATE                  ON FUTURE ALERTS         IN SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarW);

-- below are grants that may be appropriate, determine if appropriate per organizational requirements
--GRANT MONITOR, OPERATE                  ON ALL PIPES             IN SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarW);
--GRANT MONITOR, OPERATE                  ON FUTURE PIPES          IN SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarW);

-- CREATE Access ROLE

GRANT CREATE TABLE             ON SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarC);
GRANT CREATE VIEW              ON SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarC);
GRANT CREATE STREAM            ON SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarC);
GRANT CREATE FUNCTION          ON SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarC);
GRANT CREATE PROCEDURE         ON SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarC);
GRANT CREATE SEQUENCE          ON SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarC);
GRANT CREATE TASK              ON SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarC);
GRANT CREATE FILE FORMAT       ON SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarC);
GRANT CREATE STAGE             ON SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarC);
GRANT CREATE EXTERNAL TABLE    ON SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarC);
GRANT CREATE PIPE              ON SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarC);
GRANT CREATE DYNAMIC TABLE     ON SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarC);
GRANT CREATE MATERIALIZED VIEW ON SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarC);
GRANT CREATE STREAMLIT         ON SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarC);
GRANT CREATE ALERT             ON SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarC);
GRANT CREATE TAG               ON SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarC);
GRANT CREATE MASKING POLICY    ON SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarC);
GRANT CREATE ROW ACCESS POLICY ON SCHEMA IDENTIFIER($schemaNm)  TO ROLE IDENTIFIER($sarC);


-- review grants
show grants to role IDENTIFIER($sarR);
show grants to role IDENTIFIER($sarW);
show grants to role IDENTIFIER($sarC);
show grants to role IDENTIFIER($localfrAdmin);
show grants to role IDENTIFIER($pltfrAdmin);


show grants on role IDENTIFIER($sarR);
show grants on role IDENTIFIER($sarW);
show grants on role IDENTIFIER($sarC);
show grants on role IDENTIFIER($localfrAdmin);
show grants on role IDENTIFIER($pltfrAdmin);

-------------------------------------------------------------
-- 5. GRANT schema access roles to DB level access roles, if database roles are utilized
-------------------------------------------------------------
-- simple example below
--GRANT ROLE IDENTIFIER($sarR) TO ROLE << insert role name >>;
--GRANT ROLE IDENTIFIER($sarW) TO ROLE << insert role name >>;
--GRANT ROLE IDENTIFIER($sarC) TO ROLE << insert role name >>;

-------------------------------------------------------------
-- 6. Maintain only necessary objects - DROP public if applicable (optional)
-------------------------------------------------------------
USE ROLE IDENTIFIER($pltfrAdmin); -- DATABASE AND SCHEMAS OWNED BY PLATFORM ADMIN!
DROP SCHEMA IF EXISTS IDENTIFIER($publicSchemaNm); 



-------------------------------------------------------------
-- 7. WAREHOUSE GRANTS
-------------------------------------------------------------
-- SET CONTEXT 
-- construct the warehouse name and delegated admin role
SET prefixNm = $evNm || IFF(($znNm = ''), '', '_' || $znNm) || IFF(($beNm = ''), '', '_' || $beNm);
SET whNm  = $prefixNm || '_WH';
SET whComment = '';                     -- comments for warehouse
-- review context
    select $whNm;
    
-- construct the 2 Access Role names for Usage and Operate
SET warU = $whNm || '_WU_AR';  -- Monitor & Usage
SET warO = $whNm || '_WO_AR';  -- Operate & Modify (so WH can be resized operationally if needed)

-- review context
    select $whNm warehouse_name, $warU Warehouse_role_Usage, $warO Warehouse_role_wu;

---------------------------------------------------------------
-- 3. CREATE Warehouse
---------------------------------------------------------------
USE ROLE SYSADMIN;

CREATE WAREHOUSE IF NOT EXISTS IDENTIFIER($whNm) WITH
  WAREHOUSE_SIZE                = XSMALL
  INITIALLY_SUSPENDED           = TRUE 
  AUTO_RESUME                   = TRUE
  AUTO_SUSPEND                  = 60
  STATEMENT_TIMEOUT_IN_SECONDS  = 1800
  COMMENT                       = $whComment;

-- Assume Delegated Admin, so transfer ownership
-- Can grant to either platform sysadmin or local sysadmin. Grant to local domains if require autonomy in maintaining/managing warehouses.
GRANT OWNERSHIP ON WAREHOUSE IDENTIFIER($whNm) TO ROLE IDENTIFIER($pltfrAdmin);

---------------------------------------------------------------
-- 3. USERADMIN CREATE the maint account-level maint roles
---------------------------------------------------------------
USE ROLE USERADMIN;

CREATE ROLE IF NOT EXISTS IDENTIFIER($warU);
CREATE ROLE IF NOT EXISTS IDENTIFIER($warO);
---------------------------------------------------------------
-- 4. SECURITYADMIN grants privileges and wire roles hierarchy
---------------------------------------------------------------
USE ROLE SECURITYADMIN;

GRANT MONITOR, USAGE  ON WAREHOUSE IDENTIFIER($whNm) TO ROLE IDENTIFIER($warU);
GRANT OPERATE, MODIFY ON WAREHOUSE IDENTIFIER($whNm) TO ROLE IDENTIFIER($warO);

--- role heirarchy
GRANT ROLE IDENTIFIER($warU) TO ROLE IDENTIFIER($warO);

-- Assume Delegated Admin, so transfer ownership of these access roles
GRANT OWNERSHIP ON ROLE IDENTIFIER($warU) TO ROLE IDENTIFIER($pltfrAdmin) COPY CURRENT GRANTS;
GRANT OWNERSHIP ON ROLE IDENTIFIER($warO) TO ROLE IDENTIFIER($pltfrAdmin) COPY CURRENT GRANTS;


-- Assign warehouse user to functional roles
GRANT ROLE IDENTIFIER($warU) TO ROLE IDENTIFIER($sarR);
GRANT ROLE IDENTIFIER($warU) TO ROLE IDENTIFIER($sarW);
GRANT ROLE IDENTIFIER($warU) TO ROLE IDENTIFIER($sarC);
GRANT ROLE IDENTIFIER($warO) TO ROLE IDENTIFIER($localfrAdmin);


---------------------------------------------------------------
-- 100. TEST
---------------------------------------------------------------
--          Grant all three roles to your user.  Review what is visible.
-- grant role IDENTIFIER($pltfrAdmin) to user <your username>;
-- grant role IDENTIFIER($localfrAdmin) to user <your username>;
-- grant role IDENTIFIER($sarR) to user <your username>;
-- grant role IDENTIFIER($sarW) to user <your username>;
-- grant role IDENTIFIER($sarC) to user <your username>;

-- use each role and notice what you can see in the database explorer.
 use role IDENTIFIER($pltfrAdmin);
use role IDENTIFIER($localfrAdmin);
use role IDENTIFIER($sarC);
use role IDENTIFIER($sarW);
use role IDENTIFIER($sarR);
use role sysadmin;

-- use each role and run DDL on table.
use role IDENTIFIER($pltfrAdmin);
    alter table cust_address add column Addr string;
    
use role IDENTIFIER($localfrAdmin);
    alter table cust_address rename column Addr to Address;
    
use role IDENTIFIER($sarC);
    alter table cust_address rename column Address to Addr_1;       -- is not owner, doesn't have access to alter table.
    -- can create table, is the owner NOTE: DO NOT CREATE OBJECTS WITH THIS ROLE.  ONLY CREATE objects WITH FUNCTIONAL ROLES
    --                                      THAT HAVE THIS ROLE GRANTED TO SAID ROLE!
    create table cust_city (city string);  
    alter table cust_city set comment ='Testing if owner can alter their own tables';
    insert into cust_city values ('chicago');     -- works, as full role inherits R-> W -> FULL
    
use role IDENTIFIER($localfrAdmin);
    alter table cust_city add column state string;  -- works
    select * from cust_city;
    describe table cust_city;
    select get_ddl('table', 'cust_city');
    update cust_city set state = 'IL' where city ='chicago';

use role IDENTIFIER($sarW);
     insert into cust_city values ('Dallas', 'TX'); 
     update cust_city set city = 'Springfield' where state = 'IL';
     select * from cust_city;
     
use role IDENTIFIER($sarR);
     select * from cust_city;
     update cust_city set state = 'IL' where city ='Springfield';       -- fails, insufficient privileges

    
--- clean up script 
/*
use role securityadmin;
DROP ROLE if exists IDENTIFIER($localfrAdmin);
DROP ROLE if exists IDENTIFIER($pltfrAdmin);
DROP ROLE if exists IDENTIFIER($sarR);
DROP ROLE if exists IDENTIFIER($sarW);
DROP ROLE if exists IDENTIFIER($sarC);
DROP ROLE if exists IDENTIFIER($warO);
DROP ROLE if exists IDENTIFIER($warU);
--
use role accountadmin;
drop database IDENTIFIER($databaseNm);
drop warehouse IDENTIFIER($whNm);
*/

