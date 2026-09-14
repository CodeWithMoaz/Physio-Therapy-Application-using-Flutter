import 'package:cloud_firestore/cloud_firestore.dart';

class RehabExercise {
  final String id;
  final String name;
  final int sets;
  final int reps;
  final String image;
  final String video;
  final String description;
  final String difficulty;
  final List<String> targetMuscles;
  final String programId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCompleted;

  RehabExercise({
    required this.id,
    required this.name,
    required this.sets,
    required this.reps,
    required this.image,
    required this.video,
    required this.description,
    required this.difficulty,
    required this.targetMuscles,
    required this.programId,
    required this.createdAt,
    required this.updatedAt,
    this.isCompleted = false,
  });

  factory RehabExercise.fromMap(Map<String, dynamic> data, String docId) {
    String imagePath = data['image'] ?? '';
    imagePath = imagePath.replaceAll('\\', '/');

    if (imagePath.isNotEmpty &&
        !imagePath.startsWith('assets/') &&
        !imagePath.startsWith('/')) {
      imagePath = 'assets/' + imagePath;
    }

    String videoPath = data['video'] ?? '';
    videoPath = videoPath.replaceAll('\\', '/');

    if (videoPath.startsWith('assets/')) {
      videoPath = videoPath.substring('assets/'.length);
    }

    if (videoPath.isEmpty ||
        (!videoPath.startsWith('videos/') && !videoPath.startsWith('/'))) {
      videoPath = 'videos/back/Back1.mp4';
    }

    return RehabExercise(
      id: docId,
      name: data['name'] ?? '',
      sets: data['sets'] ?? 0,
      reps: data['reps'] ?? 0,
      image: imagePath,
      video: videoPath,
      description: data['description'] ?? '',
      difficulty: data['difficulty'] ?? 'Moderate',
      targetMuscles: List<String>.from(data['targetMuscles'] ?? []),
      programId: data['programId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
      'image': image,
      'video': video,
      'description': description,
      'difficulty': difficulty,
      'targetMuscles': targetMuscles,
      'programId': programId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isCompleted': isCompleted,
    };
  }

  RehabExercise copyWith({
    String? id,
    String? name,
    int? sets,
    int? reps,
    String? image,
    String? video,
    String? description,
    String? difficulty,
    List<String>? targetMuscles,
    String? programId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCompleted,
  }) {
    return RehabExercise(
      id: id ?? this.id,
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      image: image ?? this.image,
      video: video ?? this.video,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      targetMuscles: targetMuscles ?? this.targetMuscles,
      programId: programId ?? this.programId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
