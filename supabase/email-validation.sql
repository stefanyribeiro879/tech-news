-- Validação de e-mail no cadastro do Tech News (rodar uma vez).
-- Como usar: painel do Supabase > SQL Editor > New query > colar tudo > Run.
--
-- Vale só para contas NOVAS: o gatilho roda antes de inserir em auth.users.
-- Contas que já existem não são conferidas nem alteradas, e continuam
-- entrando normalmente. O app faz as mesmas conferências antes de enviar
-- (lib/email_check.dart); aqui é a garantia para quem chamar a API direto.

create function public.validate_new_user_email ()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
declare
  email text := lower(trim(coalesce(new.email, '')));
  domain text := split_part(email, '@', 2);
begin
  -- Login sem e-mail (ex.: telefone) não passa por aqui.
  if new.email is null then
    return new;
  end if;

  if char_length(email) > 254
    or email !~ '^[a-z0-9!#$%&''*+/=?^_`{|}~-]+(\.[a-z0-9!#$%&''*+/=?^_`{|}~-]+)*@([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,24}$'
  then
    raise exception 'E-mail inválido';
  end if;

  -- Serviços de e-mail temporário (mesma lista de lib/email_check.dart).
  if domain = any (array[
    '10minutemail.com', '10minutemail.net', '20minutemail.com', 'anonbox.net',
    'burnermail.io', 'byom.de', 'dispostable.com', 'dropmail.me', 'emailondeck.com',
    'fakeinbox.com', 'fakemail.net', 'getairmail.com', 'getnada.com',
    'guerrillamail.com', 'guerrillamail.net', 'guerrillamail.org',
    'guerrillamailblock.com', 'harakirimail.com', 'inboxkitten.com',
    'incognitomail.org', 'mail.tm', 'mailcatch.com', 'maildrop.cc',
    'mailinator.com', 'mailinator.net', 'mailnesia.com', 'mailpoof.com',
    'mintemail.com', 'moakt.com', 'mohmal.com', 'mytemp.email', 'nada.email',
    'sharklasers.com', 'spam4.me', 'spamgourmet.com', 'temp-mail.io',
    'temp-mail.org', 'tempail.com', 'tempmail.com', 'tempmail.dev',
    'tempmail.net', 'tempmailo.com', 'tempr.email', 'throwawaymail.com',
    'trashmail.com', 'trashmail.de', 'yopmail.com', 'yopmail.fr', 'yopmail.net'
  ]) then
    raise exception 'E-mail temporário não é aceito';
  end if;

  return new;
end;
$$;

create trigger validate_email_before_signup
  before insert on auth.users
  for each row execute function public.validate_new_user_email ();
