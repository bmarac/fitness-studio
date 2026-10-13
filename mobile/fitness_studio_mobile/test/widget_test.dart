import 'package:fitness_studio_mobile/app.dart';
import 'package:fitness_studio_mobile/injection/service_locator.dart';
import 'package:fitness_studio_mobile/features/trainers/domain/repositories/trainers_management_repository.dart';
import 'package:flutter/material.dart';
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
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);

    final fields = tester.widgetList<TextFormField>(find.byType(TextFormField));
    expect(fields.length, 2);
    expect(serviceLocator<TrainersManagementRepository>(), isNotNull);

    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsOneWidget);

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Registration'), findsOneWidget);
  });
}
