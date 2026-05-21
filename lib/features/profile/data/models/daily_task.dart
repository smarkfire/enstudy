class DailyTask {
  final String taskId;
  final String title;
  final String description;
  final bool isCompleted;
  final int reward;

  const DailyTask({
    required this.taskId,
    required this.title,
    required this.description,
    this.isCompleted = false,
    required this.reward,
  });

  DailyTask copyWith({
    String? taskId,
    String? title,
    String? description,
    bool? isCompleted,
    int? reward,
  }) =>
      DailyTask(
        taskId: taskId ?? this.taskId,
        title: title ?? this.title,
        description: description ?? this.description,
        isCompleted: isCompleted ?? this.isCompleted,
        reward: reward ?? this.reward,
      );
}
