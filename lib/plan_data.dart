class PlanData {
  /// 数据库中的计划 ID。
  /// 新建计划保存前为 null，保存后会获得真实 ID。
  int? id;

  String planName;
  List<ExerciseData> exercises;

  PlanData({
    this.id,
    this.planName = '',
    List<ExerciseData>? exercises,
  }) : exercises = exercises ?? [];
}

class ExerciseData {
  String name;
  List<SetData> sets;

  ExerciseData({
    this.name = '',
    List<SetData>? sets,
  }) : sets = sets ?? [];
}

class SetData {
  double? weight;
  int? reps;

  SetData({
    this.weight,
    this.reps,
  });
}