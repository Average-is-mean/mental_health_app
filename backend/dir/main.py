from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from textblob import TextBlob
from google import genai
import os
from dotenv import load_dotenv
import json
import re
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer


# Load .env for Gemini API Key
load_dotenv()
client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))  # ✅ fixed


# FastAPI app
app = FastAPI()

# CORS middleware (important for Flutter frontend)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # or restrict to your frontend origin
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Input model
class JournalEntry(BaseModel):
    text: str


# Route: Enhanced Analyze
@app.post("/analyze")
async def analyze_sentiment(entry: JournalEntry):
    text = entry.text.strip()
     # 🐞 DEBUG: Print received journal text
    print(f"\n📩 Received journal entry: {text}\n")
    
    # Step 1: Basic Sentiment with TextBlob
    analyzer = SentimentIntensityAnalyzer()
    scores = analyzer.polarity_scores(text)
    polarity = scores["compound"]  # from -1 (neg) to +1 (pos)
    sentiment = (
        "positive" if polarity > 0.2 else
        "negative" if polarity < -0.2 else
        "neutral"
    )
    print(f"🧠 TextBlob Sentiment → polarity: {polarity}, sentiment: {sentiment}")  # 🐞 DEBUG

    # Step 2: Gemini AI - Smart Suggestions & Reflective Follow-up
    try:
        prompt = f"""
        Analyze the following journal entry for emotional tone and suggest personalized mental health recommendations.

        Journal Entry:
        \"\"\"{text}\"\"\"

        Respond with:
        1. A brief analysis of emotional state.
        2. 2-3 personalized physical habits or diet tips.
        3. Estimated time to spend daily on those habits.
        4. One thoughtful, reflective follow-up question.

        Output in JSON format like:
        {{
          "analysis": "...",
          "suggestions": ["...", "..."],
          "time_estimate": "...",
          "follow_up_question": "..."
        }}
        """

        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt
        )
        ai_data = response.text

        print(f"🧠 Gemini raw response:\n{ai_data}")  # 🐞 DEBUG


        # Try parsing manually if needed (Gemini sometimes responds as Markdown-like text)
        
        json_text = re.search(r"\{[\s\S]+\}", ai_data)
        if json_text:
            suggestions = json.loads(json_text.group())
        else:
            print("⚠️ Could not extract JSON from Gemini response.")  # 🐞 DEBUG
            suggestions = {
                "analysis": "Could not parse Gemini response.",
                "suggestions": [],
                "time_estimate": "",
                "follow_up_question": ""
            }

    except Exception as e:
        print("❌ Gemini Error:", e)  # 🐞 DEBUG
        suggestions = {
            "analysis": "AI suggestion unavailable due to error.",
            "suggestions": [],
            "time_estimate": "",
            "follow_up_question": ""
        }
    # 🐞 DEBUG: Final API response
    print("✅ Returning response:")
    print(json.dumps({
        "sentiment": sentiment,
        "polarity": polarity,
        "ai_analysis": suggestions
    }, indent=2))

    return {
        "sentiment": sentiment,
        "polarity": polarity,
        "ai_analysis": suggestions
    }
