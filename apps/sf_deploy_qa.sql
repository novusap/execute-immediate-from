--------------------------------------------------------------------------------------------
--  SCRIPT:    Code from this script updates objects in the QA_DB database 
--             in the QA Snowflake Account.
--             Confusing, yes. But We're really just testing builds accross accounts.
--
--   YY-MM-DD WHO          CHANGE DESCRIPTION
--   -------- ------------ -----------------------------------------------------------------

--------------------------------------------------------------------------------------------

-- TABLES
EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/qa/apps/bronze/Tables/Customer.sql USING (ENV => 'QA', TEST => 'TST');
EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/qa/apps/bronze/Tables/Orders.sql USING (ENV => 'QA');
EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/qa/apps/bronze/Tables/Product.sql USING (ENV => 'QA');
EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/qa/apps/silver/Tables/Customer.sql USING (ENV => 'QA');
EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/qa/apps/silver/Tables/Orders.sql USING (ENV => 'QA');
EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/qa/apps/silver/Tables/Product.sql USING (ENV => 'QA');
EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/qa/apps/gold/Tables/Shipping.sql USING (ENV => 'QA');
EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/qa/apps/gold/Tables/Customer.sql USING (ENV => 'QA');

-- VIEWS
EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/qa/apps/bronze/Views/Customer_Orders.sql USING (ENV => 'QA');
EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/qa/apps/silver/Views/Customer_Orders.sql USING (ENV => 'QA');
EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/qa/apps/silver/Views/Product_Inventory.sql USING (ENV => 'QA');

-- PROCEDURES
EXECUTE IMMEDIATE FROM @SNOWFLAKE_GIT_REPO/branches/qa/apps/bronze/Procedures/Load_Bronze_Customer_Orders.sql USING (ENV => 'QA');