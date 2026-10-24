import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/services/wallet_controller.dart';
import '../../wallet/widgets/virtual_wallet_card.dart';
import '../../wallet/widgets/balance_editor.dart';
import '../../../core/services/supabase/auth_service.dart';
import '../../../core/services/supabase/supabase_config.dart';
import '../../auth/presentation/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _sounds = true;
  bool _vibrations = true;
  bool _animations = true;

  @override
  Widget build(BuildContext context) {
    final user = SupabaseConfig.initialized ? supabase.auth.currentUser : null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.spaceM),
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.violet, AppColors.info],
                  ),
                  border: Border.all(color: AppColors.gold, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.violet.withValues(alpha: .32),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: const Icon(Icons.person, size: 46, color: Colors.white),
              ),
              const SizedBox(height: AppDimens.spaceM),
              Text(
                user?.userMetadata?['username'] as String? ?? 'Joueur local',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user == null
                    ? 'Mode local'
                    : user.appMetadata['role'] == 'admin'
                    ? 'Administrateur'
                    : 'Connecté',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: AppDimens.spaceM),
              if (user == null)
                FilledButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text('Se connecter'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                )
              else
                OutlinedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Se déconnecter'),
                  onPressed: () async {
                    try {
                      await AuthService.signOut();
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Déconnexion impossible. Réessayez.'),
                          ),
                        );
                      }
                    }
                  },
                ),
              ListenableBuilder(
                listenable: WalletController.instance,
                builder: (context, _) => VirtualWalletCard(
                  balance: WalletController.instance.balance,
                ),
              ),
              const SizedBox(height: AppDimens.spaceL),
              FilledButton.icon(
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Modifier mon solde'),
                onPressed: () => showBalanceEditor(context),
              ),
              const SizedBox(height: AppDimens.spaceM),
              _SectionCard(
                children: [
                  _SwitchTile(
                    icon: Icons.volume_up_rounded,
                    color: AppColors.gold,
                    label: 'Sons',
                    value: _sounds,
                    onChanged: (v) => setState(() => _sounds = v),
                  ),
                  _SwitchTile(
                    icon: Icons.vibration_rounded,
                    color: AppColors.cyan,
                    label: 'Vibrations',
                    value: _vibrations,
                    onChanged: (v) => setState(() => _vibrations = v),
                  ),
                  _SwitchTile(
                    icon: Icons.animation_rounded,
                    color: AppColors.violet,
                    label: 'Animations',
                    value: _animations,
                    onChanged: (v) => setState(() => _animations = v),
                  ),
                  _NavTile(
                    icon: Icons.language_rounded,
                    color: AppColors.greenBright,
                    label: 'Langue',
                    trailing: 'Français',
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceElevated, AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        border: Border.all(color: AppColors.violet.withValues(alpha: .22)),
      ),
      child: Column(children: children),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color color;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.gold,
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .13),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(label, style: const TextStyle(color: AppColors.textPrimary)),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .13),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(label, style: const TextStyle(color: AppColors.textPrimary)),
      trailing: trailing != null
          ? Text(trailing!, style: const TextStyle(color: AppColors.textMuted))
          : const Icon(Icons.chevron_right, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}
