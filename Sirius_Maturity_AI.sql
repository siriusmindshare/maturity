

---> set the Role
USE ROLE SNOWFLAKE_LEARNING_ROLE;

---> set the Warehouse
USE WAREHOUSE SNOWFLAKE_LEARNING_WH;

---> set the Database
USE DATABASE SNOWFLAKE_LEARNING_DB;

---> set the Schema
SET schema_name = CONCAT(current_user(), '_LOAD_SAMPLE_DATA_FROM_S3');
USE SCHEMA IDENTIFIER($schema_name);

-------------------------------------------------------------------------------------------
    -- Step 2: With context in place, let's now create a Table
        -- CREATE TABLE: https://docs.snowflake.com/en/sql-reference/sql/create-table -- not necessary
-----------------------------------------------------------------------------------------

-- 1. Create database/schema
---> set the Role
USE ROLE SNOWFLAKE_LEARNING_ROLE;

---> set the Warehouse
USE WAREHOUSE SNOWFLAKE_LEARNING_WH;

---> set the Database
USE DATABASE SNOWFLAKE_LEARNING_DB;
CREATE OR REPLACE SCHEMA SNOWFLAKE_LEARNING_DB.CORTEX_APP;

USE SCHEMA CORTEX_APP;

-- 2. File format for CSV
CREATE OR REPLACE FILE FORMAT CSV_FMT
  TYPE = CSV
  SKIP_HEADER = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  NULL_IF = ('NULL', 'null', '');

-- 3. Internal stage
CREATE OR REPLACE STAGE CSV_STAGE
  FILE_FORMAT = CSV_FMT;

-- 4. Upload your local file from Snowsight or SnowSQL:
--PUT file:///Users/yourname/Downloads/45_Question_table_Sheet1.csv @CSV_STAGE --AUTO_COMPRESS=FALSE OVERWRITE=TRUE;


-------------------------------------------------------------------------------------------
    -- Step 3: To connect to the Blob Storage, let's create a Stage
        -- Creating an S3 Stage: https://docs.snowflake.com/en/user-guide/data-load-s3-create-stage
-------------------------------------------------------------------------------------------

--CREATE OR REPLACE STAGE blob_stage
--url = 's3://sfquickstarts/tastybytes/'
--file_format = (type = csv);

---> query the Stage to find the Menu CSV file
--LIST @blob_stage/raw_pos/menu/;


-------------------------------------------------------------------------------------------
    -- Step 4: Now let's Load the Menu CSV file from the Stage
        -- COPY INTO <table>: https://docs.snowflake.com/en/sql-reference/sql/copy-into-table
-------------------------------------------------------------------------------------------

---> copy the Menu file into the Menu table
--COPY INTO menu
--FROM @blob_stage/raw_pos/menu/;

-- 5. Target table
CREATE OR REPLACE TABLE QUESTION_BANK (
    NUM NUMBER,
    SECTION STRING,
    QUESTION STRING,
    OPTION_A STRING,
    OPTION_B STRING,
    OPTION_C STRING,
    OPTION_D STRING,
    OPTION_E STRING,
    CHOICE STRING,
    MATURITY_RATING FLOAT,
    DESCRIPTION STRING
);

-- 6. Load CSV
COPY INTO QUESTION_BANK
FROM (
    SELECT
      $1::NUMBER,
      $2::STRING,
      $3::STRING,
      $4::STRING,
      $5::STRING,
      $6::STRING,
      $7::STRING,
      $8::STRING,
      $9::STRING,
      TRY_TO_NUMBER($10),   -- ✅ FIX HERE
      $11::STRING
    FROM @CSV_STAGE/45_Question_table_Sheet1.csv
)
FILE_FORMAT = (FORMAT_NAME = CSV_FMT);

-- 7. Create a single searchable text field
CREATE OR REPLACE VIEW QUESTION_BANK_SEARCH_V AS
SELECT
    NUM,
    SECTION,
    QUESTION,
    OPTION_A,
    OPTION_B,
    OPTION_C,
    OPTION_D,
    OPTION_E,
    CHOICE,
    MATURITY_RATING,
    DESCRIPTION,
    CONCAT(
      'Section: ', COALESCE(SECTION,''), '\n',
      'Question: ', COALESCE(QUESTION,''), '\n',
      'Option A: ', COALESCE(OPTION_A,''), '\n',
      'Option B: ', COALESCE(OPTION_B,''), '\n',
      'Option C: ', COALESCE(OPTION_C,''), '\n',
      'Option D: ', COALESCE(OPTION_D,''), '\n',
      'Option E: ', COALESCE(OPTION_E,''), '\n',
      'Selected Choice: ', COALESCE(CHOICE,''), '\n',
      'Maturity Rating: ', COALESCE(TO_VARCHAR(MATURITY_RATING),''), '\n',
      'Description: ', COALESCE(DESCRIPTION,'')
    ) AS SEARCH_TEXT
FROM QUESTION_BANK;





-------------------------------------------------------------------------------------------
    -- Step 5: Query the Menu table
        -- SELECT: https://docs.snowflake.com/en/sql-reference/sql/select
        -- TOP <n>: https://docs.snowflake.com/en/sql-reference/constructs/top_n
        -- FLATTEN: https://docs.snowflake.com/en/sql-reference/functions/flatten
-------------------------------------------------------------------------------------------


CREATE OR REPLACE CORTEX SEARCH SERVICE QUESTION_CHAT_SVC
ON SEARCH_TEXT
ATTRIBUTES SECTION, CHOICE, MATURITY_RATING, NUM
WAREHOUSE = SNOWFLAKE_LEARNING_WH
TARGET_LAG = '1 hour'
AS (
    SELECT
      NUM,
      SECTION,
      CHOICE,
      MATURITY_RATING,
      SEARCH_TEXT
    FROM QUESTION_BANK_SEARCH_V
);


DESCRIBE CORTEX SEARCH SERVICE QUESTION_CHAT_SVC;


{"results":[{"@scores":{"text_match":1.0024438,"cosine_similarity":0.64163435,"reranker_score":3.9563222},"SEARCH_TEXT":"Section: Section0: Organization Context\nQuestion: Urgency for AI impact\nOption A: No urgency\nOption B: 12+ months\nOption C: 6–12 months\nOption D: 3–6 months\nOption E: Immediate / critical\nSelected Choice: C\nMaturity Rating: 3\nDescription: While AI impact is not mission-critical in the immediate term, there is a clear expectation that AI-driven efficiency gains will be important within the next 6–12 months."},{"@scores":{"text_match":2.1934002E-7,"cosine_similarity":0.400863,"reranker_score":-9.253711},"SEARCH_TEXT":"Section: Section0: Organization Context\nQuestion: Primary motivation for AI adoption\nOption A: Exploration / curiosity\nOption B: Cost reduction\nOption C: Productivity improvement\nOption D: Revenue growth\nOption E: Competitive differentiation\nSelected Choice: C\nMaturity Rating: 2\nDescription: AI is primarily adopted to improve developer productivity, especially by accelerating coding, debugging, and documentation tasks rather than driving new AI-based products or revenue streams."},{"@scores":{"text_match":1.6844868E-7,"cosine_similarity":0.34538084,"reranker_score":-8.6353245},"SEARCH_TEXT":"Section: Section K: Change Management & Organizational Design\nQuestion: How is employee anxiety regarding AI driven job displacement managed?\nOption A: Ignored or dismissed\nOption B: Reactive reassurances\nOption C: Leadership communication focusing on AI as augmentation\nOption D: Formal change management and transition plans\nOption E: Proactive job redesign with guaranteed upskilling\nSelected Choice: \nMaturity Rating: \nDescription: "},{"@scores":{"text_match":1.7370765E-7,"cosine_similarity":0.4017353,"reranker_score":-10.747576},"SEARCH_TEXT":"Section: Section M: Advanced Data Management (GenAI Focus)\nQuestion: How frequently is enterprise data vectorized and updated for AI search?\nOption A: Static/one off extraction\nOption B: Manual periodic batch updates\nOption C: Automated scheduled batch updates\nOption D: Event driven near real time indexing\nOption E: Continuous real time dynamic streaming updates\nSelected Choice: \nMaturity Rating: \nDescription: "},{"@scores":{"text_match":1.751155E-7,"cosine_similarity":0.3486958,"reranker_score":-9.310249},"SEARCH_TEXT":"Section: Section H: Strategy, Visibility & Value\nQuestion: How central is AI to long-term competitive strategy?\nOption A: Opportunistic\nOption B: Experimental\nOption C: Annual planning\nOption D: Multi-year strategy\nOption E: Core differentiation\nSelected Choice: B\nMaturity Rating: 2\nDescription: AI is viewed as an important experimental capability for improving efficiency rather than a core long-term competitive differentiator."}],"request_id":"ae3fe4c1-a0c8-4703-ab92-39926c13c4f8"}
SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
  'QUESTION_CHAT_SVC',
  '{
    "query": "Urgency for AI impact",
    "limit": 5
  }'
);

SELECT PARSE_JSON(
  SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
    'QUESTION_CHAT_SVC',
    '{
      "query": "Urgency for AI impact",
      "limit": 5
    }'
  )
) AS RESULT_JSON;

ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';