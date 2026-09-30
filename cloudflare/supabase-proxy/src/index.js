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

    const target = new URL(url.pathname + url.search, env.SUPABASE_URL);

    // Copia método, cabeçalhos e corpo. Funciona também para WebSocket (realtime).
    return fetch(new Request(target, request));
  },
};
