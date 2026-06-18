"""
Custom error types and error handling utilities.
"""

from fastapi import HTTPException, status


class AppError(Exception):
    """Base application error."""

    def __init__(self, message: str, error_code: str = "UNKNOWN_ERROR"):
        self.message = message
        self.error_code = error_code
        super().__init__(message)


class ExtractionError(AppError):
    """Raised when content extraction fails."""

    def __init__(self, message: str = "Failed to extract content from URL."):
        super().__init__(message, error_code="EXTRACTION_FAILED")


class AIAnalysisError(AppError):
    """Raised when AI analysis fails or returns invalid output."""

    def __init__(self, message: str = "AI analysis failed. Please try again."):
        super().__init__(message, error_code="AI_ANALYSIS_FAILED")


class RateLimitError(AppError):
    """Raised when user exceeds rate limits."""

    def __init__(self, message: str = "Rate limit exceeded."):
        super().__init__(message, error_code="RATE_LIMIT_EXCEEDED")


def app_error_to_http(error: AppError) -> HTTPException:
    """Convert an AppError to an appropriate HTTPException."""
    status_map = {
        "EXTRACTION_FAILED": status.HTTP_422_UNPROCESSABLE_ENTITY,
        "AI_ANALYSIS_FAILED": status.HTTP_502_BAD_GATEWAY,
        "RATE_LIMIT_EXCEEDED": status.HTTP_429_TOO_MANY_REQUESTS,
    }

    return HTTPException(
        status_code=status_map.get(error.error_code, status.HTTP_500_INTERNAL_SERVER_ERROR),
        detail=error.message,
    )
