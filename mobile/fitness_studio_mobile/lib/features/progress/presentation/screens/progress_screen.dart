import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../navigation/app_routes.dart';
import '../../../profile/presentation/state/profile_provider.dart';
import '../../domain/entities/member_progress.dart';
import '../state/member_progress_provider.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({this.memberId, this.memberName, super.key});

  final int? memberId;
  final String? memberName;

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  String? _selectedCode;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.memberName ?? 'Napredak')),
      floatingActionButton: widget.memberId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push(
                AppRoutes.createMeasurementPath(widget.memberId!),
                extra: widget.memberName ?? 'Član',
              ),
              icon: const Icon(Icons.add),
              label: const Text('Mjerenje'),
            ),
      body: profile.when(
        loading: () => const LoadingView(),
        error: (error, stackTrace) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(profileProvider),
        ),
        data: (profile) {
          final memberId = widget.memberId ?? profile.member?.id;
          if (memberId == null) {
            return const EmptyView(
              title: 'Nema članskog profila',
              message: 'Praćenje napretka dostupno je članovima.',
            );
          }

          final progress = ref.watch(memberProgressProvider(memberId));
          return progress.when(
            loading: () => const LoadingView(),
            error: (error, stackTrace) => ErrorView(
              message: error.toString(),
              onRetry: () => ref.invalidate(memberProgressProvider(memberId)),
            ),
            data: (progress) => _ProgressContent(
              progress: progress,
              selectedCode: _selectedCode,
              onSelected: (value) => setState(() => _selectedCode = value),
              onRefresh: () async =>
                  ref.refresh(memberProgressProvider(memberId).future),
            ),
          );
        },
      ),
    );
  }
}

class _ProgressContent extends StatelessWidget {
  const _ProgressContent({
    required this.progress,
    required this.selectedCode,
    required this.onSelected,
    required this.onRefresh,
  });

  final MemberProgress progress;
  final String? selectedCode;
  final ValueChanged<String> onSelected;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (progress.latestValues.isEmpty) {
      return const EmptyView(
        title: 'Nema mjerenja',
        message: 'Još nema zabilježenih podataka o napretku.',
      );
    }

    final selected =
        progress.latestValues.any((value) => value.code == selectedCode)
        ? selectedCode!
        : progress.latestValues.first.code;
    final parameter = progress.latestByCode(selected)!;
    final points = progress.pointsFor(selected);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          DropdownButtonFormField<String>(
            initialValue: selected,
            decoration: const InputDecoration(
              labelText: 'Parametar',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.show_chart),
            ),
            items: progress.latestValues
                .map(
                  (value) => DropdownMenuItem(
                    value: value.code,
                    child: Text(value.name),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) onSelected(value);
            },
          ),
          const SizedBox(height: 16),
          _CurrentValueCard(
            parameter: parameter,
            change: progress.changeFor(selected),
          ),
          const SizedBox(height: 16),
          _ProgressChart(parameter: parameter, points: points),
          const SizedBox(height: 16),
          _HistoryCard(parameter: parameter, points: points.reversed.toList()),
        ],
      ),
    );
  }
}

class _CurrentValueCard extends StatelessWidget {
  const _CurrentValueCard({required this.parameter, required this.change});

  final ProgressValue parameter;
  final double? change;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trenutno', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(
                    parameter.formattedValue,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (change != null)
              _ChangeIndicator(value: change!, parameter: parameter),
          ],
        ),
      ),
    );
  }
}

class _ChangeIndicator extends StatelessWidget {
  const _ChangeIndicator({required this.value, required this.parameter});

  final double value;
  final ProgressValue parameter;

  @override
  Widget build(BuildContext context) {
    final icon = value > 0
        ? Icons.arrow_upward
        : value < 0
        ? Icons.arrow_downward
        : Icons.remove;
    final sign = value > 0 ? '+' : '';
    final unit = parameter.unit == null ? '' : ' ${parameter.unit}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 4),
        Text(
          '$sign${value.toStringAsFixed(parameter.decimalPlaces)}$unit',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _ProgressChart extends StatelessWidget {
  const _ProgressChart({required this.parameter, required this.points});

  final ProgressValue parameter;
  final List<ProgressPoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Kretanje',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: points.length < 2
                  ? const Center(
                      child: Text('Za graf su potrebna barem dva mjerenja.'),
                    )
                  : LineChart(_chartData(context)),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _chartData(BuildContext context) {
    final theme = Theme.of(context);
    final values = points.map((point) => point.value).toList();
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = maxValue - minValue;
    final padding = range == 0
        ? math.max(maxValue.abs() * 0.1, 1.0)
        : range * 0.2;

    return LineChartData(
      minX: 0,
      maxX: (points.length - 1).toDouble(),
      minY: minValue - padding,
      maxY: maxValue + padding,
      gridData: FlGridData(
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: theme.colorScheme.outlineVariant, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 44,
            getTitlesWidget: (value, meta) => Text(
              value.toStringAsFixed(parameter.decimalPlaces),
              style: theme.textTheme.labelSmall,
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.round();
              if (index < 0 || index >= points.length) {
                return const SizedBox.shrink();
              }
              final date = points[index].measuredAt;
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${date.day}.${date.month}.',
                  style: theme.textTheme.labelSmall,
                ),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: [
            for (var index = 0; index < points.length; index++)
              FlSpot(index.toDouble(), points[index].value),
          ],
          isCurved: true,
          color: theme.colorScheme.primary,
          barWidth: 3,
          dotData: FlDotData(
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
                  radius: 4,
                  color: theme.colorScheme.primary,
                  strokeWidth: 2,
                  strokeColor: theme.colorScheme.surface,
                ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.parameter, required this.points});

  final ProgressValue parameter;
  final List<ProgressPoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Povijest',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < points.length; index++) ...[
              if (index > 0) const Divider(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(points[index].measuredAt),
                          style: theme.textTheme.bodyLarge,
                        ),
                        if (points[index].note case final note?
                            when note.trim().isNotEmpty)
                          Text(note, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Text(
                    _formatValue(points[index].value, parameter),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day.$month.${value.year}.';
}

String _formatValue(double value, ProgressValue parameter) {
  final number = value.toStringAsFixed(parameter.decimalPlaces);
  return parameter.unit == null ? number : '$number ${parameter.unit}';
}
