-- Change as need to point to your Github UserName, URL, and Personal Access Token
USE ROLE ACCOUNTADMIN;
USE DATABASE ADM_CONTROL_DB;
USE SCHEMA DEPLOY;
CREATE OR REPLACE USER SVC_DEPLOY
PASSWORD = 'YOUR SF PWD'
DEFAULT_ROLE = ACCOUNTADMIN;
GRANT ROLE ACCOUNTADMIN TO USER SVC_DEPLOY;
CREATE OR REPLACE SECRET GITHUB_SECRET
	TYPE = PASSWORD
	USERNAME = 'YOUR UID' 
	PASSWORD = 'YOUR_PAT' 
 
CREATE OR REPLACE API INTEGRATION GITHUB_API_INTEGRATION
	API_PROVIDER = GIT_HTTPS_API
	API_ALLOWED_PREFIXES = ('https://github.com/mtacker')
	ALLOWED_AUTHENTICATION_SECRETS = (GITHUB_SECRET)
	ENABLED = TRUE;

CREATE OR REPLACE GIT REPOSITORY SNOWFLAKE_GIT_REPO
	API_INTEGRATION = GITHUB_API_INTEGRATION
	GIT_CREDENTIALS = GITHUB_SECRET
	ORIGIN = 'https://github.com/mtacker/execute-immediate-from';