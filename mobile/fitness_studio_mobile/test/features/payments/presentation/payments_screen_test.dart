import 'package:fitness_studio_mobile/features/payments/domain/entities/membership_payment.dart';
import 'package:fitness_studio_mobile/features/payments/presentation/screens/payments_screen.dart';
import 'package:fitness_studio_mobile/features/payments/presentation/state/payment_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/localized_test_app.dart';

void main() {
  testWidgets('shows member payment amount and status', (tester) async {
    final payment = MembershipPayment(
      id: 1,
      memberMembershipId: 2,
      memberId: 3,
      memberName: 'Ana Horvat',
      planName: 'Grupni trening 2x tjedno',
      periodStartsOn: DateTime(2026, 10, 11),
      periodEndsOn: DateTime(2026, 11, 11),
      dueOn: DateTime(2026, 10, 11),
      fullAmount: 70,
      amountDue: 70,
      currency: 'EUR',
      status: 'pending',
      isOverdue: false,
      recipientName: 'Kristina Lisec',
      iban: 'HR4923400093114113828',
      paymentModel: 'HR00',
      paymentReference: '1',
      paymentDescription: 'poduka',
      barcodeUrl: '/api/membership-payments/1/barcode',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          paymentsProvider((
            admin: false,
            view: PaymentView.all,
          )).overrideWith((ref) async => [payment]),
        ],
        child: localizedTestApp(home: const PaymentsScreen(admin: false)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Grupni trening 2x tjedno'), findsOneWidget);
    expect(find.textContaining('Neplaćeno'), findsOneWidget);
    await tester.tap(find.text('Grupni trening 2x tjedno'));
    await tester.pumpAndSettle();
    expect(find.text('Kristina Lisec'), findsOneWidget);
    expect(find.text('Uplatio sam'), findsOneWidget);
  });

  testWidgets('admin sees filters and billing date dialog', (tester) async {
    final membership = MembershipBillingItem(
      id: 4,
      memberName: 'Ana Horvat',
      planName: 'Mjesečni paket',
      startsOn: DateTime(2026, 1, 1),
      endsOn: null,
      billingStartsOn: null,
      nextBillingOn: null,
      isActive: true,
    );
    const summary = MembershipPaymentSummary(
      pending: 1,
      reported: 2,
      overdue: 3,
      paid: 4,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          paymentsProvider((
            admin: true,
            view: PaymentView.pending,
          )).overrideWith((ref) async => []),
          paymentSummaryProvider.overrideWith((ref) async => summary),
          billingMembershipsProvider.overrideWith((ref) async => [membership]),
        ],
        child: localizedTestApp(home: const PaymentsScreen(admin: true)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Za naplatu (1)'), findsOneWidget);
    expect(find.text('Čeka potvrdu (2)'), findsOneWidget);
    expect(find.text('Naplata nije uključena'), findsOneWidget);
    await tester.tap(find.text('Uključi naplatu'));
    await tester.pumpAndSettle();
    expect(find.text('Naplata vrijedi od'), findsOneWidget);
    expect(find.text('Ana Horvat'), findsWidgets);
  });

  testWidgets('admin can open mark-paid confirmation from payment row', (
    tester,
  ) async {
    final payment = MembershipPayment(
      id: 9,
      memberMembershipId: 2,
      memberId: 3,
      memberName: 'Ana Horvat',
      planName: 'Mjesečni paket',
      periodStartsOn: DateTime(2026, 10, 1),
      periodEndsOn: DateTime(2026, 11, 1),
      dueOn: DateTime(2026, 10, 1),
      fullAmount: 70,
      amountDue: 70,
      currency: 'EUR',
      status: 'pending',
      isOverdue: false,
      recipientName: 'Kristina Lisec',
      iban: 'HR4923400093114113828',
      paymentModel: 'HR00',
      paymentReference: '1',
      paymentDescription: 'poduka',
      barcodeUrl: '/api/membership-payments/9/barcode',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          paymentsProvider((
            admin: true,
            view: PaymentView.pending,
          )).overrideWith((ref) async => [payment]),
          paymentSummaryProvider.overrideWith(
            (ref) async => const MembershipPaymentSummary(
              pending: 1,
              reported: 0,
              overdue: 0,
              paid: 0,
            ),
          ),
          billingMembershipsProvider.overrideWith((ref) async => []),
        ],
        child: localizedTestApp(home: const PaymentsScreen(admin: true)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Označi plaćeno'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('Ana Horvat'), findsWidgets);
    expect(find.textContaining('70,00'), findsWidgets);
  });

  testWidgets('enabled membership remains visible in active billing', (
    tester,
  ) async {
    final membership = MembershipBillingItem(
      id: 4,
      memberName: 'Ana Horvat',
      planName: 'Mjesečni paket',
      startsOn: DateTime(2026, 1, 1),
      endsOn: null,
      billingStartsOn: DateTime(2026, 2, 1),
      nextBillingOn: DateTime(2026, 11, 1),
      isActive: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          paymentsProvider((
            admin: true,
            view: PaymentView.pending,
          )).overrideWith((ref) async => []),
          paymentSummaryProvider.overrideWith(
            (ref) async => const MembershipPaymentSummary(
              pending: 0,
              reported: 0,
              overdue: 0,
              paid: 0,
            ),
          ),
          billingMembershipsProvider.overrideWith((ref) async => [membership]),
        ],
        child: localizedTestApp(home: const PaymentsScreen(admin: true)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aktivna naplata'), findsOneWidget);
    expect(find.textContaining('Naplata vrijedi od:'), findsOneWidget);
    expect(find.textContaining('2026.'), findsOneWidget);
    expect(find.text('Ana Horvat'), findsOneWidget);
  });
}
