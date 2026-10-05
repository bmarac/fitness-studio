import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../injection/service_locator.dart';
import '../../../auth/presentation/state/login_controller.dart';
import '../../../auth/presentation/state/login_state.dart';
import '../../../bookings/domain/entities/booking.dart';
import '../../../bookings/domain/usecases/cancel_booking.dart';
import '../../../bookings/domain/usecases/cancel_fixed_schedule.dart';
import '../../../bookings/domain/usecases/create_booking.dart';
import '../../../bookings/domain/usecases/update_booking_status.dart';
import '../../domain/entities/class_session.dart';
import '../../domain/usecases/cancel_class_session.dart';
import '../state/class_sessions_controller.dart';
import '../state/class_session_bookings_provider.dart';
import '../state/class_session_details_provider.dart';

class ClassSessionDetailsScreen extends ConsumerWidget {
  const ClassSessionDetailsScreen({super.key, required this.classSessionId});

  final int classSessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classSession = ref.watch(classSessionDetailsProvider(classSessionId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalji termina')),
      body: classSession.when(
        data: (classSession) =>
            _ClassSessionDetailsContent(classSession: classSession),
        error: (error, stackTrace) => ErrorView(
          message: error.toString(),
          onRetry: () =>
              ref.invalidate(classSessionDetailsProvider(classSessionId)),
        ),
        loading: () => const LoadingView(),
      ),
    );
  }
}

class _ClassSessionDetailsContent extends ConsumerStatefulWidget {
  const _ClassSessionDetailsContent({required this.classSession});

  final ClassSession classSession;

  @override
  ConsumerState<_ClassSessionDetailsContent> createState() =>
      _ClassSessionDetailsContentState();
}

class _ClassSessionDetailsContentState
    extends ConsumerState<_ClassSessionDetailsContent> {
  bool _isBooking = false;
  bool _isCancelling = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final classSession = widget.classSession;
    final spotsLeft = classSession.capacity - classSession.bookedCount;
    final canViewParticipants = _canManage(classSession);
    final bookings = canViewParticipants
        ? ref.watch(classSessionBookingsProvider(classSession.id))
        : null;
    final authState = ref.watch(loginControllerProvider);
    final canBook =
        authState is LoginSuccess && authState.session.user.memberId != null;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            classSession.classTypeName,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            classSession.trainerFullName,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Datum',
                    value: _formatDate(classSession.startsAt),
                  ),
                  _DetailRow(
                    icon: Icons.schedule,
                    label: 'Vrijeme',
                    value:
                        '${_formatTime(classSession.startsAt)} - ${_formatTime(classSession.endsAt)}',
                  ),
                  _DetailRow(
                    icon: Icons.timer_outlined,
                    label: 'Trajanje',
                    value: '${classSession.durationMinutes} min',
                  ),
                  _DetailRow(
                    icon: Icons.info_outline,
                    label: 'Status',
                    value: classSession.status,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Popunjenost',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: classSession.capacity == 0
                        ? 0
                        : classSession.bookedCount / classSession.capacity,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${classSession.bookedCount}/${classSession.capacity} rezervirano',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    spotsLeft > 0
                        ? '$spotsLeft mjesta slobodno'
                        : 'Termin je pun',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: spotsLeft > 0
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (bookings != null) ...[
            const SizedBox(height: 16),
            _ParticipantsCard(
              bookings: bookings,
              capacity: classSession.capacity,
              classSessionId: classSession.id,
              classSessionStartsAt: classSession.startsAt,
              attendanceEnabled:
                  classSession.status != 'cancelled' &&
                  !classSession.startsAt.isAfter(DateTime.now()),
              onRetry: () =>
                  ref.invalidate(classSessionBookingsProvider(classSession.id)),
            ),
          ],
          const SizedBox(height: 24),
          if (canBook)
            FilledButton(
              onPressed:
                  spotsLeft > 0 &&
                      classSession.status == 'scheduled' &&
                      !_isBooking
                  ? () => _createBooking(classSession)
                  : null,
              child: Text(_isBooking ? 'Rezerviram...' : 'Rezerviraj'),
            ),
          if (canViewParticipants) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: classSession.status == 'scheduled' && !_isCancelling
                  ? () => _confirmCancellation(classSession)
                  : null,
              icon: _isCancelling
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.event_busy_outlined),
              label: Text(
                _isCancelling ? 'Otkazujem...' : 'Otkaži ovaj termin',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _canManage(ClassSession classSession) {
    final authState = ref.read(loginControllerProvider);
    if (authState is! LoginSuccess) {
      return false;
    }

    final user = authState.session.user;
    return user.hasRole('admin') ||
        (user.hasRole('trainer') && user.trainerId == classSession.trainerId);
  }

  Future<void> _confirmCancellation(ClassSession classSession) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Otkaži termin'),
        content: const Text(
          'Želiš li otkazati samo ovaj termin? Budući termini iz rasporeda ostat će aktivni.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Otkaži termin'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _isCancelling = true);
    final result = await serviceLocator<CancelClassSession>()(classSession.id);

    if (!mounted) {
      return;
    }

    setState(() => _isCancelling = false);

    switch (result) {
      case Success():
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Termin je otkazan.')));
        ref.invalidate(classSessionDetailsProvider(classSession.id));
        ref.invalidate(classSessionBookingsProvider(classSession.id));
        await ref
            .read(classSessionsControllerProvider.notifier)
            .loadClassSessions();
      case FailureResult(failure: final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _createBooking(ClassSession classSession) async {
    final authState = ref.read(loginControllerProvider);
    final memberId = switch (authState) {
      LoginSuccess(session: final session) => session.user.memberId,
      _ => null,
    };

    if (memberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prijavljeni korisnik nije povezan s clanom.'),
        ),
      );
      return;
    }

    setState(() {
      _isBooking = true;
    });

    final createBooking = serviceLocator<CreateBooking>();
    final result = await createBooking(
      memberId: memberId,
      classSessionId: classSession.id,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isBooking = false;
    });

    switch (result) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rezervacija je spremljena.')),
        );
        ref.invalidate(classSessionDetailsProvider(classSession.id));
        ref.read(classSessionsControllerProvider.notifier).loadClassSessions();
      case FailureResult(failure: final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  static String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');

    return '$day.$month.${value.year}.';
  }

  static String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}

class _ParticipantsCard extends StatelessWidget {
  const _ParticipantsCard({
    required this.bookings,
    required this.capacity,
    required this.classSessionId,
    required this.classSessionStartsAt,
    required this.attendanceEnabled,
    required this.onRetry,
  });

  final AsyncValue<List<Booking>> bookings;
  final int capacity;
  final int classSessionId;
  final DateTime classSessionStartsAt;
  final bool attendanceEnabled;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            bookings.when(
              loading: () => const Row(
                children: [
                  SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Učitavam polaznike...'),
                ],
              ),
              error: (error, stackTrace) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Polaznici',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Polaznike trenutno nije moguće učitati.'),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Pokušaj ponovno'),
                  ),
                ],
              ),
              data: (items) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Polaznici (${items.length}/$capacity)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (items.isEmpty)
                    const Text('Nema prijavljenih polaznika.')
                  else
                    for (var index = 0; index < items.length; index++) ...[
                      if (index > 0) const Divider(height: 20),
                      _ParticipantRow(
                        booking: items[index],
                        classSessionId: classSessionId,
                        classSessionStartsAt: classSessionStartsAt,
                        attendanceEnabled: attendanceEnabled,
                      ),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantRow extends ConsumerStatefulWidget {
  const _ParticipantRow({
    required this.booking,
    required this.classSessionId,
    required this.classSessionStartsAt,
    required this.attendanceEnabled,
  });

  final Booking booking;
  final int classSessionId;
  final DateTime classSessionStartsAt;
  final bool attendanceEnabled;

  @override
  ConsumerState<_ParticipantRow> createState() => _ParticipantRowState();
}

class _ParticipantRowState extends ConsumerState<_ParticipantRow> {
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;

    return Row(
      children: [
        const CircleAvatar(child: Icon(Icons.person_outline)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking.memberFullName,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 2),
              Text(
                _statusLabel(booking.status),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (_isUpdating)
          const SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (widget.attendanceEnabled) ...[
          IconButton(
            tooltip: 'Prisutan',
            onPressed: () => _updateStatus('attended'),
            style: booking.status == 'attended'
                ? IconButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                  )
                : null,
            icon: const Icon(Icons.check),
          ),
          IconButton(
            tooltip: 'Nije došao',
            onPressed: () => _updateStatus('no_show'),
            style: booking.status == 'no_show'
                ? IconButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.errorContainer,
                  )
                : null,
            icon: const Icon(Icons.person_off_outlined),
          ),
        ],
        if (!_isUpdating)
          PopupMenuButton<_ParticipantAction>(
            tooltip: 'Akcije za člana',
            onSelected: _handleAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _ParticipantAction.removeFromSession,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.person_remove_outlined),
                  title: Text('Ukloni s ovog termina'),
                ),
              ),
              if (booking.memberFixedScheduleId != null)
                const PopupMenuItem(
                  value: _ParticipantAction.removeFromFixedSchedule,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.event_busy_outlined),
                    title: Text('Ukloni iz fiksne grupe'),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Future<void> _handleAction(_ParticipantAction action) async {
    final removesFixedSchedule =
        action == _ParticipantAction.removeFromFixedSchedule;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          removesFixedSchedule ? 'Ukloni iz fiksne grupe' : 'Ukloni s termina',
        ),
        content: Text(
          removesFixedSchedule
              ? 'Član će biti uklonjen s ovog i svih budućih termina iz ove fiksne grupe.'
              : 'Član će biti uklonjen samo s ovog termina.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ukloni'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _isUpdating = true);

    final Result<void> result;
    if (removesFixedSchedule) {
      final fixedScheduleId = widget.booking.memberFixedScheduleId;
      if (fixedScheduleId == null) {
        setState(() => _isUpdating = false);
        return;
      }

      result = await serviceLocator<CancelFixedSchedule>()(
        id: fixedScheduleId,
        effectiveFrom: widget.classSessionStartsAt,
      );
    } else {
      result = await serviceLocator<CancelBooking>()(widget.booking.id);
    }

    if (!mounted) {
      return;
    }

    setState(() => _isUpdating = false);

    switch (result) {
      case Success():
        ref.invalidate(classSessionBookingsProvider(widget.classSessionId));
        ref.invalidate(classSessionDetailsProvider(widget.classSessionId));
        await ref
            .read(classSessionsControllerProvider.notifier)
            .loadClassSessions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                removesFixedSchedule
                    ? 'Član je uklonjen iz fiksne grupe.'
                    : 'Član je uklonjen s termina.',
              ),
            ),
          );
        }
      case FailureResult(failure: final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _updateStatus(String status) async {
    if (_isUpdating || widget.booking.status == status) {
      return;
    }

    setState(() => _isUpdating = true);
    final result = await serviceLocator<UpdateBookingStatus>()(
      id: widget.booking.id,
      status: status,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isUpdating = false);

    switch (result) {
      case Success():
        ref.invalidate(classSessionBookingsProvider(widget.classSessionId));
      case FailureResult(failure: final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  static String _statusLabel(String status) {
    return switch (status) {
      'booked' => 'Rezervirano',
      'waitlisted' => 'Lista čekanja',
      'attended' => 'Prisutan',
      'no_show' => 'Nije došao',
      _ => status,
    };
  }
}

enum _ParticipantAction { removeFromSession, removeFromFixedSchedule }

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelMedium),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
