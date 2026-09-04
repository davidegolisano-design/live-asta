create extension if not exists pgcrypto;

create table if not exists public.fanta_rooms (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  password text not null default '',
  initial_credits integer not null default 500 check (initial_credits > 0),
  limit_p integer not null default 3 check (limit_p >= 0),
  limit_d integer not null default 8 check (limit_d >= 0),
  limit_c integer not null default 8 check (limit_c >= 0),
  limit_a integer not null default 6 check (limit_a >= 0),
  timer_seconds integer not null default 5 check (timer_seconds > 0),
  prep_seconds integer not null default 5 check (prep_seconds > 0),
  sealed_timer_seconds integer not null default 30 check (sealed_timer_seconds > 0),
  sealed_reveal_seconds integer not null default 5 check (sealed_reveal_seconds > 0),
  auctioned_ids jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.fanta_teams (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.fanta_rooms(id) on delete cascade,
  name text not null,
  credits_remaining integer not null default 500 check (credits_remaining >= 0),
  created_at timestamptz not null default now(),
  unique(room_id,name)
);

create table if not exists public.fanta_purchases (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.fanta_rooms(id) on delete cascade,
  team_id uuid not null references public.fanta_teams(id) on delete cascade,
  player_id text not null,
  player_name text not null default '',
  role text not null default '',
  club text not null default '',
  price integer not null check (price > 0),
  created_at timestamptz not null default now(),
  unique(room_id,player_id)
);

create table if not exists public.fanta_app_data (
  key text primary key,
  data jsonb,
  file_name text,
  updated_at timestamptz not null default now()
);

alter table public.fanta_rooms enable row level security;
alter table public.fanta_teams enable row level security;
alter table public.fanta_purchases enable row level security;
alter table public.fanta_app_data enable row level security;

drop policy if exists liveasta_rooms_all on public.fanta_rooms;
create policy liveasta_rooms_all on public.fanta_rooms for all to anon using (true) with check (true);
drop policy if exists liveasta_teams_all on public.fanta_teams;
create policy liveasta_teams_all on public.fanta_teams for all to anon using (true) with check (true);
drop policy if exists liveasta_purchases_all on public.fanta_purchases;
create policy liveasta_purchases_all on public.fanta_purchases for all to anon using (true) with check (true);
drop policy if exists liveasta_app_data_all on public.fanta_app_data;
create policy liveasta_app_data_all on public.fanta_app_data for all to anon using (true) with check (true);

create or replace function public.fanta_assign_player(
  p_room_id uuid, p_team_id uuid, p_player_id text, p_player_name text,
  p_role text, p_club text, p_price integer
) returns void language plpgsql security definer set search_path=public as $$
declare v_credits integer;
begin
  if p_price is null or p_price <= 0 then raise exception 'Prezzo non valido'; end if;
  select credits_remaining into v_credits from fanta_teams where id=p_team_id and room_id=p_room_id for update;
  if v_credits is null then raise exception 'Squadra non trovata'; end if;
  if v_credits < p_price then raise exception 'Crediti insufficienti'; end if;
  if exists(select 1 from fanta_purchases where room_id=p_room_id and player_id=p_player_id) then raise exception 'Giocatore già assegnato'; end if;
  insert into fanta_purchases(room_id,team_id,player_id,player_name,role,club,price)
  values(p_room_id,p_team_id,p_player_id,coalesce(p_player_name,''),coalesce(p_role,''),coalesce(p_club,''),p_price);
  update fanta_teams set credits_remaining=credits_remaining-p_price where id=p_team_id;
end $$;

create or replace function public.fanta_remove_purchase(p_purchase_id uuid)
returns void language plpgsql security definer set search_path=public as $$
declare v_team uuid; v_price integer;
begin
  select team_id,price into v_team,v_price from fanta_purchases where id=p_purchase_id for update;
  if v_team is null then return; end if;
  delete from fanta_purchases where id=p_purchase_id;
  update fanta_teams set credits_remaining=credits_remaining+v_price where id=v_team;
end $$;

grant usage on schema public to anon;
grant select,insert,update,delete on public.fanta_rooms,public.fanta_teams,public.fanta_purchases,public.fanta_app_data to anon;
grant execute on function public.fanta_assign_player(uuid,uuid,text,text,text,text,integer) to anon;
grant execute on function public.fanta_remove_purchase(uuid) to anon;
