import 'package:flutter/material.dart';

import '../../../core/services/wallet_controller.dart';
import '../../../core/widgets/cancel_text_button.dart';

Future<void> showBalanceEditor(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const _BalanceEditor());

class _BalanceEditor extends StatefulWidget {
  const _BalanceEditor();

  @override
  State<_BalanceEditor> createState() => _BalanceEditorState();
}

class _BalanceEditorState extends State<_BalanceEditor> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController(
    text: WalletController.instance.balance.toStringAsFixed(2),
  );
  bool _saving = false;
  String? _error;

  double? _parse(String value) => double.tryParse(
    value.replaceAll(RegExp(r'[\s\u00a0\u202f]'), '').replaceAll(',', '.'),
  );

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await WalletController.instance.setBalance(_parse(_amount.text)!);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Impossible d’enregistrer le solde. Réessayez.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: const Text('Modifier mon solde'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choisissez votre nouveau solde virtuel.'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amount,
              autofocus: true,
              enabled: !_saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Nouveau solde',
                suffixText: 'XAF',
              ),
              validator: (value) {
                final amount = _parse(value ?? '');
                if (amount == null ||
                    !amount.isFinite ||
                    amount < 0 ||
                    !(amount * 100).isFinite) {
                  return 'Saisissez un montant positif ou zéro.';
                }
                return null;
              },
              onFieldSubmitted: (_) => _save(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        CancelTextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
        ),
      ],
    ),
  );
}
