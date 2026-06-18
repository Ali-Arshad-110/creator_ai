"""
Analysis service — orchestrates content extraction and AI analysis.
This is the core business logic layer.
"""

import logging
from datetime import datetime, timezone
from uuid import uuid4

from app.config import Settings
from app.models.schemas import AnalysisRequest, AnalysisResponse, InputType
from app.services.ai_engine import AIEngine
from app.services.content_extractor import ContentExtractor
from app.services.database_service import DatabaseService
from app.utils.errors import ExtractionError, AIAnalysisError, app_error_to_http

logger = logging.getLogger("creatorai")


class AnalysisService:
    """
    Orchestrates the full analysis pipeline:
    1. Extract content metadata (URL → scrape, or parse text)
    2. Run AI analysis via LLM
    3. Validate and structure the response
    4. (Phase 4: persist to database)
    5. Return AnalysisResponse
    """

    def __init__(self, settings: Settings):
        self.extractor = ContentExtractor()
        self.ai_engine = AIEngine(settings)
        self.db = DatabaseService(settings)

    async def analyze(
        self,
        request: AnalysisRequest,
        user_id: str,
    ) -> AnalysisResponse:
        """
        Full analysis pipeline.

        Args:
            request: Validated analysis request (URL or text).
            user_id: Authenticated user's ID.

        Returns:
            AnalysisResponse with structured AI insights.
        """
        analysis_id = uuid4()
        logger.info(
            f"Starting analysis {analysis_id} for user {user_id} "
            f"(type={request.input_type})"
        )

        # Step 1: Extract content
        content_data = await self._extract_content(request)
        logger.info(f"Content extracted: {len(content_data.get('content', ''))} chars")

        # Step 2: Run AI analysis
        ai_result = await self.ai_engine.analyze_content(content_data)
        logger.info(f"AI analysis complete: hook_score={ai_result.get('hook_score')}")

        # Step 3: Build response
        now = datetime.now(timezone.utc)
        response = AnalysisResponse(
            id=analysis_id,
            hook_score=ai_result["hook_score"],
            engagement_prediction=ai_result["engagement_prediction"],
            retention_prediction=ai_result["retention_prediction"],
            strengths=ai_result["strengths"],
            weaknesses=ai_result["weaknesses"],
            audience_fit=ai_result["audience_fit"],
            improvement_suggestions=ai_result["improvement_suggestions"],
            content_ideas=ai_result["content_ideas"],
            caption_suggestions=ai_result["caption_suggestions"],
            created_at=now,
        )

        # Step 4: Persist to database (non-blocking, non-fatal for now)
        try:
            await self.db.save_analysis(
                user_id=user_id,
                analysis_data={
                    "id": str(analysis_id),
                    "user_id": user_id,
                    "input_type": request.input_type.value,
                    "input_content": request.content[:500],
                    "reel_url": request.content if request.input_type == InputType.URL else None,
                    "result": ai_result,
                    "hook_score": ai_result["hook_score"],
                    "created_at": now.isoformat(),
                },
            )
            logger.info(f"Analysis {analysis_id} saved to database")
        except NotImplementedError:
            logger.info("Database save skipped (Phase 4)")
        except Exception as e:
            logger.error(f"Failed to save analysis {analysis_id}: {e}")

        return response

    async def _extract_content(self, request: AnalysisRequest) -> dict:
        """Route to the correct extraction method based on input type."""
        try:
            if request.input_type == InputType.URL:
                return await self.extractor.extract_from_url(request.content)
            else:
                return self.extractor.extract_from_text(request.content)
        except ExtractionError:
            raise
        except Exception as e:
            logger.error(f"Content extraction failed: {e}")
            # Fall back to treating input as raw text
            return self.extractor.extract_from_text(request.content)
