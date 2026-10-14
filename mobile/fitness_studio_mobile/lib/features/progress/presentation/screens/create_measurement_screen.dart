import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/result.dart';
import '../../../../core/l10n/localization.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../injection/service_locator.dart';
import '../../domain/entities/progress_management.dart';
import '../../domain/repositories/progress_repository.dart';
import '../state/member_progress_provider.dart';
import '../state/progress_management_providers.dart';

class CreateMeasurementScreen extends ConsumerStatefulWidget {
  const CreateMeasurementScreen({
    required this.memberId,
    required this.memberName,
    super.key,
  });

  final int memberId;
  final String memberName;

  @override
  ConsumerState<CreateMeasurementScreen> createState() =>
      _CreateMeasurementScreenState();
}

class _CreateMeasurementScreenState
    extends ConsumerState<CreateMeasurementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  final Map<int, TextEditingController> _controllers = {};
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parameters = ref.watch(measurementParametersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.newMeasurementTitle)),
      body: parameters.when(
        loading: () => const LoadingView(),
        error: (error, stackTrace) => ErrorView(
          message: localizedError(context, error),
          onRetry: () => ref.invalidate(measurementParametersProvider),
        ),
        data: (parameters) {
          final manual = parameters.where((item) => item.canEnter).toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Text(
                  widget.memberName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(context.l10n.enterOneMeasuredParameter),
                const SizedBox(height: 20),
                for (final parameter in manual) ...[
                  TextFormField(
                    controller: _controllerFor(parameter.id),
                    enabled: !_saving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9,.\-]')),
                    ],
                    decoration: InputDecoration(
                      labelText: parameter.name,
                      suffixText: parameter.unit,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => _validateValue(parameter, value),
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _noteController,
                  enabled: !_saving,
                  maxLines: 3,
                  maxLength: 2000,
                  decoration: InputDecoration(
                    labelText: context.l10n.labelNotes,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _saving ? null : () => _save(manual),
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _saving
                        ? context.l10n.actionSaving
                        : context.l10n.saveMeasurement,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  TextEditingController _controllerFor(int id) =>
      _controllers.putIfAbsent(id, TextEditingController.new);

  String? _validateValue(MeasurementParameter parameter, String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = double.tryParse(raw.replaceAll(',', '.'));
    if (value == null) return context.l10n.invalidNumber;
    return null;
  }

  Future<void> _save(List<MeasurementParameter> parameters) async {
    if (!_formKey.currentState!.validate()) return;
    final values = parameters
        .where((item) => _controllerFor(item.id).text.trim().isNotEmpty)
        .map(
          (item) => NewMeasurementValue(
            parameterId: item.id,
            value: double.parse(
              _controllerFor(item.id).text.trim().replaceAll(',', '.'),
            ),
          ),
        )
        .toList(growable: false);

    if (values.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.enterOneValue)));
      return;
    }

    setState(() => _saving = true);
    final result = await serviceLocator<ProgressRepository>().createMeasurement(
      widget.memberId,
      NewMeasurement(
        measuredAt: DateTime.now(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        values: values,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);

    switch (result) {
      case Success():
        ref.invalidate(memberProgressProvider(widget.memberId));
        Navigator.of(context).pop(true);
      case FailureResult(failure: final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.localized(context))));
    }
  }
}
