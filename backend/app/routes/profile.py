from datetime import datetime, timezone
import uuid
from fastapi import APIRouter, Depends, HTTPException, status, Query

from app.config import Settings, get_settings
from app.dependencies import get_current_user
from app.models.schemas import (
    ProfileAnalyzeRequest,
    ProfileAnalysisResponse,
    ProfileMetricsResponse,
    ProfileAnalysisListResponse,
    ProfileAnalysisListItem,
)
from app.services.database_service import DatabaseService
from app.services.profile_service import ProfileService
from app.services.analytics_service import AnalyticsService

router = APIRouter()


@router.post(
    "/profile/analyze",
    response_model=ProfileAnalysisResponse,
    summary="Analyze Instagram profile",
    description="Fetches, computes and caches analytics metrics for an Instagram username.",
)
async def analyze_profile(
    payload: ProfileAnalyzeRequest,
    user: dict = Depends(get_current_user),
    settings: Settings = Depends(get_settings),
):
    db = DatabaseService(settings)
    profile_service = ProfileService()
    analytics_service = AnalyticsService()

    username = payload.username

    # 1. Check if profile exists and was updated within last 24 hours
    cached_profile = await db.get_profile_by_username(username)
    if cached_profile:
        # Check if the cache is fresh (less than 24 hours old)
        updated_at = cached_profile["updated_at"]
        if isinstance(updated_at, str):
            # Parse ISO string with timezone info
            try:
                updated_at_dt = datetime.fromisoformat(updated_at.replace("Z", "+00:00"))
            except Exception:
                updated_at_dt = datetime.now(timezone.utc)
        else:
            updated_at_dt = updated_at

        time_diff = datetime.now(timezone.utc) - updated_at_dt
        if time_diff.total_seconds() < 86400:
            # Fetch latest report for this profile
            latest_report = await db.get_latest_analytics_report(cached_profile["id"])
            if latest_report:
                # Cache hit! Return cached data directly
                return ProfileAnalysisResponse(
                    id=latest_report["id"],
                    username=cached_profile["username"],
                    full_name=cached_profile["full_name"],
                    avatar_url=cached_profile["avatar_url"],
                    followers_count=cached_profile["followers_count"],
                    following_count=cached_profile["following_count"],
                    posts_count=cached_profile["posts_count"],
                    biography=cached_profile["biography"],
                    external_url=cached_profile["external_url"],
                    metrics=ProfileMetricsResponse(
                        engagement_rate=latest_report["engagement_rate"],
                        average_likes=latest_report["average_likes"],
                        average_comments=latest_report["average_comments"],
                        posting_frequency=latest_report["posting_frequency"],
                        audience_quality_score=latest_report["audience_quality_score"],
                        growth_estimation=latest_report["growth_estimation"],
                        is_estimated=latest_report["is_estimated"],
                        strengths=latest_report["strengths"] or [],
                        weaknesses=latest_report["weaknesses"] or []
                    ),
                    updated_at=updated_at_dt
                )

    # 2. Cache miss: fetch live profile metadata
    raw_data = await profile_service.fetch_profile(username)

    # 3. Save profile metadata to cache table
    profile_payload = {
        "username": raw_data["username"],
        "full_name": raw_data["full_name"],
        "avatar_url": raw_data["avatar_url"],
        "followers_count": raw_data["followers_count"],
        "following_count": raw_data["following_count"],
        "posts_count": raw_data["posts_count"],
        "biography": raw_data["biography"],
        "external_url": raw_data["external_url"],
        "updated_at": datetime.now(timezone.utc).isoformat()
    }
    saved_profile = await db.save_profile(profile_payload)
    profile_id = saved_profile.get("id")

    # 4. Save a snapshot of the metrics for historical progression
    snapshot_payload = {
        "profile_id": profile_id,
        "followers_count": raw_data["followers_count"],
        "following_count": raw_data["following_count"],
        "posts_count": raw_data["posts_count"]
    }
    await db.save_profile_snapshot(snapshot_payload)

    # 5. Run mathematical calculations via AnalyticsService
    computed = await analytics_service.compute_metrics(
        raw_data,
        user_id=user["id"],
        is_estimated=raw_data["is_estimated"]
    )
    metrics_data = computed["metrics"]

    # 6. Save computed report
    report_payload = {
        "profile_id": profile_id,
        "user_id": user["id"],
        "engagement_rate": metrics_data["engagement_rate"],
        "average_likes": metrics_data["average_likes"],
        "average_comments": metrics_data["average_comments"],
        "posting_frequency": metrics_data["posting_frequency"],
        "audience_quality_score": metrics_data["audience_quality_score"],
        "growth_estimation": metrics_data["growth_estimation"],
        "is_estimated": metrics_data["is_estimated"],
        "strengths": metrics_data["strengths"],
        "weaknesses": metrics_data["weaknesses"]
    }
    saved_report = await db.save_analytics_report(report_payload)

    return ProfileAnalysisResponse(
        id=saved_report["id"],
        username=saved_profile["username"],
        full_name=saved_profile["full_name"],
        avatar_url=saved_profile["avatar_url"],
        followers_count=saved_profile["followers_count"],
        following_count=saved_profile["following_count"],
        posts_count=saved_profile["posts_count"],
        biography=saved_profile["biography"],
        external_url=saved_profile["external_url"],
        metrics=ProfileMetricsResponse(
            engagement_rate=saved_report["engagement_rate"],
            average_likes=saved_report["average_likes"],
            average_comments=saved_report["average_comments"],
            posting_frequency=saved_report["posting_frequency"],
            audience_quality_score=saved_report["audience_quality_score"],
            growth_estimation=saved_report["growth_estimation"],
            is_estimated=saved_report["is_estimated"],
            strengths=saved_report["strengths"] or [],
            weaknesses=saved_report["weaknesses"] or []
        ),
        updated_at=datetime.fromisoformat(saved_profile["updated_at"].replace("Z", "+00:00"))
    )


@router.get(
    "/profile/history",
    response_model=ProfileAnalysisListResponse,
    summary="List profile audit history",
    description="Returns list of previously audited profiles for the user.",
)
async def list_profile_history(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    user: dict = Depends(get_current_user),
    settings: Settings = Depends(get_settings),
):
    db = DatabaseService(settings)
    items, total = await db.get_reports_history(user["id"], page=page, limit=limit)

    list_items = []
    for item in items:
        profiles_info = item.get("profiles") or {}
        list_items.append(
            ProfileAnalysisListItem(
                id=uuid.UUID(item["id"]),
                username=profiles_info.get("username", "unknown"),
                full_name=profiles_info.get("full_name"),
                avatar_url=profiles_info.get("avatar_url"),
                followers_count=profiles_info.get("followers_count", 0),
                engagement_rate=item["engagement_rate"],
                created_at=datetime.fromisoformat(item["created_at"].replace("Z", "+00:00"))
            )
        )

    has_more = total > page * limit

    return ProfileAnalysisListResponse(
        items=list_items,
        total=total,
        page=page,
        limit=limit,
        has_more=has_more
    )


@router.delete(
    "/profile/history/{report_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a profile audit report from history",
)
async def delete_profile_history(
    report_id: str,
    user: dict = Depends(get_current_user),
    settings: Settings = Depends(get_settings),
):
    db = DatabaseService(settings)
    success = await db.delete_analytics_report(report_id, user_id=user["id"])

    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Analytics report not found or access denied.",
        )
