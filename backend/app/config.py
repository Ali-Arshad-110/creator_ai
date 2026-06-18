"""
Application configuration loaded from environment variables.
Uses pydantic-settings for validation and type safety.
"""

from functools import lru_cache
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings with environment variable binding."""

    # App
    app_name: str = "CreatorAI"
    app_version: str = "0.1.0"
    debug: bool = False
    environment: str = "development"

    # Server
    host: str = "0.0.0.0"
    port: int = 8000

    # Supabase
    supabase_url: str
    supabase_anon_key: str
    supabase_service_role_key: str
    supabase_jwt_secret: str

    # LLM
    llm_provider: str = "openai"  # openai | anthropic | gemini
    llm_api_key: str
    llm_model: str = "gpt-4o-mini"

    # Rate Limiting
    rate_limit_per_minute: int = 10
    rate_limit_per_day: int = 50

    # CORS
    cors_origins: list[str] = ["*"]

    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
        "case_sensitive": False,
    }


@lru_cache
def get_settings() -> Settings:
    """Cached settings instance — loaded once per process."""
    return Settings()
