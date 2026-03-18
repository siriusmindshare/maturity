# app.py
import os
import json
import snowflake.connector
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()
from dotenv import load_dotenv
load_dotenv()

class ChatRequest(BaseModel):
    prompt: str
    top_k: int = 5

def get_conn():
    return snowflake.connector.connect(
        user=os.getenv("SNOWFLAKE_USER"),
        password=os.getenv("SNOWFLAKE_PASSWORD"),
        account=os.getenv("SNOWFLAKE_ACCOUNT"),
        warehouse=os.getenv("SNOWFLAKE_WAREHOUSE"),
        database="SNOWFLAKE_LEARNING_DB",
        schema="CORTEX_APP",
        role=os.getenv("SNOWFLAKE_ROLE"),
    )
import json
import re

def parse_snowflake_result(row):
    # Step 1: extract JSON string from tuple
    raw_json_str = row[0]

    # Step 2: convert string → dict
    data = json.loads(raw_json_str)

    parsed_results = []

    for r in data.get("results", []):
        text = r.get("SEARCH_TEXT", "")

        # Step 3: extract fields using regex
        def extract(pattern):
            match = re.search(pattern, text)
            return match.group(1).strip() if match else ""

        parsed = {
            "section": extract(r"Section:\s*(.*)"),
            "question": extract(r"Question:\s*(.*)"),
            "selected_choice": extract(r"Selected Choice:\s*(.*)"),
            "maturity_rating": extract(r"Maturity Rating:\s*(.*)"),
            "description": extract(r"Description:\s*(.*)")
        }

        parsed_results.append(parsed)

    # Step 4: build final JSON response
    return {
        "request_id": data.get("request_id"),
        "results": parsed_results
    }


@app.post("/chat")
def chat(req: ChatRequest):
    conn = get_conn()
    cur = conn.cursor()

        # Accept either plain text prompt or JSON string inside prompt
 
    # Accept either:
    # 1) plain text prompt, or
    # 2) JSON string like {"query":"...", "limit":5}
    search_query = req.prompt
    limit = req.top_k

    try:
        parsed = json.loads(req.prompt)
        if isinstance(parsed, dict):
            search_query = parsed.get("query", req.prompt)
            limit = int(parsed.get("limit", req.top_k))
    except Exception:
        pass

    search_payload = {
        "query": search_query,
        "limit": limit
    }

    # search_sql = f"""
    # SELECT PARSE_JSON(
    #   SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
    #     'QUESTION_CHAT_SVC',
    #     $$ {json.dumps(search_payload)} $$
    #   )
    # ) AS RESULT_JSON
    # """

    search_sql = """
SELECT PARSE_JSON(
  SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
    'QUESTION_CHAT_SVC',
    '{
      "query": "Urgency for AI impact",
      "limit": 5
    }'
  )
) AS RESULT_JSON
"""
    cur.execute(search_sql)
    row = cur.fetchone()
    print(row)
   
    result_json = row[0]

    parsed_output = parse_snowflake_result(row)
    answer = parsed_output['results']

    print(json.dumps(parsed_output, indent=2))
    hits = result_json.get("results", []) if isinstance(result_json, dict) else []


    cur.close()
    conn.close()

    return {
        "answer": answer,
        "matches": hits
    }