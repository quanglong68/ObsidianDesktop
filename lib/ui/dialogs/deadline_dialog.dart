import 'package:flutter/material.dart';

import '../../providers/app_provider.dart';

class BlinkingBadge extends StatefulWidget {
  final bool isBlinking;
  final Color badgeColor;
  final String badgeText;

  const BlinkingBadge({
    super.key,
    required this.isBlinking,
    required this.badgeColor,
    required this.badgeText,
  });

  @override
  State<BlinkingBadge> createState() => _BlinkingBadgeState();
}

class _BlinkingBadgeState extends State<BlinkingBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    if (widget.isBlinking) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(BlinkingBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isBlinking && !oldWidget.isBlinking) {
      _controller.repeat(reverse: true);
    } else if (!widget.isBlinking && oldWidget.isBlinking) {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: widget.badgeColor),
        boxShadow: widget.isBlinking
            ? [
                BoxShadow(
                  color: widget.badgeColor.withOpacity(0.6),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: Text(
        widget.badgeText,
        style: TextStyle(
          color: widget.badgeColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    if (!widget.isBlinking) return badge;

    return FadeTransition(
      opacity: Tween(begin: 0.2, end: 1.0).animate(_controller),
      child: badge,
    );
  }
}

void showDeadlineDialog(BuildContext context, AppProvider provider) {
  showDialog(
    context: context,
    builder: (contextDialog) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: const Color(0xFFF26F21).withOpacity(0.5),
            width: 2,
          ),
        ),
        title: StatefulBuilder(
          builder: (context, setState) {
            DateTime now = DateTime.now();
            String todayString =
                "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.event_note, color: Color(0xFFF26F21)),
                    SizedBox(width: 10),
                    Text(
                      "DEADLINE & NHIỆM VỤ",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Hôm nay: $todayString",
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        content: SizedBox(
          width: 700,
          height: 600,
          child: ListenableBuilder(
            listenable: provider,
            builder: (context, child) {
              List<TaskItem> allTasks = provider.getAllTasks();
              DateTime now = DateTime.now();
              DateTime today = DateTime(now.year, now.month, now.day);

              if (allTasks.isEmpty) {
                return const Center(
                  child: Text(
                    "Tuyệt vời! Không có deadline nào.",
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: allTasks.length,
                itemBuilder: (context, index) {
                  TaskItem task = allTasks[index];
                  DateTime taskDay = DateTime(
                    task.dueDate.year,
                    task.dueDate.month,
                    task.dueDate.day,
                  );
                  int diffDays = taskDay.difference(today).inDays;

                  String badgeText;
                  Color badgeColor;
                  Color cardBorderColor;

                  if (task.isDone) {
                    badgeText = "Đã làm";
                    badgeColor = Colors.grey;
                    cardBorderColor = Colors.grey.withOpacity(0.2);
                  } else if (diffDays < 0) {
                    badgeText = "Quá hạn";
                    badgeColor = Colors.redAccent;
                    cardBorderColor = Colors.redAccent.withOpacity(0.5);
                  } else if (diffDays == 0) {
                    badgeText = "Hôm nay";
                    badgeColor = Colors.redAccent;
                    cardBorderColor = Colors.redAccent;
                  } else if (diffDays <= 3) {
                    badgeText = "Còn $diffDays ngày";
                    badgeColor = Colors.redAccent;
                    cardBorderColor = Colors.redAccent.withOpacity(0.8);
                  } else if (diffDays <= 7) {
                    badgeText = "Còn $diffDays ngày";
                    badgeColor = Colors.orangeAccent;
                    cardBorderColor = Colors.orangeAccent.withOpacity(0.5);
                  } else {
                    badgeText = "Còn $diffDays ngày";
                    badgeColor = Colors.cyanAccent;
                    cardBorderColor = Colors.cyanAccent.withOpacity(0.3);
                  }

                  bool isUrgent = !task.isDone && diffDays <= 3;
                  String dateStr =
                      "${task.dueDate.day.toString().padLeft(2, '0')}/${task.dueDate.month.toString().padLeft(2, '0')}/${task.dueDate.year}";

                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cardBorderColor,
                        width: isUrgent ? 1.5 : 1.0,
                      ),
                      boxShadow: isUrgent
                          ? [
                              BoxShadow(
                                color: badgeColor.withOpacity(0.1),
                                blurRadius: 10,
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(contextDialog);
                              provider.openObsidianFile(task.fileName);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.content,
                                  style: TextStyle(
                                    color: task.isDone
                                        ? Colors.grey
                                        : Colors.white,
                                    fontWeight: task.isDone
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                    decoration: task.isDone
                                        ? TextDecoration.lineThrough
                                        : null,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    BlinkingBadge(
                                      isBlinking: isUrgent,
                                      badgeColor: badgeColor,
                                      badgeText: badgeText,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "File: ${task.fileName}  •  Hạn: $dateStr",
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: task.isDone
                                ? Colors.grey.withOpacity(0.2)
                                : const Color(0xFF064E3B),
                            side: BorderSide(
                              color: task.isDone
                                  ? Colors.grey
                                  : Colors.greenAccent,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 15,
                            ),
                          ),
                          icon: Icon(
                            task.isDone ? Icons.undo : Icons.check,
                            color: task.isDone
                                ? Colors.grey
                                : Colors.greenAccent,
                            size: 18,
                          ),
                          label: Text(
                            task.isDone ? "Hoàn tác" : "Đã làm",
                            style: TextStyle(
                              color: task.isDone
                                  ? Colors.grey
                                  : Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () {
                            provider.toggleTaskStatus(task);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      );
    },
  );
}
