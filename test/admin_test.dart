import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:under_over_7/core/router/root_navigation.dart';
import 'package:under_over_7/core/services/supabase/admin_service.dart';
import 'package:under_over_7/features/admin/presentation/admin_screen.dart';

class FakeAdminService extends AdminService {
  Map<String, dynamic>? saved;
  bool active = true;
  bool fail = false;
  @override
  Future<List<Map<String, dynamic>>> listUsers() async {
    if (fail) throw const AdminException('Accès administrateur refusé.');
    return [
      {
        'id': 'player',
        'username': 'alice',
        'email': 'alice@underover7.local',
        'is_active': active,
        'max_devices': 2,
        'device_count': 1,
        'balance': 5000,
        'valid_until': '2099-01-01T00:00:00Z',
        'last_sign_in_at': null,
      },
    ];
  }

  @override
  Future<void> saveUser(Map<String, dynamic> values) async {
    saved = values;
  }

  @override
  Future<void> setActive(String userId, bool value) async {
    active = value;
  }
}

void main() {
  test('seul le rôle serveur accorde l’administration', () {
    User user(Map<String, dynamic> app, Map<String, dynamic> personal) => User(
      id: 'test',
      appMetadata: app,
      userMetadata: personal,
      aud: 'authenticated',
      createdAt: '2026-01-01T00:00:00Z',
    );
    expect(hasAdminRole(null), false);
    expect(
      hasAdminRole(user({}, {'username': 'cedric', 'role': 'admin'})),
      false,
    );
    expect(hasAdminRole(user({'role': 'admin'}, {})), true);
    expect(hasAdminRole(user({'role': 'player'}, {})), false);
  });

  testWidgets('onglet réservé à l’admin et retiré après perte du rôle', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AdminNavigation(isAdmin: false)),
    );
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('400 XAF'), findsOneWidget);
    await tester.pumpWidget(
      const MaterialApp(home: AdminNavigation(isAdmin: true)),
    );
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('2000 XAF'), findsOneWidget);
    await tester.pumpWidget(
      const MaterialApp(home: AdminNavigation(isAdmin: false)),
    );
    expect(find.text('Admin'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('recherche, blocage confirmé et déblocage', (tester) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = FakeAdminService();
    await tester.pumpWidget(MaterialApp(home: AdminScreen(service: service)));
    await tester.pumpAndSettle();
    expect(find.text('alice'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'introuvable');
    await tester.pumpAndSettle();
    expect(find.text('Aucun utilisateur trouvé.'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'ALICE');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bloquer'));
    await tester.pumpAndSettle();
    expect(service.active, true);
    await tester.tap(find.widgetWithText(FilledButton, 'Bloquer'));
    await tester.pumpAndSettle();
    expect(service.active, false);
    expect(find.text('Désactivé'), findsOneWidget);
    await tester.tap(find.text('Débloquer'));
    await tester.pumpAndSettle();
    expect(service.active, true);
  });

  testWidgets('création validée et édition des accès', (tester) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = FakeAdminService();
    await tester.pumpWidget(MaterialApp(home: AdminScreen(service: service)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer un utilisateur'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(service.saved, isNull);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'bob');
    await tester.enterText(fields.at(1), 'Password123');
    await tester.enterText(fields.at(2), '3');
    await tester.enterText(fields.at(3), '60');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(service.saved?['username'], 'bob');
    expect(service.saved?['maxDevices'], 3);
    expect(service.saved?['validityDays'], 60);
    expect(service.saved?.containsKey('userId'), false);
    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(service.saved?['userId'], 'player');
    expect(service.saved?['password'], '');
    expect(service.saved?['clearDevices'], true);
  });

  testWidgets('un refus serveur affiche une erreur et permet de réessayer', (
    tester,
  ) async {
    final service = FakeAdminService()..fail = true;
    await tester.pumpWidget(MaterialApp(home: AdminScreen(service: service)));
    await tester.pumpAndSettle();
    expect(find.text('Accès administrateur refusé.'), findsOneWidget);
    service.fail = false;
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.text('alice'), findsOneWidget);
  });
}
