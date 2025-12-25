-- Multi-Format Book Support Migration
-- Run this in Supabase SQL Editor before deploying the app update

-- 1. Create user_settings table for migration version tracking
CREATE TABLE IF NOT EXISTS user_settings (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  migration_version INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS for user_settings
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own settings" ON user_settings
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own settings" ON user_settings
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own settings" ON user_settings
  FOR UPDATE USING (auth.uid() = user_id);

-- 2. Create library_book_formats table
CREATE TABLE library_book_formats (
  id SERIAL PRIMARY KEY,
  library_book_id INTEGER REFERENCES library(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  format TEXT NOT NULL,  -- 'audiobook', 'eBook', 'paperback', 'hardcover'
  length INTEGER,        -- pages for physical/ebook, minutes for audiobook (nullable)
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for efficient lookups
CREATE INDEX idx_library_book_formats_book ON library_book_formats(library_book_id);
CREATE INDEX idx_library_book_formats_user ON library_book_formats(user_id);

-- RLS for library_book_formats
ALTER TABLE library_book_formats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own formats" ON library_book_formats
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own formats" ON library_book_formats
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own formats" ON library_book_formats
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own formats" ON library_book_formats
  FOR DELETE USING (auth.uid() = user_id);

-- 3. Add format_id column to progress_events (nullable initially for migration)
ALTER TABLE progress_events ADD COLUMN IF NOT EXISTS format_id INTEGER REFERENCES library_book_formats(id);

-- Index for efficient lookups
CREATE INDEX IF NOT EXISTS idx_progress_events_format ON progress_events(format_id);
