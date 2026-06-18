"""
Content extractor — fetches metadata from Instagram reel URLs
and parses raw text input into structured analysis context.
"""

import re
import logging

import httpx

from app.utils.errors import ExtractionError

logger = logging.getLogger("creatorai")


class ContentExtractor:
    """
    Extracts content metadata from Instagram reel URLs or raw text.
    
    URL extraction uses Instagram's oEmbed endpoint (public, no API key needed)
    plus page scraping as fallback for caption/hashtags.
    """

    def __init__(self):
        self._http_client = httpx.AsyncClient(
            timeout=15.0,
            headers={
                "User-Agent": (
                    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                    "AppleWebKit/537.36 (KHTML, like Gecko) "
                    "Chrome/120.0.0.0 Safari/537.36"
                ),
            },
            follow_redirects=True,
        )

    async def extract_from_url(self, url: str) -> dict:
        """
        Extract metadata from an Instagram reel URL.

        Strategy:
        1. Try Instagram oEmbed API (reliable, gives title/author)
        2. Try page scrape for caption and hashtags
        3. Fall back to URL-only context if both fail

        Returns:
            dict with keys: caption, hashtags, author, source_url, content
        """
        url = self._normalize_url(url)
        result = {
            "source_url": url,
            "caption": "",
            "hashtags": [],
            "author": "",
            "content": "",
        }

        # Strategy 1: oEmbed API
        try:
            oembed_data = await self._fetch_oembed(url)
            if oembed_data:
                result["author"] = oembed_data.get("author_name", "")
                title = oembed_data.get("title", "")
                if title:
                    result["caption"] = title
                    result["hashtags"] = self._extract_hashtags(title)
                    result["content"] = title
        except Exception as e:
            logger.warning(f"oEmbed failed for {url}: {e}")

        # Strategy 2: Page scrape for richer caption
        if not result["content"]:
            try:
                scraped = await self._scrape_page(url)
                if scraped:
                    result.update(scraped)
            except Exception as e:
                logger.warning(f"Page scrape failed for {url}: {e}")

        # If we got nothing at all, provide minimal context
        if not result["content"] and not result["caption"]:
            result["content"] = f"Instagram Reel from URL: {url}"
            logger.info(f"No content extracted from {url}, using URL as context")

        return result

    def extract_from_text(self, text: str) -> dict:
        """
        Parse raw text input into structured content for analysis.

        Returns:
            dict with keys: content, caption, hashtags, word_count
        """
        text = text.strip()
        hashtags = self._extract_hashtags(text)

        # Remove hashtags from content for cleaner analysis
        clean_content = re.sub(r'#\w+', '', text).strip()

        return {
            "content": text,
            "caption": clean_content[:200] if clean_content else text[:200],
            "hashtags": hashtags,
            "author": "",
            "word_count": len(text.split()),
        }

    async def _fetch_oembed(self, url: str) -> dict | None:
        """Fetch metadata via Instagram's public oEmbed endpoint."""
        oembed_url = f"https://api.instagram.com/oembed/?url={url}"
        try:
            response = await self._http_client.get(oembed_url)
            if response.status_code == 200:
                return response.json()
        except Exception:
            pass
        return None

    async def _scrape_page(self, url: str) -> dict | None:
        """
        Attempt to scrape the Instagram page for og:description meta tag.
        This contains the full caption for public posts.
        """
        try:
            response = await self._http_client.get(url)
            if response.status_code != 200:
                return None

            html = response.text

            # Extract og:description (contains caption)
            og_match = re.search(
                r'<meta\s+(?:property|name)="og:description"\s+content="([^"]*)"',
                html,
                re.IGNORECASE,
            )
            caption = ""
            if og_match:
                caption = og_match.group(1)
                # Decode HTML entities
                caption = caption.replace("&amp;", "&").replace("&quot;", '"')
                caption = caption.replace("&#39;", "'").replace("&lt;", "<")
                caption = caption.replace("&gt;", ">")

            # Extract og:title for author info
            title_match = re.search(
                r'<meta\s+(?:property|name)="og:title"\s+content="([^"]*)"',
                html,
                re.IGNORECASE,
            )
            author = ""
            if title_match:
                title = title_match.group(1)
                # Instagram titles are usually "Author on Instagram: caption..."
                if " on Instagram" in title:
                    author = title.split(" on Instagram")[0].strip()

            if caption or author:
                return {
                    "caption": caption,
                    "content": caption,
                    "hashtags": self._extract_hashtags(caption),
                    "author": author,
                }

        except Exception as e:
            logger.warning(f"Scrape parse error: {e}")

        return None

    @staticmethod
    def _extract_hashtags(text: str) -> list[str]:
        """Pull all #hashtags from text."""
        return re.findall(r'#(\w+)', text)

    @staticmethod
    def _normalize_url(url: str) -> str:
        """Clean up Instagram URL (remove tracking params, ensure https)."""
        url = url.strip()
        if not url.startswith("http"):
            url = f"https://{url}"
        # Remove query params (tracking noise)
        url = url.split("?")[0]
        # Remove trailing slash
        url = url.rstrip("/")
        return url
