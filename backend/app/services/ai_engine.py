"""
AI Engine — LLM provider abstraction layer.
Supports swapping between OpenAI and Anthropic without changing business logic.
"""

import json
import logging
from abc import ABC, abstractmethod

from openai import AsyncOpenAI
from anthropic import AsyncAnthropic

from app.config import Settings
from app.prompts.analysis_prompt import SYSTEM_PROMPT, build_analysis_prompt
from app.utils.errors import AIAnalysisError

logger = logging.getLogger("creatorai")

# Fallback response when LLM fails — prevents broken UI
FALLBACK_RESPONSE = {
    "hook_score": 5,
    "engagement_prediction": "Unable to fully analyze — please try again.",
    "retention_prediction": "Unable to fully analyze — please try again.",
    "strengths": ["Content was submitted successfully"],
    "weaknesses": ["Analysis could not be completed at this time"],
    "audience_fit": "Unable to determine — please retry.",
    "improvement_suggestions": ["Try submitting again or paste the script directly"],
    "content_ideas": ["Retry analysis for personalized suggestions"],
    "caption_suggestions": ["Retry analysis for caption suggestions"],
}


class LLMProvider(ABC):
    """Abstract base for LLM providers."""

    @abstractmethod
    async def generate(self, prompt: str, system_prompt: str) -> str:
        """Send prompt to LLM and return raw response text."""
        ...


class OpenAIProvider(LLMProvider):
    """OpenAI API provider (GPT-4o, GPT-4o-mini, etc.)."""

    def __init__(self, api_key: str, model: str):
        self.client = AsyncOpenAI(api_key=api_key)
        self.model = model

    async def generate(self, prompt: str, system_prompt: str) -> str:
        response = await self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": prompt},
            ],
            temperature=0.7,
            max_tokens=2000,
            response_format={"type": "json_object"},
        )
        return response.choices[0].message.content or ""


class AnthropicProvider(LLMProvider):
    """Anthropic API provider (Claude 3.5, Claude 4, etc.)."""

    def __init__(self, api_key: str, model: str):
        self.client = AsyncAnthropic(api_key=api_key)
        self.model = model

    async def generate(self, prompt: str, system_prompt: str) -> str:
        response = await self.client.messages.create(
            model=self.model,
            system=system_prompt,
            messages=[
                {"role": "user", "content": prompt},
            ],
            temperature=0.7,
            max_tokens=2000,
        )
        return response.content[0].text


class AIEngine:
    """
    Facade over LLM providers.
    Handles prompt construction, response parsing, validation, and fallback logic.
    """

    def __init__(self, settings: Settings):
        self.provider = self._create_provider(settings)

    def _create_provider(self, settings: Settings) -> LLMProvider:
        """Factory method — instantiate the configured LLM provider."""
        providers = {
            "openai": lambda: OpenAIProvider(settings.llm_api_key, settings.llm_model),
            "anthropic": lambda: AnthropicProvider(settings.llm_api_key, settings.llm_model),
        }

        factory = providers.get(settings.llm_provider)
        if not factory:
            raise ValueError(
                f"Unsupported LLM provider: {settings.llm_provider}. "
                f"Supported: {list(providers.keys())}"
            )
        return factory()

    async def analyze_content(self, content_data: dict) -> dict:
        """
        Run AI analysis on extracted content.

        1. Build prompt from content data
        2. Call LLM provider
        3. Parse and validate JSON response
        4. Return structured dict (or fallback on failure)
        """
        prompt = build_analysis_prompt(content_data)

        try:
            logger.info("Sending content to LLM for analysis...")
            raw_response = await self.provider.generate(prompt, SYSTEM_PROMPT)
            logger.info(f"LLM response received ({len(raw_response)} chars)")

            # Parse and validate
            result = self._parse_response(raw_response)
            return result

        except AIAnalysisError:
            raise
        except Exception as e:
            logger.error(f"LLM call failed: {e}")
            # Return fallback instead of crashing
            return FALLBACK_RESPONSE.copy()

    def _parse_response(self, raw: str) -> dict:
        """
        Parse LLM response into validated dict.
        Handles common issues: markdown wrappers, missing fields, wrong types.
        """
        # Strip markdown code block wrappers if present
        raw = raw.strip()
        if raw.startswith("```json"):
            raw = raw[7:]
        if raw.startswith("```"):
            raw = raw[3:]
        if raw.endswith("```"):
            raw = raw[:-3]
        raw = raw.strip()

        try:
            data = json.loads(raw)
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse LLM JSON: {e}")
            logger.error(f"Raw response: {raw[:500]}")
            return FALLBACK_RESPONSE.copy()

        # Validate and coerce required fields
        return self._validate_fields(data)

    def _validate_fields(self, data: dict) -> dict:
        """Ensure all required fields exist with correct types."""
        validated = {}

        # hook_score: int 0-10
        try:
            score = int(data.get("hook_score", 5))
            validated["hook_score"] = max(0, min(10, score))
        except (ValueError, TypeError):
            validated["hook_score"] = 5

        # String fields
        string_fields = [
            "engagement_prediction",
            "retention_prediction",
            "audience_fit",
        ]
        for field in string_fields:
            value = data.get(field, "")
            validated[field] = str(value) if value else "Not available."

        # List[str] fields
        list_fields = [
            "strengths",
            "weaknesses",
            "improvement_suggestions",
            "content_ideas",
            "caption_suggestions",
        ]
        for field in list_fields:
            value = data.get(field, [])
            if isinstance(value, list):
                validated[field] = [str(item) for item in value if item]
            else:
                validated[field] = [str(value)] if value else ["Not available."]

        return validated
