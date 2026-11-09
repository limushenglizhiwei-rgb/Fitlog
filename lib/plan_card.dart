import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/plan_data.dart';

class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.plan,
    this.onStartTraining,
  });

  final PlanData plan;
  final VoidCallback? onStartTraining;

  @override
  Widget build(BuildContext context) {
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
          Text(
            plan.planName.isEmpty ? '未命名计划' : plan.planName,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // 动作名只显示文字，不使用灰色背景
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: plan.exercises.map((exercise) {
              return Text(
                exercise.name,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: onStartTraining == null
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      onStartTraining!();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF168AF7),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('开始训练'),
            ),
          ),
        ],
      ),
    );
  }
}
