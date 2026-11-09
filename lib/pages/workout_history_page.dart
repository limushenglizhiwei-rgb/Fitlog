
import 'package:flutter/material.dart';
import 'package:flutter_application_1/database/database_helper.dart';
import 'workout_detail_page.dart';

class WorkoutHistoryPage extends StatefulWidget {
  const WorkoutHistoryPage({super.key});

  @override
  State<WorkoutHistoryPage> createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends State<WorkoutHistoryPage> {
  static const Color _blue = Color(0xFF3478F6);

  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = DatabaseHelper.getWorkoutHistory();
  }

  String _formatDate(dynamic value) {
    if (value == null) return '时间未知';

    final date = DateTime.tryParse(value.toString());
    if (date == null) return '时间未知';

    final local = date.toLocal();
    final year = local.year;
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$year/$month/$day  $hour:$minute';
  }

  String _formatDuration(dynamic value) {
    final seconds = (value as num?)?.toInt() ?? 0;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    if (minutes <= 0) return '$remainingSeconds秒';
    return '$minutes分$remainingSeconds秒';
  }

  int _completionRate(Map<String, dynamic> workout) {
    final total = (workout['total_sets'] as num?)?.toInt() ?? 0;
    final completed = (workout['completed_sets'] as num?)?.toInt() ?? 0;

    if (total <= 0) return 0;
    return (completed * 100 / total).round();
  }

  Future<void> _openWorkout(
    Map<String, dynamic> workout,
  ) async {
    final workoutId = (workout['id'] as num?)?.toInt();
    if (workoutId == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutDetailPage(workoutId: workoutId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          '训练历史',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('训练记录加载失败'),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _historyFuture =
                            DatabaseHelper.getWorkoutHistory();
                      });
                    },
                    child: const Text('重新加载'),
                  ),
                ],
              ),
            );
          }

          final workouts = snapshot.data ?? [];

          if (workouts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 40,
                    color: Colors.black26,
                  ),
                  SizedBox(height: 12),
                  Text(
                    '还没有训练记录',
                    style: TextStyle(color: Colors.black54),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '完成一次训练后，记录会显示在这里',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black38,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: workouts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final workout = workouts[index];
              final planName =
                  workout['plan_name']?.toString().trim();
              final title = (planName == null || planName.isEmpty)
                  ? '自主训练'
                  : planName;

              final completed =
                  (workout['completed_sets'] as num?)?.toInt() ?? 0;
              final total =
                  (workout['total_sets'] as num?)?.toInt() ?? 0;
              final rate = _completionRate(workout);

              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _openWorkout(workout),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.black38,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatDate(workout['completed_at']),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black45,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _buildInfo(
                              '完成度',
                              '$rate%',
                            ),
                            _buildInfo(
                              '完成组数',
                              '$completed/$total',
                            ),
                            _buildInfo(
                              '训练时长',
                              _formatDuration(
                                workout['duration_seconds'],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfo(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black45,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _blue,
            ),
          ),
        ],
      ),
    );
  }
}
