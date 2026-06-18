"""
Health check endpoint — used by load balancers and monitoring.
"""

from fastapi import APIRouter

from app.config import get_settings

router = APIRouter()


@router.get("/health")
async def health_check():
    """Returns service status and version."""
    settings = get_settings()
    return {
        "status": "healthy",
        "version": settings.app_version,
        "service": settings.app_name,
    }
