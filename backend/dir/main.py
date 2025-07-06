from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from textblob import TextBlob

app = FastAPI()

# Allow access from any origin (adjust if needed for production)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

class JournalEntry(BaseModel):
    text: str

@app.post("/analyze")
def analyze_sentiment(entry: JournalEntry):
    blob = TextBlob(entry.text)
    polarity = blob.sentiment.polarity
    sentiment = (
        "positive" if polarity > 0.2 else
        "negative" if polarity < -0.2 else
        "neutral"
    )
    return {"sentiment": sentiment, "polarity": polarity}
