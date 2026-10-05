import 'package:fitness_studio_mobile/app.dart';
import 'package:fitness_studio_mobile/injection/service_locator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders login form', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    await configureDependencies();

    await tester.pumpWidget(const ProviderScope(child: FitnessStudioApp()));
    await tester.pumpAndSettle();

    expect(find.text('Fitness Studio'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Lozinka'), findsOneWidget);
    expect(find.text('Prijavi se'), findsOneWidget);
  });
}
