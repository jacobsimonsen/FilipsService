-- Kør i Supabase SQL Editor efter oprettelse af Filips bruger.
begin;
create schema if not exists filips_private;
revoke all on schema filips_private from public;
grant usage on schema filips_private to anon, authenticated;

create table if not exists filips_private.admin_users (user_id uuid primary key references auth.users(id));
create table if not exists filips_private.rate_limits (key text primary key, count integer not null, expires_at timestamptz not null);
revoke all on all tables in schema filips_private from public, anon, authenticated;
do $$
declare owner_id uuid;
begin
  select id into owner_id from auth.users where lower(email) = 'filipvsimonsen@gmail.com';
  if owner_id is null then raise exception 'Opret først Filips bekræftede bruger med filipvsimonsen@gmail.com under Authentication → Users.'; end if;
  insert into filips_private.admin_users(user_id) values(owner_id) on conflict do nothing;
end $$;

create table if not exists public.filips_jobs (
  id uuid primary key,
  created_at timestamptz not null default now(),
  requested_date date not null,
  scheduled_date date not null,
  status text not null default 'new' check(status in ('new','accepted')),
  service text not null check(service in ('Snerydning','Græsslåning','Løvrydning')),
  customer_name text not null,
  address text not null,
  email text not null,
  phone text not null,
  message text not null default '',
  extras jsonb not null default '[]',
  price integer not null check(price >= 0),
  payload_hash text not null
);
create index if not exists filips_jobs_date_idx on public.filips_jobs(scheduled_date,created_at,id);
alter table public.filips_jobs enable row level security;
revoke all on public.filips_jobs from public,anon,authenticated;
grant select on public.filips_jobs to authenticated;
grant update(status,scheduled_date) on public.filips_jobs to authenticated;

create or replace function filips_private.is_admin()
returns boolean language sql stable security definer set search_path = ''
as $$ select exists(select 1 from filips_private.admin_users where user_id = (select auth.uid())); $$;
revoke all on function filips_private.is_admin() from public;
grant execute on function filips_private.is_admin() to anon,authenticated;
create or replace function public.filips_is_admin()
returns boolean language sql stable security invoker set search_path = ''
as $$ select filips_private.is_admin(); $$;
revoke all on function public.filips_is_admin() from public;
grant execute on function public.filips_is_admin() to anon,authenticated;
drop policy if exists "Filip reads jobs" on public.filips_jobs;
create policy "Filip reads jobs" on public.filips_jobs for select to authenticated using ((select filips_private.is_admin()));
drop policy if exists "Filip updates jobs" on public.filips_jobs;
create policy "Filip updates jobs" on public.filips_jobs for update to authenticated using ((select filips_private.is_admin())) with check ((select filips_private.is_admin()));

create or replace function filips_private.submit_inquiry(payload jsonb)
returns uuid language plpgsql security definer set search_path = ''
as $$
declare
  job_id uuid; wanted date; kind text; customer text; street text; mail text; tel text; msg text;
  opts jsonb; extra jsonb := '[]'::jsonb; total integer; driveway integer := 0;
  canonical jsonb; fingerprint text; saved text; rate_count integer; bucket text;
begin
  if jsonb_typeof(payload) is distinct from 'object' or octet_length(payload::text) > 16384 then raise exception 'Ugyldig forespørgsel.'; end if;
  if coalesce(payload->>'honey','') <> '' then raise exception 'Forespørgslen kunne ikke sendes.'; end if;
  if coalesce(payload->>'id','') !~* '^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$' then raise exception 'Genindlæs siden, og prøv igen.'; end if;
  job_id := (payload->>'id')::uuid;
  if coalesce(payload->>'date','') !~ '^20[0-9]{2}-[0-9]{2}-[0-9]{2}$' then raise exception 'Vælg en gyldig dato.'; end if;
  begin wanted := (payload->>'date')::date;
  exception when others then raise exception 'Vælg en gyldig dato.'; end;
  if wanted < (now() at time zone 'Europe/Copenhagen')::date then raise exception 'Vælg en dato fra i dag og frem.'; end if;
  kind := payload->>'service';
  total := case kind when 'Snerydning' then 40 when 'Græsslåning' then 50 when 'Løvrydning' then 40 else null end;
  if total is null then raise exception 'Vælg en gyldig service.'; end if;
  customer := btrim(coalesce(payload->>'name','')); street := btrim(coalesce(payload->>'address',''));
  mail := btrim(coalesce(payload->>'email','')); tel := btrim(coalesce(payload->>'phone','')); msg := btrim(coalesce(payload->>'message',''));
  if length(customer) not between 1 and 120 or length(street) not between 1 and 250 or length(mail) not between 3 and 254 or length(msg)>2000 then raise exception 'Kontrollér dine kontaktoplysninger.'; end if;
  if mail !~ '^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]+$' then raise exception 'Skriv en gyldig e-mailadresse.'; end if;
  if length(tel) not between 6 and 40 or tel !~ '^[+()0-9[:space:].-]+$' or length(regexp_replace(tel,'[^0-9]','','g')) < 6 then raise exception 'Skriv et gyldigt telefonnummer.'; end if;
  opts := coalesce(payload->'options','{}'::jsonb);
  if jsonb_typeof(opts) <> 'object' then raise exception 'Vælg gyldige tillæg.'; end if;
  if kind = 'Snerydning' then
    if coalesce(opts->>'driveway','') not in ('20','40') then raise exception 'Vælg lille eller stor indkørsel.'; end if;
    driveway := (opts->>'driveway')::integer;
    if opts->'salt' = 'true'::jsonb then extra := extra || jsonb_build_array(jsonb_build_object('name','Saltning','price',15)); end if;
    if driveway>0 then extra := extra || jsonb_build_array(jsonb_build_object('name',case when driveway=20 then 'Lille indkørsel' else 'Stor indkørsel' end,'price',driveway)); end if;
    if opts->'corner' = 'true'::jsonb then extra := extra || jsonb_build_array(jsonb_build_object('name','Hjørnegrund','price',30)); end if;
  elsif kind = 'Græsslåning' and opts->'grass' = 'true'::jsonb then
    extra := jsonb_build_array(jsonb_build_object('name','Opsamling af græs','price',10));
  elsif kind = 'Løvrydning' and opts->'leaves' = 'true'::jsonb then
    extra := jsonb_build_array(jsonb_build_object('name','Bortkørsel af løv','price',10));
  end if;
  select total+coalesce(sum((item->>'price')::integer),0) into total from jsonb_array_elements(extra) as item;
  canonical := jsonb_build_object('id',job_id,'date',wanted,'service',kind,'name',customer,'address',street,'email',mail,'phone',tel,'message',msg,'extras',extra,'price',total);
  fingerprint := md5(canonical::text);
  -- Serializes concurrent retries and rate checks without trusting browser-provided prices or identity.
  perform pg_advisory_xact_lock(74921007);
  select payload_hash into saved from public.filips_jobs where id=job_id;
  if found then
    if saved<>fingerprint then raise exception 'Genindlæs siden, og send igen.'; end if;
    return job_id;
  end if;
  bucket := to_char(now() at time zone 'UTC','YYYY-MM-DD-HH24');
  delete from filips_private.rate_limits where expires_at < now();
  insert into filips_private.rate_limits(key,count,expires_at) values('global:'||bucket,1,now()+interval '2 hours')
    on conflict(key) do update set count=filips_private.rate_limits.count+1 returning count into rate_count;
  if rate_count>200 then raise exception 'Der er sendt mange forespørgsler. Skriv direkte til Filip.'; end if;
  insert into filips_private.rate_limits(key,count,expires_at) values('email:'||md5(lower(mail))||':'||bucket,1,now()+interval '2 hours')
    on conflict(key) do update set count=filips_private.rate_limits.count+1 returning count into rate_count;
  if rate_count>8 then raise exception 'Der er sendt mange forespørgsler fra denne e-mail. Prøv senere.'; end if;
  insert into public.filips_jobs(id,requested_date,scheduled_date,status,service,customer_name,address,email,phone,message,extras,price,payload_hash)
    values(job_id,wanted,wanted,'new',kind,customer,street,mail,tel,msg,extra,total,fingerprint);
  return job_id;
end $$;
revoke all on function filips_private.submit_inquiry(jsonb) from public;
grant execute on function filips_private.submit_inquiry(jsonb) to anon,authenticated;
-- Only this validated wrapper is exposed through Supabase's public Data API.
create or replace function public.filips_submit_inquiry(payload jsonb)
returns uuid language sql security invoker set search_path = ''
as $$ select filips_private.submit_inquiry(payload); $$;
revoke all on function public.filips_submit_inquiry(jsonb) from public;
grant execute on function public.filips_submit_inquiry(jsonb) to anon,authenticated;
notify pgrst, 'reload schema';
commit;
