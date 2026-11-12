
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/plan_data.dart';

class TrainingExerciseCard extends StatelessWidget {
  const TrainingExerciseCard({
    super.key,
    required this.exercise,
    required this.completedSets,
    required this.onToggleSetCompleted,
  });

  final ExerciseData exercise;
  final Set<int> completedSets;
  final ValueChanged<int> onToggleSetCompleted;

  static const Color _blue = Color(0xFF168AF7);
  static const Color _text = Color(0xFF101828);
  static const Color _muted = Color(0xFF8A8F98);
  static const Color _line = Color(0xFFE4E7EC);
  static const Color _completedBg = Color(0xFFEAF2FF);

  String _weightText(double? weight) {
    if (weight == null) return '';
    return weight == weight.roundToDouble()
        ? weight.toInt().toString()
        : weight.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
  padding: const EdgeInsets.only(bottom: 28),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            exercise.name,
            style: const TextStyle(
              color: _text,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // 表头
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Row(
            children: [
              SizedBox(width: 42, child: Center(child: Text(
                '组', style: TextStyle(color: _muted, fontSize: 13),
              ))),
              SizedBox(width: 10),
              Expanded(child: Center(child: Text(
                'KG', style: TextStyle(color: _muted, fontSize: 13),
              ))),
              SizedBox(width: 10),
              Expanded(child: Center(child: Text(
                '次', style: TextStyle(color: _muted, fontSize: 13),
              ))),
              SizedBox(width: 10),
              SizedBox(width: 44, child: Center(child: Text(
                '完成', style: TextStyle(color: _muted, fontSize: 13),
              ))),
            ],
          ),
        ),

        // 每一组独立成为一个视觉单元
        for (int i = 0; i < exercise.sets.length; i++) ...[
          _buildSetRow(i),
          if (i < exercise.sets.length - 1)
            const SizedBox(height: 8),
        ],
      ],
      ),
    );
  }

  Widget _buildSetRow(int index) { 
    final set = exercise.sets[index];
    final isCompleted = completedSets.contains(index);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isCompleted ? _completedBg : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted ? _completedBg : _line,
        ),
      ),
      child: Row(
        children: [
          // 组号
          Container(
            width: 42,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFFD6E6FF)
                  : const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: isCompleted ? _blue : _text,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // 重量输入框
          Expanded(
            child: _buildInput(
              initialValue: _weightText(set.weight),
              hint: '重量',
              decimal: true,
              onChanged: (value) {
                set.weight = double.tryParse(value);
              },
            ),
          ),
          const SizedBox(width: 10),

          // 次数输入框
          Expanded(
            child: _buildInput(
              initialValue: set.reps?.toString() ?? '',
              hint: '次数',
              decimal: false,
              onChanged: (value) {
                set.reps = int.tryParse(value);
              },
            ),
          ),
          const SizedBox(width: 10),

          // 完成按钮
          SizedBox(
            width: 44,
            height: 46,
            child: Material(
              color: isCompleted ? _blue : const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  HapticFeedback.lightImpact();
                  onToggleSetCompleted(index);
                },
                child: Icon(
                  Icons.check_rounded,
                  color: isCompleted ? Colors.white : const Color(0xFFADB3BD),
                  size: 23,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required String initialValue,
    required String hint,
    required bool decimal,
    required ValueChanged<String> onChanged,
  }) {
    return SizedBox(
      height: 46,
      child: TextFormField(
        key: ValueKey('${exercise.name}_${hint}_${exercise.sets.length}'),
        initialValue: initialValue,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
        ),
        inputFormatters: [
          if (decimal)
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
          else
            FilteringTextInputFormatter.digitsOnly,
        ],
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _text,
          fontSize: 17,
          fontWeight: FontWeight.w500,
        ),
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: _muted,
            fontSize: 13,
            fontWeight: FontWeight.normal,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _blue, width: 1.4),
          ),
        ),
      ),
    );
  }
}
