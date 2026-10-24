import 'package:flutter/material.dart';

import '../../../core/services/supabase/auth_service.dart';
import '../../../core/services/supabase/supabase_config.dart';
import '../../../core/services/session_guard.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_mode.dart';
import '../../../core/router/root_navigation.dart';

/// Écran de connexion. Aucune inscription possible depuis l'app : les
/// identifiants sont créés par l'administrateur (page web admin séparée)
/// et transmis manuellement au joueur.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialError});

  final String? initialError;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _error = widget.initialError;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Identifiant et mot de passe requis.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (!SupabaseConfig.initialized) await SupabaseConfig.initialize();
      await AuthService.signIn(username: username, password: password);
      SessionGuard.start();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RootNavigation()),
          (_) => false,
        );
      }
    } on AccessDeniedException catch (error) {
      if (mounted) setState(() => _error = error.reason);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Connexion impossible. Vérifiez vos identifiants et votre connexion.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.spaceL),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.casino, color: AppColors.gold, size: 64),
                  const SizedBox(height: AppDimens.spaceM),
                  const Text(
                    predictorOnly ? 'PRÉDICTEUR' : 'UNDER & OVER 7',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    predictorOnly
                        ? 'Connectez-vous avec votre compte de l’application'
                        : 'Environnement d\'entraînement — monnaie virtuelle',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: AppDimens.spaceXl),
                  TextField(
                    controller: _usernameController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Identifiant',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppDimens.spaceM),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppDimens.spaceM),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppDimens.spaceL),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusM,
                          ),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                              ),
                            )
                          : const Text(
                              'SE CONNECTER',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.spaceM),
                  const Text(
                    'Pas de compte ? Contactez l\'administrateur.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
