# 🚀 Snowflake Cortex Chat App (FastAPI + Streamlit)

This project provides a lightweight **AI-powered chat application** using:

- ❄️ Snowflake Cortex (Search + AI_COMPLETE)
- ⚡ FastAPI (backend API)
- 🎨 Streamlit (UI frontend)

---

## 📁 Project Structure

```
maturity/
│
├── app.py               # FastAPI backend
├── streamlit_app.py    # Streamlit UI
├── test.py             # Testing scripts (optional)
├── requirements.txt    # Dependencies
├── .env                # Environment variables
├── maturity/           # Python virtual environment
└── __pycache__/        # Auto-generated
```

---

## 🧱 1. Setup Virtual Environment

### Create environment

```
python3.11 -m venv maturity
```

### Activate environment

```
source maturity/bin/activate
```

---

## 📦 2. Install Dependencies

```
pip install --upgrade pip
pip install -r requirements.txt
```

### If no requirements.txt:

```
pip install fastapi uvicorn streamlit requests snowflake-connector-python python-dotenv
```

---

## 🔐 3. Configure Environment Variables

Create a `.env` file in the root directory:

```
SNOWFLAKE_USER=your_user
SNOWFLAKE_PASSWORD=your_password
SNOWFLAKE_ACCOUNT=your_account   # e.g. xy12345.us-east-1
SNOWFLAKE_WAREHOUSE=your_wh
SNOWFLAKE_ROLE=your_role
```

---

## ▶️ 4. Run FastAPI Backend

```
python -m uvicorn app:app --reload
```

### Access API

- Swagger UI: http://127.0.0.1:8000/docs
- Endpoint: POST /chat

---

## 🧪 Test API (curl)

```
curl -X POST "http://127.0.0.1:8000/chat"   -H "Content-Type: application/json"   -d '{
    "prompt": "Urgency for AI impact",
    "top_k": 5
  }'
```

---

## 🎨 5. Run Streamlit UI

```
streamlit run streamlit_app.py
```

### Access UI

http://localhost:8501

---

## 🧠 How It Works

1. User enters query in Streamlit  
2. Request sent to FastAPI `/chat`  
3. FastAPI:
   - Calls `SNOWFLAKE.CORTEX.SEARCH_PREVIEW`
   - Retrieves relevant rows
   - Sends context to `AI_COMPLETE`  
4. Returns:
   - AI-generated answer
   - Matching records  

---

## ⚠️ Troubleshooting

### ❌ uvicorn: command not found
```
pip install uvicorn
```

### ❌ streamlit: command not found
```
pip install streamlit
```

### ❌ pyarrow build error
```
pip install pyarrow --only-binary :all:
```

### ❌ Snowflake model error (region)

Enable cross-region inference:

```
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';
```

### ❌ No results from search

Use JSON payload:

```
{
  "query": "Urgency for AI impact",
  "limit": 5
}
```

---

## 🧹 Deactivate Environment

```
deactivate
```

---

## 🚀 Future Improvements

- Chat history (memory)  
- Streaming responses  
- Deployment (Docker / AWS / GCP)  
- Replace SEARCH_PREVIEW with production search API  
- UI enhancements (chat bubbles)  

---

## 👤 Author

Venkata Duvvuri  
AI/ML | Snowflake Cortex | Applied AI Systems  

---

## 📄 License

MIT License
