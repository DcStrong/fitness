import 'package:flutter/material.dart';

import '../../data/plans_format.dart';
import '../../data/plans_models.dart';

class PlanLoadsTable extends StatelessWidget {
  const PlanLoadsTable({
    required this.exercises,
    this.onWeightChanged,
    this.readOnly = false,
    super.key,
  });

  final List<PlanExerciseItem> exercises;
  final void Function(String exerciseId, double weightKg)? onWeightChanged;
  final bool readOnly;

  List<PlanExerciseItem> get _rows =>
      exercises.where((item) => item.exerciseKind == 'weight_reps').toList();

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Нагрузки', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final exercise in rows)
          _LoadRow(
            key: Key('plan-load-${exercise.exerciseId}'),
            exercise: exercise,
            readOnly: readOnly || onWeightChanged == null,
            onChanged: onWeightChanged,
          ),
      ],
    );
  }
}

class _LoadRow extends StatefulWidget {
  const _LoadRow({
    required this.exercise,
    required this.readOnly,
    required this.onChanged,
    super.key,
  });

  final PlanExerciseItem exercise;
  final bool readOnly;
  final void Function(String exerciseId, double weightKg)? onChanged;

  @override
  State<_LoadRow> createState() => _LoadRowState();
}

class _LoadRowState extends State<_LoadRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final weight = workingWeightKg(widget.exercise);
    _controller = TextEditingController(
      text: weight == null ? '' : _format(weight),
    );
  }

  @override
  void didUpdateWidget(covariant _LoadRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = workingWeightKg(oldWidget.exercise);
    final weight = workingWeightKg(widget.exercise);
    if (previous == weight) return;
    final next = weight == null ? '' : _format(weight);
    if (_controller.text != next) {
      _controller.text = next;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(widget.exercise.exerciseName)),
          SizedBox(
            width: 88,
            child: TextField(
              controller: _controller,
              enabled: !widget.readOnly,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                isDense: true,
                suffixText: 'кг',
              ),
              onSubmitted: _commit,
              onEditingComplete: () => _commit(_controller.text),
            ),
          ),
        ],
      ),
    );
  }

  void _commit(String raw) {
    final parsed = double.tryParse(raw.replaceAll(',', '.'));
    if (parsed == null || parsed < 0) return;
    widget.onChanged?.call(widget.exercise.exerciseId, parsed);
  }

  String _format(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }
}
