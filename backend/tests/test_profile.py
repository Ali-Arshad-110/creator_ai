from unittest.mock import AsyncMock, patch
import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.dependencies import get_current_user

# Mock user data matching test_analysis
MOCK_USER = {
    "id": "00000000-0000-0000-0000-000000000000",
    "email": "test@example.com",
    "full_name": "Test User",
    "avatar_url": "https://example.com/avatar.png",
    "role": "authenticated",
}


@pytest.fixture
def authorized_client():
    """Client with overridden auth dependency."""
    app.dependency_overrides[get_current_user] = lambda: MOCK_USER
    with TestClient(app) as client:
        yield client
    app.dependency_overrides.clear()


def test_analyze_profile_requires_auth(client):
    """Analyze profile endpoint should return 403 without auth token."""
    response = client.post(
        "/api/v1/profile/analyze",
        json={"username": "mrbeast"},
    )
    assert response.status_code == 403


@patch("app.services.profile_service.ProfileService.fetch_profile", new_callable=AsyncMock)
@patch("app.services.database_service.DatabaseService.get_profile_by_username", new_callable=AsyncMock)
@patch("app.services.database_service.DatabaseService.save_profile", new_callable=AsyncMock)
@patch("app.services.database_service.DatabaseService.save_profile_snapshot", new_callable=AsyncMock)
@patch("app.services.database_service.DatabaseService.save_analytics_report", new_callable=AsyncMock)
def test_analyze_profile_success(
    mock_save_report,
    mock_save_snapshot,
    mock_save_profile,
    mock_get_profile,
    mock_fetch_profile,
    authorized_client
):
    """Verify that posting a username performs analysis, saves metrics, and returns formatted data."""
    mock_get_profile.return_value = None  # Cache miss
    mock_fetch_profile.return_value = {
        "username": "mrbeast",
        "full_name": "MrBeast",
        "avatar_url": "https://example.com/mrbeast.jpg",
        "followers_count": 87000000,
        "following_count": 970,
        "posts_count": 480,
        "biography": "Watch my latest video!",
        "external_url": "https://youtube.com/mrbeast",
        "recent_posts": [
            {"likes": 1000000, "comments": 20000, "created_at": "2026-06-18T12:00:00"},
            {"likes": 1200000, "comments": 25000, "created_at": "2026-06-17T12:00:00"}
        ],
        "is_estimated": False
    }

    mock_save_profile.return_value = {
        "id": "11111111-1111-1111-1111-111111111111",
        "username": "mrbeast",
        "full_name": "MrBeast",
        "avatar_url": "https://example.com/mrbeast.jpg",
        "followers_count": 87000000,
        "following_count": 970,
        "posts_count": 480,
        "biography": "Watch my latest video!",
        "external_url": "https://youtube.com/mrbeast",
        "updated_at": "2026-06-18T13:00:00Z"
    }

    mock_save_report.return_value = {
        "id": "22222222-2222-2222-2222-222222222222",
        "engagement_rate": 1.29,
        "average_likes": 1100000.0,
        "average_comments": 22500.0,
        "posting_frequency": 7.0,
        "audience_quality_score": 85,
        "growth_estimation": 4.5,
        "is_estimated": False,
        "strengths": ["High engagement rate."],
        "weaknesses": []
    }

    response = authorized_client.post(
        "/api/v1/profile/analyze",
        json={"username": "mrbeast"}
    )

    assert response.status_code == 200
    data = response.json()
    assert data["username"] == "mrbeast"
    assert data["followers_count"] == 87000000
    assert data["metrics"]["engagement_rate"] == 1.29
    assert data["metrics"]["average_likes"] == 1100000.0
    assert data["metrics"]["is_estimated"] is False

    mock_fetch_profile.assert_called_once_with("mrbeast")
    mock_save_profile.assert_called_once()
    mock_save_snapshot.assert_called_once()
    mock_save_report.assert_called_once()


@patch("app.services.database_service.DatabaseService.get_reports_history", new_callable=AsyncMock)
def test_profile_history_success(mock_get_history, authorized_client):
    """Retrieve profile audit history successfully."""
    mock_get_history.return_value = (
        [
            {
                "id": "22222222-2222-2222-2222-222222222222",
                "engagement_rate": 1.29,
                "created_at": "2026-06-18T13:00:00Z",
                "profiles": {
                    "username": "mrbeast",
                    "full_name": "MrBeast",
                    "avatar_url": "https://example.com/mrbeast.jpg",
                    "followers_count": 87000000
                }
            }
        ],
        1
    )

    response = authorized_client.get("/api/v1/profile/history?page=1&limit=10")

    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 1
    assert len(data["items"]) == 1
    assert data["items"][0]["username"] == "mrbeast"
    assert data["items"][0]["engagement_rate"] == 1.29
    mock_get_history.assert_called_once_with(MOCK_USER["id"], page=1, limit=10)


@patch("app.services.database_service.DatabaseService.delete_analytics_report", new_callable=AsyncMock)
def test_delete_profile_history_success(mock_delete, authorized_client):
    """Delete a profile audit report returns 204."""
    mock_delete.return_value = True

    response = authorized_client.delete("/api/v1/profile/history/22222222-2222-2222-2222-222222222222")

    assert response.status_code == 204
    mock_delete.assert_called_once_with("22222222-2222-2222-2222-222222222222", user_id=MOCK_USER["id"])
