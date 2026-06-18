import asyncio
import sys
from app.services.profile_service import ProfileService

async def main():
    username = "mrbeast"
    if len(sys.argv) > 1:
        username = sys.argv[1]
    
    print(f"Testing ProfileService with username: {username}")
    service = ProfileService()
    try:
        res = await service.fetch_profile(username)
        print("Success! Result keys:", res.keys())
        print("Is Estimated:", res.get("is_estimated"))
        print("Followers:", res.get("followers_count"))
        print("Bio:", res.get("biography"))
        print("Recent posts count:", len(res.get("recent_posts", [])))
    except Exception as e:
        print("Failed with exception:", e)

if __name__ == "__main__":
    asyncio.run(main())
