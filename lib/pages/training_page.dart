import 'dart:async';

import 'package:flutter_application_1/database/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/plan_data.dart';

import 'training_exercise_card.dart';

class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key, required this.plan});

  final PlanData plan;

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage>
    with SingleTickerProviderStateMixin {
  late final PlanData _plannedPlan;
  late final PlanData _workoutPlan;
  late final DateTime _startTime;
  late final AnimationController _shakeController;

  bool _isSaving = false;

  Timer? _timer;
  Duration _elapsed = Duration.zero;

  // 每个动作分别记录已完成的组
  // 例如：动作0的第1、3组完成，数据就是 {0: {0, 2}}
  final Map<int, Set<int>> _completedSets = {};

  @override
  void initState() {
    super.initState();

    // 复制计划，避免本次训练修改原计划的数据
    _plannedPlan = _copyPlan(widget.plan);
    _workoutPlan = _copyPlan(widget.plan);
    _startTime = DateTime.now();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    // 每秒刷新一次计时显示
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() {
        _elapsed = DateTime.now().difference(_startTime);
      });
    });
  }

  PlanData _copyPlan(PlanData source) {
    return PlanData(
      planName: source.planName,
      exercises: source.exercises.map((exercise) {
        return ExerciseData(
          name: exercise.name,
          sets: exercise.sets.map((set) {
            return SetData(weight: set.weight, reps: set.reps);
          }).toList(),
        );
      }).toList(),
    );
  }

  // 计划中的总组数
  int get _totalSets {
    return _workoutPlan.exercises.fold(
      0,
      (total, exercise) => total + exercise.sets.length,
    );
  }

  // 已完成的组数
  int get _completedCount {
    return _completedSets.values.fold(0, (total, sets) => total + sets.length);
  }

  // 已完成组的训练总量：重量 × 次数
  double get _trainingVolume {
    double volume = 0;

    for (final entry in _completedSets.entries) {
      final exerciseIndex = entry.key;

      if (exerciseIndex >= _workoutPlan.exercises.length) {
        continue;
      }

      final exercise = _workoutPlan.exercises[exerciseIndex];

      for (final setIndex in entry.value) {
        if (setIndex >= exercise.sets.length) {
          continue;
        }

        final set = exercise.sets[setIndex];
        volume += (set.weight ?? 0) * (set.reps ?? 0);
      }
    }

    return volume;
  }

  // 格式化训练时长
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${duration.inMinutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  // 切换某一组的完成状态
  void _toggleSetCompleted(int exerciseIndex, int setIndex) {
    setState(() {
      final sets = _completedSets.putIfAbsent(exerciseIndex, () => <int>{});

      if (sets.contains(setIndex)) {
        sets.remove(setIndex);
      } else {
        sets.add(setIndex);
      }
    });
  }

  Future<void> _finishTraining() async {
    if (_isSaving) return;

    final remaining = _totalSets - _completedCount;

    final shouldFinish = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('结束训练？'),
        content: Text(
          remaining > 0 ? '还有 $remaining 组未完成，确定结束并保存本次训练吗？' : '确定结束并保存本次训练吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('继续训练'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('结束并保存'),
          ),
        ],
      ),
    );

    if (shouldFinish != true || !mounted) return;

    setState(() {
      _isSaving = true;
    });

    final completedAt = DateTime.now();

    try {
      final workoutId = await DatabaseHelper.saveWorkout(
        plannedPlan: _plannedPlan,
        actualPlan: _workoutPlan,
        completedSets: _completedSets,
        startedAt: _startTime,
        completedAt: completedAt,
        durationSeconds: completedAt.difference(_startTime).inSeconds,
      );

      if (!mounted) return;

      _timer?.cancel();
      Navigator.pop(context, workoutId);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('训练记录保存失败：$e')));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalSets == 0 ? 0.0 : _completedCount / _totalSets;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _workoutPlan.planName.isEmpty ? '未命名计划' : _workoutPlan.planName,
          style: const TextStyle(
            color: Color(0xFF101828),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _finishTraining,
            child: const Text(
              '完成',
              style: TextStyle(
                color: Color(0xFF168AF7),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 训练数据区域
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildMetric('训练时长', _formatDuration(_elapsed)),
                    ),
                    Expanded(
                      child: _buildMetric(
                        '训练总量',
                        _formatVolume(_trainingVolume),
                      ),
                    ),
                    Expanded(
                      child: _buildMetric(
                        '完成组数',
                        '$_completedCount/$_totalSets',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFF2F3F7),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF168AF7),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF2F3F7)),

          // 动作及组数列表
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              children: [
                for (int i = 0; i < _workoutPlan.exercises.length; i++) ...[
                  TrainingExerciseCard(
                    key: ValueKey('training_exercise_$i'),
                    exercise: _workoutPlan.exercises[i],
                    completedSets: _completedSets[i] ?? <int>{},
                    onToggleSetCompleted: (setIndex) {
                      _toggleSetCompleted(i, setIndex);
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF8A8F98), fontSize: 13),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF101828),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatVolume(double volume) {
    if (volume == volume.roundToDouble()) {
      return volume.toInt().toString();
    }

    return volume.toStringAsFixed(1);
  }
}
