-- ============================================
-- TM CONTRACTOR TRACKER - COMPLETE SQL SETUP
-- ============================================
-- Run this script in your Supabase SQL Editor
-- ============================================

-- Step 1: Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- Step 2: Create Tables
-- ============================================

-- Table: users
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('contractor', 'so', 'executive', 'gmAgm')),
  name TEXT NOT NULL,
  team_id TEXT,
  manager_id UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for users
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_team_id ON users(team_id);
CREATE INDEX IF NOT EXISTS idx_users_manager_id ON users(manager_id);

-- Table: contractor_teams
CREATE TABLE IF NOT EXISTS contractor_teams (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  team_id TEXT UNIQUE NOT NULL,
  leader_name TEXT NOT NULL,
  so_id UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for contractor_teams
CREATE INDEX IF NOT EXISTS idx_contractor_teams_so_id ON contractor_teams(so_id);
CREATE INDEX IF NOT EXISTS idx_contractor_teams_team_id ON contractor_teams(team_id);

-- Table: attendance
CREATE TABLE IF NOT EXISTS attendance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id),
  team_id TEXT NOT NULL,
  check_in_time TIMESTAMP WITH TIME ZONE NOT NULL,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  location_address TEXT,
  date DATE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for attendance
CREATE INDEX IF NOT EXISTS idx_attendance_user_id ON attendance(user_id);
CREATE INDEX IF NOT EXISTS idx_attendance_team_id ON attendance(team_id);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance(date);
CREATE INDEX IF NOT EXISTS idx_attendance_check_in_time ON attendance(check_in_time);

-- Unique constraint: One check-in per user per day
CREATE UNIQUE INDEX IF NOT EXISTS idx_attendance_user_date ON attendance(user_id, date);

-- Table: tasks
CREATE TABLE IF NOT EXISTS tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  team_id TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  completion_percentage DOUBLE PRECISION DEFAULT 0 CHECK (completion_percentage >= 0 AND completion_percentage <= 100),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed')),
  created_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for tasks
CREATE INDEX IF NOT EXISTS idx_tasks_team_id ON tasks(team_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_created_by ON tasks(created_by);
CREATE INDEX IF NOT EXISTS idx_tasks_start_date ON tasks(start_date);

-- Table: task_updates
CREATE TABLE IF NOT EXISTS task_updates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id),
  image_url TEXT,
  comment TEXT NOT NULL,
  progress_update DOUBLE PRECISION CHECK (progress_update >= 0 AND progress_update <= 100),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for task_updates
CREATE INDEX IF NOT EXISTS idx_task_updates_task_id ON task_updates(task_id);
CREATE INDEX IF NOT EXISTS idx_task_updates_user_id ON task_updates(user_id);
CREATE INDEX IF NOT EXISTS idx_task_updates_updated_at ON task_updates(updated_at);

-- ============================================
-- Step 3: Enable Row Level Security (RLS)
-- ============================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE contractor_teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_updates ENABLE ROW LEVEL SECURITY;

-- ============================================
-- Step 4: Create RLS Policies
-- ============================================

-- Policies for users table
DROP POLICY IF EXISTS "Users can view their own data" ON users;
CREATE POLICY "Users can view their own data" ON users
  FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Admins can view all users" ON users;
CREATE POLICY "Admins can view all users" ON users
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('so', 'executive', 'gmAgm')
    )
  );

-- Policies for contractor_teams table
DROP POLICY IF EXISTS "SO can view their teams" ON contractor_teams;
CREATE POLICY "SO can view their teams" ON contractor_teams
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND id = so_id
    )
  );

DROP POLICY IF EXISTS "Executives and GM can view all teams" ON contractor_teams;
CREATE POLICY "Executives and GM can view all teams" ON contractor_teams
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('executive', 'gmAgm')
    )
  );

-- Policies for attendance table
DROP POLICY IF EXISTS "Users can view their own attendance" ON attendance;
CREATE POLICY "Users can view their own attendance" ON attendance
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own attendance" ON attendance;
CREATE POLICY "Users can insert their own attendance" ON attendance
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can view all attendance" ON attendance;
CREATE POLICY "Admins can view all attendance" ON attendance
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('so', 'executive', 'gmAgm')
    )
  );

-- Policies for tasks table
DROP POLICY IF EXISTS "Contractors can view their team's tasks" ON tasks;
CREATE POLICY "Contractors can view their team's tasks" ON tasks
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND users.team_id = tasks.team_id
    )
  );

DROP POLICY IF EXISTS "Admins can view all tasks" ON tasks;
CREATE POLICY "Admins can view all tasks" ON tasks
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('so', 'executive', 'gmAgm')
    )
  );

DROP POLICY IF EXISTS "Admins can create tasks" ON tasks;
CREATE POLICY "Admins can create tasks" ON tasks
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('so', 'executive', 'gmAgm')
    )
  );

DROP POLICY IF EXISTS "Admins can update tasks" ON tasks;
CREATE POLICY "Admins can update tasks" ON tasks
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('so', 'executive', 'gmAgm')
    )
  );

-- Policies for task_updates table
DROP POLICY IF EXISTS "Users can view updates for their tasks" ON task_updates;
CREATE POLICY "Users can view updates for their tasks" ON task_updates
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM tasks 
      JOIN users ON users.team_id = tasks.team_id 
      WHERE tasks.id = task_updates.task_id AND users.id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Contractors can insert updates for their tasks" ON task_updates;
CREATE POLICY "Contractors can insert updates for their tasks" ON task_updates
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM tasks 
      JOIN users ON users.team_id = tasks.team_id 
      WHERE tasks.id = task_id AND users.id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Admins can view all task updates" ON task_updates;
CREATE POLICY "Admins can view all task updates" ON task_updates
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('so', 'executive', 'gmAgm')
    )
  );

-- ============================================
-- Step 5: Create Storage Bucket for Task Images
-- ============================================
-- Note: Run this in SQL Editor if bucket doesn't exist
-- Or create manually in Supabase Dashboard > Storage

INSERT INTO storage.buckets (id, name, public) 
VALUES ('task-images', 'task-images', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies
DROP POLICY IF EXISTS "Authenticated users can upload images" ON storage.objects;
CREATE POLICY "Authenticated users can upload images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'task-images');

DROP POLICY IF EXISTS "Images are publicly accessible" ON storage.objects;
CREATE POLICY "Images are publicly accessible"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'task-images');

-- ============================================
-- Step 6: Insert Sample Users
-- ============================================
-- IMPORTANT: These users need to be created in Supabase Auth first!
-- You can use the SQL below, OR create them manually in Supabase Dashboard > Authentication

-- After creating users in Supabase Auth, insert their records into the users table

-- Sample passwords for all users: Test@123

-- GM/AGM User
INSERT INTO users (email, role, name)
VALUES ('gm@tm.com', 'gmAgm', 'General Manager')
ON CONFLICT (email) DO NOTHING;

-- Executive User
INSERT INTO users (email, role, name, manager_id)
VALUES (
  'executive@tm.com', 
  'executive', 
  'Executive Officer',
  (SELECT id FROM users WHERE email = 'gm@tm.com')
)
ON CONFLICT (email) DO NOTHING;

-- Site Officer 1
INSERT INTO users (email, role, name, manager_id)
VALUES (
  'so1@tm.com', 
  'so', 
  'Site Officer Alpha',
  (SELECT id FROM users WHERE email = 'executive@tm.com')
)
ON CONFLICT (email) DO NOTHING;

-- Site Officer 2
INSERT INTO users (email, role, name, manager_id)
VALUES (
  'so2@tm.com', 
  'so', 
  'Site Officer Beta',
  (SELECT id FROM users WHERE email = 'executive@tm.com')
)
ON CONFLICT (email) DO NOTHING;

-- ============================================
-- Step 7: Create Contractor Teams
-- ============================================

-- Team 1 under SO1
INSERT INTO contractor_teams (team_id, leader_name, so_id)
VALUES (
  'TEAM001',
  'John Doe',
  (SELECT id FROM users WHERE email = 'so1@tm.com')
)
ON CONFLICT (team_id) DO NOTHING;

-- Team 2 under SO1
INSERT INTO contractor_teams (team_id, leader_name, so_id)
VALUES (
  'TEAM002',
  'Jane Smith',
  (SELECT id FROM users WHERE email = 'so1@tm.com')
)
ON CONFLICT (team_id) DO NOTHING;

-- Team 3 under SO2
INSERT INTO contractor_teams (team_id, leader_name, so_id)
VALUES (
  'TEAM003',
  'Mike Johnson',
  (SELECT id FROM users WHERE email = 'so2@tm.com')
)
ON CONFLICT (team_id) DO NOTHING;

-- Team 4 under SO2
INSERT INTO contractor_teams (team_id, leader_name, so_id)
VALUES (
  'TEAM004',
  'Sarah Williams',
  (SELECT id FROM users WHERE email = 'so2@tm.com')
)
ON CONFLICT (team_id) DO NOTHING;

-- ============================================
-- Step 8: Create Contractor Users
-- ============================================

-- Contractors for TEAM001
INSERT INTO users (email, role, name, team_id)
VALUES ('contractor1@tm.com', 'contractor', 'John Doe', 'TEAM001')
ON CONFLICT (email) DO NOTHING;

INSERT INTO users (email, role, name, team_id)
VALUES ('contractor2@tm.com', 'contractor', 'Alex Brown', 'TEAM001')
ON CONFLICT (email) DO NOTHING;

-- Contractors for TEAM002
INSERT INTO users (email, role, name, team_id)
VALUES ('contractor3@tm.com', 'contractor', 'Jane Smith', 'TEAM002')
ON CONFLICT (email) DO NOTHING;

INSERT INTO users (email, role, name, team_id)
VALUES ('contractor4@tm.com', 'contractor', 'Emily Davis', 'TEAM002')
ON CONFLICT (email) DO NOTHING;

-- Contractors for TEAM003
INSERT INTO users (email, role, name, team_id)
VALUES ('contractor5@tm.com', 'contractor', 'Mike Johnson', 'TEAM003')
ON CONFLICT (email) DO NOTHING;

INSERT INTO users (email, role, name, team_id)
VALUES ('contractor6@tm.com', 'contractor', 'Chris Wilson', 'TEAM003')
ON CONFLICT (email) DO NOTHING;

-- Contractors for TEAM004
INSERT INTO users (email, role, name, team_id)
VALUES ('contractor7@tm.com', 'contractor', 'Sarah Williams', 'TEAM004')
ON CONFLICT (email) DO NOTHING;

INSERT INTO users (email, role, name, team_id)
VALUES ('contractor8@tm.com', 'contractor', 'Lisa Martinez', 'TEAM004')
ON CONFLICT (email) DO NOTHING;

-- ============================================
-- Step 9: Create Sample Tasks
-- ============================================

-- Tasks for TEAM001
INSERT INTO tasks (team_id, title, description, start_date, end_date, completion_percentage, status, created_by)
VALUES (
  'TEAM001',
  'Building Foundation Work',
  'Complete foundation excavation and concrete pouring for Block A',
  CURRENT_DATE - INTERVAL '5 days',
  CURRENT_DATE + INTERVAL '10 days',
  45.0,
  'in_progress',
  (SELECT id FROM users WHERE email = 'so1@tm.com')
);

INSERT INTO tasks (team_id, title, description, start_date, end_date, completion_percentage, status, created_by)
VALUES (
  'TEAM001',
  'Steel Framework Installation',
  'Install steel framework for building structure',
  CURRENT_DATE,
  CURRENT_DATE + INTERVAL '20 days',
  10.0,
  'in_progress',
  (SELECT id FROM users WHERE email = 'so1@tm.com')
);

-- Tasks for TEAM002
INSERT INTO tasks (team_id, title, description, start_date, end_date, completion_percentage, status, created_by)
VALUES (
  'TEAM002',
  'Electrical Wiring - Floor 1',
  'Complete electrical wiring and conduit installation for first floor',
  CURRENT_DATE - INTERVAL '3 days',
  CURRENT_DATE + INTERVAL '7 days',
  60.0,
  'in_progress',
  (SELECT id FROM users WHERE email = 'so1@tm.com')
);

INSERT INTO tasks (team_id, title, description, start_date, end_date, completion_percentage, status, created_by)
VALUES (
  'TEAM002',
  'Site Cleanup',
  'Clean up construction site and organize materials',
  CURRENT_DATE - INTERVAL '2 days',
  CURRENT_DATE + INTERVAL '1 day',
  90.0,
  'in_progress',
  (SELECT id FROM users WHERE email = 'so1@tm.com')
);

-- Tasks for TEAM003
INSERT INTO tasks (team_id, title, description, start_date, end_date, completion_percentage, status, created_by)
VALUES (
  'TEAM003',
  'Plumbing Installation',
  'Install main water lines and drainage system',
  CURRENT_DATE - INTERVAL '7 days',
  CURRENT_DATE + INTERVAL '5 days',
  75.0,
  'in_progress',
  (SELECT id FROM users WHERE email = 'so2@tm.com')
);

INSERT INTO tasks (team_id, title, description, start_date, end_date, completion_percentage, status, created_by)
VALUES (
  'TEAM003',
  'Bathroom Fixture Installation',
  'Install toilets, sinks, and showers in all bathrooms',
  CURRENT_DATE,
  CURRENT_DATE + INTERVAL '15 days',
  5.0,
  'pending',
  (SELECT id FROM users WHERE email = 'so2@tm.com')
);

-- Tasks for TEAM004
INSERT INTO tasks (team_id, title, description, start_date, end_date, completion_percentage, status, created_by)
VALUES (
  'TEAM004',
  'Painting - Interior Walls',
  'Paint all interior walls with primer and finish coat',
  CURRENT_DATE - INTERVAL '10 days',
  CURRENT_DATE - INTERVAL '1 day',
  100.0,
  'completed',
  (SELECT id FROM users WHERE email = 'so2@tm.com')
);

INSERT INTO tasks (team_id, title, description, start_date, end_date, completion_percentage, status, created_by)
VALUES (
  'TEAM004',
  'Flooring Installation',
  'Install ceramic tiles in kitchen and living areas',
  CURRENT_DATE - INTERVAL '4 days',
  CURRENT_DATE + INTERVAL '6 days',
  55.0,
  'in_progress',
  (SELECT id FROM users WHERE email = 'so2@tm.com')
);

-- ============================================
-- Step 10: Create Sample Attendance Records
-- ============================================

-- Attendance for the last 7 days for various contractors
-- Using various locations in Malaysia

-- TEAM001 Contractors
INSERT INTO attendance (user_id, team_id, check_in_time, latitude, longitude, location_address, date)
VALUES (
  (SELECT id FROM users WHERE email = 'contractor1@tm.com'),
  'TEAM001',
  CURRENT_TIMESTAMP - INTERVAL '1 day' + INTERVAL '8 hours',
  3.1390,
  101.6869,
  'Kuala Lumpur City Centre, Malaysia',
  CURRENT_DATE - INTERVAL '1 day'
)
ON CONFLICT (user_id, date) DO NOTHING;

INSERT INTO attendance (user_id, team_id, check_in_time, latitude, longitude, location_address, date)
VALUES (
  (SELECT id FROM users WHERE email = 'contractor2@tm.com'),
  'TEAM001',
  CURRENT_TIMESTAMP - INTERVAL '1 day' + INTERVAL '8 hours 15 minutes',
  3.1390,
  101.6869,
  'Kuala Lumpur City Centre, Malaysia',
  CURRENT_DATE - INTERVAL '1 day'
)
ON CONFLICT (user_id, date) DO NOTHING;

-- TEAM002 Contractors
INSERT INTO attendance (user_id, team_id, check_in_time, latitude, longitude, location_address, date)
VALUES (
  (SELECT id FROM users WHERE email = 'contractor3@tm.com'),
  'TEAM002',
  CURRENT_TIMESTAMP - INTERVAL '1 day' + INTERVAL '7 hours 45 minutes',
  5.4164,
  100.3327,
  'Georgetown, Penang, Malaysia',
  CURRENT_DATE - INTERVAL '1 day'
)
ON CONFLICT (user_id, date) DO NOTHING;

INSERT INTO attendance (user_id, team_id, check_in_time, latitude, longitude, location_address, date)
VALUES (
  (SELECT id FROM users WHERE email = 'contractor4@tm.com'),
  'TEAM002',
  CURRENT_TIMESTAMP - INTERVAL '1 day' + INTERVAL '8 hours 5 minutes',
  5.4164,
  100.3327,
  'Georgetown, Penang, Malaysia',
  CURRENT_DATE - INTERVAL '1 day'
)
ON CONFLICT (user_id, date) DO NOTHING;

-- TEAM003 Contractors
INSERT INTO attendance (user_id, team_id, check_in_time, latitude, longitude, location_address, date)
VALUES (
  (SELECT id FROM users WHERE email = 'contractor5@tm.com'),
  'TEAM003',
  CURRENT_TIMESTAMP - INTERVAL '2 days' + INTERVAL '8 hours 10 minutes',
  1.4927,
  103.7414,
  'Johor Bahru, Malaysia',
  CURRENT_DATE - INTERVAL '2 days'
)
ON CONFLICT (user_id, date) DO NOTHING;

INSERT INTO attendance (user_id, team_id, check_in_time, latitude, longitude, location_address, date)
VALUES (
  (SELECT id FROM users WHERE email = 'contractor6@tm.com'),
  'TEAM003',
  CURRENT_TIMESTAMP - INTERVAL '2 days' + INTERVAL '8 hours 30 minutes',
  1.4927,
  103.7414,
  'Johor Bahru, Malaysia',
  CURRENT_DATE - INTERVAL '2 days'
)
ON CONFLICT (user_id, date) DO NOTHING;

-- TEAM004 Contractors
INSERT INTO attendance (user_id, team_id, check_in_time, latitude, longitude, location_address, date)
VALUES (
  (SELECT id FROM users WHERE email = 'contractor7@tm.com'),
  'TEAM004',
  CURRENT_TIMESTAMP - INTERVAL '3 days' + INTERVAL '7 hours 55 minutes',
  2.1896,
  102.2501,
  'Malacca City, Malaysia',
  CURRENT_DATE - INTERVAL '3 days'
)
ON CONFLICT (user_id, date) DO NOTHING;

INSERT INTO attendance (user_id, team_id, check_in_time, latitude, longitude, location_address, date)
VALUES (
  (SELECT id FROM users WHERE email = 'contractor8@tm.com'),
  'TEAM004',
  CURRENT_TIMESTAMP - INTERVAL '3 days' + INTERVAL '8 hours 20 minutes',
  2.1896,
  102.2501,
  'Malacca City, Malaysia',
  CURRENT_DATE - INTERVAL '3 days'
)
ON CONFLICT (user_id, date) DO NOTHING;

-- ============================================
-- Step 11: Create Sample Task Updates
-- ============================================

-- Task updates with progress comments
INSERT INTO task_updates (task_id, user_id, comment, progress_update, updated_at)
VALUES (
  (SELECT id FROM tasks WHERE title = 'Building Foundation Work' LIMIT 1),
  (SELECT id FROM users WHERE email = 'contractor1@tm.com'),
  'Completed excavation for section A. Started concrete preparation.',
  45.0,
  CURRENT_TIMESTAMP - INTERVAL '1 day'
);

INSERT INTO task_updates (task_id, user_id, comment, progress_update, updated_at)
VALUES (
  (SELECT id FROM tasks WHERE title = 'Electrical Wiring - Floor 1' LIMIT 1),
  (SELECT id FROM users WHERE email = 'contractor3@tm.com'),
  'Completed wiring for 3 out of 5 rooms. Inspection scheduled for tomorrow.',
  60.0,
  CURRENT_TIMESTAMP - INTERVAL '1 day'
);

INSERT INTO task_updates (task_id, user_id, comment, progress_update, updated_at)
VALUES (
  (SELECT id FROM tasks WHERE title = 'Plumbing Installation' LIMIT 1),
  (SELECT id FROM users WHERE email = 'contractor5@tm.com'),
  'Main water lines installed. Testing for leaks completed successfully.',
  75.0,
  CURRENT_TIMESTAMP - INTERVAL '2 days'
);

INSERT INTO task_updates (task_id, user_id, comment, progress_update, updated_at)
VALUES (
  (SELECT id FROM tasks WHERE title = 'Painting - Interior Walls' LIMIT 1),
  (SELECT id FROM users WHERE email = 'contractor7@tm.com'),
  'Final coat applied to all rooms. Project completed.',
  100.0,
  CURRENT_TIMESTAMP - INTERVAL '3 days'
);

-- ============================================
-- SETUP COMPLETE!
-- ============================================

-- ============================================
-- TEST CREDENTIALS
-- ============================================

/*
IMPORTANT: You need to create these users in Supabase Authentication first!

Go to: Supabase Dashboard > Authentication > Users > Add User

Create the following users with password: Test@123

ADMIN USERS (Login with Email + Password):
=======================================
1. GM/AGM:
   Email: gm@tm.com
   Password: Test@123
   
2. Executive:
   Email: executive@tm.com
   Password: Test@123
   
3. Site Officer 1:
   Email: so1@tm.com
   Password: Test@123
   
4. Site Officer 2:
   Email: so2@tm.com
   Password: Test@123

CONTRACTOR USERS (Login with Team ID + Leader Name):
================================================
1. Team: TEAM001, Leader: John Doe
2. Team: TEAM002, Leader: Jane Smith
3. Team: TEAM003, Leader: Mike Johnson
4. Team: TEAM004, Leader: Sarah Williams

Note: Contractors also need email accounts in Auth for RLS to work:
- contractor1@tm.com to contractor8@tm.com (Password: Test@123)
*/

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Check all users
SELECT email, role, name, team_id FROM users ORDER BY role, name;

-- Check all teams
SELECT team_id, leader_name FROM contractor_teams ORDER BY team_id;

-- Check all tasks
SELECT team_id, title, completion_percentage, status FROM tasks ORDER BY team_id, title;

-- Check attendance count
SELECT COUNT(*) as total_attendance FROM attendance;

-- Check task updates count
SELECT COUNT(*) as total_updates FROM task_updates;

-- ============================================
-- SUCCESS!
-- ============================================
-- Your database is now ready to use!
-- Don't forget to:
-- 1. Create users in Supabase Authentication
-- 2. Create storage bucket 'task-images'
-- 3. Update your Flutter app with Supabase credentials
-- ============================================
