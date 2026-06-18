import asyncio
import hashlib
import random
from datetime import datetime, timedelta
from typing import Dict, Any, Optional
import logging
import instaloader

logger = logging.getLogger("creatorai")


class ProfileService:
    """
    Handles fetching public Instagram profiles using Instaloader.
    Includes a deterministic, seed-based fallback generator for rate-limited scenarios.
    """

    def __init__(self):
        # Premium iOS/Safari User Agent
        self.user_agent = (
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) "
            "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1"
        )
        self.loader = instaloader.Instaloader(user_agent=self.user_agent, max_connection_attempts=1)

    async def fetch_profile(self, username: str) -> Dict[str, Any]:
        """
        Retrieves Instagram profile information.
        Attempts live scraping first, then falls back to a deterministic generator if blocked.
        """
        clean_username = username.strip().lower().replace("@", "")
        
        # 1. Attempt live scraping (runs in a separate thread to prevent blocking event loop)
        try:
            logger.info(f"Attempting live Instagram scrape for: {clean_username}")
            # Strict 3-second timeout on live connections to avoid rate limit hangs
            data = await asyncio.wait_for(
                asyncio.to_thread(self._scrape_live, clean_username),
                timeout=3.0
            )
            if data:
                logger.info(f"Live scrape succeeded for: {clean_username}")
                return data
        except asyncio.TimeoutError:
            logger.warning(f"Live Instagram scrape timed out (3.0s limit) for {clean_username}")
        except Exception as e:
            logger.warning(f"Live Instagram scrape failed/rate-limited for {clean_username}: {e}")

        # 2. Seeded fallback generator
        logger.info(f"Falling back to deterministic simulation for: {clean_username}")
        return self._generate_fallback(clean_username)

    def _scrape_live(self, username: str) -> Dict[str, Any]:
        """Synchronous wrapper for Instaloader extraction."""
        profile = instaloader.Profile.from_username(self.loader.context, username)
        
        # Grab up to 12 recent posts to compute metrics
        recent_posts = []
        posts_iterator = profile.get_posts()
        for _ in range(12):
            try:
                post = next(posts_iterator)
                recent_posts.append({
                    "likes": post.likes,
                    "comments": post.comments,
                    "created_at": post.date_utc.isoformat()
                })
            except StopIteration:
                break
            except Exception as e:
                logger.warning(f"Error parsing post for {username}: {e}")
                break

        return {
            "username": profile.username,
            "full_name": profile.full_name or profile.username,
            "avatar_url": profile.profile_pic_url,
            "followers_count": profile.followers,
            "following_count": profile.followees,
            "posts_count": profile.mediacount,
            "biography": profile.biography or "",
            "external_url": profile.external_url or "",
            "recent_posts": recent_posts,
            "is_estimated": False
        }

    def _generate_fallback(self, username: str) -> Dict[str, Any]:
        """
        Generates realistic, deterministic profile metrics based on the username hash.
        Guarantees that the same username yields identical values across multiple runs.
        """
        # Create a stable integer seed from the username
        seed_hash = hashlib.sha256(username.encode("utf-8")).hexdigest()
        seed_int = int(seed_hash[:8], 16)
        rng = random.Random(seed_int)

        # Preset stats for common accounts to make testing feel realistic
        if username == "mrbeast":
            followers = 87235457
            following = 970
            posts = 486
            full_name = "MrBeast"
            bio = "Watch my latest video! 👇"
            url = "https://youtube.com/mrbeast"
        elif username == "cristiano":
            followers = 628000000
            following = 582
            posts = 3680
            full_name = "Cristiano Ronaldo"
            bio = "SIUUU! Join my journey."
            url = "https://cr7.com"
        elif username == "leomessi":
            followers = 502000000
            following = 310
            posts = 1120
            full_name = "Leo Messi"
            bio = "Bienvenidos a la cuenta oficial de Instagram."
            url = "https://leomessi.com"
        else:
            # Generate random but cohesive stats based on username hash
            follower_tier = rng.choice([1000, 10000, 100000, 1000000])
            followers = int(rng.uniform(0.5, 3.0) * follower_tier)
            following = rng.randint(150, 1200)
            posts = rng.randint(20, 800)
            full_name = username.replace("_", " ").replace(".", " ").title()
            bio = rng.choice([
                f"Creator & Innovator. Business inquiries: contact@{username}.com",
                f"Sharing my daily lifestyle, tips and hacks. Subscribe to my channel!",
                f"Fashion | Tech | Lifestyle. Sharing positive vibes only ✨",
                f"Just a creator navigating the social algorithm. Lets connect!"
            ])
            url = f"https://linktr.ee/{username}"

        # Generate realistic engagement counts for last 12 posts
        # Typical engagement rates: 0.5% to 5%
        engagement_rate = rng.uniform(0.01, 0.05)
        avg_likes = int(followers * engagement_rate * rng.uniform(0.7, 0.95))
        avg_comments = int(avg_likes * rng.uniform(0.015, 0.04))

        # Build 12 posts spaced out over the last month
        recent_posts = []
        base_time = datetime.utcnow()
        for i in range(12):
            post_time = base_time - timedelta(days=rng.uniform(1, 4) * (i + 1))
            likes = int(avg_likes * rng.uniform(0.6, 1.4))
            comments = int(avg_comments * rng.uniform(0.5, 1.5))
            recent_posts.append({
                "likes": likes,
                "comments": comments,
                "created_at": post_time.isoformat()
            })

        return {
            "username": username,
            "full_name": full_name,
            "avatar_url": f"https://api.dicebear.com/7.x/bottts/svg?seed={username}",
            "followers_count": followers,
            "following_count": following,
            "posts_count": posts,
            "biography": bio,
            "external_url": url,
            "recent_posts": recent_posts,
            "is_estimated": True
        }
