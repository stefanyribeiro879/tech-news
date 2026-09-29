import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ======================================================
// PREFERÊNCIAS GUARDADAS NO APARELHO
// (no navegador ficam no localStorage)
// ======================================================

class AppSettings extends ChangeNotifier {
  static const _themeKey = 'theme_mode';
  static const _rememberKey = 'remember_login';
  static const _hasAccountKey = 'has_account_on_device';

  SharedPreferences? _prefs;

  ThemeMode themeMode = ThemeMode.light;

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

    themeMode = _prefs!.getString(_themeKey) == 'dark'
        ? ThemeMode.dark
        : ThemeMode.light;
    rememberLogin = _prefs!.getBool(_rememberKey) ?? true;
    hasAccountOnDevice = _prefs!.getBool(_hasAccountKey) ?? false;
  }

  void setDarkMode(bool dark) {
    themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    _prefs?.setString(_themeKey, dark ? 'dark' : 'light');
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
