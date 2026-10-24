import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/login_screen.dart';
import 'supabase/auth_service.dart';
import 'supabase/supabase_config.dart';

/// Permet de renvoyer l'utilisateur vers la connexion depuis n'importe quel
/// écran (compte bloqué ou expiré pendant que l'app est ouverte).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Un compte bloqué ou expiré n'a accès qu'à l'écran de connexion.
///
/// - Toutes les 30 s, tant qu'une session existe, l'accès est revalidé côté
///   serveur ([start]).
/// - Dès qu'une action est refusée pour ce motif, [handleAccessError] renvoie
///   immédiatement vers la connexion, sans attendre le prochain passage.
///
/// Indépendant de tout écran : survit au remplacement de la pile de navigation.
class SessionGuard {
  SessionGuard._();

  static Timer? _timer;
  static bool _ejecting = false;

  static void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _check());
  }

  /// À appeler dans le `catch` d'un appel serveur. Renvoie true (et ramène à
  /// la connexion) si l'erreur signifie « compte bloqué » ou « accès expiré » ;
  /// false pour toute autre erreur, à traiter normalement par l'appelant.
  static bool handleAccessError(Object error) {
    final reason = error.toString();
    if (reason.contains('ACCOUNT_DISABLED')) {
      unawaited(eject('Ce compte a été désactivé.'));
      return true;
    }
    if (reason.contains('ACCOUNT_EXPIRED')) {
      unawaited(eject('Votre accès a expiré. Contactez l\'administrateur.'));
      return true;
    }
    return false;
  }

  static Future<void> _check() async {
    if (AuthService.signingIn ||
        _ejecting ||
        supabase.auth.currentSession == null) {
      return;
    }
    try {
      await AuthService.registerCurrentDevice();
    } on AccessDeniedException catch (error) {
      await eject(error.reason);
    } on AuthException {
      await eject('Votre session a pris fin. Reconnectez-vous.');
    } catch (_) {
      // Réseau indisponible : on réessaiera au prochain passage.
    }
  }

  static Future<void> eject(String message) async {
    if (_ejecting) return;
    _ejecting = true;
    try {
      await AuthService.signOut();
      appNavigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen(initialError: message)),
        (route) => false,
      );
    } finally {
      _ejecting = false;
    }
  }
}
