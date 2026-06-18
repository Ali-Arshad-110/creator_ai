"""
Analysis routes — content submission and AI analysis.
"""

import logging

from fastapi import APIRouter, Depends, HTTPException, status

from app.config import Settings, get_settings
from app.dependencies import get_current_user
from app.models.schemas import AnalysisRequest, AnalysisResponse
from app.services.analysis_service import AnalysisService
from app.utils.errors import AppError, app_error_to_http

logger = logging.getLogger("creatorai")

router = APIRouter()


@router.post(
    "/analyze",
    response_model=AnalysisResponse,
    status_code=status.HTTP_200_OK,
    summary="Analyze Instagram content",
    description="Submit a reel URL or text content for AI-powered analysis.",
)
async def analyze_content(
    request: AnalysisRequest,
    user: dict = Depends(get_current_user),
    settings: Settings = Depends(get_settings),
):
    """
    Core analysis endpoint.
    Accepts a reel URL or raw text, runs AI analysis, returns structured insights.
    """
    try:
        service = AnalysisService(settings)
        result = await service.analyze(request, user_id=user["id"])
        return result

    except AppError as e:
        raise app_error_to_http(e)

    except Exception as e:
        logger.error(f"Unexpected analysis error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An unexpected error occurred during analysis. Please try again.",
        )
