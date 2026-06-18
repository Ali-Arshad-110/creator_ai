"""
Analysis and history endpoint tests.
"""

from unittest.mock import AsyncMock, patch
import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.dependencies import get_current_user

# Mock user data returned by overridden dependency
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


def test_analyze_requires_auth(client):
    """Analysis endpoint should return 403 without auth token."""
    response = client.post(
        "/api/v1/analyze",
        json={"input_type": "text", "content": "Test content"},
    )
    assert response.status_code == 403


@patch("app.services.ai_engine.AIEngine.analyze_content", new_callable=AsyncMock)
@patch("app.services.database_service.DatabaseService.save_analysis", new_callable=AsyncMock)
def test_analyze_success(mock_save, mock_analyze, authorized_client):
    """Analysis endpoint returns structured AI insights and saves to DB."""
    mock_analyze.return_value = {
        "hook_score": 8,
        "engagement_prediction": "High engagement expected.",
        "retention_prediction": "Steady retention.",
        "strengths": ["Strong opening hook"],
        "weaknesses": ["Lack of clear CTA"],
        "audience_fit": "Target niche fit is perfect.",
        "improvement_suggestions": ["Add a CTA at the end"],
        "content_ideas": ["Next video on hook design"],
        "caption_suggestions": ["Check this out!"],
    }
    mock_save.return_value = {"id": "some-id"}

    response = authorized_client.post(
        "/api/v1/analyze",
        json={"input_type": "text", "content": "This is a great script for a reel."},
    )

    assert response.status_code == 200
    data = response.json()
    assert data["hook_score"] == 8
    assert "id" in data
    assert data["engagement_prediction"] == "High engagement expected."
    assert "Strong opening hook" in data["strengths"]
    
    mock_analyze.assert_called_once()
    mock_save.assert_called_once()


@patch("app.services.database_service.DatabaseService.get_analyses", new_callable=AsyncMock)
def test_list_analyses_success(mock_get, authorized_client):
    """History listing endpoint returns paginated past analyses."""
    mock_get.return_value = (
        [
            {
                "id": "11111111-1111-1111-1111-111111111111",
                "input_type": "text",
                "input_content": "Some input script",
                "hook_score": 7,
                "created_at": "2026-06-17T12:00:00Z",
            }
        ],
        1,
    )

    response = authorized_client.get("/api/v1/analyses?page=1&limit=10")

    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 1
    assert len(data["items"]) == 1
    assert data["items"][0]["hook_score"] == 7
    assert data["items"][0]["input_content"] == "Some input script"
    mock_get.assert_called_once_with(MOCK_USER["id"], page=1, limit=10)


@patch("app.services.database_service.DatabaseService.get_analysis_by_id", new_callable=AsyncMock)
def test_get_analysis_detail_success(mock_get_by_id, authorized_client):
    """Fetch single analysis details by ID."""
    mock_get_by_id.return_value = {
        "id": "11111111-1111-1111-1111-111111111111",
        "user_id": MOCK_USER["id"],
        "input_type": "text",
        "input_content": "Some input script",
        "hook_score": 7,
        "created_at": "2026-06-17T12:00:00Z",
        "result": {
            "engagement_prediction": "High engagement.",
            "retention_prediction": "Steady retention.",
            "strengths": ["Strong opening hook"],
            "weaknesses": ["Lack of clear CTA"],
            "audience_fit": "Target niche fit is perfect.",
            "improvement_suggestions": ["Add a CTA at the end"],
            "content_ideas": ["Next video on hook design"],
            "caption_suggestions": ["Check this out!"],
        }
    }

    response = authorized_client.get("/api/v1/analyses/11111111-1111-1111-1111-111111111111")

    assert response.status_code == 200
    data = response.json()
    assert data["hook_score"] == 7
    assert data["engagement_prediction"] == "High engagement."
    mock_get_by_id.assert_called_once_with("11111111-1111-1111-1111-111111111111", user_id=MOCK_USER["id"])


@patch("app.services.database_service.DatabaseService.soft_delete_analysis", new_callable=AsyncMock)
def test_delete_analysis_success(mock_delete, authorized_client):
    """Soft-delete analysis returns 204."""
    mock_delete.return_value = True

    # Clear rate limit state by using a clean client or just sending one delete request
    # (Rate limiter only limits the /analyze endpoint, so this is unaffected)
    response = authorized_client.delete("/api/v1/analyses/11111111-1111-1111-1111-111111111111")

    assert response.status_code == 204
    mock_delete.assert_called_once_with("11111111-1111-1111-1111-111111111111", user_id=MOCK_USER["id"])


@patch("app.services.ai_engine.AIEngine.analyze_content", new_callable=AsyncMock)
@patch("app.services.database_service.DatabaseService.save_analysis", new_callable=AsyncMock)
def test_analyze_rate_limiter(mock_save, mock_analyze, authorized_client):
    """Rate limiter middleware blocks requests after exceeding the limit."""
    # Clear rate limiter state to avoid test pollution
    from app.main import app
    from app.middleware.rate_limiter import RateLimitMiddleware
    
    curr = app.middleware_stack
    while curr is not None:
        if isinstance(curr, RateLimitMiddleware):
            curr.requests.clear()
            break
        curr = getattr(curr, "app", None)

    mock_analyze.return_value = {
        "hook_score": 8,
        "engagement_prediction": "High.",
        "retention_prediction": "Good.",
        "strengths": [],
        "weaknesses": [],
        "audience_fit": "",
        "improvement_suggestions": [],
        "content_ideas": [],
        "caption_suggestions": [],
    }
    mock_save.return_value = {"id": "some-id"}

    # Hit the endpoint up to the limit of 10 requests per minute
    for _ in range(10):
        response = authorized_client.post(
            "/api/v1/analyze",
            json={"input_type": "text", "content": "Test script"},
        )
        assert response.status_code == 200

    # The 11th request should be blocked by the rate limiter
    response = authorized_client.post(
        "/api/v1/analyze",
        json={"input_type": "text", "content": "Test script"},
    )
    assert response.status_code == 429
    assert "Rate limit exceeded" in response.json()["detail"]

