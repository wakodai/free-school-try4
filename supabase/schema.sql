-- Supabase schema for guardians, students, attendance submissions, and message logs
-- Idempotent definitions to allow re-application via SQL editor.

-- Enable UUID generation if not already available
create extension if not exists "pgcrypto";

create table if not exists guardians (
  id uuid primary key default gen_random_uuid(),
  line_user_id text unique,
  name text not null,
  phone text,
  created_at timestamptz not null default now()
);

create table if not exists students (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  grade text,
  created_at timestamptz not null default now()
);

create table if not exists guardian_students (
  guardian_id uuid not null references guardians(id) on delete cascade,
  student_id uuid not null references students(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (guardian_id, student_id)
);

create table if not exists attendance_submissions (
  id uuid primary key default gen_random_uuid(),
  guardian_id uuid not null references guardians(id) on delete cascade,
  student_id uuid not null references students(id) on delete cascade,
  date date not null,
  status text not null check (status in ('present', 'absent', 'late', 'unknown')),
  note text,
  submitted_at timestamptz not null default now(),
  unique (guardian_id, student_id, date)
);

create index if not exists idx_attendance_date on attendance_submissions(date);
create index if not exists idx_attendance_student on attendance_submissions(student_id);

create table if not exists message_logs (
  id uuid primary key default gen_random_uuid(),
  guardian_id uuid references guardians(id) on delete set null,
  direction text not null check (direction in ('inbound', 'outbound')),
  body text not null,
  metadata jsonb default '{}'::jsonb,
  sent_at timestamptz not null default now()
);

create index if not exists idx_message_logs_guardian on message_logs(guardian_id, sent_at desc);

-- Sample data for local development
-- Guardrails: ON CONFLICT DO NOTHING keeps the seed idempotent.
insert into guardians (id, line_user_id, name, phone)
values
  ('11111111-1111-4111-8111-111111111111', 'line_user_ayaka', '佐藤綾香', '090-1111-2222'),
  ('22222222-2222-4222-8222-222222222222', 'line_user_kazuki', '田中和樹', '080-3333-4444')
on conflict (id) do update set
  line_user_id = excluded.line_user_id,
  name = excluded.name,
  phone = excluded.phone;

insert into students (id, name, grade)
values
  ('33333333-3333-4333-8333-333333333333', '佐藤太一', '小学5年'),
  ('44444444-4444-4444-8444-444444444444', '田中ゆい', '小学4年'),
  ('55555555-5555-4555-8555-555555555555', '田中はると', '小学2年')
on conflict (id) do update set
  name = excluded.name,
  grade = excluded.grade;

insert into guardian_students (guardian_id, student_id)
values
  ('11111111-1111-4111-8111-111111111111', '33333333-3333-4333-8333-333333333333'),
  ('22222222-2222-4222-8222-222222222222', '44444444-4444-4444-8444-444444444444'),
  ('22222222-2222-4222-8222-222222222222', '55555555-5555-4555-8555-555555555555')
on conflict (guardian_id, student_id) do nothing;

insert into attendance_submissions (id, guardian_id, student_id, date, status, note)
values
  ('66666666-6666-4666-8666-666666666666', '11111111-1111-4111-8111-111111111111', '33333333-3333-4333-8333-333333333333', '2026-01-05', 'present', '通常通り出席'),
  ('77777777-7777-4777-8777-777777777777', '22222222-2222-4222-8222-222222222222', '44444444-4444-4444-8444-444444444444', '2026-01-06', 'absent', '発熱のため欠席'),
  ('88888888-8888-4888-8888-888888888888', '22222222-2222-4222-8222-222222222222', '55555555-5555-4555-8555-555555555555', '2026-01-06', 'late', '通院後に参加')
on conflict (id) do update set
  guardian_id = excluded.guardian_id,
  student_id = excluded.student_id,
  date = excluded.date,
  status = excluded.status,
  note = excluded.note;

insert into message_logs (id, guardian_id, direction, body, metadata, sent_at)
values
  ('99999999-9999-4999-8999-999999999999', '11111111-1111-4111-8111-111111111111', 'inbound', '今日の宿題はありますか？', '{"line_message_id":"msg-in-1"}', '2026-01-05T12:00:00Z'),
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111111', 'outbound', '宿題は算数プリント3枚です。', '{"line_message_id":"msg-out-1"}', '2026-01-05T12:05:00Z'),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', '22222222-2222-4222-8222-222222222222', 'inbound', '明日の持ち物を教えてください。', '{"line_message_id":"msg-in-2"}', '2026-01-06T09:00:00Z')
on conflict (id) do update set
  guardian_id = excluded.guardian_id,
  direction = excluded.direction,
  body = excluded.body,
  metadata = excluded.metadata,
  sent_at = excluded.sent_at;
