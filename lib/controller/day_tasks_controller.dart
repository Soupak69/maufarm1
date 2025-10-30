import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TaskController extends ChangeNotifier {
  TaskController();

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
          .select()
          .eq('uuid', user.id)
          .eq('is_deleted', 'not_deleted')
          .order('date', ascending: true);

      debugPrint('Raw response: $response');
      debugPrint('Response type: ${response.runtimeType}');

      tasks = List<Map<String, dynamic>>.from(response as List);
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