import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_mode.dart';
import '../services/supabase/admin_service.dart';
import '../services/supabase/supabase_config.dart';
import '../../features/admin/presentation/admin_screen.dart';
import '../../features/auth/presentation/login_screen.dart';

import '../../features/game/presentation/game_screen.dart';
import '../../features/game/presentation/predictor_portal.dart';

/// L'administration n'est proposée qu'aux comptes disposant du rôle serveur.
class RootNavigation extends StatelessWidget {
  const RootNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    if (!SupabaseConfig.initialized || supabase.auth.currentSession == null) {
      return const LoginScreen();
    }
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, _) {
        if (supabase.auth.currentSession == null) return const LoginScreen();
        if (predictorOnly) return const PredictorPortal();
        return AdminNavigation(
          isAdmin: hasAdminRole(supabase.auth.currentUser),
        );
      },
    );
  }
}

class AdminNavigation extends StatefulWidget {
  const AdminNavigation({super.key, required this.isAdmin});
  final bool isAdmin;
  @override
  State<AdminNavigation> createState() => _AdminNavigationState();
}

class _AdminNavigationState extends State<AdminNavigation> {
  int _index = 0;
  bool _adminOpened = false;

  @override
  void didUpdateWidget(covariant AdminNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isAdmin) {
      _index = 0;
      _adminOpened = false;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: widget.isAdmin ? _index : 0,
      children: [
        GameScreen(
          key: ValueKey(widget.isAdmin),
          initialStake: widget.isAdmin ? 2000 : 400,
        ),
        if (widget.isAdmin && _adminOpened) const AdminScreen(),
      ],
    ),
    bottomNavigationBar: widget.isAdmin
        ? NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() {
              _index = value;
              if (value == 1) _adminOpened = true;
            }),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.casino_outlined),
                label: 'Jeu',
              ),
              NavigationDestination(
                icon: Icon(Icons.admin_panel_settings_outlined),
                label: 'Admin',
              ),
            ],
          )
        : null,
  );
}
