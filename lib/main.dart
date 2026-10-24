import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/router/root_navigation.dart';
import 'core/services/session_guard.dart';
import 'core/services/wallet_controller.dart';
import 'core/services/supabase/auth_service.dart';
import 'core/services/supabase/supabase_config.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  await SupabaseConfig.initialize();
  SessionGuard.start();
  runApp(const UnderOver7App());
}

class UnderOver7App extends StatelessWidget {
  const UnderOver7App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'Under & Over 7',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const AuthGate(),
    );
  }
}

/// Décide, au lancement, si une session valide existe déjà sur cet appareil
/// (auth par identifiant/mot de passe créés par l'admin — plus d'auth
/// anonyme). Si oui, revalide l'accès côté serveur (expiration, statut,
/// limite d'appareils) avant d'ouvrir le jeu ; sinon, affiche la connexion.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

enum _GateState { checking, signedIn, signedOut }

class _AuthGateState extends State<AuthGate> {
  _GateState _state = _GateState.checking;
  String? _error;
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    if (!SupabaseConfig.initialized || supabase.auth.currentSession == null) {
      setState(() => _state = _GateState.signedOut);
      return;
    }
    try {
      await AuthService.registerCurrentDevice();
      await WalletController.instance.loadForUser(
        supabase.auth.currentUser!.id,
      );
      if (mounted) setState(() => _state = _GateState.signedIn);
    } on AccessDeniedException catch (error) {
      await AuthService.signOut();
      if (mounted) {
        setState(() {
          _error = error.reason;
          _state = _GateState.signedOut;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _state = _GateState.signedOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _GateState.checking:
        return const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
        );
      case _GateState.signedIn:
        return const RootNavigation();
      case _GateState.signedOut:
        return LoginScreen(key: ValueKey(_error), initialError: _error);
    }
  }
}
