--------------------------------------------------------------------------------------------
--  SCRIPT:    Code from this script updates objects in Snowflake DEV account.
--             
--             
--
--   YY-MM-DD WHO          CHANGE DESCRIPTION
--   -------- ------------ -----------------------------------------------------------------

--------------------------------------------------------------------------------------------

-- TABLES
EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/dev/apps/bronze/Tables/Customer.sql USING (ENV => 'DEV');
EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/dev/apps/bronze/Tables/Orders.sql USING (ENV => 'DEV');
EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/dev/apps/bronze/Tables/Product.sql USING (ENV => 'DEV');
EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/dev/apps/silver/Tables/Customer.sql USING (ENV => 'DEV');
EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/dev/apps/silver/Tables/Orders.sql USING (ENV => 'DEV');
EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/dev/apps/silver/Tables/Product.sql USING (ENV => 'DEV');
EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/dev/apps/gold/Tables/Shipping.sql USING (ENV => 'DEV');
 
-- VIEWS
EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/dev/apps/bronze/Views/Customer_Orders.sql USING (ENV => 'DEV');
EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/dev/apps/silver/Views/Customer_Orders.sql USING (ENV => 'DEV');
EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/dev/apps/silver/Views/Product_Inventory.sql USING (ENV => 'DEV');

-- PROCEDURES
EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/dev/apps/bronze/Procedures/Load_Bronze_Customer_Orders.sql USING (ENV => 'DEV');