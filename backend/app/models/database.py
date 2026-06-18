"""
Database models — Supabase table definitions.
Used for documentation and type reference (Supabase manages the actual schema).
"""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class UserRecord(BaseModel):
    """Mirror of the users table in Supabase."""
    id: UUID
    email: str
    full_name: str | None = None
    avatar_url: str | None = None
    created_at: datetime
    updated_at: datetime | None = None


class AnalysisRecord(BaseModel):
    """Mirror of the analyses table in Supabase."""
    id: UUID
    user_id: UUID
    input_type: str
    input_content: str
    reel_url: str | None = None
    result: dict
    hook_score: int
    is_deleted: bool = False
    created_at: datetime
