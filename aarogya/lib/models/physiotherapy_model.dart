enum BodyArea {
  neck,
  lowerBack,
  shoulder,
  knee,
  posture,
}

enum ExerciseGoal {
  painRelief,
  mobility,
  strengthening,
  rehabilitation,
}

enum SessionDifficulty {
  tooEasy,
  justRight,
  tooChallenging,
}

class PhysioExercise {
  final String id;
  final String title;
  final BodyArea bodyArea;
  final ExerciseGoal goal;
  final int durationSeconds;
  final int targetReps;
  final List<String> instructions;
  final String safetyGuidance;
  final String breathingNotes;
  final String targetMuscles;

  const PhysioExercise({
    required this.id,
    required this.title,
    required this.bodyArea,
    required this.goal,
    required this.durationSeconds,
    required this.targetReps,
    required this.instructions,
    required this.safetyGuidance,
    required this.breathingNotes,
    required this.targetMuscles,
  });

  String get bodyAreaLabel {
    switch (bodyArea) {
      case BodyArea.neck:
        return 'Neck / Cervical';
      case BodyArea.lowerBack:
        return 'Lower Back / Lumbar';
      case BodyArea.shoulder:
        return 'Shoulder & Rotator Cuff';
      case BodyArea.knee:
        return 'Knee & Quadriceps';
      case BodyArea.posture:
        return 'Thoracic & Posture';
    }
  }

  String get goalLabel {
    switch (goal) {
      case ExerciseGoal.painRelief:
        return 'Pain Relief';
      case ExerciseGoal.mobility:
        return 'Mobility & Range';
      case ExerciseGoal.strengthening:
        return 'Strengthening';
      case ExerciseGoal.rehabilitation:
        return 'Post-Rehab Recovery';
    }
  }

  factory PhysioExercise.fromJson(Map<String, dynamic> json) {
    return PhysioExercise(
      id: json['id'] as String,
      title: json['title'] as String,
      bodyArea: BodyArea.values.firstWhere(
        (e) => e.name == json['bodyArea'],
        orElse: () => BodyArea.neck,
      ),
      goal: ExerciseGoal.values.firstWhere(
        (e) => e.name == json['goal'],
        orElse: () => ExerciseGoal.mobility,
      ),
      durationSeconds: json['durationSeconds'] as int? ?? 60,
      targetReps: json['targetReps'] as int? ?? 10,
      instructions: (json['instructions'] as List?)?.map((e) => e.toString()).toList() ?? [],
      safetyGuidance: json['safetyGuidance'] as String? ?? 'Discontinue if sharp pain occurs.',
      breathingNotes: json['breathingNotes'] as String? ?? 'Exhale during exertion, inhale on release.',
      targetMuscles: json['targetMuscles'] as String? ?? 'Target area muscles',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'bodyArea': bodyArea.name,
      'goal': goal.name,
      'durationSeconds': durationSeconds,
      'targetReps': targetReps,
      'instructions': instructions,
      'safetyGuidance': safetyGuidance,
      'breathingNotes': breathingNotes,
      'targetMuscles': targetMuscles,
    };
  }
}

class PhysioSessionLog {
  final String id;
  final String exerciseId;
  final String exerciseTitle;
  final BodyArea bodyArea;
  final int durationSeconds;
  final int completedReps;
  final int painRating; // 0 - 10 Visual Analog Scale
  final SessionDifficulty difficulty;
  final String? userNotes;
  final DateTime completedAt;

  const PhysioSessionLog({
    required this.id,
    required this.exerciseId,
    required this.exerciseTitle,
    required this.bodyArea,
    required this.durationSeconds,
    required this.completedReps,
    required this.painRating,
    required this.difficulty,
    this.userNotes,
    required this.completedAt,
  });

  String get difficultyLabel {
    switch (difficulty) {
      case SessionDifficulty.tooEasy:
        return 'Too Easy';
      case SessionDifficulty.justRight:
        return 'Just Right';
      case SessionDifficulty.tooChallenging:
        return 'Too Challenging';
    }
  }

  factory PhysioSessionLog.fromJson(Map<String, dynamic> json) {
    return PhysioSessionLog(
      id: json['id'] as String,
      exerciseId: json['exerciseId'] as String,
      exerciseTitle: json['exerciseTitle'] as String,
      bodyArea: BodyArea.values.firstWhere(
        (e) => e.name == json['bodyArea'],
        orElse: () => BodyArea.neck,
      ),
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      completedReps: json['completedReps'] as int? ?? 0,
      painRating: json['painRating'] as int? ?? 0,
      difficulty: SessionDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => SessionDifficulty.justRight,
      ),
      userNotes: json['userNotes'] as String?,
      completedAt: DateTime.tryParse(json['completedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exerciseId': exerciseId,
      'exerciseTitle': exerciseTitle,
      'bodyArea': bodyArea.name,
      'durationSeconds': durationSeconds,
      'completedReps': completedReps,
      'painRating': painRating,
      'difficulty': difficulty.name,
      if (userNotes != null) 'userNotes': userNotes,
      'completedAt': completedAt.toIso8601String(),
    };
  }
}

class PhysioPlan {
  final String id;
  final String title;
  final String subtitle;
  final BodyArea targetArea;
  final int estimatedDurationMinutes;
  final List<PhysioExercise> exercises;

  const PhysioPlan({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.targetArea,
    required this.estimatedDurationMinutes,
    required this.exercises,
  });
}
