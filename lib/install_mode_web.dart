import 'package:web/web.dart' as web;

// Aberto pelo ícone da tela de início (sem a barra do navegador)?
bool get isInstalledWebApp =>
    web.window.matchMedia('(display-mode: standalone)').matches;
