# CreatorAI — Architecture

## Overview

CreatorAI follows a clean, layered architecture optimized for small-team velocity and future scaling.

```
Flutter App → FastAPI Backend → Supabase (Auth + DB)
                    ↓
              LLM Provider (OpenAI / Anthropic)
                    ↓
              Instagram (Content Extraction)
```

## Layers

### Frontend (Flutter)
- **Screens** — Full-page views (Login, Home, Result, History, Settings)
- **Providers** — Riverpod StateNotifiers managing reactive state
- **Services** — HTTP client (ApiService), auth (AuthService), storage (StorageService)
- **Models** — Typed data classes mirroring API response schemas
- **Widgets** — Reusable UI components shared across screens

### Backend (FastAPI)
- **Routes** — Thin HTTP handlers that validate input and delegate to services
- **Services** — Business logic (AnalysisService orchestrates extraction + AI + persistence)
- **Models** — Pydantic schemas for request/response validation
- **Middleware** — Auth verification, rate limiting
- **Prompts** — LLM prompt templates separated from logic for easy iteration

### Data Flow

```
User Input → Flutter Provider → ApiService.post('/analyze')
                                       ↓
                              FastAPI Route (auth + validation)
                                       ↓
                              AnalysisService.analyze()
                                       ↓
                    ┌──────────────────┼──────────────────┐
                    ↓                  ↓                  ↓
            ContentExtractor      AIEngine          DatabaseService
            (URL → metadata)   (prompt → LLM)     (persist result)
                    ↓                  ↓                  ↓
              Instagram API     OpenAI/Anthropic      Supabase
```

## Design Principles

| Principle | Application |
|-----------|-------------|
| SOLID | Each service has a single responsibility; AI providers use interface abstraction |
| Separation of Concerns | Prompts separated from AI engine; routes separated from business logic |
| Dependency Injection | FastAPI `Depends()` for auth and settings; Riverpod for Flutter |
| Fail Gracefully | Custom error hierarchy with HTTP mapping; LLM fallback responses |
| Config as Code | All secrets via environment variables; no hardcoded keys |
