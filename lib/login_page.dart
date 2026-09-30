import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_settings.dart';
import 'supabase_service.dart';
import 'theme.dart';

// ======================================================
// ENTRADA NO APP: CADASTRO E LOGIN
// Obrigatória. No primeiro acesso do aparelho abre o cadastro; depois, o
// login. Ao entrar, o AuthGate (main.dart) percebe a sessão e segue sozinho.
// ======================================================

class AuthFlow extends StatefulWidget {
  const AuthFlow({super.key});

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

enum _AuthScreen { signUp, login, forgotPassword }

class _AuthFlowState extends State<AuthFlow> {
  late _AuthScreen screen = appSettings.hasAccountOnDevice
      ? _AuthScreen.login
      : _AuthScreen.signUp;

  // Mensagem mostrada no login depois de criar a conta (ex.: confirmar e-mail).
  String? loginNotice;

  // E-mail digitado no login, para já preencher o "esqueci a senha".
  String forgotEmail = '';

  void goTo(_AuthScreen next, {String? notice}) {
    setState(() {
      screen = next;
      loginNotice = notice;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: switch (screen) {
        _AuthScreen.signUp => SignUpForm(
          key: const ValueKey('signup'),
          onGoToLogin: ({String? notice}) =>
              goTo(_AuthScreen.login, notice: notice),
        ),
        _AuthScreen.login => LoginForm(
          key: const ValueKey('login'),
          notice: loginNotice,
          onGoToSignUp: () => goTo(_AuthScreen.signUp),
          onForgotPassword: (email) {
            forgotEmail = email;
            goTo(_AuthScreen.forgotPassword);
          },
        ),
        _AuthScreen.forgotPassword => ForgotPasswordForm(
          key: const ValueKey('forgot'),
          initialEmail: forgotEmail,
          onBackToLogin: () => goTo(_AuthScreen.login),
        ),
      },
    );
  }
}

// ======================================================
// LOGIN
// ======================================================

class LoginForm extends StatefulWidget {
  final String? notice;
  final VoidCallback onGoToSignUp;
  final ValueChanged<String> onForgotPassword;

  const LoginForm({
    super.key,
    this.notice,
    required this.onGoToSignUp,
    required this.onForgotPassword,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool remember = appSettings.rememberLogin;
  bool showPassword = false;
  bool loading = false;
  String? error;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      appSettings.setRememberLogin(remember);
      await SupabaseService.signIn(
        emailController.text.trim(),
        passwordController.text,
      );
      appSettings.markHasAccount();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = authErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      emoji: '☕',
      title: 'Bom te ver de novo!',
      subtitle: 'Entre para continuar lendo as notícias dos seus temas.',
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.notice != null) NoticeBox(widget.notice!),

            EmailField(controller: emailController),

            const SizedBox(height: 14),

            PasswordField(
              controller: passwordController,
              visible: showPassword,
              onToggleVisible: () {
                setState(() {
                  showPassword = !showPassword;
                });
              },
              onSubmitted: submit,
            ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: loading
                    ? null
                    : () => widget.onForgotPassword(emailController.text.trim()),
                child: const Text(
                  'Esqueci minha senha',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),

            RememberLoginCheckbox(
              value: remember,
              onChanged: (value) {
                setState(() {
                  remember = value;
                });
              },
            ),

            if (error != null) ErrorText(error!),

            const SizedBox(height: 12),

            LoadingButton(label: 'Entrar', loading: loading, onPressed: submit),

            const SizedBox(height: 18),

            SwitchAuthLink(
              question: 'Ainda não tem conta?',
              action: 'Criar conta',
              onTap: loading ? null : widget.onGoToSignUp,
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// CADASTRO
// ======================================================

class SignUpForm extends StatefulWidget {
  final void Function({String? notice}) onGoToLogin;

  const SignUpForm({super.key, required this.onGoToLogin});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool remember = appSettings.rememberLogin;
  bool showPassword = false;
  bool loading = false;
  String? error;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      error = null;
    });

    final email = emailController.text.trim();

    try {
      appSettings.setRememberLogin(remember);
      final loggedIn = await SupabaseService.signUp(
        nameController.text.trim(),
        email,
        passwordController.text,
      );
      appSettings.markHasAccount();

      if (!loggedIn && mounted) {
        // O projeto exige confirmar o e-mail antes do primeiro login.
        widget.onGoToLogin(
          notice:
              'Conta criada! Abra o link enviado para $email e depois entre aqui.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = authErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      emoji: '📰',
      title: 'Crie sua conta',
      subtitle:
          'Leva menos de um minuto. Depois você escolhe os temas que mais gosta.',
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Como podemos te chamar?',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Informe seu nome'
                  : null,
            ),

            const SizedBox(height: 14),

            EmailField(controller: emailController),

            const SizedBox(height: 14),

            PasswordField(
              controller: passwordController,
              visible: showPassword,
              onToggleVisible: () {
                setState(() {
                  showPassword = !showPassword;
                });
              },
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: confirmController,
              obscureText: !showPassword,
              onFieldSubmitted: (_) => submit(),
              decoration: const InputDecoration(
                labelText: 'Confirme a senha',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
              validator: (value) => value != passwordController.text
                  ? 'As senhas não são iguais'
                  : null,
            ),

            RememberLoginCheckbox(
              value: remember,
              onChanged: (value) {
                setState(() {
                  remember = value;
                });
              },
            ),

            if (error != null) ErrorText(error!),

            const SizedBox(height: 12),

            LoadingButton(
              label: 'Criar conta',
              loading: loading,
              onPressed: submit,
            ),

            const SizedBox(height: 18),

            SwitchAuthLink(
              question: 'Já tem conta?',
              action: 'Entrar',
              onTap: loading ? null : () => widget.onGoToLogin(),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// ESQUECI A SENHA
// Passo 1: e-mail → o Supabase envia um código de 6 dígitos.
// Passo 2: código → ao validar, o Supabase abre uma sessão de recuperação e
// o AuthGate (main.dart) troca esta tela pela NewPasswordForm.
// ======================================================

class ForgotPasswordForm extends StatefulWidget {
  final String initialEmail;
  final VoidCallback onBackToLogin;

  const ForgotPasswordForm({
    super.key,
    required this.initialEmail,
    required this.onBackToLogin,
  });

  @override
  State<ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<ForgotPasswordForm> {
  final formKey = GlobalKey<FormState>();
  late final emailController = TextEditingController(text: widget.initialEmail);
  final codeController = TextEditingController();

  bool codeSent = false;
  bool loading = false;
  String? error;
  String? notice;

  String get email => emailController.text.trim();

  @override
  void dispose() {
    emailController.dispose();
    codeController.dispose();
    super.dispose();
  }

  Future<void> sendCode() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      await SupabaseService.sendPasswordResetCode(email);
      if (!mounted) return;
      codeController.clear();
      setState(() {
        loading = false;
        codeSent = true;
        // O Supabase não revela se o e-mail tem conta (evita descobrir contas).
        notice =
            'Se existir uma conta com $email, enviamos um código de 6 dígitos. '
            'Confira também o spam.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = authErrorMessage(e);
      });
    }
  }

  Future<void> verifyCode() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      // Se der certo, o AuthGate já troca para a tela de nova senha.
      await SupabaseService.verifyPasswordResetCode(email, codeController.text);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = authErrorMessage(e);
      });
    }
  }

  void useAnotherEmail() {
    setState(() {
      codeSent = false;
      notice = null;
      error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      emoji: codeSent ? '✉️' : '🔑',
      title: codeSent ? 'Digite o código' : 'Esqueceu a senha?',
      subtitle: codeSent
          ? 'Digite o código de 6 dígitos que chegou no seu e-mail.'
          : 'Informe o e-mail da sua conta. Vamos enviar um código para '
                'você criar uma nova senha.',
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (notice != null) NoticeBox(notice!),

            if (!codeSent)
              EmailField(controller: emailController)
            else
              TextFormField(
                controller: codeController,
                autofocus: true,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 10,
                ),
                onFieldSubmitted: (_) => verifyCode(),
                decoration: const InputDecoration(
                  labelText: 'Código de verificação',
                  prefixIcon: Icon(Icons.pin_outlined),
                ),
                validator: (value) =>
                    (value?.length ?? 0) != 6 ? 'O código tem 6 dígitos' : null,
              ),

            if (error != null) ErrorText(error!),

            const SizedBox(height: 16),

            LoadingButton(
              label: codeSent ? 'Confirmar código' : 'Enviar código',
              loading: loading,
              onPressed: codeSent ? verifyCode : sendCode,
            ),

            if (codeSent) ...[
              const SizedBox(height: 10),
              SwitchAuthLink(
                question: 'Não recebeu?',
                action: 'Reenviar código',
                onTap: loading ? null : sendCode,
              ),
              TextButton(
                onPressed: loading ? null : useAnotherEmail,
                child: const Text('Usar outro e-mail'),
              ),
            ],

            const SizedBox(height: 8),

            SwitchAuthLink(
              question: 'Lembrou a senha?',
              action: 'Entrar',
              onTap: loading ? null : widget.onBackToLogin,
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// NOVA SENHA
// Aparece depois que o código foi validado (sessão de recuperação ativa).
// ======================================================

class NewPasswordForm extends StatefulWidget {
  final VoidCallback onDone;

  const NewPasswordForm({super.key, required this.onDone});

  @override
  State<NewPasswordForm> createState() => _NewPasswordFormState();
}

class _NewPasswordFormState extends State<NewPasswordForm> {
  final formKey = GlobalKey<FormState>();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool showPassword = false;
  bool loading = false;
  String? error;

  @override
  void dispose() {
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      await SupabaseService.updatePassword(passwordController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha alterada! Você já está conectado.')),
      );
      widget.onDone();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = authErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      emoji: '🔒',
      title: 'Crie uma nova senha',
      subtitle: 'Código confirmado! Agora escolha a sua nova senha.',
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PasswordField(
              controller: passwordController,
              visible: showPassword,
              onToggleVisible: () {
                setState(() {
                  showPassword = !showPassword;
                });
              },
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: confirmController,
              obscureText: !showPassword,
              onFieldSubmitted: (_) => submit(),
              decoration: const InputDecoration(
                labelText: 'Confirme a nova senha',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
              validator: (value) => value != passwordController.text
                  ? 'As senhas não são iguais'
                  : null,
            ),

            if (error != null) ErrorText(error!),

            const SizedBox(height: 16),

            LoadingButton(
              label: 'Salvar nova senha',
              loading: loading,
              onPressed: submit,
            ),

            const SizedBox(height: 8),

            // Desistir encerra a sessão de recuperação e volta ao login.
            TextButton(
              onPressed: loading ? null : SupabaseService.signOut,
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// PEÇAS COMPARTILHADAS
// ======================================================

class AuthLayout extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Widget child;

  const AuthLayout({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: colors.outlineVariant),
                        ),
                        child: Image.asset('assets/images/logo.png'),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Tech News',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 36),

                  Text(emoji, style: const TextStyle(fontSize: 40)),

                  const SizedBox(height: 10),

                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 30,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 28),

                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EmailField extends StatelessWidget {
  final TextEditingController controller;

  const EmailField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      decoration: const InputDecoration(
        labelText: 'E-mail',
        prefixIcon: Icon(Icons.mail_outline_rounded),
      ),
      validator: (value) {
        final email = value?.trim() ?? '';
        return (email.contains('@') && email.contains('.'))
            ? null
            : 'Informe um e-mail válido';
      },
    );
  }
}

class PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool visible;
  final VoidCallback onToggleVisible;
  final VoidCallback? onSubmitted;

  const PasswordField({
    super.key,
    required this.controller,
    required this.visible,
    required this.onToggleVisible,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      onFieldSubmitted: (_) => onSubmitted?.call(),
      decoration: InputDecoration(
        labelText: 'Senha',
        helperText: 'Mínimo de 6 caracteres',
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          tooltip: visible ? 'Esconder senha' : 'Mostrar senha',
          onPressed: onToggleVisible,
          icon: Icon(
            visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          ),
        ),
      ),
      validator: (value) => (value == null || value.length < 6)
          ? 'A senha precisa ter pelo menos 6 caracteres'
          : null,
    );
  }
}

class RememberLoginCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const RememberLoginCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: CheckboxListTile(
        value: value,
        onChanged: (checked) => onChanged(checked ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Manter conectado neste aparelho',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          'Desmarque em aparelhos compartilhados.',
          style: TextStyle(color: context.colors.onSurfaceVariant),
        ),
      ),
    );
  }
}

class NoticeBox extends StatelessWidget {
  final String message;

  const NoticeBox(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.mark_email_read_outlined, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class ErrorText extends StatelessWidget {
  final String message;

  const ErrorText(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: context.colors.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class LoadingButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const LoadingButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.white,
              ),
            )
          : Text(label),
    );
  }
}

class SwitchAuthLink extends StatelessWidget {
  final String question;
  final String action;
  final VoidCallback? onTap;

  const SwitchAuthLink({
    super.key,
    required this.question,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          question,
          style: TextStyle(color: context.colors.onSurfaceVariant),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            action,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
