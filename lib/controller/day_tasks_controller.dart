import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/notification_service.dart'; 

class TaskController extends ChangeNotifier {
  TaskController();

  final NotificationService _notificationService = NotificationService(); 
  List<Map<String, dynamic>> tasks = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadTasks() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint('No user signed in.');
        tasks = [];
        isLoading = false;
        notifyListeners();
        return;
      }

      debugPrint('Loading tasks for user: ${user.id}');

      final response = await Supabase.instance.client
          .from('tasks')
          .select('*, fields(name)')
          .eq('uuid', user.id)
          .eq('is_deleted', 'not_deleted')
          .order('date', ascending: true);

      debugPrint('Raw response: $response');
      debugPrint('Response type: ${response.runtimeType}');

     
      tasks = (response as List).map<Map<String, dynamic>>((task) {
        final taskMap = Map<String, dynamic>.from(task);
        
       
        if (taskMap['fields'] != null && taskMap['fields'] is Map) {
          final fieldData = taskMap['fields'] as Map<String, dynamic>;
          taskMap['field_name'] = fieldData['name'];
        }
        
        
        taskMap.remove('fields');
        
        return taskMap;
      }).toList();
      
      debugPrint('Loaded ${tasks.length} tasks: $tasks');
    } catch (e, stackTrace) {
      debugPrint('Error loading tasks: $e');
      debugPrint('Stack trace: $stackTrace');
      errorMessage = e.toString();
      tasks = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTaskStatus(int taskId, bool isDone) async {
    try {
      debugPrint('Updating task $taskId status to: ${isDone ? "done" : "pending"}');

      await Supabase.instance.client
          .from('tasks')
          .update({'status': isDone ? 'done' : 'pending'})
          .eq('id', taskId);

      final taskIndex = tasks.indexWhere((task) => task['id'] == taskId);
      if (taskIndex != -1) {
        tasks[taskIndex]['status'] = isDone ? 'done' : 'pending';
        notifyListeners();
      }

      
      if (isDone) {
        await _notificationService.removeTaskNotifications(taskId);
        debugPrint('🛑 Removed notifications for completed task $taskId');
      }

      debugPrint('Task status updated successfully');
    } catch (e, stackTrace) {
      debugPrint('Error updating task status: $e');
      debugPrint('Stack trace: $stackTrace');
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteTask(int taskId) async {
    try {
      debugPrint('Deleting task $taskId');

      await Supabase.instance.client
          .from('tasks')
          .update({'is_deleted': 'deleted'})
          .eq('id', taskId);

      tasks.removeWhere((task) => task['id'] == taskId);
      notifyListeners();

      
      await _notificationService.removeTaskNotifications(taskId);
      debugPrint('🗑️ Removed notifications for deleted task $taskId');

      debugPrint('Task deleted successfully');
    } catch (e, stackTrace) {
      debugPrint('Error deleting task: $e');
      debugPrint('Stack trace: $stackTrace');
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}