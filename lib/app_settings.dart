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

  SharedPreferences? _prefs;

  AppLook look = AppLook.light;

  // "Manter conectado": se false, a sessão é encerrada ao abrir o app de novo.
  bool rememberLogin = true;

  // Primeira vez no aparelho abre o cadastro; depois, o login.
  bool hasAccountOnDevice = false;

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

  void markHasAccount() {
    hasAccountOnDevice = true;
    _prefs?.setBool(_hasAccountKey, true);
  }
}

final appSettings = AppSettings();
