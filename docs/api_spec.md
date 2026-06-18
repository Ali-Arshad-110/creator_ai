# CreatorAI — API Specification

Base URL: `http://localhost:8000` (dev) / `https://api.creatorai.app` (prod)

All protected endpoints require `Authorization: Bearer <supabase_jwt>`.

---

## Health

### `GET /health`
**Auth:** None

**Response (200):**
```json
{
  "status": "healthy",
  "version": "0.1.0",
  "service": "CreatorAI"
}
```

---

## Analysis

### `POST /api/v1/analyze`
**Auth:** Required

**Request:**
```json
{
  "input_type": "url",
  "content": "https://www.instagram.com/reel/ABC123/"
}
```

| Field | Type | Rules |
|-------|------|-------|
| `input_type` | `"url"` or `"text"` | Required |
| `content` | string | 1-5000 chars. If `url`, must contain `instagram.com` |

**Response (200):**
```json
{
  "id": "uuid",
  "hook_score": 8,
  "engagement_prediction": "High — strong opening hook",
  "retention_prediction": "Medium — pacing drops mid-reel",
  "strengths": ["Strong visual hook", "Trending hashtags"],
  "weaknesses": ["Caption lacks CTA", "No story arc"],
  "audience_fit": "Growth/motivation niche, 18-34",
  "improvement_suggestions": ["Add question-based CTA"],
  "content_ideas": ["Behind-the-scenes process"],
  "caption_suggestions": ["Stop scrolling if you want to grow 👇"],
  "created_at": "2026-06-17T12:00:00Z"
}
```

**Errors:**
| Code | Detail |
|------|--------|
| 400 | Invalid input |
| 401 | Missing/invalid auth token |
| 422 | Content extraction failed |
| 429 | Rate limit exceeded |
| 502 | AI analysis failed |

---

## History

### `GET /api/v1/analyses`
**Auth:** Required

**Query params:** `page` (default: 1), `limit` (default: 20)

**Response (200):**
```json
{
  "items": [
    {
      "id": "uuid",
      "input_type": "url",
      "input_content": "https://instagram.com/reel/...",
      "hook_score": 8,
      "created_at": "2026-06-17T12:00:00Z"
    }
  ],
  "total": 42,
  "page": 1,
  "limit": 20,
  "has_more": true
}
```

### `GET /api/v1/analyses/{id}`
**Auth:** Required — returns 404 if analysis belongs to another user.

### `DELETE /api/v1/analyses/{id}`
**Auth:** Required — soft-delete, returns 204.

---

## Rate Limits

| Endpoint | Limit |
|----------|-------|
| `POST /api/v1/analyze` | 10/min, 50/day per user |
| All other endpoints | No limit |
