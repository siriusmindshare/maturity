FROM python:3.11-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    STREAMLIT_SERVER_HEADLESS=true \
    STREAMLIT_SERVER_ADDRESS=0.0.0.0 \
    STREAMLIT_BROWSER_GATHER_USAGE_STATS=false

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /app/requirements.txt

RUN pip install --upgrade pip setuptools wheel && \
    pip install -r /app/requirements.txt

COPY app.py /app/app.py
COPY streamlit_app.py /app/streamlit_app.py
COPY start.sh /app/start.sh

RUN chmod +x /app/start.sh

EXPOSE 8000 8501

CMD ["/app/start.sh"]
