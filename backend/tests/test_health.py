"""
Health endpoint tests.
"""


def test_health_returns_200(client):
    """Health check should always return 200 with service info."""
    response = client.get("/health")
    assert response.status_code == 200

    data = response.json()
    assert data["status"] == "healthy"
    assert "version" in data
    assert data["service"] == "CreatorAI"


def test_health_includes_version(client):
    """Health response should include the app version."""
    response = client.get("/health")
    data = response.json()
    assert data["version"] == "0.1.0"
