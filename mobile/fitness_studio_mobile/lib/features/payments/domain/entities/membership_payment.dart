class MembershipPayment {
  const MembershipPayment({
    required this.id,
    required this.memberMembershipId,
    required this.memberId,
    required this.memberName,
    required this.planName,
    required this.periodStartsOn,
    required this.periodEndsOn,
    required this.dueOn,
    required this.fullAmount,
    required this.amountDue,
    required this.currency,
    required this.status,
    required this.isOverdue,
    required this.recipientName,
    required this.iban,
    required this.paymentModel,
    required this.paymentReference,
    required this.paymentDescription,
    required this.barcodeUrl,
  });

  final int id;
  final int memberMembershipId;
  final int memberId;
  final String memberName;
  final String planName;
  final DateTime periodStartsOn;
  final DateTime periodEndsOn;
  final DateTime dueOn;
  final double fullAmount;
  final double amountDue;
  final String currency;
  final String status;
  final bool isOverdue;
  final String recipientName;
  final String iban;
  final String paymentModel;
  final String paymentReference;
  final String paymentDescription;
  final String barcodeUrl;

  factory MembershipPayment.fromJson(Map<String, dynamic> json) {
    return MembershipPayment(
      id: json['id'] as int,
      memberMembershipId: json['memberMembershipId'] as int,
      memberId: json['memberId'] as int,
      memberName: json['memberName'] as String,
      planName: json['planName'] as String,
      periodStartsOn: DateTime.parse(json['periodStartsOn'] as String),
      periodEndsOn: DateTime.parse(json['periodEndsOn'] as String),
      dueOn: DateTime.parse(json['dueOn'] as String),
      fullAmount: (json['fullAmount'] as num).toDouble(),
      amountDue: (json['amountDue'] as num).toDouble(),
      currency: json['currency'] as String,
      status: json['status'] as String,
      isOverdue: json['isOverdue'] as bool,
      recipientName: json['recipientName'] as String,
      iban: json['iban'] as String,
      paymentModel: json['paymentModel'] as String,
      paymentReference: json['paymentReference'] as String,
      paymentDescription: json['paymentDescription'] as String,
      barcodeUrl: json['barcodeUrl'] as String,
    );
  }
}

enum PaymentView { pending, reported, overdue, paid, all }

class MembershipPaymentSummary {
  const MembershipPaymentSummary({
    required this.pending,
    required this.reported,
    required this.overdue,
    required this.paid,
  });

  final int pending;
  final int reported;
  final int overdue;
  final int paid;

  factory MembershipPaymentSummary.fromJson(Map<String, dynamic> json) =>
      MembershipPaymentSummary(
        pending: json['pending'] as int,
        reported: json['reported'] as int,
        overdue: json['overdue'] as int,
        paid: json['paid'] as int,
      );
}

class PaymentSettings {
  const PaymentSettings({
    required this.recipientName,
    required this.iban,
    required this.paymentModel,
    required this.paymentReference,
    required this.paymentDescription,
    required this.memberReminderDays,
    required this.adminReminderDays,
    required this.notificationTime,
    required this.isComplete,
  });
  final String recipientName;
  final String iban;
  final String paymentModel;
  final String paymentReference;
  final String paymentDescription;
  final List<int> memberReminderDays;
  final List<int> adminReminderDays;
  final String notificationTime;
  final bool isComplete;
  factory PaymentSettings.fromJson(Map<String, dynamic> json) =>
      PaymentSettings(
        recipientName: json['recipientName'] as String,
        iban: json['iban'] as String,
        paymentModel: json['paymentModel'] as String,
        paymentReference: json['paymentReference'] as String,
        paymentDescription: json['paymentDescription'] as String,
        memberReminderDays: (json['memberReminderDays'] as List<dynamic>)
            .cast<int>(),
        adminReminderDays: (json['adminReminderDays'] as List<dynamic>)
            .cast<int>(),
        notificationTime: json['notificationTime'] as String,
        isComplete: json['isComplete'] as bool,
      );
}

class MembershipBillingItem {
  const MembershipBillingItem({
    required this.id,
    required this.memberName,
    required this.planName,
    required this.startsOn,
    required this.endsOn,
    required this.billingStartsOn,
    required this.nextBillingOn,
    required this.isActive,
  });
  final int id;
  final String memberName;
  final String planName;
  final DateTime startsOn;
  final DateTime? endsOn;
  final DateTime? billingStartsOn;
  final DateTime? nextBillingOn;
  final bool isActive;
  factory MembershipBillingItem.fromJson(Map<String, dynamic> json) =>
      MembershipBillingItem(
        id: json['id'] as int,
        memberName: json['memberName'] as String,
        planName: json['membershipPlanName'] as String,
        startsOn: DateTime.parse(json['startsOn'] as String),
        endsOn: json['endsOn'] == null
            ? null
            : DateTime.parse(json['endsOn'] as String),
        billingStartsOn: json['billingStartsOn'] == null
            ? null
            : DateTime.parse(json['billingStartsOn'] as String),
        nextBillingOn: json['nextBillingOn'] == null
            ? null
            : DateTime.parse(json['nextBillingOn'] as String),
        isActive: json['isActive'] as bool,
      );
}

class SetMembershipBillingResult {
  const SetMembershipBillingResult({
    required this.createdObligations,
    required this.nextBillingOn,
  });

  final int createdObligations;
  final DateTime? nextBillingOn;

  factory SetMembershipBillingResult.fromJson(Map<String, dynamic> json) =>
      SetMembershipBillingResult(
        createdObligations: json['createdObligations'] as int,
        nextBillingOn: json['nextBillingOn'] == null
            ? null
            : DateTime.parse(json['nextBillingOn'] as String),
      );
}

class BillingNotification {
  const BillingNotification({
    required this.id,
    required this.paymentObligationId,
    required this.title,
    required this.body,
    required this.readAt,
    required this.createdAt,
  });
  final int id;
  final int? paymentObligationId;
  final String title;
  final String body;
  final DateTime? readAt;
  final DateTime createdAt;
  factory BillingNotification.fromJson(Map<String, dynamic> json) =>
      BillingNotification(
        id: json['id'] as int,
        paymentObligationId: json['paymentObligationId'] as int?,
        title: json['title'] as String,
        body: json['body'] as String,
        readAt: json['readAt'] == null
            ? null
            : DateTime.parse(json['readAt'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
