import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

class DayTasksList extends StatefulWidget {
  final List<Map<String, dynamic>> tasks;
  final Function(int taskId, bool isChecked)? onTaskChecked;
  final Function(int taskId)? onTaskDeleted;
  final Function(Map<String, dynamic> task)? onTaskEdit;

  const DayTasksList({
    super.key,
    required this.tasks,
    this.onTaskChecked,
    this.onTaskDeleted,
    this.onTaskEdit,
  });

  @override
  State<DayTasksList> createState() => _DayTasksListState();
}

class _DayTasksListState extends State<DayTasksList> {
    String _formatDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return '';
      try {
        final date = DateTime.parse(dateStr);
        return DateFormat('MMM d').format(date); 
      } catch (e) {
        return dateStr;
      }
    }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 180,
      child: ListView.separated(
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: widget.tasks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final task = widget.tasks[index];
          final priority = task['priority'] ?? 'Normal';
          final date = _formatDate(task['date']);
          final status = task['status'] ?? 'pending';
          final isChecked = status == 'done';

          Color priorityColor;
          switch (priority) {
            case 'Urgent':
              priorityColor = Colors.redAccent;
              break;
            case 'Medium':
              priorityColor = Colors.amber;
              break;
            default:
              priorityColor = Colors.green;
          }

          return Container(
            width: 180,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (date.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 235, 255, 235),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          date,
                          style: TextStyle(
                            color: ThemeData.estimateBrightnessForColor(
                                  const Color.fromARGB(255, 179, 240, 182)) == Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (task['time'] != null && task['time'].toString().isNotEmpty)
                      Text(
                        task['time'],
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () {
                        final taskId = task['id'];
                        if (taskId != null) {
                          widget.onTaskEdit?.call(task);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () async {
                        final taskId = task['id'];
                        if (taskId != null) {
                          await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              bool isDeleted = false;

                              return StatefulBuilder(
                                builder: (context, setState) {
                                  return AlertDialog(
                                      title: Text(isDeleted ? 'task_deleted'.tr() : 'delete_task'.tr()),
                                      content: Text(
                                        isDeleted
                                            ? 'task_deleted_success'.tr()
                                            : 'delete_task_confirm'.tr(),
                                      ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    actions: <Widget>[
                                      if (isDeleted)
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                            style: TextButton.styleFrom(
                                            foregroundColor: Colors.green,
                                            ),
                                            child: const Text('OK'),
                                        )
                                      else ...[
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.green,
                                          ),
                                          child: Text('cancel_button'.tr()),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            widget.onTaskDeleted?.call(taskId);
                                            setState(() {
                                              isDeleted = true;
                                            });
                                          },
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.redAccent,
                                          ),
                                          child: Text('delete_button'.tr()),
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                Text(
                  task['title'] ?? '',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'priority'.tr(),
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            priority,
                            style: TextStyle(
                              color: priorityColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Checkbox(
                      value: isChecked,
                      onChanged: (value) {
                        final taskId = task['id'];
                        if (taskId != null) {
                          widget.onTaskChecked?.call(taskId, value ?? false);
                        }
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      activeColor: const Color.fromARGB(255, 179, 240, 182),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}