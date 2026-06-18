# CreatorAI — Deployment Guide

## Infrastructure

| Component | Service | Tier |
|-----------|---------|------|
| Backend API | Railway | Hobby ($5/mo) |
| Database + Auth | Supabase | Free |
| Frontend (if web) | Vercel / Firebase Hosting | Free |
| Mobile App | Google Play / App Store | Dev accounts |

---

## Backend Deployment (Railway)

### 1. Push to GitHub
```bash
git init
git add .
git commit -m "Phase 1: Project scaffold"
git remote add origin <your-repo-url>
git push -u origin main
```

### 2. Railway Setup
1. Create a new project on [railway.app](https://railway.app)
2. Connect your GitHub repo
3. Set root directory to `backend/`
4. Railway will auto-detect the Dockerfile

### 3. Environment Variables
Set these in the Railway dashboard:
```
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=xxx
SUPABASE_SERVICE_ROLE_KEY=xxx
SUPABASE_JWT_SECRET=your-supabase-jwt-secret  # Found in Supabase API settings
LLM_PROVIDER=openai
LLM_API_KEY=sk-xxx
LLM_MODEL=gpt-4o-mini
ENVIRONMENT=production
DEBUG=false
```

### 4. Custom Domain (optional)
Add a custom domain in Railway settings → Networking.

---

## Supabase & Clerk Setup

### 1. Create Project
1. Go to [supabase.com](https://supabase.com), create a new project.
2. Copy `Project URL`, `anon` / `service_role` keys, and the **JWT Secret** (from Dashboard → Project Settings → API).

### 2. Configure Clerk Provider
Because you are using **Clerk** as the Identity Provider instead of Google:
1. Set up your Clerk application in the [Clerk Dashboard](https://dashboard.clerk.com).
2. Configure Clerk's JWT template to issue tokens with claims mapping to Supabase requirements, or configure Clerk as an OAuth/OIDC Provider in **Supabase Dashboard** under **Authentication → Providers**.
3. Retrieve the Client ID and Client Secret or Public Keys from Clerk and paste them into the custom provider settings in Supabase.

### 3. Enable Email Auth & Troubleshooting Redirects
1. Go to **Authentication → Providers → Email** in Supabase.
2. To allow users to sign up and immediately log in without validating their email, toggle **"Confirm email"** to **OFF** (disabled).
3. If this toggle is kept **ON**, newly registered users will see a "Check your email" status and won't be able to log in or route to the home screen until their email address is confirmed.

### 4. Run Migrations
Execute the SQL from `docs/supabase_migration.sql` in the SQL Editor:
- Creates `users` and `analyses` tables
- Sets up RLS policies
- Creates indexes

---

## Production Checklist

- [ ] Environment variables set (no defaults in prod)
- [ ] `DEBUG=false` in production
- [ ] Supabase RLS policies enabled
- [ ] Rate limiting configured
- [ ] CORS origins restricted to your domain
- [ ] API docs endpoint disabled (`/docs` returns 404)
- [ ] Error responses don't leak stack traces
- [ ] LLM API key has usage limits set in provider dashboard
- [ ] Monitoring/alerting configured (Railway metrics)
