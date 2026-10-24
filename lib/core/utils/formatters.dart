import 'package:intl/intl.dart';

/// Formatte un montant virtuel avec séparateur d'espaces, ex: 25 572 903.82
class AppFormatters {
  AppFormatters._();

  static final NumberFormat _amount = NumberFormat.decimalPatternDigits(
    locale: 'fr_FR',
    decimalDigits: 2,
  );

  static final NumberFormat _stake = NumberFormat.decimalPattern('fr_FR');

  static String amount(double value) => _amount.format(value);

  static String stake(num value) => _stake.format(value);
}
