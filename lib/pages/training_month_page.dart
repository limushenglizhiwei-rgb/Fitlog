
import 'package:flutter/material.dart';
import 'package:flutter_application_1/database/database_helper.dart';

class TrainingMonthPage extends StatefulWidget {
  const TrainingMonthPage({
    super.key,
    this.year = 2026,
    this.month = 9,
  });

  final int year;
  final int month;

  @override
  State<TrainingMonthPage> createState() => _TrainingMonthPageState();
}

class _TrainingMonthPageState extends State<TrainingMonthPage> {
  static const Color _backgroundColor = Colors.white;
  static const Color _titleColor = Color(0xFF101828);
  static const Color _trainingDayColor = Color(0xFF168BF5);
  static const Color _secondaryTextColor = Color(0xFF667085);
  static const Color _borderColor = Color(0xFFEAECF0);

  List<Map<String, dynamic>> _workouts = [];
  int _selectedDay = 1;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _initialDay;
    _loadWorkouts();
  }

  int get _initialDay {
    final now = DateTime.now();

    if (now.year == widget.year && now.month == widget.month) {
      return now.day;
    }

    return 1;
  }

  /// 读取当前月份的真实训练记录。
  Future<void> _loadWorkouts() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final workouts = await DatabaseHelper.getWorkoutsForMonth(
        year: widget.year,
        month: widget.month,
      );

      if (!mounted) return;

      // 当前月默认选择今天。
      // 查看其他月份时，优先选择最近一个训练日。
      final now = DateTime.now();
      int selectedDay;

      if (now.year == widget.year && now.month == widget.month) {
        selectedDay = now.day;
      } else if (workouts.isNotEmpty) {
        selectedDay = DateTime.parse(
          workouts.first['completed_at'] as String,
        ).day;
      } else {
        selectedDay = 1;
      }

      setState(() {
        _workouts = workouts;
        _selectedDay = selectedDay;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  /// 判断某一天是否存在训练记录。
  bool _hasWorkoutOnDay(int day) {
    return _workouts.any((workout) {
      final date = DateTime.parse(
        workout['completed_at'] as String,
      );

      return date.year == widget.year &&
          date.month == widget.month &&
          date.day == day;
    });
  }

  /// 获取选中日期的所有训练。
  List<Map<String, dynamic>> get _selectedWorkouts {
    return _workouts.where((workout) {
      final date = DateTime.parse(
        workout['completed_at'] as String,
      );

      return date.year == widget.year &&
          date.month == widget.month &&
          date.day == _selectedDay;
    }).toList();
  }

  String _formatDuration(dynamic seconds) {
    final totalSeconds = (seconds as num?)?.toInt() ?? 0;

    if (totalSeconds <= 0) {
      return '时长未记录';
    }

    final minutes = totalSeconds ~/ 60;

    if (minutes < 60) {
      return '$minutes 分钟';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    return remainingMinutes == 0
        ? '$hours 小时'
        : '$hours 小时 $remainingMinutes 分钟';
  }

  String _formatDateTime(String value) {
    final date = DateTime.parse(value);

    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(
      widget.year,
      widget.month,
    );

    final firstWeekday = DateTime(
      widget.year,
      widget.month,
      1,
    ).weekday;

    final leadingEmptyCells = firstWeekday - 1;

    final cells = <Widget>[];

    for (int i = 0; i < leadingEmptyCells; i++) {
      cells.add(const SizedBox.shrink());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final isTrainingDay = _hasWorkoutOnDay(day);
      final isSelected = day == _selectedDay;

      cells.add(
        InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            setState(() {
              _selectedDay = day;
            });
          },
          child: Center(
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? _trainingDayColor
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? Colors.white
                          : _titleColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? (isTrainingDay
                              ? Colors.white
                              : Colors.transparent)
                          : isTrainingDay
                              ? _trainingDayColor
                              : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final selectedWorkouts = _selectedWorkouts;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        surfaceTintColor: _backgroundColor,
        elevation: 0,
        titleSpacing: 20,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 19,
            color: _titleColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '训练日历',
          style: TextStyle(
            color: _titleColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.year}年${widget.month}月',
                style: const TextStyle(
                  color: _titleColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: ['一', '二', '三', '四', '五', '六', '日']
                    .map(
                      (weekday) => Expanded(
                        child: Center(
                          child: Text(
                            weekday,
                            style: const TextStyle(
                              color: _secondaryTextColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 7,
                crossAxisSpacing: 0,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: cells,
              ),

              const SizedBox(height: 28),
              const Divider(
                color: _borderColor,
                height: 1,
              ),
              const SizedBox(height: 24),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${widget.month}月$_selectedDay日',
                    style: const TextStyle(
                      color: _titleColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (!_isLoading && !_hasError &&
                      selectedWorkouts.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF4FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '训练日',
                        style: TextStyle(
                          color: _trainingDayColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: CircularProgressIndicator(
                      color: _trainingDayColor,
                      strokeWidth: 2,
                    ),
                  ),
                )
              else if (_hasError)
                _buildEmptyState(
                  icon: Icons.error_outline,
                  title: '训练记录加载失败',
                  subtitle: '请检查数据库后重试',
                  action: TextButton(
                    onPressed: _loadWorkouts,
                    child: const Text('重新加载'),
                  ),
                )
              else if (selectedWorkouts.isEmpty)
                _buildEmptyState(
                  icon: Icons.event_note_outlined,
                  title: '这一天还没有训练记录',
                  subtitle: '完成一次训练后，记录会显示在这里',
                )
              else
                ...selectedWorkouts.map(_buildWorkoutCard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 28,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 28,
            color: const Color(0xFF98A2B3),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: _titleColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _secondaryTextColor,
              fontSize: 12,
            ),
          ),
          ? action,
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(Map<String, dynamic> workout) {
    final completedSets =
        (workout['completed_sets'] as num?)?.toInt() ?? 0;
    final totalSets =
        (workout['total_sets'] as num?)?.toInt() ?? 0;
    final duration = _formatDuration(workout['duration_seconds']);
    final completedAt = workout['completed_at'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.fitness_center,
              color: _titleColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout['plan_name'] as String? ?? '未命名训练',
                  style: const TextStyle(
                    color: _titleColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$completedSets/$totalSets 组完成',
                  style: const TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_formatDateTime(completedAt)} · $duration',
                  style: const TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
