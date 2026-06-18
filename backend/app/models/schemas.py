"""
Pydantic schemas for request/response validation.
Single source of truth for API data contracts.
"""

from datetime import datetime
from enum import Enum
from uuid import UUID

from pydantic import BaseModel, Field, HttpUrl, field_validator


class InputType(str, Enum):
    """Content input method."""
    URL = "url"
    TEXT = "text"


# ── Request Schemas ──────────────────────────────────────────────


class AnalysisRequest(BaseModel):
    """POST /analyze request body."""
    input_type: InputType
    content: str = Field(
        ...,
        min_length=1,
        max_length=5000,
        description="Instagram Reel URL or raw text content to analyze.",
    )

    @field_validator("content")
    @classmethod
    def validate_content(cls, v: str, info) -> str:
        v = v.strip()
        if not v:
            raise ValueError("Content cannot be empty.")

        # If URL type, validate it looks like an Instagram URL
        if info.data.get("input_type") == InputType.URL:
            if "instagram.com" not in v.lower():
                raise ValueError(
                    "URL must be a valid Instagram link."
                )
        return v


# ── Response Schemas ─────────────────────────────────────────────


class AnalysisResponse(BaseModel):
    """Structured AI analysis result."""
    id: UUID
    hook_score: int = Field(..., ge=0, le=10, description="Hook effectiveness 0-10")
    engagement_prediction: str
    retention_prediction: str
    strengths: list[str]
    weaknesses: list[str]
    audience_fit: str
    improvement_suggestions: list[str]
    content_ideas: list[str]
    caption_suggestions: list[str]
    created_at: datetime


class AnalysisListItem(BaseModel):
    """Compact analysis for history list view."""
    id: UUID
    input_type: InputType
    input_content: str = Field(..., max_length=200)
    hook_score: int
    created_at: datetime


class AnalysisListResponse(BaseModel):
    """Paginated history response."""
    items: list[AnalysisListItem]
    total: int
    page: int
    limit: int
    has_more: bool


# ── Error Schemas ────────────────────────────────────────────────


class ErrorResponse(BaseModel):
    """Standard error response."""
    detail: str
    error_code: str | None = None


# ── Profile Analytics Schemas ─────────────────────────────────────


class ProfileAnalyzeRequest(BaseModel):
    """POST /profile/analyze request body."""
    username: str = Field(
        ...,
        min_length=1,
        max_length=100,
        pattern=r"^@?[a-zA-Z0-9_\.]+$",
        description="Instagram username to search and analyze."
    )

    @field_validator("username")
    @classmethod
    def clean_username(cls, v: str) -> str:
        v = v.strip().replace("@", "").lower()
        if not v:
            raise ValueError("Username cannot be empty.")
        return v


class ProfileMetricsResponse(BaseModel):
    """Nested metrics fields inside ProfileAnalysisResponse."""
    engagement_rate: float
    average_likes: float
    average_comments: float
    posting_frequency: float
    audience_quality_score: int
    growth_estimation: float
    is_estimated: bool
    strengths: list[str]
    weaknesses: list[str]


class ProfileAnalysisResponse(BaseModel):
    """Full detail of profile analysis results."""
    id: UUID
    username: str
    full_name: str | None = None
    avatar_url: str | None = None
    followers_count: int
    following_count: int
    posts_count: int
    biography: str | None = None
    external_url: str | None = None
    metrics: ProfileMetricsResponse
    updated_at: datetime


class ProfileAnalysisListItem(BaseModel):
    """Simplified list item for profile history searches."""
    id: UUID
    username: str
    full_name: str | None = None
    avatar_url: str | None = None
    followers_count: int
    engagement_rate: float
    created_at: datetime


class ProfileAnalysisListResponse(BaseModel):
    """Paginated search history for profile audits."""
    items: list[ProfileAnalysisListItem]
    total: int
    page: int
    limit: int
    has_more: bool


class ProfileSearchSuggestion(BaseModel):
    """Instagram search autocomplete suggestion."""
    username: str
    full_name: str | None = None
    avatar_url: str | None = None


class ProfileSearchSuggestionList(BaseModel):
    """List of suggestions."""
    suggestions: list[ProfileSearchSuggestion]

