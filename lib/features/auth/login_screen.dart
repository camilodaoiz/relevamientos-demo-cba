import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/usuario.dart';
import '../../core/state/demo_store.dart';
import '../../core/theme/app_colors.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController(text: 'admin@demo.com');
  final _password = TextEditingController(text: '123');
  bool _obscure = true;
  bool _loading = false;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // RF-015/RF-018: acceso demo RBAC con credenciales propias por rol.
    final users = ref.watch(demoStoreProvider).usuarios;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 760;
                  if (!wide) {
                    return Column(
                      children: [
                        const _InstitutionPanel(compact: true),
                        _AccessPanel(
                          users: users,
                          email: _email,
                          password: _password,
                          obscure: _obscure,
                          loading: _loading,
                          message: _message,
                          onObscure: () => setState(() => _obscure = !_obscure),
                          onProfile: (email) => setState(() {
                            _email.text = email;
                            _password.text = '123';
                          }),
                          onLogin: _login,
                          onCidi: _mockCidi,
                        ),
                      ],
                    );
                  }
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Expanded(flex: 5, child: _InstitutionPanel()),
                        Expanded(
                          flex: 6,
                          child: _AccessPanel(
                            users: users,
                            email: _email,
                            password: _password,
                            obscure: _obscure,
                            loading: _loading,
                            message: _message,
                            onObscure: () =>
                                setState(() => _obscure = !_obscure),
                            onProfile: (email) => setState(() {
                              _email.text = email;
                              _password.text = '123';
                            }),
                            onLogin: _login,
                            onCidi: _mockCidi,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final store = ref.read(demoStoreProvider);
    final user = store.authenticateDemo(_email.text.trim(), _password.text);
    if (!mounted) return;
    if (user == null) {
      setState(() {
        _loading = false;
        _message = 'Credenciales inválidas o usuario inactivo.';
      });
      return;
    }
    unawaited(store.seedFirebaseDemoData());
    context.go(_homeFor(user));
  }

  void _mockCidi() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Acceso CiDi simulado para la demo. Usá un perfil RBAC.'),
      ),
    );
  }
}

String _homeFor(Usuario user) {
  return switch (user.rolId) {
    'R-06' => '/mobile/tasks',
    'R-07' => '/backoffice/analista',
    'R-08' => '/backoffice/auditoria',
    _ => '/backoffice/dashboard',
  };
}

class _InstitutionPanel extends StatelessWidget {
  const _InstitutionPanel({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 24 : 34),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(15),
          topRight: Radius.circular(compact ? 15 : 0),
          bottomLeft: Radius.circular(compact ? 0 : 15),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            'assets/logos/hacer_para_crecer_icon.png',
            width: 90,
            height: 90,
          ),
          const SizedBox(height: 22),
          Text(
            'Relevamientos\ndigitales',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Ministerio de Innovación\nProvincia de Córdoba',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.74),
              height: 1.45,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 52),
            const _GovernmentSlogan(),
          ],
        ],
      ),
    );
  }
}

class _GovernmentSlogan extends StatelessWidget {
  const _GovernmentSlogan();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
        ),
      ),
      child: Image.asset(
        'assets/logos/logo_gobierno_cordoba.png',
        key: const Key('government-slogan-logo'),
        height: 60,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
      ),
    );
  }
}

class _AccessPanel extends StatelessWidget {
  const _AccessPanel({
    required this.users,
    required this.email,
    required this.password,
    required this.obscure,
    required this.loading,
    required this.message,
    required this.onObscure,
    required this.onProfile,
    required this.onLogin,
    required this.onCidi,
  });

  final List<Usuario> users;
  final TextEditingController email;
  final TextEditingController password;
  final bool obscure;
  final bool loading;
  final String? message;
  final VoidCallback onObscure;
  final ValueChanged<String> onProfile;
  final VoidCallback onLogin;
  final VoidCallback onCidi;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(34),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Ingresar', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'Accedé con el perfil asignado al operativo.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: onCidi,
            icon: const Icon(Icons.account_circle_outlined),
            label: const Text('Ingresar con CiDi'),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(child: Divider()),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'o con credenciales demo',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            key: ValueKey(email.text),
            isExpanded: true,
            initialValue: users.any((user) => user.email == email.text)
                ? email.text
                : null,
            decoration: const InputDecoration(
              labelText: 'Perfil RBAC',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            items: [
              for (final user in users)
                DropdownMenuItem(
                  value: user.email,
                  child: Text(
                    '${user.email} · ${user.rolId}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) onProfile(value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: password,
            obscureText: obscure,
            onSubmitted: (_) => onLogin(),
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: onObscure,
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                tooltip: obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Contraseña para todos los perfiles demo: 123',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          if (message != null) ...[
            const SizedBox(height: 10),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: loading ? null : onLogin,
            icon: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.login, size: 18),
            label: Text(loading ? 'Validando...' : 'Ingresar'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: AppColors.accent,
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => context.go('/demo-selector'),
            child: const Text('Ver todos los perfiles de presentación'),
          ),
        ],
      ),
    );
  }
}
