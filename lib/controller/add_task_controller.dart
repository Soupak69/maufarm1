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

      print('📝 Adding task: $title');
      print('📅 Date: $date, Time: $time');

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

      print('✅ Task inserted successfully: ${response['id']}');

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
      print('❌ Error adding task: $e');
      print('Stack trace: $stackTrace');
      
      generalError = e is PostgrestException 
          ? (e.message ?? 'Failed to add task') 
          : 'Failed to add task. Please try again.';
      notifyListeners();
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

      print('✏️ Updating task: $taskId');

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

      print('✅ Task updated successfully');

     
      await _notificationService.cancelTaskNotifications(taskId);
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
      print('❌ Error updating task: $e');
      print('Stack trace: $stackTrace');
      
      generalError = e is PostgrestException 
          ? (e.message ?? 'Failed to update task') 
          : 'Failed to update task. Please try again.';
      notifyListeners();
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
      
      final timeFormatted = _notificationService.parseTimeToHHMM(time);
      final taskDateTimeStr = '$date $timeFormatted';
      
      print('🕐 Parsing datetime: $taskDateTimeStr');
      
      final taskDateTime = DateTime.tryParse(taskDateTimeStr);
      
      if (taskDateTime == null) {
        print('⚠️ Failed to parse datetime: $taskDateTimeStr');
        return;
      }

      if (taskDateTime.isBefore(DateTime.now())) {
        print('⏭️ Task time is in the past, skipping notifications');
        return;
      }

      print('🔔 Scheduling notifications for: $taskDateTime');
      
      await _notificationService.scheduleTaskNotifications(
        taskTitle: title,
        scheduledDateTime: taskDateTime,
        taskId: taskId,
      );

      await _notificationService.scheduleMissedTaskNotification(
        taskId: taskId,
        taskTitle: title,
        scheduledDateTime: taskDateTime,
      );
      
    } catch (e, stackTrace) {
      print('❌ Error scheduling notifications: $e');
      print('Stack trace: $stackTrace');
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