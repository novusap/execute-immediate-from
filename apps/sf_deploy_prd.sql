-- /****************************************************************************************\
--  SCRIPT:    Code from this script updates objects in Snowflake production account.
--             
--             
--
--   YY-MM-DD WHO          CHANGE DESCRIPTION
--   -------- ------------ -----------------------------------------------------------------

-- \****************************************************************************************/


-- -- UPDATES IN ADM_CONTROL_DB DATABASE
-------------------------------------

-- SCHEMAS      

-- 
EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/master/apps/adm_control/snowflake_objects/databases/schemas/tags_schema/tags.sql;
EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/master/apps/adm_control/snowflake_objects/databases/schemas/alerts_schema/alerts.sql;
-- Uncaught exception of type 'STATEMENT_ERROR' in file @SNOWFLAKE_GIT_REPO/branches/master/apps/sf_deploy_prd.sql on line 20 at position 0:           │
-- │ Cannot perform operation. This session does not have a current database. Call 'USE DATABASE', or use a qualified name.    



-- "Unsupported feature 'session variables not supported during object dependencies backfill."

-- EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/master/apps/fin_sales/snowflake_objects/databases/schemas/fin_sales_silver/fin_sales_silver_schema.sql;
-- EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/master/apps/fin_sales/snowflake_objects/databases/schemas/fin_sales_bronze/fin_sales_bronze_schema.sql;
-- EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/master/apps/fin_sales/snowflake_objects/databases/schemas/fin_sales_gold/fin_sales_gold_schema.sql;

-- -- TABLES
-- EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/master/project_files/bronze/Tables/Customer.sql USING (ENV => 'PRD');
-- EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/master/project_files/bronze/Tables/Orders.sql USING (ENV => 'PRD');
-- EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/master/project_files/bronze/Tables/Product.sql USING (ENV => 'PRD');
-- -- EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/master/project_files/silver/Tables/Customer.sql USING (ENV => 'PRD');
-- -- EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/master/project_files/silver/Tables/Orders.sql USING (ENV => 'PRD');
-- -- EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/master/project_files/silver/Tables/Product.sql USING (ENV => 'PRD');
-- -- EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/master/project_files/gold/Tables/Shipping.sql USING (ENV => 'PRD');
 
-- -- VIEWS
-- EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/master/project_files/bronze/Views/Customer_Orders.sql USING (ENV => 'PRD');
-- -- EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/master/project_files/silver/Views/Customer_Orders.sql USING (ENV => 'PRD');
-- -- EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/master/project_files/silver/Views/Product_Inventory.sql USING (ENV => 'PRD');

-- -- PROCEDURES
-- -- EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/master/project_files/bronze/Procedures/Load_Bronze_Customer_Orders.sql USING (ENV => 'PRD');