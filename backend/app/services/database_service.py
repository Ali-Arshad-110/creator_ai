"""
Database service — Supabase client wrapper.
Handles JWT verification and all database operations.
"""

import logging
import asyncio

import jwt
from supabase import create_client, Client

from app.config import Settings

logger = logging.getLogger("creatorai")


class DatabaseService:
    """
    Supabase interaction layer.
    Wraps the Supabase Python client for auth verification + CRUD operations.
    """

    def __init__(self, settings: Settings):
        self.supabase_url = settings.supabase_url
        self.supabase_key = settings.supabase_service_role_key
        self.jwt_secret = settings.supabase_jwt_secret
        self._client: Client | None = None

    @property
    def client(self) -> Client:
        """Lazy-initialized Supabase client using service_role key (bypasses RLS)."""
        if self._client is None:
            self._client = create_client(self.supabase_url, self.supabase_key)
        return self._client

    async def verify_token(self, token: str) -> dict | None:
        """
        Verify a Supabase-issued JWT and return user claims.

        Supabase JWTs (whether from email/password or Clerk OAuth) are all signed
        with the same project JWT secret. We decode and validate here.

        Returns:
            dict with user info (sub, email, role) if valid.
            None if token is invalid, expired, or malformed.
        """
        try:
            payload = jwt.decode(
                token,
                self.jwt_secret,
                algorithms=["HS256"],
                audience="authenticated",
            )

            user_id = payload.get("sub")
            if not user_id:
                logger.warning("JWT missing 'sub' claim")
                return None

            # Extract user metadata from Supabase JWT claims
            user_metadata = payload.get("user_metadata", {})

            return {
                "id": user_id,
                "email": payload.get("email", ""),
                "full_name": user_metadata.get("full_name") or user_metadata.get("name", ""),
                "avatar_url": user_metadata.get("avatar_url") or user_metadata.get("picture", ""),
                "role": payload.get("role", "authenticated"),
            }

        except jwt.ExpiredSignatureError:
            logger.warning("JWT expired")
            return None
        except jwt.InvalidAudienceError:
            logger.warning("JWT has invalid audience")
            return None
        except jwt.DecodeError as e:
            logger.warning(f"JWT decode failed: {e}")
            return None
        except Exception as e:
            logger.error(f"Unexpected JWT verification error: {e}")
            return None

    async def upsert_user(self, user_data: dict) -> dict:
        """
        Create or update user in the users table on first authenticated request.
        Uses service_role key so RLS is bypassed.
        """
        try:
            def _execute():
                return (
                    self.client.table("users")
                    .upsert(
                        {
                            "id": user_data["id"],
                            "email": user_data["email"],
                            "full_name": user_data.get("full_name", ""),
                            "avatar_url": user_data.get("avatar_url", ""),
                        },
                        on_conflict="id",
                    )
                    .execute()
                )
            result = await asyncio.to_thread(_execute)
            return result.data[0] if result.data else user_data
        except Exception as e:
            logger.error(f"Failed to upsert user: {e}")
            # Non-fatal — user can still use the API even if profile sync fails
            return user_data

    async def save_analysis(self, user_id: str, analysis_data: dict) -> dict:
        """Persist an analysis result."""
        try:
            def _execute():
                return self.client.table("analyses").insert(analysis_data).execute()
            result = await asyncio.to_thread(_execute)
            return result.data[0] if result.data else {}
        except Exception as e:
            logger.error(f"Failed to save analysis in DB: {e}")
            raise

    async def get_analyses(
        self,
        user_id: str,
        page: int = 1,
        limit: int = 20,
    ) -> tuple[list[dict], int]:
        """Fetch paginated analysis history."""
        try:
            start = (page - 1) * limit
            end = start + limit - 1

            def _execute():
                return (
                    self.client.table("analyses")
                    .select("id, input_type, input_content, hook_score, created_at", count="exact")
                    .eq("user_id", user_id)
                    .eq("is_deleted", False)
                    .order("created_at", desc=True)
                    .range(start, end)
                    .execute()
                )
            result = await asyncio.to_thread(_execute)
            items = result.data if result.data else []
            total = result.count if result.count is not None else len(items)
            return items, total
        except Exception as e:
            logger.error(f"Failed to fetch analyses: {e}")
            return [], 0

    async def get_analysis_by_id(self, analysis_id: str, user_id: str) -> dict | None:
        """Fetch single analysis."""
        try:
            def _execute():
                return (
                    self.client.table("analyses")
                    .select("*")
                    .eq("id", analysis_id)
                    .eq("user_id", user_id)
                    .eq("is_deleted", False)
                    .execute()
                )
            result = await asyncio.to_thread(_execute)
            return result.data[0] if result.data else None
        except Exception as e:
            logger.error(f"Failed to fetch analysis {analysis_id}: {e}")
            return None

    async def soft_delete_analysis(self, analysis_id: str, user_id: str) -> bool:
        """Soft-delete an analysis."""
        try:
            def _execute():
                return (
                    self.client.table("analyses")
                    .update({"is_deleted": True})
                    .eq("id", analysis_id)
                    .eq("user_id", user_id)
                    .execute()
                )
            result = await asyncio.to_thread(_execute)
            return len(result.data) > 0 if result.data else False
        except Exception as e:
            logger.error(f"Failed to delete analysis {analysis_id}: {e}")
            return False
