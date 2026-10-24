import 'package:flutter/foundation.dart';

/// Le navigateur ouvre le prédicteur ; Android conserve l'application complète.
const predictorOnly = bool.fromEnvironment(
  'PREDICTOR_ONLY',
  defaultValue: kIsWeb,
);
