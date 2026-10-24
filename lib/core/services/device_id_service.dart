import 'dart:math';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Identifiant d'appareil persistant, généré une fois puis stocké
/// localement. Sert à faire respecter la limite d'appareils par compte
/// (voir `register_device` dans supabase/migrations/0003_access_control.sql).
class DeviceIdService {
  DeviceIdService._();

  static const _prefsKey = 'under_over_7_device_id';
  static const _channel = MethodChannel('under_over_7/device');

  static Future<String> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_prefsKey);
    if (existing != null && existing.isNotEmpty) return existing;

    try {
      final deviceId = await _channel.invokeMethod<String>('stableDeviceId');
      if (deviceId != null && deviceId.isNotEmpty) {
        await prefs.setString(_prefsKey, deviceId);
        return deviceId;
      }
    } on PlatformException {
      // Les plateformes sans implémentation native conservent leur stockage
      // local, qui reste persistant lors d'une mise à jour standard.
    } on MissingPluginException {
      // Idem pour les tests et les plateformes autres qu'Android.
    }

    final generated = _generateLegacyId();
    await prefs.setString(_prefsKey, generated);
    return generated;
  }

  static String _generateLegacyId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
