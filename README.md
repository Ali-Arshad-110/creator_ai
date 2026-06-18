# CreatorAI

Understand why content works. An AI-powered application for Instagram creators to turn content into actionable growth insights in under 30 seconds.

## Project Structure

- `/backend`: FastAPI service for handling auth integration, scraping/metadata extraction, rate-limiting, and AI prompt composition/execution.
- `/frontend`: Flutter mobile application providing an intuitive, fast, and modern interface for submitting Reels and reviewing history.
- `/docs`: Architectural decisions, API specifications, and deployment documentation.

## Tech Stack

- **Frontend:** Flutter
- **Backend:** FastAPI
- **Database:** Supabase (Auth + DB)
- **AI Engine:** Structured LLM calls (OpenAI/Anthropic/Gemini)

## Setup & Running

Please refer to the README files in individual folders for setup guides:
- [Backend Setup & Run](./backend/README.md)
- [Frontend Setup & Run](./frontend/README.md)
