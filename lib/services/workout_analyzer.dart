import 'package:flutter/material.dart';



enum AnalysisStatus {
  good,     // 绿色：符合或超过计划
  special,  // 黄色：特殊情况
  poor,     // 红色：低于计划
}

class AnalysisColors {
  static const Color poor = Color(0xFFFF5F57);
  static const Color special = Color(0xFFFFBD2E);
  static const Color good = Color(0xFF28C840);

  static Color getColor(AnalysisStatus status) {
    switch (status) {
      case AnalysisStatus.poor:
        return poor;
      case AnalysisStatus.special:
        return special;
      case AnalysisStatus.good:
        return good;
    }
  }
}

enum SetPerformance {
  exceeded,
  matched,
  below,
  special,
  unavailable,
}

class ExerciseAnalysis {
  final String name;
  final AnalysisStatus status;
  final String summary;
  final int totalSets;
  final int completedSets;

  const ExerciseAnalysis({
    required this.name,
    required this.status,
    required this.summary,
    required this.totalSets,
    required this.completedSets,
  });
}

class WorkoutAnalysis {
  final AnalysisStatus status;
  final String summary;
  final int totalSets;
  final int completedSets;
  final List<ExerciseAnalysis> exercises;

  const WorkoutAnalysis({
    required this.status,
    required this.summary,
    required this.totalSets,
    required this.completedSets,
    required this.exercises,
  });
}

class WorkoutAnalyzer {
  /// 分析单组表现
  static SetPerformance analyzeSet(Map<String, dynamic> set) {
    final plannedWeight = _toDouble(set['planned_weight']);
    final actualWeight = _toDouble(set['actual_weight']);

    final plannedReps = _toInt(set['planned_reps']);
    final actualReps = _toInt(set['actual_reps']);

    // 只比较双方都有数据的维度
    final comparisons = <int>[];

    if (plannedWeight != null && actualWeight != null) {
      comparisons.add(actualWeight.compareTo(plannedWeight));
    }

    if (plannedReps != null && actualReps != null) {
      comparisons.add(actualReps.compareTo(plannedReps));
    }

    if (comparisons.isEmpty) {
      return SetPerformance.unavailable;
    }

    final hasHigher = comparisons.any((value) => value > 0);
    final hasLower = comparisons.any((value) => value < 0);

    // 重量和次数方向不一致
    if (hasHigher && hasLower) {
      return SetPerformance.special;
    }

    if (hasLower) {
      return SetPerformance.below;
    }

    if (hasHigher) {
      return SetPerformance.exceeded;
    }

    return SetPerformance.matched;
  }

  /// 分析单个动作
  static ExerciseAnalysis analyzeExercise(
    Map<String, dynamic> exercise,
  ) {
    final name = exercise['name']?.toString() ?? '动作';

    final sets = (exercise['sets'] as List?)
            ?.whereType<Map>()
            .map((set) => Map<String, dynamic>.from(set))
            .toList() ??
        [];

    final completedSets = sets.where((set) {
      return _toInt(set['is_completed']) == 1;
    }).toList();

    final total = sets.length;
    final completed = completedSets.length;

    if (completed == 0) {
      return ExerciseAnalysis(
        name: name,
        status: AnalysisStatus.poor,
        summary: '本次计划 $total 组，未完成训练。',
        totalSets: total,
        completedSets: 0,
      );
    }

    final performances = completedSets
        .map(analyzeSet)
        .toList();

    final comparable = performances
        .where((item) => item != SetPerformance.unavailable)
        .toList();

    final hasExceeded =
        comparable.contains(SetPerformance.exceeded);
    final hasMatched =
        comparable.contains(SetPerformance.matched);
    final hasBelow =
        comparable.contains(SetPerformance.below);
    final hasSpecial =
        comparable.contains(SetPerformance.special);

    AnalysisStatus status;
    String performanceText;

    if (completed < total) {
      status = AnalysisStatus.special;
      performanceText = _performanceDescription(
        hasExceeded,
        hasMatched,
        hasBelow,
        hasSpecial,
        comparable.isEmpty,
      );
    } else if (comparable.isEmpty) {
      status = AnalysisStatus.special;
      performanceText = '缺少可比较的实际数据';
    } else if (hasSpecial || (hasBelow && (hasExceeded || hasMatched))) {
      status = AnalysisStatus.special;
      performanceText = '组间表现存在差异';
    } else if (hasBelow) {
      status = AnalysisStatus.poor;
      performanceText = '整体低于计划';
    } else if (hasExceeded) {
      status = AnalysisStatus.good;
      performanceText = '表现超额完成';
    } else {
      status = AnalysisStatus.good;
      performanceText = '表现符合计划';
    }

    final summary = completed < total
        ? '完成 $completed/$total 组，$performanceText。'
        : '$performanceText。';

    return ExerciseAnalysis(
      name: name,
      status: status,
      summary: summary,
      totalSets: total,
      completedSets: completed,
    );
  }

  /// 分析整次训练
  static WorkoutAnalysis analyzeWorkout(
    List<Map<String, dynamic>> exercises,
  ) {
    final results = exercises.map(analyzeExercise).toList();

    final totalSets = results.fold<int>(
      0,
      (sum, item) => sum + item.totalSets,
    );

    final completedSets = results.fold<int>(
      0,
      (sum, item) => sum + item.completedSets,
    );

    final statuses = results.map((item) => item.status).toList();

    AnalysisStatus status;
    String summary;

    if (completedSets == 0) {
      status = AnalysisStatus.poor;
      summary = '本次训练没有完成任何组数。';
    } else if (statuses.contains(AnalysisStatus.special) ||
        (statuses.contains(AnalysisStatus.good) &&
            statuses.contains(AnalysisStatus.poor))) {
      status = AnalysisStatus.special;
      summary = '本次训练存在特殊变化，建议结合各动作表现查看。';
    } else if (statuses.every((item) => item == AnalysisStatus.poor)) {
      status = AnalysisStatus.poor;
      summary = '本次训练整体表现低于计划。';
    } else if (statuses.contains(AnalysisStatus.good)) {
      status = AnalysisStatus.good;

      if (statuses.every((item) => item == AnalysisStatus.good) &&
          results.any((item) => item.summary.contains('超额完成'))) {
        summary = '本次训练整体表现超额完成。';
      } else {
        summary = '本次训练整体符合计划。';
      }
    } else {
      status = AnalysisStatus.special;
      summary = '本次训练存在特殊情况，建议查看具体动作记录。';
    }

    return WorkoutAnalysis(
      status: status,
      summary: summary,
      totalSets: totalSets,
      completedSets: completedSets,
      exercises: results,
    );
  }

  static String _performanceDescription(
    bool exceeded,
    bool matched,
    bool below,
    bool special,
    bool unavailable,
  ) {
    if (unavailable) return '缺少可比较的实际数据';

    if (special || (below && (exceeded || matched))) {
      return '已完成组之间存在表现差异';
    }

    if (below && !exceeded && !matched) {
      return '已完成组整体低于计划';
    }

    if (exceeded) return '已完成组的表现达到或超过计划';

    if (matched) return '已完成组的表现符合计划';

    return '表现存在特殊变化';
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
