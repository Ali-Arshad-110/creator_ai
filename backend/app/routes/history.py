"""
History routes — CRUD for past analyses.
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query

from app.config import Settings, get_settings
from app.dependencies import get_current_user
from app.models.schemas import AnalysisResponse, AnalysisListResponse, AnalysisListItem
from app.services.database_service import DatabaseService

router = APIRouter()


@router.get(
    "/analyses",
    response_model=AnalysisListResponse,
    summary="List analysis history",
    description="Returns paginated list of past analyses for the authenticated user.",
)
async def list_analyses(
    page: int = Query(1, ge=1, description="Page number starting from 1"),
    limit: int = Query(20, ge=1, le=100, description="Number of items per page"),
    user: dict = Depends(get_current_user),
    settings: Settings = Depends(get_settings),
):
    """Paginated history listing."""
    db = DatabaseService(settings)
    items, total = await db.get_analyses(user["id"], page=page, limit=limit)

    list_items = []
    for item in items:
        list_items.append(
            AnalysisListItem(
                id=item["id"],
                input_type=item["input_type"],
                input_content=item["input_content"],
                hook_score=item["hook_score"],
                created_at=item["created_at"],
            )
        )

    has_more = total > page * limit

    return AnalysisListResponse(
        items=list_items,
        total=total,
        page=page,
        limit=limit,
        has_more=has_more,
    )


@router.get(
    "/analyses/{analysis_id}",
    response_model=AnalysisResponse,
    summary="Get analysis detail",
)
async def get_analysis(
    analysis_id: str,
    user: dict = Depends(get_current_user),
    settings: Settings = Depends(get_settings),
):
    """Single analysis detail."""
    db = DatabaseService(settings)
    analysis = await db.get_analysis_by_id(analysis_id, user_id=user["id"])

    if not analysis:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Analysis not found or access denied.",
        )

    result_data = analysis.get("result", {})
    return AnalysisResponse(
        id=analysis["id"],
        hook_score=analysis["hook_score"],
        engagement_prediction=result_data.get("engagement_prediction", ""),
        retention_prediction=result_data.get("retention_prediction", ""),
        strengths=result_data.get("strengths", []),
        weaknesses=result_data.get("weaknesses", []),
        audience_fit=result_data.get("audience_fit", ""),
        improvement_suggestions=result_data.get("improvement_suggestions", []),
        content_ideas=result_data.get("content_ideas", []),
        caption_suggestions=result_data.get("caption_suggestions", []),
        created_at=analysis["created_at"],
    )


@router.delete(
    "/analyses/{analysis_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete an analysis",
)
async def delete_analysis(
    analysis_id: str,
    user: dict = Depends(get_current_user),
    settings: Settings = Depends(get_settings),
):
    """Soft-delete an analysis."""
    db = DatabaseService(settings)
    success = await db.soft_delete_analysis(analysis_id, user_id=user["id"])

    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Analysis not found, already deleted, or access denied.",
        )
