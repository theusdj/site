-- Abel Arena · schema Supabase (rode no SQL Editor, uma vez)
create extension if not exists pgcrypto;

create table profiles (id uuid primary key references auth.users on delete cascade, name text,
  role text not null check (role in ('admin','organizer','editor')));
create table modalities (id uuid primary key default gen_random_uuid(), name text not null unique, active boolean not null default true);
create table teams (id uuid primary key default gen_random_uuid(), name text not null unique, class_name text,
  color text not null default '#1261A0', active boolean not null default true, created_at timestamptz not null default now());
create table matches (
  id uuid primary key default gen_random_uuid(),
  modality_id uuid not null references modalities on delete restrict,
  home_id uuid not null references teams on delete restrict,
  away_id uuid not null references teams on delete restrict,
  home_score int check (home_score >= 0), away_score int check (away_score >= 0),
  status text not null default 'scheduled' check (status in ('scheduled','live','finished','postponed','cancelled')),
  match_date date, match_time time, location text, phase text, round int, notes text,
  updated_at timestamptz not null default now(),
  check (home_id <> away_id),
  check (status not in ('live','finished') or (home_score is not null and away_score is not null)));
create table news (id uuid primary key default gen_random_uuid(), title text not null, content text not null, category text,
  author text, image_url text, published boolean not null default false, created_at timestamptz not null default now());
create table audit_log (id bigint generated always as identity primary key, user_id uuid, action text not null, detail text, created_at timestamptz not null default now());

create index on matches (modality_id, status); create index on matches (match_date);
create index on matches (home_id); create index on matches (away_id); create index on news (published, created_at desc);

create function is_staff(roles text[]) returns boolean language sql stable security definer set search_path = public
as $$ select exists (select 1 from profiles where id = auth.uid() and role = any(roles)) $$;

create function log_match() returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'DELETE' then insert into audit_log(user_id,action,detail) values (auth.uid(),'partida removida',old.id::text); return old; end if;
  new.updated_at := now();
  insert into audit_log(user_id,action,detail) values (auth.uid(), 'partida '||lower(tg_op)||' ('||new.status||')', new.home_score||' x '||new.away_score||' · '||new.id);
  return new;
end $$;
create trigger trg_match_audit before insert or update or delete on matches for each row execute function log_match();

alter table profiles enable row level security; alter table modalities enable row level security; alter table teams enable row level security;
alter table matches enable row level security; alter table news enable row level security; alter table audit_log enable row level security;

-- Leitura pública (somente conteúdo publicado)
create policy read_modalities on modalities for select using (true);
create policy read_teams on teams for select using (true);
create policy read_matches on matches for select using (true);
create policy read_news on news for select using (published or is_staff(array['admin','editor']));
-- Escrita: só autenticados com papel adequado
create policy w_modalities on modalities for all to authenticated using (is_staff(array['admin','organizer'])) with check (is_staff(array['admin','organizer']));
create policy w_teams on teams for all to authenticated using (is_staff(array['admin','organizer'])) with check (is_staff(array['admin','organizer']));
create policy w_matches on matches for all to authenticated using (is_staff(array['admin','organizer'])) with check (is_staff(array['admin','organizer']));
create policy w_news on news for all to authenticated using (is_staff(array['admin','editor'])) with check (is_staff(array['admin','editor']));
create policy own_profile on profiles for select to authenticated using (id = auth.uid() or is_staff(array['admin']));
create policy admin_profiles on profiles for all to authenticated using (is_staff(array['admin'])) with check (is_staff(array['admin']));
create policy read_audit on audit_log for select to authenticated using (is_staff(array['admin','organizer']));

alter publication supabase_realtime add table matches, teams, news, modalities;
insert into modalities(name) values ('Futsal'),('Vôlei'),('Queimada');

-- Depois de criar seu usuário em Authentication > Users, torne-o administrador:
-- insert into profiles(id,name,role) select id,'Seu nome','admin' from auth.users where email='seu@email.com';
