import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme.dart';

// ======================================================
// PREFERÊNCIAS GUARDADAS NO APARELHO
// (no navegador ficam no localStorage)
// ======================================================

class AppSettings extends ChangeNotifier {
  static const _lookKey = 'app_look';
  static const _oldThemeKey = 'theme_mode'; // versões até 1.0.2
  static const _rememberKey = 'remember_login';
  static const _hasAccountKey = 'has_account_on_device';
  static const _readingScaleKey = 'reading_scale';

  // Tamanhos do texto na leitura da notícia (botão "Aa").
  static const readingScales = [0.9, 1.0, 1.15, 1.3];

  SharedPreferences? _prefs;

  AppLook look = AppLook.light;

  // "Manter conectado": se false, a sessão é encerrada ao abrir o app de novo.
  bool rememberLogin = true;

  // Primeira vez no aparelho abre o cadastro; depois, o login.
  bool hasAccountOnDevice = false;

  // Tamanho do texto da notícia (1.0 = padrão).
  double readingScale = 1.0;

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      return; // sem armazenamento: usa os valores padrão
    }

    final saved = _prefs!.getString(_lookKey);
    look = saved != null
        ? AppLook.fromName(saved)
        // Quem usava o antigo "Tema escuro" continua no escuro.
        : _prefs!.getString(_oldThemeKey) == 'dark'
        ? AppLook.dark
        : AppLook.light;
    rememberLogin = _prefs!.getBool(_rememberKey) ?? true;
    hasAccountOnDevice = _prefs!.getBool(_hasAccountKey) ?? false;
    final scale = _prefs!.getDouble(_readingScaleKey);
    readingScale = readingScales.contains(scale) ? scale! : 1.0;
  }

  void setLook(AppLook value) {
    look = value;
    _prefs?.setString(_lookKey, value.name);
    notifyListeners();
  }

  void setRememberLogin(bool value) {
    rememberLogin = value;
    _prefs?.setBool(_rememberKey, value);
    notifyListeners();
  }

  // Passa para o próximo tamanho (volta ao menor depois do maior).
  void nextReadingScale() {
    final index = readingScales.indexOf(readingScale);
    readingScale = readingScales[(index + 1) % readingScales.length];
    _prefs?.setDouble(_readingScaleKey, readingScale);
    notifyListeners();
  }

  void markHasAccount() {
    hasAccountOnDevice = true;
    _prefs?.setBool(_hasAccountKey, true);
  }
}

final appSettings = AppSettings();
