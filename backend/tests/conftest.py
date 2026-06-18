"""
Pytest configuration and shared fixtures.
"""

import pytest
from fastapi.testclient import TestClient

from app.main import app


@pytest.fixture
def client():
    """FastAPI test client."""
    return TestClient(app)


@pytest.fixture
def auth_headers():
    """Mock auth headers for protected endpoints."""
    return {"Authorization": "Bearer test-token-placeholder"}
