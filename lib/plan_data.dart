class PlanData {

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