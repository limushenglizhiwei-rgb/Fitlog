import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/plan_data.dart';

class PlanManageCard extends StatelessWidget {
  const PlanManageCard({
    super.key,
    required this.plan,
    required this.onEdit,
    required this.onDelete,
  });

  final PlanData plan;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  int get totalSets {
    return plan.exercises.fold(
      0,
      (total, exercise) => total + exercise.sets.length,
    );
  }

  String _formatWeight(double? weight) {
    if (weight == null) return '--';

    return weight == weight.roundToDouble()
        ? weight.toInt().toString()
        : weight.toString();
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF168AF7);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDEFF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.planName.isEmpty ? '未命名计划' : plan.planName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onDelete();
                },
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 20, color: Colors.black38),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            '${plan.exercises.length} 个动作  ·  $totalSets 组',
            style: const TextStyle(fontSize: 12, color: Colors.black45),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEDEFF2)),
          const SizedBox(height: 14),

          ...plan.exercises.asMap().entries.map((entry) {
            final exerciseIndex = entry.key;
            final exercise = entry.value;

            return Padding(
              padding: EdgeInsets.only(
                bottom: exerciseIndex == plan.exercises.length - 1 ? 0 : 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name.isEmpty ? '未命名动作' : exercise.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 7),

                  ...exercise.sets.asMap().entries.map((setEntry) {
                    final setIndex = setEntry.key;
                    final set = setEntry.value;

                    final weight = set.weight == null
                        ? '--'
                        : '${_formatWeight(set.weight)} kg';
                    final reps = set.reps?.toString() ?? '--';

                    return Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 54,
                            child: Text(
                              '第 ${setIndex + 1} 组',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black45,
                              ),
                            ),
                          ),
                          Text(
                            '$weight × $reps 次',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          }),

          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onEdit();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: blue,
                side: const BorderSide(color: blue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('编辑计划'),
            ),
          ),
        ],
      ),
    );
  }
}
