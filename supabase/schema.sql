-- Banco de dados do Tech News no Supabase.
-- Como usar: painel do Supabase > SQL Editor > New query > colar tudo > Run.

-- ======================================================
-- PERFIL DO USUÁRIO
-- E-mail e senha ficam em auth.users (gerenciado pelo Supabase Auth).
-- ======================================================

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text,
  favorite_categories text[] not null default '{}',
  created_at timestamptz not null default now()
);

-- ======================================================
-- NOTÍCIAS SALVAS
-- Guarda a notícia inteira, pois ela sai do cache do backend depois.
-- ======================================================

create table public.saved_articles (
  user_id uuid not null default auth.uid () references auth.users (id) on delete cascade,
  article_id text not null,
  title text not null,
  summary text not null default '',
  content text not null default '',
  url text not null,
  image_url text,
  source text not null,
  category text not null,
  published_at timestamptz not null,
  saved_at timestamptz not null default now(),
  primary key (user_id, article_id)
);

-- ======================================================
-- SEGURANÇA (RLS): cada usuário só vê e altera os próprios dados
-- ======================================================

alter table public.profiles enable row level security;
alter table public.saved_articles enable row level security;

create policy "Usuário lê o próprio perfil" on public.profiles
  for select to authenticated
  using ((select auth.uid ()) = id);

create policy "Usuário atualiza o próprio perfil" on public.profiles
  for update to authenticated
  using ((select auth.uid ()) = id)
  with check ((select auth.uid ()) = id);

create policy "Usuário gerencia as próprias notícias salvas" on public.saved_articles
  for all to authenticated
  using ((select auth.uid ()) = user_id)
  with check ((select auth.uid ()) = user_id);

-- ======================================================
-- CRIA O PERFIL AUTOMATICAMENTE NO CADASTRO
-- O nome vem do campo "name" enviado pelo app no signUp.
-- ======================================================

create function public.handle_new_user ()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, name)
  values (new.id, new.raw_user_meta_data ->> 'name');
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user ();
