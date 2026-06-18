"""
Analysis prompt templates — structured prompts for LLM content analysis.
Separated from business logic for easy iteration and A/B testing.
"""

SYSTEM_PROMPT = """You are an expert Instagram content strategist and growth advisor.
You analyze Instagram Reels and provide actionable, data-informed feedback.

Your analysis MUST be returned as valid JSON matching this exact schema:
{
  "hook_score": <integer 0-10>,
  "engagement_prediction": "<string>",
  "retention_prediction": "<string>",
  "strengths": ["<string>", ...],
  "weaknesses": ["<string>", ...],
  "audience_fit": "<string>",
  "improvement_suggestions": ["<string>", ...],
  "content_ideas": ["<string>", ...],
  "caption_suggestions": ["<string>", ...]
}

Rules:
- hook_score: Rate the opening hook's effectiveness from 0 (no hook) to 10 (perfect hook).
- strengths/weaknesses: Provide 2-5 specific, actionable items each.
- content_ideas: Suggest 3 related content ideas the creator should make next.
- caption_suggestions: Provide 2-3 engaging caption alternatives.
- Be specific. Avoid generic advice like "post consistently".
- Reference the actual content in your feedback.
- Return ONLY valid JSON. No markdown, no explanation outside the JSON."""


def build_analysis_prompt(content_data: dict) -> str:
    """
    Build the user prompt from extracted content data.

    Args:
        content_data: Output from ContentExtractor with keys like
                      caption, hashtags, content, word_count, etc.

    Returns:
        Formatted prompt string.
    """
    parts = ["Analyze this Instagram Reel content:\n"]

    if caption := content_data.get("caption"):
        parts.append(f"**Caption:** {caption}\n")

    if hashtags := content_data.get("hashtags"):
        parts.append(f"**Hashtags:** {', '.join(hashtags)}\n")

    if content := content_data.get("content"):
        parts.append(f"**Script/Content:** {content}\n")

    if author := content_data.get("author"):
        parts.append(f"**Creator:** {author}\n")

    parts.append("\nProvide your analysis as structured JSON.")

    return "\n".join(parts)
