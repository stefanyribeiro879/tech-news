-- Reforços de segurança do Tech News (rodar uma vez, depois do schema.sql).
-- Como usar: painel do Supabase > SQL Editor > New query > colar tudo > Run.

-- ======================================================
-- LIMITES DE TAMANHO
-- Impede que alguém use a própria conta para gravar textos gigantes.
-- "not valid": não confere o que já está gravado, só o que for gravado daqui
-- para frente (assim o script não falha por causa de dados antigos).
-- ======================================================

alter table public.profiles
  add constraint profiles_name_size
    check (char_length(name) <= 80) not valid,
  add constraint profiles_topics_size
    check (cardinality(favorite_categories) <= 10) not valid;

alter table public.saved_articles
  add constraint saved_small_fields_size
    check (
      char_length(article_id) <= 64
      and char_length(source) <= 100
      and char_length(category) <= 50
      and char_length(title) <= 500
      and char_length(summary) <= 2000
      and char_length(content) <= 100000
    ) not valid,
  -- Links só http(s): bloqueia "javascript:" e afins.
  add constraint saved_url_web
    check (url ~* '^https?://' and char_length(url) <= 2048) not valid,
  add constraint saved_image_web
    check (
      image_url is null
      or (image_url ~* '^https?://' and char_length(image_url) <= 2048)
    ) not valid;

-- Até 500 notícias salvas por pessoa.
create function public.limit_saved_articles ()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  if (select count(*) from public.saved_articles where user_id = new.user_id) >= 500 then
    raise exception 'Limite de 500 notícias salvas atingido';
  end if;
  return new;
end;
$$;

create trigger saved_articles_limit
  before insert on public.saved_articles
  for each row execute function public.limit_saved_articles ();

-- ======================================================
-- EXCLUIR A PRÓPRIA CONTA (LGPD / exigência do Google Play)
-- Apaga o usuário do login; perfil e notícias salvas saem junto (on delete
-- cascade). Só apaga quem está logado — nunca outra pessoa.
-- ======================================================

create function public.delete_my_account ()
returns void
language plpgsql
security definer set search_path = ''
as $$
begin
  if auth.uid () is null then
    raise exception 'Não autenticado';
  end if;
  delete from auth.users where id = auth.uid ();
end;
$$;

revoke execute on function public.delete_my_account () from public, anon;
grant execute on function public.delete_my_account () to authenticated;
