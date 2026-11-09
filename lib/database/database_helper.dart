import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_application_1/plan_data.dart';

class DatabaseHelper {
  static const String _databaseName = 'fitness_tracker.db';
  static const int _databaseVersion = 4;

  static Database? _database;

  // 获取数据库实例
  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  // 初始化数据库
  static Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

    return openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // 创建所有数据表
  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE plan_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        position INTEGER NOT NULL,
        FOREIGN KEY (plan_id) REFERENCES plans(id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE plan_sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_id INTEGER NOT NULL,
        set_number INTEGER NOT NULL,
        weight REAL,
        reps INTEGER,
        FOREIGN KEY (exercise_id) REFERENCES plan_exercises(id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
  CREATE TABLE workouts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    plan_name TEXT NOT NULL,
    started_at TEXT NOT NULL,
    completed_at TEXT NOT NULL,
    duration_seconds INTEGER NOT NULL DEFAULT 0,
    total_sets INTEGER NOT NULL DEFAULT 0,
    completed_sets INTEGER NOT NULL DEFAULT 0
  )
''');

    await db.execute('''
  CREATE TABLE workout_exercises (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    workout_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    position INTEGER NOT NULL,
    FOREIGN KEY (workout_id)
      REFERENCES workouts(id) ON DELETE CASCADE
  )
''');

    await db.execute('''
  CREATE TABLE workout_sets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    exercise_id INTEGER NOT NULL,
    set_number INTEGER NOT NULL,
    planned_weight REAL,
    planned_reps INTEGER,
    actual_weight REAL,
    actual_reps INTEGER,
    is_completed INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (exercise_id)
      REFERENCES workout_exercises(id) ON DELETE CASCADE
  )
''');

    await db.execute('''
  CREATE TABLE weight_records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    weight REAL NOT NULL,
    recorded_at TEXT NOT NULL,
    time_type TEXT NOT NULL,
    created_at TEXT NOT NULL
  )
''');
  }

  // 首次创建数据库
  static Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  // 数据库版本升级
  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE plan_exercises (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          plan_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          position INTEGER NOT NULL,
          FOREIGN KEY (plan_id) REFERENCES plans(id)
            ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE plan_sets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          exercise_id INTEGER NOT NULL,
          set_number INTEGER NOT NULL,
          weight REAL,
          reps INTEGER,
          FOREIGN KEY (exercise_id) REFERENCES plan_exercises(id)
            ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 3) {
      await db.execute('''
    CREATE TABLE workouts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      plan_name TEXT NOT NULL,
      started_at TEXT NOT NULL,
      completed_at TEXT NOT NULL,
      duration_seconds INTEGER NOT NULL DEFAULT 0,
      total_sets INTEGER NOT NULL DEFAULT 0,
      completed_sets INTEGER NOT NULL DEFAULT 0
    )
  ''');

      await db.execute('''
    CREATE TABLE workout_exercises (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      workout_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      position INTEGER NOT NULL,
      FOREIGN KEY (workout_id)
        REFERENCES workouts(id) ON DELETE CASCADE
    )
  ''');

      await db.execute('''
    CREATE TABLE workout_sets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      exercise_id INTEGER NOT NULL,
      set_number INTEGER NOT NULL,
      planned_weight REAL,
      planned_reps INTEGER,
      actual_weight REAL,
      actual_reps INTEGER,
      is_completed INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (exercise_id)
        REFERENCES workout_exercises(id) ON DELETE CASCADE
    )
  ''');
    }

    if (oldVersion < 4) {
      await db.execute('''
    CREATE TABLE weight_records (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      weight REAL NOT NULL,
      recorded_at TEXT NOT NULL,
      time_type TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
  ''');
    }
  }

  // 保存完整训练计划
  static Future<int> savePlan(PlanData plan) async {
    final db = await database;

    final planId = await db.transaction((txn) async {
      final id = await txn.insert('plans', {
        'name': plan.planName,
        'created_at': DateTime.now().toIso8601String(),
      });

      for (int i = 0; i < plan.exercises.length; i++) {
        final exercise = plan.exercises[i];

        final exerciseId = await txn.insert('plan_exercises', {
          'plan_id': id,
          'name': exercise.name,
          'position': i,
        });

        for (int j = 0; j < exercise.sets.length; j++) {
          final set = exercise.sets[j];

          await txn.insert('plan_sets', {
            'exercise_id': exerciseId,
            'set_number': j + 1,
            'weight': set.weight,
            'reps': set.reps,
          });
        }
      }

      return id;
    });

    // 关键：把数据库生成的 ID 回填到内存中的计划对象。
    plan.id = planId;

    return planId;
  }

  // 保存一次训练的历史记录
  static Future<int> saveWorkout({
    required PlanData plannedPlan,
    required PlanData actualPlan,
    required Map<int, Set<int>> completedSets,
    required DateTime startedAt,
    required DateTime completedAt,
    required int durationSeconds,
  }) async {
    final db = await database;

    // 计算计划总组数和实际完成组数
    final totalSets = plannedPlan.exercises.fold<int>(
      0,
      (total, exercise) => total + exercise.sets.length,
    );

    final completedCount = _countValidCompletedSets(plannedPlan, completedSets);

    return db.transaction((txn) async {
      // 1. 保存本次训练的基本信息
      final workoutId = await txn.insert('workouts', {
        'plan_name': plannedPlan.planName,
        'started_at': startedAt.toIso8601String(),
        'completed_at': completedAt.toIso8601String(),
        'duration_seconds': durationSeconds,
        'total_sets': totalSets,
        'completed_sets': completedCount,
      });

      // 2. 保存每个动作和每组的计划、实际数据
      for (int i = 0; i < plannedPlan.exercises.length; i++) {
        final plannedExercise = plannedPlan.exercises[i];

        final actualExercise = i < actualPlan.exercises.length
            ? actualPlan.exercises[i]
            : plannedExercise;

        final exerciseId = await txn.insert('workout_exercises', {
          'workout_id': workoutId,
          'name': plannedExercise.name,
          'position': i,
        });

        for (int j = 0; j < plannedExercise.sets.length; j++) {
          final plannedSet = plannedExercise.sets[j];

          final actualSet = j < actualExercise.sets.length
              ? actualExercise.sets[j]
              : plannedSet;

          final isCompleted = completedSets[i]?.contains(j) ?? false;

          await txn.insert('workout_sets', {
            'exercise_id': exerciseId,
            'set_number': j + 1,
            'planned_weight': plannedSet.weight,
            'planned_reps': plannedSet.reps,
            'actual_weight': actualSet.weight,
            'actual_reps': actualSet.reps,
            'is_completed': isCompleted ? 1 : 0,
          });
        }
      }

      return workoutId;
    });
  }

  /// 根据训练 ID 读取单次训练的完整详情。
  static Future<Map<String, dynamic>?> getWorkoutDetail(int workoutId) async {
    final db = await database;

    // 1. 查询训练基本信息
    final workoutRows = await db.query(
      'workouts',
      where: 'id = ?',
      whereArgs: [workoutId],
      limit: 1,
    );

    if (workoutRows.isEmpty) return null;

    final workout = Map<String, dynamic>.from(workoutRows.first);

    // 2. 查询本次训练的所有动作
    final exerciseRows = await db.query(
      'workout_exercises',
      where: 'workout_id = ?',
      whereArgs: [workoutId],
      orderBy: 'position ASC',
    );

    final exercises = <Map<String, dynamic>>[];

    // 3. 查询每个动作下的所有训练组
    for (final exerciseRow in exerciseRows) {
      final exercise = Map<String, dynamic>.from(exerciseRow);

      final setRows = await db.query(
        'workout_sets',
        where: 'exercise_id = ?',
        whereArgs: [exercise['id']],
        orderBy: 'set_number ASC',
      );

      exercise['sets'] = setRows
          .map((row) => Map<String, dynamic>.from(row))
          .toList();

      exercises.add(exercise);
    }

    workout['exercises'] = exercises;

    return workout;
  }

  static Future<void> updatePlan(int planId, PlanData plan) async {
    final db = await database;

    await db.transaction((txn) async {
      // 更新训练计划名称
      await txn.update(
        'plans',
        {'name': plan.planName},
        where: 'id = ?',
        whereArgs: [planId],
      );

      // 删除旧动作，关联的组数会通过外键级联删除
      await txn.delete(
        'plan_exercises',
        where: 'plan_id = ?',
        whereArgs: [planId],
      );

      // 重新写入动作和组数
      for (int i = 0; i < plan.exercises.length; i++) {
        final exercise = plan.exercises[i];

        final exerciseId = await txn.insert('plan_exercises', {
          'plan_id': planId,
          'name': exercise.name,
          'position': i,
        });

        for (int j = 0; j < exercise.sets.length; j++) {
          final set = exercise.sets[j];

          await txn.insert('plan_sets', {
            'exercise_id': exerciseId,
            'set_number': j + 1,
            'weight': set.weight,
            'reps': set.reps,
          });
        }
      }
    });
  }

  static Future<void> deletePlan(int planId) async {
    final db = await database;

    await db.delete('plans', where: 'id = ?', whereArgs: [planId]);
  }

  // 查询所有训练计划
  static Future<List<Map<String, dynamic>>> getPlans() async {
    final db = await database;

    return db.query('plans', orderBy: 'id DESC');
  }

  static Future<List<PlanData>> getFullPlans() async {
    final db = await database;

    // 1. 查询所有计划
    final planRows = await db.query('plans', orderBy: 'id DESC');

    final List<PlanData> result = [];

    // 2. 遍历每个计划
    for (final planRow in planRows) {
      final planId = planRow['id'] as int;

      final exerciseRows = await db.query(
        'plan_exercises',
        where: 'plan_id = ?',
        whereArgs: [planId],
        orderBy: 'position ASC',
      );

      final List<ExerciseData> exercises = [];

      // 3. 遍历每个动作，查询它的组数
      for (final exerciseRow in exerciseRows) {
        final exerciseId = exerciseRow['id'] as int;

        final setRows = await db.query(
          'plan_sets',
          where: 'exercise_id = ?',
          whereArgs: [exerciseId],
          orderBy: 'set_number ASC',
        );

        final sets = setRows.map((row) {
          final weight = row['weight'];
          final reps = row['reps'];

          return SetData(
            weight: weight == null ? null : (weight as num).toDouble(),
            reps: reps == null ? null : (reps as num).toInt(),
          );
        }).toList();

        exercises.add(
          ExerciseData(name: exerciseRow['name'] as String, sets: sets),
        );
      }

      // 4. 组装完整计划
      result.add(
        PlanData(
          id: planId,
          planName: planRow['name'] as String,
          exercises: exercises,
        ),
      );
    }

    return result;
  }

  // 查询训练次数
  static Future<int> getWorkoutCount() async {
    final db = await database;

    final result = await db.rawQuery('SELECT COUNT(*) AS total FROM workouts');

    return (result.first['total'] as num).toInt();
  }

  // 查询所有训练记录的平均完成度
  static Future<double> getAverageCompletion() async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT
        CASE
          WHEN SUM(total_sets) > 0
          THEN SUM(completed_sets) * 100.0 / SUM(total_sets)
          ELSE 0
        END AS completion
      FROM workouts
    ''');

    return (result.first['completion'] as num?)?.toDouble() ?? 0;
  }

  // 查询最近的训练记录
  static Future<List<Map<String, dynamic>>> getRecentWorkouts({
    int limit = 2,
  }) async {
    final db = await database;

    return db.query('workouts', orderBy: 'completed_at DESC', limit: limit);
  }

  static Future<List<Map<String, dynamic>>> getWorkoutHistory() async {
    final db = await database;

    return db.query('workouts', orderBy: 'completed_at DESC');
  }

  /// 查询指定月份的训练记录。
  static Future<List<Map<String, dynamic>>> getWorkoutsForMonth({
    required int year,
    required int month,
  }) async {
    final db = await database;

    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1);

    return db.query(
      'workouts',
      where: 'completed_at >= ? AND completed_at < ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'completed_at DESC',
    );
  }

  // 查询指定时间范围内的训练趋势
  static Future<List<Map<String, dynamic>>> getWorkoutTrend({
    required DateTime startDate,
  }) async {
    final db = await database;

    return db.query(
      'workouts',
      columns: ['completed_at', 'total_sets', 'completed_sets'],
      where: 'completed_at >= ?',
      whereArgs: [startDate.toIso8601String()],
      orderBy: 'completed_at ASC',
    );
  }

  static Future<Map<String, Map<String, double>>> getDailyWorkoutStats({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;

    String dateKey(DateTime date) {
      final year = date.year.toString().padLeft(4, '0');
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      return '$year-$month-$day';
    }

    final start = dateKey(startDate);
    final end = dateKey(endDate);

    // 每日完成度：同一天多次训练时，先合计组数再计算比例。
    final completionRows = await db.rawQuery(
      '''
      SELECT
        date(completed_at) AS workout_date,
        SUM(total_sets) AS total_sets,
        SUM(completed_sets) AS completed_sets
      FROM workouts
      WHERE date(completed_at) >= date(?)
        AND date(completed_at) <= date(?)
      GROUP BY date(completed_at)
      ''',
      [start, end],
    );

    // 每日训练量：只累计已完成组的实际重量 × 实际次数。
    final volumeRows = await db.rawQuery(
      '''
      SELECT
        date(w.completed_at) AS workout_date,
        SUM(
          CASE
            WHEN ws.is_completed = 1
              AND ws.actual_weight IS NOT NULL
              AND ws.actual_reps IS NOT NULL
            THEN ws.actual_weight * ws.actual_reps
            ELSE 0
          END
        ) AS total_volume
      FROM workouts w
      JOIN workout_exercises we ON we.workout_id = w.id
      JOIN workout_sets ws ON ws.exercise_id = we.id
      WHERE date(w.completed_at) >= date(?)
        AND date(w.completed_at) <= date(?)
      GROUP BY date(w.completed_at)
      ''',
      [start, end],
    );

    final result = <String, Map<String, double>>{};

    for (final row in completionRows) {
      final date = row['workout_date'] as String;
      final totalSets = (row['total_sets'] as num?)?.toDouble() ?? 0;
      final completedSets = (row['completed_sets'] as num?)?.toDouble() ?? 0;

      result[date] = {
        'completion': totalSets > 0 ? completedSets * 100 / totalSets : 0,
        'volume': 0,
      };
    }

    for (final row in volumeRows) {
      final date = row['workout_date'] as String;
      final volume = (row['total_volume'] as num?)?.toDouble() ?? 0;

      result.putIfAbsent(date, () => {'completion': 0, 'volume': 0});
      result[date]!['volume'] = volume;
    }

    return result;
  }

  static int _countValidCompletedSets(
    PlanData plannedPlan,
    Map<int, Set<int>> completedSets,
  ) {
    int count = 0;

    for (final entry in completedSets.entries) {
      final exerciseIndex = entry.key;

      if (exerciseIndex < 0 || exerciseIndex >= plannedPlan.exercises.length) {
        continue;
      }

      final plannedSets = plannedPlan.exercises[exerciseIndex].sets;

      for (final setIndex in entry.value) {
        if (setIndex >= 0 && setIndex < plannedSets.length) {
          count++;
        }
      }
    }

    return count;
  }

  // 保存体重记录
  static Future<int> saveWeightRecord({
    required double weight,
    required DateTime recordedAt,
    required String timeType,
  }) async {
    final db = await database;

    return db.insert('weight_records', {
      'weight': weight,
      'recorded_at': DateTime(
        recordedAt.year,
        recordedAt.month,
        recordedAt.day,
      ).toIso8601String(),
      'time_type': timeType,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // 查询体重记录，按记录日期从早到晚排列
  static Future<List<Map<String, dynamic>>> getWeightRecords({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;

    String? where;
    List<Object?>? whereArgs;

    if (startDate != null && endDate != null) {
      final start = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      ).toIso8601String();

      final end = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
      ).add(const Duration(days: 1)).toIso8601String();

      where = 'recorded_at >= ? AND recorded_at < ?';
      whereArgs = [start, end];
    }

    return db.query(
      'weight_records',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'recorded_at ASC, created_at ASC',
    );
  }
}
