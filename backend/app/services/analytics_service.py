import math
from datetime import datetime
from typing import Dict, Any, List


class AnalyticsService:
    """
    Computes analytics, engagement metrics, and audience health profiles
    from scraped or estimated Instagram account data.
    """

    async def compute_metrics(self, raw_data: Dict[str, Any], user_id: str, is_estimated: bool = False) -> Dict[str, Any]:
        """
        Calculates all computed metrics and strengths/weaknesses from raw profiles.
        """
        followers = raw_data["followers_count"]
        following = raw_data["following_count"]
        posts_count = raw_data["posts_count"]
        recent_posts = raw_data["recent_posts"]

        # 1. Average Likes & Comments
        total_likes = 0
        total_comments = 0
        num_posts = len(recent_posts)

        for post in recent_posts:
            total_likes += post["likes"]
            total_comments += post["comments"]

        avg_likes = total_likes / num_posts if num_posts > 0 else 0.0
        avg_comments = total_comments / num_posts if num_posts > 0 else 0.0

        # 2. Engagement Rate
        engagement_rate = 0.0
        if followers > 0:
            engagement_rate = ((avg_likes + avg_comments) / followers) * 100.0
        # Clamp to 2 decimal places
        engagement_rate = round(engagement_rate, 2)

        # 3. Posting Frequency (posts per week)
        posting_frequency = 0.0
        if num_posts >= 2:
            try:
                # Parse dates
                dates = [datetime.fromisoformat(p["created_at"]) for p in recent_posts]
                newest = max(dates)
                oldest = min(dates)
                days_span = (newest - oldest).days
                if days_span > 0:
                    posting_frequency = (num_posts / days_span) * 7.0
            except Exception:
                # Fallback to general estimation
                posting_frequency = 2.5
        posting_frequency = round(posting_frequency, 1)

        # 4. Growth Estimation (Annualized projection in %)
        # Typical values between 1% and 15% based on engagement rate
        growth_estimation = 2.0
        if engagement_rate > 3.0:
            growth_estimation = 8.5
        elif engagement_rate > 1.5:
            growth_estimation = 4.5
        elif engagement_rate > 0.5:
            growth_estimation = 2.0
        else:
            growth_estimation = 0.5

        # 5. Audience Quality Score (AQS)
        # Expected engagement rate benchmark based on account size
        # Logarithmic curve: larger accounts have lower expected engagement
        expected_er = 3.0
        if followers > 0:
            # expected_er = -0.5 * ln(followers) + 8. Clamp between 0.8% and 8%
            try:
                expected_er = -0.5 * math.log(followers) + 8.0
            except ValueError:
                pass
            expected_er = max(0.8, min(8.0, expected_er))

        # AQS is calculated relative to expected engagement benchmarks
        ratio = engagement_rate / expected_er if expected_er > 0 else 1.0
        aqs = int(ratio * 75)
        # Clamp between 10 and 100
        aqs = max(10, min(100, aqs))

        # 6. Strengths and Weaknesses
        strengths = []
        weaknesses = []

        if engagement_rate >= 2.5:
            strengths.append("High engagement rate relative to account size.")
        elif engagement_rate < 1.0:
            weaknesses.append("Lower average engagement. Encourage more community interactions.")

        f2f_ratio = followers / following if following > 0 else followers
        if f2f_ratio > 10.0:
            strengths.append("Strong influencer ratio (highly followed relative to following count).")
        elif f2f_ratio < 1.0:
            weaknesses.append("High following-to-follower ratio. Consider cleaning up following list.")

        if posting_frequency >= 3.0:
            strengths.append("Consistent posting schedule (3+ times per week).")
        elif posting_frequency < 0.5:
            weaknesses.append("Inconsistent upload frequency. Aim for at least 1 post per week.")

        if aqs >= 80:
            strengths.append("Excellent audience quality index with active profile interactions.")
        elif aqs < 40:
            weaknesses.append("Lower audience interaction score. Watch out for inactive followers.")

        # Ensure we always have at least 1 strength and weakness for design integrity
        if not strengths:
            strengths.append("Healthy organic viewer reach.")
        if not weaknesses:
            weaknesses.append("Opportunity to experiment with varied posting formats (e.g. reels).")

        return {
            "username": raw_data["username"],
            "full_name": raw_data["full_name"],
            "avatar_url": raw_data["avatar_url"],
            "followers_count": followers,
            "following_count": following,
            "posts_count": posts_count,
            "biography": raw_data["biography"],
            "external_url": raw_data["external_url"],
            "updated_at": datetime.utcnow().isoformat() + "Z",
            "metrics": {
                "engagement_rate": engagement_rate,
                "average_likes": round(avg_likes, 1),
                "average_comments": round(avg_comments, 1),
                "posting_frequency": posting_frequency,
                "audience_quality_score": aqs,
                "growth_estimation": round(growth_estimation, 1),
                "is_estimated": is_estimated,
                "strengths": strengths,
                "weaknesses": weaknesses
            }
        }
