"""
Rate limiter middleware — prevents abuse of analysis endpoint.
Uses in-memory storage for MVP; upgrade to Redis for production scale.
"""

import time
from collections import defaultdict

from fastapi import Request, status
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware

from app.config import get_settings


class RateLimitMiddleware(BaseHTTPMiddleware):
    """
    Simple token-bucket rate limiter.
    Tracks requests per IP per minute.

    Limitations (acceptable for MVP):
    - In-memory store (lost on restart)
    - Per-instance (not shared across workers)

    Upgrade path: Redis-based rate limiting.
    """

    def __init__(self, app):
        super().__init__(app)
        self.requests: dict[str, list[float]] = defaultdict(list)

    async def dispatch(self, request: Request, call_next):
        # Only rate-limit the analysis endpoint
        if request.url.path != "/api/v1/analyze":
            return await call_next(request)

        settings = get_settings()
        client_ip = request.client.host if request.client else "unknown"
        now = time.time()
        window = 60.0  # 1 minute

        # Clean old entries
        self.requests[client_ip] = [
            t for t in self.requests[client_ip]
            if now - t < window
        ]

        if len(self.requests[client_ip]) >= settings.rate_limit_per_minute:
            return JSONResponse(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                content={
                    "detail": "Rate limit exceeded. Please wait before making another request."
                },
            )

        self.requests[client_ip].append(now)
        return await call_next(request)
