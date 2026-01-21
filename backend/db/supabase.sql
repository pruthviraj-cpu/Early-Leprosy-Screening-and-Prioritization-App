create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  age int,
  gender text,
  phone text,
  created_at timestamp default now()
);

create table ai_chats (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  role text check (role in ('user', 'ai')),
  message text,
  created_at timestamp default now()
);

create table diagnosis_results (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,

  disease_name text, -- "Leprosy"
  probability numeric(5,2), -- 0.00 - 100.00

  age int,
  gender text,

  latitude numeric(9,6),
  longitude numeric(9,6),

  image_url text, -- Supabase Storage URL

  created_at timestamp default now()
);

create table user_locations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  latitude numeric(9,6),
  longitude numeric(9,6),
  created_at timestamp default now()
);

create index idx_ai_chats_user on ai_chats(user_id, created_at);
create index idx_diagnosis_user on diagnosis_results(user_id, created_at);

alter table profiles enable row level security;
alter table ai_chats enable row level security;
alter table diagnosis_results enable row level security;

create policy "User can read own chats"
on ai_chats
for select
using (auth.uid() = user_id);

create policy "User can insert own chats"
on ai_chats
for insert
with check (auth.uid() = user_id);



