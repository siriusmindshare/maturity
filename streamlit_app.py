import json
import requests
import streamlit as st

API_URL = "http://127.0.0.1:8000/chat"

st.set_page_config(page_title="Snowflake Chat", page_icon="💬", layout="centered")
st.title("💬 Snowflake Chat UI")

query = st.text_area(
    "Enter your question",
    value="questions about AI adoption stage and urgency",
    height=120,
)

top_k = st.number_input("Top K", min_value=1, max_value=20, value=5, step=1)

if st.button("Ask"):
    prompt_payload = {
        "query": query,
        "limit": top_k
    }

    request_body = {
        "prompt": json.dumps(prompt_payload),
        "top_k": top_k
    }

    st.subheader("Request Body")
    st.code(json.dumps(request_body, indent=2), language="json")

    try:
        response = requests.post(API_URL, json=request_body, timeout=120)

        st.subheader("Status Code")
        st.write(response.status_code)

        if response.ok:
            data = response.json()

            st.subheader("Answer")
            st.write(data.get("answer", "No answer returned"))

            matches = data.get("matches", [])
            if matches:
                st.subheader("Matches")
                for i, match in enumerate(matches, start=1):
                    with st.expander(f"Match {i}"):
                        st.json(match)
            else:
                st.info("No matches returned.")
        else:
            st.subheader("Error")
            st.code(response.text)

    except Exception as e:
        st.error(f"Request failed: {e}")