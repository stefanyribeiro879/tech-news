// Proxy do Supabase no Cloudflare Workers.
// Algumas redes/DNS bloqueiam *.supabase.co; o app fala com este Worker
// (em *.workers.dev) e ele repassa a requisição para o Supabase.

const ALLOWED_PREFIXES = [
  '/auth/v1/',
  '/rest/v1/',
  '/realtime/v1/',
  '/storage/v1/',
  '/functions/v1/',
];

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname === '/health') {
      return new Response('ok');
    }

    // Só repassa as rotas da API do Supabase; o resto é recusado.
    if (!ALLOWED_PREFIXES.some((prefix) => url.pathname.startsWith(prefix))) {
      return new Response('Not found', { status: 404 });
    }

    // Todo mundo chega ao Supabase com o IP do Cloudflare, então o limite de
    // tentativas por IP do Supabase deixa de separar os usuários. Aqui o
    // limite é por IP real: protege login, cadastro e códigos contra
    // tentativas em massa (força bruta).
    const clientIp = request.headers.get('CF-Connecting-IP') ?? 'desconhecido';
    if (url.pathname.startsWith('/auth/v1/') && request.method !== 'GET' && env.AUTH_LIMITER) {
      const { success } = await env.AUTH_LIMITER.limit({ key: clientIp });
      if (!success) {
        return new Response(
          JSON.stringify({
            code: 'over_request_rate_limit',
            message: 'Too many requests: rate limit exceeded',
          }),
          { status: 429, headers: { 'Content-Type': 'application/json' } },
        );
      }
    }

    // Monta o destino sempre no host do Supabase (nunca em outro domínio).
    const target = new URL(env.SUPABASE_URL);
    target.pathname = url.pathname;
    target.search = url.search;

    const forwarded = new Request(target, request);
    forwarded.headers.set('X-Forwarded-For', clientIp);

    // Copia método, cabeçalhos e corpo. Funciona também para WebSocket (realtime).
    return fetch(forwarded);
  },
};
