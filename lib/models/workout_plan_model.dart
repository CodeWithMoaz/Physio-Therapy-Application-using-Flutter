class WorkoutPlan {
  final String targetArea;
  final String bodyType;
  final List<Week> weeks;
  final Map<String, dynamic> metrics;
  final List<String> precautions;
  final String description;

  WorkoutPlan({
    required this.targetArea,
    required this.bodyType,
    required this.weeks,
    this.metrics = const {},
    this.precautions = const [],
    this.description = '',
  });

  factory WorkoutPlan.fromMap(Map<String, dynamic> map) {
    return WorkoutPlan(
      targetArea: map['target_area'] ?? 'Unknown',
      bodyType: map['body_type'] ?? 'Unknown',
      weeks: (map['weeks'] as List<dynamic>?)
              ?.map((week) => Week.fromMap(week))
              .toList() ??
          [],
      metrics: Map<String, dynamic>.from(map['metrics'] ?? {}),
      precautions: List<String>.from(map['precautions'] ?? []),
      description: map['description'] ?? '',
    );
  }

  factory WorkoutPlan.empty() {
    return WorkoutPlan(
      targetArea: 'Unknown',
      bodyType: 'Unknown',
      weeks: [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'target_area': targetArea,
      'body_type': bodyType,
      'weeks': weeks.map((week) => week.toMap()).toList(),
      'metrics': metrics,
      'precautions': precautions,
      'description': description,
    };
  }
}

class Week {
  final int weekNumber;
  final List<Day> days;
  final String focus;
  final String intensity;

  Week({
    required this.weekNumber,
    required this.days,
    this.focus = '',
    this.intensity = 'Moderate',
  });

  factory Week.fromMap(Map<String, dynamic> map) {
    return Week(
      weekNumber: map['week'] ?? 1,
      days: (map['days'] as List<dynamic>?)
              ?.map((day) => Day.fromMap(day))
              .toList() ??
          [],
      focus: map['focus'] ?? '',
      intensity: map['intensity'] ?? 'Moderate',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'week': weekNumber,
      'days': days.map((day) => day.toMap()).toList(),
      'focus': focus,
      'intensity': intensity,
    };
  }
}

class Day {
  final int dayNumber;
  final List<Exercise> exercises;
  final String focus;
  final int duration;

  Day({
    required this.dayNumber,
    required this.exercises,
    this.focus = '',
    this.duration = 30,
  });

  factory Day.fromMap(Map<String, dynamic> map) {
    return Day(
      dayNumber: map['day'] ?? 1,
      exercises: (map['exercises'] as List<dynamic>?)
              ?.map((exercise) => Exercise.fromMap(exercise))
              .toList() ??
          [],
      focus: map['focus'] ?? '',
      duration: map['duration'] ?? 30,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'day': dayNumber,
      'exercises': exercises.map((exercise) => exercise.toMap()).toList(),
      'focus': focus,
      'duration': duration,
    };
  }
}

class Exercise {
  final String name;
  final String description;
  final int sets;
  final int reps;
  final String duration;
  final String difficulty;
  final List<String> equipment;
  final List<String> instructions;
  final String imageUrl;
  final String videoUrl;

  Exercise({
    required this.name,
    required this.description,
    required this.sets,
    required this.reps,
    required this.duration,
    required this.difficulty,
    this.equipment = const [],
    this.instructions = const [],
    this.imageUrl = '',
    this.videoUrl = '',
  });

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      name: map['name'] ?? 'Unknown Exercise',
      description: map['description'] ?? '',
      sets: map['sets'] ?? 3,
      reps: map['reps'] ?? 10,
      duration: map['duration'] ?? '30 seconds',
      difficulty: map['difficulty'] ?? 'Medium',
      equipment: List<String>.from(map['equipment'] ?? []),
      instructions: List<String>.from(map['instructions'] ?? []),
      imageUrl: map['image_url'] ?? '',
      videoUrl: map['video_url'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'sets': sets,
      'reps': reps,
      'duration': duration,
      'difficulty': difficulty,
      'equipment': equipment,
      'instructions': instructions,
      'image_url': imageUrl,
      'video_url': videoUrl,
    };
  }
}
