import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/notification_service.dart';

class AddTaskController extends ChangeNotifier {
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  final TextEditingController titleController = TextEditingController();

  String selectedPriority = 'Normal';
  bool isLoading = false;

  String? dateError;
  String? timeError;
  String? titleError;
  String? generalError;

  final BuildContext context;
  final VoidCallback? onTaskAdded;
  final Map<String, dynamic>? taskToEdit;

  final NotificationService _notificationService = NotificationService();

  bool get isEditMode => taskToEdit != null;

  AddTaskController({
    required this.context,
    this.onTaskAdded,
    this.taskToEdit,
  }) {
    _notificationService.initialize();
    _initializeFields();
  }

  void _initializeFields() {
    if (taskToEdit != null) {
      dateController.text = taskToEdit!['date'] ?? '';
      timeController.text = taskToEdit!['time'] ?? '';
      titleController.text = taskToEdit!['title'] ?? '';
      selectedPriority = taskToEdit!['priority'] ?? 'Normal';
    }
  }

  void disposeControllers() {
    dateController.dispose();
    timeController.dispose();
    titleController.dispose();
  }

  void clearErrors() {
    dateError = null;
    timeError = null;
    titleError = null;
    generalError = null;
    notifyListeners();
  }

  bool validateFields() {
    clearErrors();
    bool isValid = true;

    if (dateController.text.trim().isEmpty) {
      dateError = 'Please select a date';
      isValid = false;
    }

    if (timeController.text.trim().isEmpty) {
      timeError = 'Please select a time';
      isValid = false;
    }

    if (titleController.text.trim().isEmpty) {
      titleError = 'Please enter a task title';
      isValid = false;
    }

    if (!isValid) {
      notifyListeners();
    }

    return isValid;
  }

  Future<void> saveTask() async {
    if (isEditMode) {
      await updateTask();
    } else {
      await addTask();
    }
  }

  Future<void> addTask() async {
    if (!validateFields()) return;

    final date = dateController.text.trim();
    final time = timeController.text.trim();
    final title = titleController.text.trim();

    _setLoading(true);
    clearErrors();

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        generalError = 'Please sign in to add tasks';
        notifyListeners();
        _setLoading(false);
        return;
      }

      final response = await Supabase.instance.client
          .from('tasks')
          .insert({
            'date': date,
            'time': time,
            'title': title,
            'priority': selectedPriority,
            'uuid': user.id,
            'is_deleted': 'not_deleted',
            'status': 'pending',
          })
          .select()
          .single();

      final taskId = response['id'] as int;

      await _scheduleNotifications(date, time, title, taskId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        onTaskAdded?.call();
        Navigator.pop(context);
      }
    } catch (e, stackTrace) {
      generalError = e is PostgrestException
          ? (e.message ?? 'Failed to add task')
          : 'Failed to add task. Please try again.';
      notifyListeners();
      print('❌ Error adding task: $e');
      print(stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateTask() async {
    if (!validateFields()) return;

    final date = dateController.text.trim();
    final time = timeController.text.trim();
    final title = titleController.text.trim();
    final taskId = taskToEdit!['id'] as int;

    _setLoading(true);
    clearErrors();

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        generalError = 'Please sign in to update tasks';
        notifyListeners();
        _setLoading(false);
        return;
      }

      final response = await Supabase.instance.client
          .from('tasks')
          .update({
            'date': date,
            'time': time,
            'title': title,
            'priority': selectedPriority,
          })
          .eq('id', taskId)
          .select()
          .single();

      // Remove old notifications and schedule new ones
      await _notificationService.removeTaskNotifications(taskId);
      await _scheduleNotifications(date, time, title, taskId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        onTaskAdded?.call();
        Navigator.pop(context);
      }
    } catch (e, stackTrace) {
      generalError = e is PostgrestException
          ? (e.message ?? 'Failed to update task')
          : 'Failed to update task. Please try again.';
      notifyListeners();
      print('❌ Error updating task: $e');
      print(stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _scheduleNotifications(
    String date,
    String time,
    String title,
    int taskId,
  ) async {
    try {
      final timeFormatted = _parseTimeToHHMM(time);
      final taskDateTimeStr = '$date $timeFormatted';
      final taskDateTime = DateTime.tryParse(taskDateTimeStr);

      if (taskDateTime == null) return;
      if (taskDateTime.isBefore(DateTime.now())) return;

      await _notificationService.scheduleTaskNotifications(
        taskTitle: title,
        scheduledDateTime: taskDateTime,
        taskId: taskId,
      );
    } catch (e, stackTrace) {
      print('❌ Error scheduling notifications: $e');
      print(stackTrace);
    }
  }

  String _parseTimeToHHMM(String time) {
    try {
      // Already HH:MM
      if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(time)) return time;

      // 12-hour format
      final regex = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)', caseSensitive: false);
      final match = regex.firstMatch(time);
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        final minute = match.group(2)!;
        final period = match.group(3)!.toUpperCase();

        if (period == 'PM' && hour != 12) hour += 12;
        if (period == 'AM' && hour == 12) hour = 0;

        return '${hour.toString().padLeft(2, '0')}:$minute';
      }

      return time;
    } catch (e) {
      print('⚠️ Error parsing time: $e');
      return time;
    }
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void setPriority(String priority) {
    selectedPriority = priority;
    notifyListeners();
  }
}
