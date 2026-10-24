import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/services/supabase/admin_service.dart';
import '../../../core/services/supabase/supabase_config.dart';
import '../../../core/widgets/cancel_text_button.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key, this.service = const AdminService()});
  final AdminService service;
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<Map<String, dynamic>> _users = [];
  String _query = '';
  String? _error;
  bool _loading = true;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await widget.service.listUsers();
      if (mounted) setState(() => _users = users);
    } catch (error) {
      if (mounted) {
        setState(() {
          _users = [];
          _error = error is AdminException ? error.message : 'Impossible de charger les utilisateurs. Vérifiez votre connexion.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _expired(Map<String, dynamic> user) {
    final date = DateTime.tryParse(user['valid_until']?.toString() ?? '');
    return date != null && !date.isAfter(DateTime.now());
  }

  String _date(Object? value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    return date == null
        ? '—'
        : DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
  }

  void _notify(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _edit([Map<String, dynamic>? user]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UserEditor(service: widget.service, user: user),
    );
    if (saved == true && mounted) {
      _notify(user == null ? 'Utilisateur créé.' : 'Utilisateur modifié.');
      await _load();
    }
  }

  Future<void> _toggle(Map<String, dynamic> user) async {
    final id = user['id'] as String;
    final active = user['is_active'] == true;
    if (active) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Bloquer ce compte ?'),
          content: Text(
            '${user['username']} ne pourra plus se connecter tant que le compte sera bloqué.',
          ),
          actions: [
            CancelTextButton(onPressed: () => Navigator.pop(context, false)),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Bloquer'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() => _busy.add(id));
    try {
      await widget.service.setActive(id, !active);
      if (!mounted) return;
      _notify(active ? 'Compte bloqué.' : 'Compte débloqué.');
      await _load();
    } catch (error) {
      _notify(
        error is AdminException
            ? error.message
            : 'Opération impossible. Réessayez.',
      );
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _users
        .where(
          (u) =>
              '${u['username']} ${u['email']}'.toLowerCase().contains(_query),
        )
        .toList();
    final currentId = SupabaseConfig.initialized
        ? supabase.auth.currentUser?.id
        : null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _stat('Utilisateurs', _users.length),
                _stat(
                  'Actifs',
                  _users
                      .where((u) => u['is_active'] == true && !_expired(u))
                      .length,
                ),
                _stat('Expirés', _users.where(_expired).length),
                _stat(
                  'Appareils',
                  _users.fold<int>(
                    0,
                    (n, u) => n + ((u['device_count'] as num?)?.toInt() ?? 0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _edit(),
              icon: const Icon(Icons.person_add),
              label: const Text('Créer un utilisateur'),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Rechercher un utilisateur',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null) ...[
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              TextButton(onPressed: _load, child: const Text('Réessayer')),
            ] else if (visible.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Aucun utilisateur trouvé.'),
              )
            else
              for (final user in visible)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['username']?.toString() ?? 'Utilisateur',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          user['is_active'] != true
                              ? 'Désactivé'
                              : _expired(user)
                              ? 'Expiré'
                              : 'Actif',
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          user['email']?.toString() ?? user['id'].toString(),
                        ),
                        Text(
                          'Validité : ${user['valid_until'] == null ? 'Illimitée' : _date(user['valid_until'])}',
                        ),
                        Text(
                          'Appareils : ${user['device_count'] ?? 0} / ${user['max_devices']}',
                        ),
                        Text(
                          'Solde : ${NumberFormat('#,##0.##', 'fr_FR').format(num.tryParse('${user['balance']}') ?? 0)} XAF',
                        ),
                        Text(
                          'Dernière connexion : ${user['last_sign_in_at'] == null ? 'Jamais' : _date(user['last_sign_in_at'])}',
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            TextButton.icon(
                              onPressed: _busy.contains(user['id'])
                                  ? null
                                  : () => _edit(user),
                              icon: const Icon(Icons.edit),
                              label: const Text('Modifier'),
                            ),
                            TextButton.icon(
                              onPressed:
                                  _busy.contains(user['id']) ||
                                      currentId == user['id']
                                  ? null
                                  : () => _toggle(user),
                              icon: Icon(
                                user['is_active'] == true
                                    ? Icons.block
                                    : Icons.lock_open,
                              ),
                              label: Text(
                                user['is_active'] == true
                                    ? 'Bloquer'
                                    : 'Débloquer',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, int value) => SizedBox(
    width: 145,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            Text('$value', style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      ),
    ),
  );
}

class _UserEditor extends StatefulWidget {
  const _UserEditor({required this.service, this.user});
  final AdminService service;
  final Map<String, dynamic>? user;
  @override
  State<_UserEditor> createState() => _UserEditorState();
}

class _UserEditorState extends State<_UserEditor> {
  final _form = GlobalKey<FormState>();
  late final _username = TextEditingController(
    text: widget.user?['username']?.toString(),
  );
  final _password = TextEditingController();
  late final _devices = TextEditingController(
    text: '${widget.user?['max_devices'] ?? 1}',
  );
  final _days = TextEditingController(text: '30');
  late bool _active = widget.user?['is_active'] != false;
  bool _clearDevices = false;
  bool _saving = false;
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [_username, _password, _devices, _days]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _generate() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
    final random = Random.secure();
    _password.text = List.generate(
      12,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
    setState(() => _showPassword = true);
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.service.saveUser({
        if (widget.user != null) 'userId': widget.user!['id'],
        'username': _username.text.trim().toLowerCase(),
        'password': _password.text,
        'maxDevices': int.parse(_devices.text.trim()),
        'validityDays': int.parse(_days.text.trim()),
        'isActive': _active,
        'clearDevices': _clearDevices,
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is AdminException
              ? error.message
              : 'Enregistrement impossible. Réessayez.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _positive(String? text, int max) {
    final value = int.tryParse(text?.trim() ?? '');
    return value == null || value < 1 || value > max
        ? 'Entrez un nombre de 1 à $max.'
        : null;
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: Text(
        widget.user == null ? 'Créer un utilisateur' : 'Modifier l’utilisateur',
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _username,
                  enabled: !_saving,
                  decoration: const InputDecoration(labelText: 'Identifiant'),
                  validator: (v) =>
                      RegExp(r'^[a-zA-Z0-9._-]{3,40}$')
                          .hasMatch(v?.trim() ?? '')
                      ? null
                      : '3 à 40 lettres, chiffres, . _ -',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  enabled: !_saving,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    helperText: widget.user != null
                        ? 'Laisser vide pour conserver le mot de passe.'
                        : 'Au moins 6 caractères.',
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                      icon: Icon(
                        _showPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                    ),
                  ),
                  validator: (v) =>
                      (v ?? '').isEmpty && widget.user != null ||
                          (v ?? '').length >= 6
                      ? null
                      : 'Au moins 6 caractères.',
                ),
                TextButton(
                  onPressed: _saving ? null : _generate,
                  child: const Text('Générer un mot de passe'),
                ),
                TextFormField(
                  controller: _devices,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Appareils autorisés',
                  ),
                  validator: (v) => _positive(v, 100),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _days,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nouvelle validité (jours)',
                    helperText: 'À compter de l’enregistrement.',
                  ),
                  validator: (v) => _positive(v, 3650),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Compte actif'),
                  value: _active,
                  onChanged:
                      _saving ||
                          (SupabaseConfig.initialized &&
                              widget.user?['id'] ==
                                  supabase.auth.currentUser?.id)
                      ? null
                      : (v) => setState(() => _active = v),
                ),
                if (widget.user != null)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Libérer les appareils enregistrés'),
                    value: _clearDevices,
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => _clearDevices = v ?? false),
                  ),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        CancelTextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
        ),
      ],
    ),
  );
}
