import 'package:flutter/material.dart';
import 'package:flutter_application_1/database/database_helper.dart';

import 'services/workout_analyzer.dart';

class AnalysisDetailPage extends StatefulWidget {
  const AnalysisDetailPage({super.key, required this.title});

  final String title;

  @override
  State<AnalysisDetailPage> createState() => _AnalysisDetailPageState();
}

class _AnalysisDetailPageState extends State<AnalysisDetailPage> {
  static const Color _black = Color(0xFF171B26);
  static const Color _secondary = Color(0xFF8A8F98);
  static const Color _blue = Color(0xFF2588EE);
  static const Color _divider = Color(0xFFECEEF1);

  bool _loading = true;
  List<Map<String, dynamic>> _workouts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      if (widget.title == '训练记录' || widget.title == '训练洞察') {
        final workouts = await DatabaseHelper.getWorkoutHistory();

        final details = <Map<String, dynamic>>[];

        if (widget.title == '训练洞察') {
          for (final workout in workouts.take(4)) {
            final id = (workout['id'] as num).toInt();
            final detail = await DatabaseHelper.getWorkoutDetail(id);

            if (detail != null) details.add(detail);
          }
        }

        if (!mounted) return;

        setState(() {
          _workouts = workouts;

          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('详情数据加载失败：$e');
      if (mounted) setState(() => _loading = false);
    }
  }

  String _date(String? value) {
    if (value == null) return '--';
    final date = DateTime.tryParse(value);
    if (date == null) return '--';

    return '${date.year}.${date.month.toString().padLeft(2, '0')}.'
        '${date.day.toString().padLeft(2, '0')}';
  }

  void _showExerciseHistory(String name, double? pr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExerciseHistorySheet(exerciseName: name, pr: pr),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _black,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (widget.title == '训练记录') {
      return _buildHistory();
    }

    if (widget.title == '训练表现') {
      return _buildPerformance();
    }

    return const Center(child: Text('暂无数据'));
  }

  Widget _buildHistory() {
    if (_workouts.isEmpty) {
      return _empty('暂无训练记录');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _workouts.length,
      separatorBuilder: (_, _) => const Divider(height: 24, color: _divider),
      itemBuilder: (context, index) {
        final workout = _workouts[index];

        final id = (workout['id'] as num).toInt();
        final name = workout['plan_name']?.toString() ?? '训练记录';
        final total = (workout['total_sets'] as num?)?.toInt() ?? 0;
        final completed = (workout['completed_sets'] as num?)?.toInt() ?? 0;

        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _black,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(
              '${_date(workout['completed_at']?.toString())}'
              '  ·  完成 $completed/$total 组',
              style: const TextStyle(fontSize: 12, color: _secondary),
            ),
          ),
          trailing: const Icon(Icons.chevron_right, color: _secondary),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WorkoutDetailPage(workoutId: id),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPerformance() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadPRs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _blue));
        }

        final rows = snapshot.data ?? [];

        if (rows.isEmpty) return _empty('暂无动作表现数据');

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: rows.length,
          separatorBuilder: (_, _) =>
              const Divider(height: 24, color: _divider),
          itemBuilder: (context, index) {
            final row = rows[index];
            final name = row['exercise_name']?.toString() ?? '';
            final weight = (row['max_weight'] as num?)?.toDouble();

            return InkWell(
              onTap: () => _showExerciseHistory(name, weight),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          color: _black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      weight == null
                          ? '--'
                          : '${weight.toStringAsFixed(weight % 1 == 0 ? 0 : 1)} kg',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right,
                      color: _secondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadPRs() async {
    final db = await DatabaseHelper.database;

    return await db.rawQuery('''
    SELECT
      we.name AS exercise_name,
      MAX(ws.actual_weight) AS max_weight,
      COUNT(DISTINCT w.id) AS training_count,
      (
        SELECT w2.completed_at
        FROM workout_sets ws2
        JOIN workout_exercises we2 ON ws2.exercise_id = we2.id
        JOIN workouts w2 ON we2.workout_id = w2.id
        WHERE we2.name = we.name
          AND ws2.is_completed = 1
          AND ws2.actual_weight IS NOT NULL
          AND ws2.actual_weight > 0
        ORDER BY w2.completed_at DESC
        LIMIT 1
      ) AS last_date
    FROM workout_exercises we
    JOIN workouts w ON we.workout_id = w.id
    JOIN workout_sets ws ON ws.exercise_id = we.id
    WHERE ws.is_completed = 1
      AND ws.actual_weight IS NOT NULL
      AND ws.actual_weight > 0
    GROUP BY we.name
    ORDER BY we.name ASC
  ''');
  }

  Widget _empty(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(fontSize: 13, color: _secondary),
      ),
    );
  }
}

// --------------------------------------------------
// 单次训练详情
// --------------------------------------------------

class WorkoutDetailPage extends StatefulWidget {
  const WorkoutDetailPage({super.key, required this.workoutId});

  final int workoutId;

  @override
  State<WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends State<WorkoutDetailPage> {
  static const Color _black = Color(0xFF171B26);
  static const Color _secondary = Color(0xFF8A8F98);
  static const Color _blue = Color(0xFF2588EE);
  static const Color _divider = Color(0xFFECEEF1);

  Map<String, dynamic>? _workout;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

String _formatSetValue(dynamic weight, dynamic reps) {
  if (weight == null && reps == null) return '--';

  final num? w = weight is num
      ? weight
      : num.tryParse(weight?.toString() ?? '');

  final weightText = w == null
      ? '--'
      : w.toStringAsFixed(w % 1 == 0 ? 0 : 1);

  return '$weightText × ${reps ?? '--'}';
}

String _performanceLabel(SetPerformance performance) {
  switch (performance) {
    case SetPerformance.exceeded:
      return '超额';
    case SetPerformance.matched:
      return '符合';
    case SetPerformance.below:
      return '低于';
    case SetPerformance.special:
      return '特殊';
    case SetPerformance.unavailable:
      return '数据不足';
  }
}

Color _performanceColor(SetPerformance performance) {
  switch (performance) {
    case SetPerformance.exceeded:
    case SetPerformance.matched:
      return AnalysisColors.good;
    case SetPerformance.below:
      return AnalysisColors.poor;
    case SetPerformance.special:
      return AnalysisColors.special;
    case SetPerformance.unavailable:
      return _secondary;
  }
}

  Future<void> _loadDetail() async {
    try {
      final detail = await DatabaseHelper.getWorkoutDetail(widget.workoutId);

      if (!mounted) return;

      setState(() {
        _workout = detail;
        _loading = false;
      });
    } catch (e) {
      debugPrint('读取单次训练详情失败：$e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _workout?['plan_name']?.toString() ?? '训练详情';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _black,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : _workout == null
          ? const Center(child: Text('找不到这次训练记录'))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final workout = _workout!;
    final exercises =
        (workout['exercises'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final analysis = WorkoutAnalyzer.analyzeWorkout(exercises);
    final total = (workout['total_sets'] as num?)?.toInt() ?? 0;
    final completed = (workout['completed_sets'] as num?)?.toInt() ?? 0;
    final duration = (workout['duration_seconds'] as num?)?.toInt() ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      children: [
        Text(
          _formatDate(workout['completed_at']?.toString()),
          style: const TextStyle(fontSize: 13, color: _secondary),
        ),
        const SizedBox(height: 24),

        // 本次训练总结
        const Text(
          '本次训练总结',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _black,
          ),
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(child: _metric('$completed/$total', '完成组数')),
            Expanded(child: _metric(_formatDuration(duration), '训练时长')),
          ],
        ),

        const SizedBox(height: 28),
        const Divider(color: _divider),
        const SizedBox(height: 22),


        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 5, right: 10),
              decoration: BoxDecoration(
                color: AnalysisColors.getColor(analysis.status),
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Text(
                analysis.summary,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: _black,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),
        const Divider(color: _divider),
        const SizedBox(height: 22),

        // 动作分析
        const Text(
          '动作分析',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _black,
          ),
        ),
        const SizedBox(height: 15),

        ...exercises.map((exercise) {
  final item = WorkoutAnalyzer.analyzeExercise(exercise);

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => _showExerciseDetail(exercise),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 9,
              height: 9,
              margin: const EdgeInsets.only(top: 5, right: 12),
              decoration: BoxDecoration(
                color: AnalysisColors.getColor(item.status),
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.summary,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: _secondary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '完成 ${item.completedSets}/${item.totalSets} 组',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _secondary,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 3),
              child: Icon(
                Icons.chevron_right,
                size: 20,
                color: _secondary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}),

        const SizedBox(height: 8),
        const Divider(color: _divider),
        const SizedBox(height: 22),

        
        
      ],
    );
  }

void _showExerciseDetail(Map<String, dynamic> exercise) {
  final name = exercise['name']?.toString() ?? '动作';

  final sets = (exercise['sets'] as List?)
          ?.whereType<Map>()
          .map((set) => Map<String, dynamic>.from(set))
          .toList() ??
      [];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.78,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0D5DD),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: _black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '计划与实际 · ${sets.length} 组',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _secondary,
                  ),
                ),
                const SizedBox(height: 24),

                const Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text('组数', style: _headerStyle),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('计划', style: _headerStyle),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('实际', style: _headerStyle),
                    ),
                    SizedBox(
                      width: 58,
                      child: Text('表现', style: _headerStyle),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: sets.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 18),
                    itemBuilder: (context, index) {
                      final set = sets[index];

                      final number =
                          (set['set_number'] as num?)?.toInt() ?? index + 1;

                      final isCompleted =
                          (set['is_completed'] as num?)?.toInt() == 1;

                      final planned = _formatSetValue(
                        set['planned_weight'],
                        set['planned_reps'],
                      );

                      final actual = _formatSetValue(
                        set['actual_weight'],
                        set['actual_reps'],
                      );

                      final performance =
                          WorkoutAnalyzer.analyzeSet(set);

                      final label = !isCompleted
                          ? '未完成'
                          : _performanceLabel(performance);

                      final color = !isCompleted
                          ? _secondary
                          : _performanceColor(performance);

                      return Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Text(
                              '$number',
                              style: const TextStyle(
                                fontSize: 13,
                                color: _secondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              planned,
                              style: const TextStyle(
                                fontSize: 13,
                                color: _secondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              actual,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _black,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 58,
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      );
    },
  );
}

  static const TextStyle _headerStyle = TextStyle(
    fontSize: 12,
    color: _secondary,
  );

  Widget _metric(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w700,
            color: _black,
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: _secondary)),
      ],
    );
  }

  String _formatDate(String? value) {
    if (value == null) return '--';
    final date = DateTime.tryParse(value);
    if (date == null) return '--';

    return '${date.year}.${date.month.toString().padLeft(2, '0')}.'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) return '$hours小时$minutes分钟';
    return '$minutes分钟';
  }
}

class _ExerciseHistorySheet extends StatelessWidget {
  const _ExerciseHistorySheet({required this.exerciseName, required this.pr});

  final String exerciseName;
  final double? pr;

  static const Color _black = Color(0xFF101828);
  static const Color _secondary = Color(0xFF98A2B3);
  static const Color _blue = Color(0xFF168BF5);
  static const Color _divider = Color(0xFFEAECF0);

  Future<List<Map<String, dynamic>>> _loadHistory() async {
    final db = await DatabaseHelper.database;

    return db.rawQuery(
      '''
      SELECT
        w.completed_at,
        MAX(ws.actual_weight) AS max_weight
      FROM workout_exercises we
      JOIN workouts w ON we.workout_id = w.id
      JOIN workout_sets ws ON ws.exercise_id = we.id
      WHERE we.name = ?
        AND ws.is_completed = 1
        AND ws.actual_weight IS NOT NULL
        AND ws.actual_weight > 0
      GROUP BY w.id
      ORDER BY w.completed_at ASC
    ''',
      [exerciseName],
    );
  }

  String _formatWeight(num? value) {
    if (value == null) return '--';
    return '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)} kg';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD0D5DD),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      exerciseName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _black,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _loadHistory(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _blue),
                    );
                  }

                  final history = snapshot.data ?? [];

                  if (history.isEmpty) {
                    return const Center(
                      child: Text(
                        '暂无历史记录',
                        style: TextStyle(color: _secondary),
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F9FC),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '历史最高重量',
                              style: TextStyle(fontSize: 13, color: _secondary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatWeight(pr),
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: _blue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '累计 ${history.length} 次训练记录',
                              style: const TextStyle(
                                fontSize: 12,
                                color: _secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '历史记录',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...history.reversed.map((item) {
                        final date = item['completed_at']?.toString() ?? '';
                        final weight = item['max_weight'] as num?;

                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: _divider)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                date.length >= 10
                                    ? date.substring(0, 10)
                                    : date,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _secondary,
                                ),
                              ),
                              Text(
                                _formatWeight(weight),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _black,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
