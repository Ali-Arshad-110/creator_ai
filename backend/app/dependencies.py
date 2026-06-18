"""
FastAPI dependency injection — shared dependencies for routes.
"""

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.config import Settings, get_settings

security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    settings: Settings = Depends(get_settings),
) -> dict:
    """
    Verify Supabase JWT and return the authenticated user.
    Also upserts user profile to Supabase on each request (idempotent).
    Raises 401 if token is invalid or expired.
    """
    from app.services.database_service import DatabaseService

    token = credentials.credentials
    db = DatabaseService(settings)

    user = await db.verify_token(token)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired authentication token.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Sync user profile to Supabase users table (non-blocking, non-fatal)
    await db.upsert_user(user)

    return user
