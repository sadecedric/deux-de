import '../device_id_service.dart';
import '../local_prediction_controller.dart';
import '../session_guard.dart';
import 'supabase_config.dart';

LocalPredictionController createPredictionController() =>
    LocalPredictionController(
      store: SupabaseConfig.initialized && supabase.auth.currentUser != null
          ? SupabasePredictionStore(supabase.auth.currentUser!.id)
          : null,
    );

class SupabasePredictionStore implements PredictionStore {
  SupabasePredictionStore(this.userId);
  final String userId;

  Future<LocalPrediction> _request(bool regenerate) async {
    try {
      final data = await supabase.rpc(
        'prediction_state',
        params: {
          'p_device_id': await DeviceIdService.getOrCreate(),
          'p_regenerate': regenerate,
        },
      );
      return LocalPrediction.fromJson(Map<String, dynamic>.from(data as Map));
    } catch (error) {
      SessionGuard.handleAccessError(error);
      rethrow;
    }
  }

  @override
  Future<LocalPrediction> read() => _request(false);

  @override
  Future<LocalPrediction> generate() => _request(true);

  @override
  Stream<LocalPrediction> watch() => supabase
      .from('user_predictions')
      .stream(primaryKey: ['user_id'])
      .eq('user_id', userId)
      .where((rows) => rows.isNotEmpty)
      .map((rows) => LocalPrediction.fromJson(rows.single));
}
