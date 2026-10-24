import 'package:supabase_flutter/supabase_flutter.dart';

import '../device_id_service.dart';
import '../wallet_controller.dart';
import 'supabase_config.dart';

/// Exception typée pour les refus de `register_device` (compte expiré,
/// désactivé, ou limite d'appareils atteinte) — messages destinés à
/// être affichés tels quels à l'utilisateur.
class AccessDeniedException implements Exception {
  const AccessDeniedException(this.reason);
  final String reason;

  @override
  String toString() => reason;
}

/// Authentification par identifiant/mot de passe créés par l'administrateur
/// (aucune inscription libre — voir supabase/functions/admin-create-user).
class AuthService {
  AuthService._();

  static String _emailFor(String username) =>
      '${username.trim().toLowerCase()}@underover7.local';

  /// Connecte l'utilisateur puis enregistre cet appareil côté serveur.
  /// Lève [AccessDeniedException] si l'accès est refusé (déconnecte alors
  /// automatiquement la session pour ne pas laisser un état incohérent).
  static Future<User> signIn({
    required String username,
    required String password,
  }) async {
    signingIn = true;
    try {
      return await _signIn(username: username, password: password);
    } finally {
      signingIn = false;
    }
  }

  /// Vrai pendant une connexion en cours : la vérification périodique de
  /// session (voir AuthGate) ne doit pas interférer avec elle.
  static bool signingIn = false;

  static Future<User> _signIn({
    required String username,
    required String password,
  }) async {
    final AuthResponse response;
    try {
      response = await supabase.auth.signInWithPassword(
        email: _emailFor(username),
        password: password,
      );
    } on AuthException catch (error) {
      // Compte bloqué par l'administrateur (ban Auth) : message explicite
      // plutôt que « identifiant ou mot de passe incorrect ».
      if (error.code == 'user_banned' ||
          error.message.toLowerCase().contains('banned')) {
        throw const AccessDeniedException('Ce compte a été désactivé.');
      }
      rethrow;
    }
    final user = response.user;
    if (user == null) {
      throw const AccessDeniedException('Connexion impossible.');
    }

    try {
      await registerCurrentDevice();
    } on AccessDeniedException {
      await supabase.auth.signOut();
      rethrow;
    }

    await WalletController.instance.loadForUser(user.id);
    return user;
  }

  /// Ré-enregistre l'appareil courant pour la session déjà active
  /// (appelé au démarrage si une session persistée existe encore).
  static Future<void> registerCurrentDevice() async {
    final deviceId = await DeviceIdService.getOrCreate();
    try {
      await supabase.rpc('register_device', params: {'p_device_id': deviceId});
    } on PostgrestException catch (error) {
      throw AccessDeniedException(_friendlyMessage(error.message));
    }
  }

  static Future<void> signOut() => supabase.auth.signOut();

  static String _friendlyMessage(String code) => switch (code) {
    'ACCOUNT_EXPIRED' => 'Votre accès a expiré. Contactez l\'administrateur.',
    'ACCOUNT_DISABLED' => 'Ce compte a été désactivé.',
    'DEVICE_LIMIT_REACHED' =>
      'Nombre maximal d\'appareils atteint pour ce compte.',
    'PROFILE_NOT_FOUND' => 'Compte introuvable.',
    _ => 'Accès refusé ($code).',
  };
}
