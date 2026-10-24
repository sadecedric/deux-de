import 'package:flutter/material.dart';

import '../../../core/services/supabase/auth_service.dart';
import '../../../core/services/supabase/shared_prediction_store.dart';
import '../../auth/presentation/login_screen.dart';
import 'predictor_screen.dart';

/// Portail web : mêmes comptes et même prédiction que l'application.
class PredictorPortal extends StatefulWidget {
  const PredictorPortal({super.key});

  @override
  State<PredictorPortal> createState() => _PredictorPortalState();
}

class _PredictorPortalState extends State<PredictorPortal> {
  final _controller = createPredictionController();
  bool _signingOut = false;

  Future<void> _signOut() async {
    if (_signingOut) return;
    _signingOut = true;
    try {
      await AuthService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Déconnexion impossible. Réessayez.')),
        );
      }
    } finally {
      _signingOut = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      PredictorScreen(controller: _controller, onSignOut: _signOut);
}
