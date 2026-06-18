-- CreatorAI — Supabase Database Migration
-- Run this in your Supabase SQL Editor
-- Auth: Supabase Auth with Clerk as OAuth provider + email/password

-- ══════════════════════════════════════════════════
-- USERS TABLE (extends Supabase auth.users)
-- ══════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Auto-create a public.users row when a new auth user signs up.
-- Handles metadata from both email signup and Clerk OAuth.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name, avatar_url)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      ''
    ),
    COALESCE(
      NEW.raw_user_meta_data->>'avatar_url',
      NEW.raw_user_meta_data->>'picture',
      ''
    )
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = COALESCE(EXCLUDED.full_name, public.users.full_name),
    avatar_url = COALESCE(EXCLUDED.avatar_url, public.users.avatar_url),
    updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- ══════════════════════════════════════════════════
-- ANALYSES TABLE
-- ══════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.analyses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  input_type TEXT NOT NULL CHECK (input_type IN ('url', 'text')),
  input_content TEXT NOT NULL,
  reel_url TEXT,
  result JSONB NOT NULL DEFAULT '{}',
  hook_score INTEGER NOT NULL CHECK (hook_score >= 0 AND hook_score <= 10),
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Indexes for fast history queries
CREATE INDEX IF NOT EXISTS idx_analyses_user_id ON public.analyses(user_id);
CREATE INDEX IF NOT EXISTS idx_analyses_created_at ON public.analyses(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_analyses_user_created ON public.analyses(user_id, created_at DESC);


-- ══════════════════════════════════════════════════
-- ROW LEVEL SECURITY (RLS)
-- ══════════════════════════════════════════════════

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.analyses ENABLE ROW LEVEL SECURITY;

-- Users can only read their own profile
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
CREATE POLICY "Users can view own profile"
  ON public.users FOR SELECT
  USING (auth.uid() = id);

-- Users can update their own profile
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
CREATE POLICY "Users can update own profile"
  ON public.users FOR UPDATE
  USING (auth.uid() = id);

-- Users can only see their own analyses
DROP POLICY IF EXISTS "Users can view own analyses" ON public.analyses;
CREATE POLICY "Users can view own analyses"
  ON public.analyses FOR SELECT
  USING (auth.uid() = user_id AND is_deleted = false);

-- Users can insert their own analyses
DROP POLICY IF EXISTS "Users can create own analyses" ON public.analyses;
CREATE POLICY "Users can create own analyses"
  ON public.analyses FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can soft-delete their own analyses
DROP POLICY IF EXISTS "Users can update own analyses" ON public.analyses;
CREATE POLICY "Users can update own analyses"
  ON public.analyses FOR UPDATE
  USING (auth.uid() = user_id);


-- ══════════════════════════════════════════════════
-- SERVICE ROLE BYPASS (for backend API)
-- ══════════════════════════════════════════════════
-- The backend uses the service_role key which bypasses RLS.
-- This is intentional: the backend handles auth via JWT verification
-- and applies its own authorization logic.


-- ══════════════════════════════════════════════════
-- PROFILES & PROFILE ANALYTICS TABLES
-- ══════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username VARCHAR(100) UNIQUE NOT NULL,
  full_name VARCHAR(255),
  avatar_url TEXT,
  biography TEXT,
  external_url TEXT,
  followers_count INTEGER NOT NULL DEFAULT 0,
  following_count INTEGER NOT NULL DEFAULT 0,
  posts_count INTEGER NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.profile_snapshots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  followers_count INTEGER NOT NULL,
  following_count INTEGER NOT NULL,
  posts_count INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.analytics_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  engagement_rate NUMERIC(5,2) NOT NULL,
  average_likes NUMERIC(12,2) NOT NULL,
  average_comments NUMERIC(12,2) NOT NULL,
  posting_frequency NUMERIC(5,2) NOT NULL,
  audience_quality_score INTEGER NOT NULL,
  growth_estimation NUMERIC(5,2) NOT NULL,
  is_estimated BOOLEAN DEFAULT FALSE,
  strengths TEXT[],
  weaknesses TEXT[],
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_snapshots_profile ON public.profile_snapshots(profile_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reports_profile ON public.analytics_reports(profile_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reports_user ON public.analytics_reports(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_username ON public.profiles(username);

-- RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profile_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.analytics_reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can select profiles" ON public.profiles;
CREATE POLICY "Anyone can select profiles"
  ON public.profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Anyone can select profile_snapshots" ON public.profile_snapshots;
CREATE POLICY "Anyone can select profile_snapshots"
  ON public.profile_snapshots FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can manage own reports" ON public.analytics_reports;
CREATE POLICY "Users can manage own reports"
  ON public.analytics_reports FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create own reports" ON public.analytics_reports;
CREATE POLICY "Users can create own reports"
  ON public.analytics_reports FOR INSERT
  WITH CHECK (auth.uid() = user_id);
