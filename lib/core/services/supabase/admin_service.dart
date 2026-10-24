import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

// Seules les métadonnées attribuées côté serveur font foi.
bool hasAdminRole(User? user) => user?.appMetadata['role'] == 'admin';

class AdminService {
  const AdminService();

  Future<List<Map<String, dynamic>>> listUsers() async {
    final data = await _request(HttpMethod.get);
    return (data['users'] as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<void> saveUser(Map<String, dynamic> values) async {
    await _request(
      values['userId'] == null ? HttpMethod.post : HttpMethod.patch,
      body: values,
    );
  }

  Future<void> setActive(String userId, bool active) async {
    await _request(
      HttpMethod.patch,
      body: {'action': 'setActive', 'userId': userId, 'isActive': active},
    );
  }

  Future<Map<String, dynamic>> _request(
    HttpMethod method, {
    Map<String, dynamic>? body,
  }) async {
    if (!hasAdminRole(supabase.auth.currentUser)) {
      throw const AdminException('Accès réservé aux administrateurs.');
    }
    try {
      final response = await supabase.functions.invoke(
        'admin-create-user',
        method: method,
        body: body,
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      if (data['error'] != null) throw AdminException(_message(data['error']));
      return data;
    } on FunctionException catch (error) {
      final details = error.details;
      throw AdminException(_message(details is Map ? details['error'] : null));
    }
  }

  String _message(Object? code) => switch (code) {
    'UNAUTHORIZED' => 'Votre session a expiré. Reconnectez-vous.',
    'FORBIDDEN' => 'Accès administrateur refusé ou compte expiré.',
    'INVALID_USERNAME' =>
      'Identifiant invalide (3 à 40 lettres, chiffres, . _ -).',
    'INVALID_PASSWORD' =>
      'Le mot de passe doit contenir au moins 6 caractères.',
    'INVALID_LIMITS' => 'Vérifiez la limite d’appareils et la durée d’accès.',
    'SELF_DISABLE_FORBIDDEN' =>
      'Vous ne pouvez pas bloquer votre propre compte.',
    'USER_NOT_FOUND' => 'Cet utilisateur est introuvable.',
    _ => 'Opération impossible. Vérifiez les informations et réessayez.',
  };
}

class AdminException implements Exception {
  const AdminException(this.message);
  final String message;
  @override
  String toString() => message;
}
