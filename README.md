# 🧠 MindMate – Your Mental Health Companion App

MindMate is a Flutter-based mental wellness app powered by AI. It allows users to track their mood, journal feelings, and receive personalized mental health suggestions via the Gemini 2.5 Flash AI model.

## ✨ Features

- 🎭 Daily Mood Tracking
- 📓 Smart Journaling with AI Feedback
- 🤖 Sentiment Analysis (via VADER)
- 🧘 Personalized Activity Suggestions
- 💬 Reflective Follow-up Questions
- 🔔 Daily Mood Reminders (Flutter Local Notifications)
- 📊 Mood History & AI Analysis Dashboard
- 🔒 Firebase Auth (Google Sign-In)
- 📦 Offline Storage (Hive)
- 🚀 Gemini 2.5 Flash Integration via FastAPI

---

## 🛠 Tech Stack

| Area         | Stack                            |
|--------------|----------------------------------|
| Frontend     | Flutter                          |
| Backend      | FastAPI (Python)                 |
| AI           | Google Gemini 2.5 Flash (via `google.generativeai`) |
| Sentiment    | VADER Sentiment Analysis         |
| Auth         | Firebase Google Sign-In          |
| Storage      | Hive (local), Shared Preferences |
| Notifications| flutter_local_notifications      |

---



## 🚀 How to Run

### 🔧 Backend

1. Install requirements:
   ```bash
   pip install -r requirements.txt

# Add your Google Gemini API key to .env:
    GEMINI_API_KEY=your_key_here
#Start FastAPI server:
    uvicorn main:app --reload

### Flutter App

1. Run the App:
    flutter pub get
    flutter run

2. Build APK:
    flutter build apk --release

## 📄 License

This project is licensed under the [MIT License](LICENSE).


🙌 Author
Built with ❤️ by Abhinav


