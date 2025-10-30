import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  
  bool get isEditMode => taskToEdit != null;

  AddTaskController({
    required this.context,
    this.onTaskAdded,
    this.taskToEdit,
  }) {
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
    if (!validateFields()) {
      return;
    }

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

      final response = await Supabase.instance.client.from('tasks').insert({
        'date': date,
        'time': time,
        'title': title,
        'priority': selectedPriority,
        'uuid': user.id,
        'is_deleted': 'not_deleted',
        'status': 'pending',
      }).select();

      print('Insert response: $response');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task added successfully')),
        );
        onTaskAdded?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error adding task: $e');
      
      if (e is PostgrestException) {
        print('Postgrest error code: ${e.code}');
        print('Postgrest error message: ${e.message}');
        generalError = e.message ?? 'Failed to add task';
      } else {
        generalError = 'Failed to add task. Please try again.';
      }
      
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateTask() async {
    if (!validateFields()) {
      return;
    }

    final date = dateController.text.trim();
    final time = timeController.text.trim();
    final title = titleController.text.trim();
    final taskId = taskToEdit!['id'];

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
          .select();

      print('Update response: $response');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task updated successfully')),
        );
        onTaskAdded?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error updating task: $e');
      
      if (e is PostgrestException) {
        print('Postgrest error code: ${e.code}');
        print('Postgrest error message: ${e.message}');
        generalError = e.message ?? 'Failed to update task';
      } else {
        generalError = 'Failed to update task. Please try again.';
      }
      
      notifyListeners();
    } finally {
      _setLoading(false);
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