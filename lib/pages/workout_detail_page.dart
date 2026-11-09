
import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class WorkoutDetailPage extends StatefulWidget {
  final int workoutId;

  const WorkoutDetailPage({
    super.key,
    required this.workoutId,
  });

  @override
  State<WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends State<WorkoutDetailPage> {
  late Future<Map<String, dynamic>?> _workoutFuture;

  @override
  void initState() {
    super.initState();
    _workoutFuture =
        DatabaseHelper.getWorkoutDetail(widget.workoutId);
  }

  String _formatDuration(dynamic value) {
    final seconds = (value as num?)?.toInt() ?? 0;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    if (minutes >= 60) {
      return '${minutes ~/ 60}小时${minutes % 60}分';
    }
    return '$minutes分$remainingSeconds秒';
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '—';
    final number = (value as num).toDouble();
    return number == number.roundToDouble()
        ? number.toInt().toString()
        : number.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('训练复盘'),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _workoutFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('读取训练记录失败：${snapshot.error}'),
            );
          }

          final workout = snapshot.data;

          if (workout == null) {
            return const Center(
              child: Text('没有找到这条训练记录'),
            );
          }

          final exercises =
              (workout['exercises'] as List<dynamic>? ?? []);
          final totalSets =
              (workout['total_sets'] as num?)?.toInt() ?? 0;
          final completedSets =
              (workout['completed_sets'] as num?)?.toInt() ?? 0;
          final completion = totalSets == 0
              ? 0.0
              : completedSets / totalSets;

          double actualVolume = 0;

          for (final item in exercises) {
            final exercise = Map<String, dynamic>.from(item as Map);
            final sets =
                exercise['sets'] as List<dynamic>? ?? [];

            for (final setItem in sets) {
              final set = Map<String, dynamic>.from(setItem as Map);
              if ((set['is_completed'] as num?)?.toInt() != 1) {
                continue;
              }

              final weight =
                  (set['actual_weight'] as num?)?.toDouble();
              final reps =
                  (set['actual_reps'] as num?)?.toInt();

              if (weight != null && reps != null) {
                actualVolume += weight * reps;
              }
            }
          }

          final startedAt =
              DateTime.tryParse('${workout['started_at']}');
          final dateText = startedAt == null
              ? '日期未知'
              : '${startedAt.year}-${startedAt.month.toString().padLeft(2, '0')}-${startedAt.day.toString().padLeft(2, '0')}';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                workout['plan_name']?.toString() ?? '训练记录',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                '$dateText · ${_formatDuration(workout['duration_seconds'])}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: '完成度',
                      value: '${(completion * 100).round()}%',
                      subtitle: '$completedSets / $totalSets 组',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      title: '实际训练量',
                      value: _formatNumber(actualVolume),
                      subtitle: '重量 × 次数',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Text(
                '动作明细',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),

              ...exercises.map((item) {
                final exercise =
                    Map<String, dynamic>.from(item as Map);
                final sets =
                    exercise['sets'] as List<dynamic>? ?? [];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise['name']?.toString() ?? '未命名动作',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        const Row(
                          children: [
                            Expanded(flex: 2, child: Text('组')),
                            Expanded(flex: 3, child: Text('计划')),
                            Expanded(flex: 3, child: Text('实际')),
                            Expanded(flex: 2, child: Text('状态')),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ...sets.map((setItem) {
                          final set =
                              Map<String, dynamic>.from(setItem as Map);
                          final completed =
                              (set['is_completed'] as num?)?.toInt() == 1;

                          final planned =
                              '${_formatNumber(set['planned_weight'])} × ${_formatNumber(set['planned_reps'])}';
                          final actual =
                              '${_formatNumber(set['actual_weight'])} × ${_formatNumber(set['actual_reps'])}';

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text('${set['set_number']}'),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(planned),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    actual,
                                    style: TextStyle(
                                      color: completed
                                          ? Colors.green
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Icon(
                                    completed
                                        ? Icons.check_circle
                                        : Icons.remove_circle_outline,
                                    size: 18,
                                    color: completed
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('返回主页'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
