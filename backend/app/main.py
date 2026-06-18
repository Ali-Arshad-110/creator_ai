"""
CreatorAI API — FastAPI application entry point.
"""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.middleware.rate_limiter import RateLimitMiddleware
from app.routes import analysis, health, history, profile
from app.utils.logger import setup_logger


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifecycle: startup and shutdown hooks."""
    logger = setup_logger()
    logger.info("CreatorAI API starting up...")
    yield
    logger.info("CreatorAI API shutting down...")


def create_app() -> FastAPI:
    """Application factory — creates and configures the FastAPI instance."""
    settings = get_settings()

    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        description="AI-powered content analysis for Instagram creators.",
        docs_url="/docs" if settings.debug else None,
        redoc_url="/redoc" if settings.debug else None,
        lifespan=lifespan,
    )

    # CORS
    cors_args = {
        "allow_credentials": True,
        "allow_methods": ["*"],
        "allow_headers": ["*"],
    }
    if "*" in settings.cors_origins:
        cors_args["allow_origin_regex"] = r"https?://.*"
    else:
        cors_args["allow_origins"] = settings.cors_origins

    app.add_middleware(CORSMiddleware, **cors_args)

    # Rate Limiting
    app.add_middleware(RateLimitMiddleware)

    # Routes
    app.include_router(health.router, tags=["Health"])
    app.include_router(
        analysis.router,
        prefix="/api/v1",
        tags=["Analysis"],
    )
    app.include_router(
        history.router,
        prefix="/api/v1",
        tags=["History"],
    )
    app.include_router(
        profile.router,
        prefix="/api/v1",
        tags=["Profile"],
    )

    return app


app = create_app()
