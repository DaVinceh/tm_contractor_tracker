# Database Schema

This document describes the complete database schema for the TM Contractor Tracker application.

## Tables Overview

1. **users** - All system users (contractors and admins)
2. **contractor_teams** - Contractor team information
3. **attendance** - Daily check-in records
4. **tasks** - Tasks assigned to teams
5. **task_updates** - Daily task progress updates

---

## Table: `users`

Stores all user information including contractors and admin staff.

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('contractor', 'so', 'executive', 'gmAgm')),
  name TEXT NOT NULL,
  team_id TEXT,
  manager_id UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_team_id ON users(team_id);
CREATE INDEX idx_users_manager_id ON users(manager_id);

-- Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own data" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Admins can view all users" ON users
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('so', 'executive', 'gmAgm')
    )
  );
```

### Fields:
- `id`: Unique user identifier
- `email`: User email address
- `role`: User role (contractor, so, executive, gmAgm)
- `name`: Full name
- `team_id`: Team ID (for contractors only)
- `manager_id`: Reference to manager (SO → Executive, Executive → GM/AGM)
- `created_at`: Record creation timestamp
- `updated_at`: Record update timestamp

---

## Table: `contractor_teams`

Stores contractor team information.

```sql
CREATE TABLE contractor_teams (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  team_id TEXT UNIQUE NOT NULL,
  leader_name TEXT NOT NULL,
  so_id UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_contractor_teams_so_id ON contractor_teams(so_id);
CREATE INDEX idx_contractor_teams_team_id ON contractor_teams(team_id);

-- Row Level Security
ALTER TABLE contractor_teams ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "SO can view their teams" ON contractor_teams
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND id = so_id
    )
  );

CREATE POLICY "Executives and GM can view all teams" ON contractor_teams
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('executive', 'gmAgm')
    )
  );
```

### Fields:
- `id`: Unique team identifier
- `team_id`: Human-readable team ID
- `leader_name`: Team leader's name
- `so_id`: Reference to Site Officer managing this team
- `created_at`: Record creation timestamp
- `updated_at`: Record update timestamp

---

## Table: `attendance`

Records daily check-ins with location data.

```sql
CREATE TABLE attendance (
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

-- Indexes
CREATE INDEX idx_attendance_user_id ON attendance(user_id);
CREATE INDEX idx_attendance_team_id ON attendance(team_id);
CREATE INDEX idx_attendance_date ON attendance(date);
CREATE INDEX idx_attendance_check_in_time ON attendance(check_in_time);

-- Unique constraint: One check-in per user per day
CREATE UNIQUE INDEX idx_attendance_user_date ON attendance(user_id, date);

-- Row Level Security
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own attendance" ON attendance
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own attendance" ON attendance
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all attendance" ON attendance
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('so', 'executive', 'gmAgm')
    )
  );
```

### Fields:
- `id`: Unique attendance record identifier
- `user_id`: Reference to user who checked in
- `team_id`: Team ID of the user
- `check_in_time`: Exact check-in timestamp
- `latitude`: GPS latitude
- `longitude`: GPS longitude
- `location_address`: Geocoded address (optional)
- `date`: Check-in date (for querying)
- `created_at`: Record creation timestamp

---

## Table: `tasks`

Tasks assigned to contractor teams.

```sql
CREATE TABLE tasks (
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

-- Indexes
CREATE INDEX idx_tasks_team_id ON tasks(team_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_created_by ON tasks(created_by);
CREATE INDEX idx_tasks_start_date ON tasks(start_date);

-- Row Level Security
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Contractors can view their team's tasks" ON tasks
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND users.team_id = tasks.team_id
    )
  );

CREATE POLICY "Admins can view all tasks" ON tasks
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('so', 'executive', 'gmAgm')
    )
  );

CREATE POLICY "Admins can create tasks" ON tasks
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('so', 'executive', 'gmAgm')
    )
  );

CREATE POLICY "Admins can update tasks" ON tasks
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('so', 'executive', 'gmAgm')
    )
  );
```

### Fields:
- `id`: Unique task identifier
- `team_id`: Team assigned to this task
- `title`: Task title
- `description`: Detailed task description
- `start_date`: Task start date
- `end_date`: Task deadline (optional)
- `completion_percentage`: Current completion (0-100)
- `status`: Task status (pending, in_progress, completed)
- `created_by`: Admin user who created the task
- `created_at`: Record creation timestamp
- `updated_at`: Record update timestamp

---

## Table: `task_updates`

Daily progress updates for tasks with photos and comments.

```sql
CREATE TABLE task_updates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id),
  image_url TEXT,
  comment TEXT NOT NULL,
  progress_update DOUBLE PRECISION CHECK (progress_update >= 0 AND progress_update <= 100),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_task_updates_task_id ON task_updates(task_id);
CREATE INDEX idx_task_updates_user_id ON task_updates(user_id);
CREATE INDEX idx_task_updates_updated_at ON task_updates(updated_at);

-- Row Level Security
ALTER TABLE task_updates ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view updates for their tasks" ON task_updates
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM tasks 
      JOIN users ON users.team_id = tasks.team_id 
      WHERE tasks.id = task_updates.task_id AND users.id = auth.uid()
    )
  );

CREATE POLICY "Contractors can insert updates for their tasks" ON task_updates
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM tasks 
      JOIN users ON users.team_id = tasks.team_id 
      WHERE tasks.id = task_id AND users.id = auth.uid()
    )
  );

CREATE POLICY "Admins can view all task updates" ON task_updates
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('so', 'executive', 'gmAgm')
    )
  );
```

### Fields:
- `id`: Unique update identifier
- `task_id`: Reference to the task being updated
- `user_id`: User who submitted the update
- `image_url`: URL to uploaded photo (optional)
- `comment`: Progress comment/description
- `progress_update`: New completion percentage (optional)
- `updated_at`: Update timestamp
- `created_at`: Record creation timestamp

---

## Storage Buckets

### `task-images`

Stores task update photos.

```sql
-- Create storage bucket
INSERT INTO storage.buckets (id, name, public) 
VALUES ('task-images', 'task-images', true);

-- Storage policies
CREATE POLICY "Authenticated users can upload images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'task-images');

CREATE POLICY "Images are publicly accessible"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'task-images');
```

---

## Initial Setup SQL

Run this complete script in your Supabase SQL Editor:

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create all tables (copy from above)
-- ...

-- Insert sample data (optional for testing)

-- Sample GM/AGM
INSERT INTO auth.users (email, encrypted_password, email_confirmed_at)
VALUES ('gm@tm.com', crypt('password123', gen_salt('bf')), NOW());

INSERT INTO users (id, email, role, name)
VALUES (
  (SELECT id FROM auth.users WHERE email = 'gm@tm.com'),
  'gm@tm.com',
  'gmAgm',
  'General Manager'
);

-- Sample Executive
INSERT INTO auth.users (email, encrypted_password, email_confirmed_at)
VALUES ('executive@tm.com', crypt('password123', gen_salt('bf')), NOW());

INSERT INTO users (id, email, role, name, manager_id)
VALUES (
  (SELECT id FROM auth.users WHERE email = 'executive@tm.com'),
  'executive@tm.com',
  'executive',
  'Executive Officer',
  (SELECT id FROM users WHERE email = 'gm@tm.com')
);

-- Sample Site Officer
INSERT INTO auth.users (email, encrypted_password, email_confirmed_at)
VALUES ('so@tm.com', crypt('password123', gen_salt('bf')), NOW());

INSERT INTO users (id, email, role, name, manager_id)
VALUES (
  (SELECT id FROM auth.users WHERE email = 'so@tm.com'),
  'so@tm.com',
  'so',
  'Site Officer Alpha',
  (SELECT id FROM users WHERE email = 'executive@tm.com')
);

-- Sample Contractor Team
INSERT INTO contractor_teams (team_id, leader_name, so_id)
VALUES (
  'TEAM001',
  'John Doe',
  (SELECT id FROM users WHERE email = 'so@tm.com')
);
```

---

## Database Relationships

```
users (GM/AGM)
  └── users (Executive) [manager_id]
      └── users (SO) [manager_id]
          └── contractor_teams [so_id]
              └── users (Contractors) [team_id]
                  └── attendance [user_id]
              └── tasks [team_id]
                  └── task_updates [task_id]
```

---

## Maintenance

### Regular Cleanup

```sql
-- Delete old attendance records (older than 1 year)
DELETE FROM attendance WHERE created_at < NOW() - INTERVAL '1 year';

-- Archive completed tasks (optional)
-- Move to separate archive table if needed
```

### Indexes Maintenance

```sql
-- Reindex for performance
REINDEX TABLE users;
REINDEX TABLE attendance;
REINDEX TABLE tasks;
```

---

## Backup Strategy

1. Enable Supabase automatic backups (available in paid plans)
2. Export data regularly using Supabase dashboard
3. Use `pg_dump` for manual backups

```bash
pg_dump -h db.xxx.supabase.co -U postgres -d postgres > backup.sql
```
