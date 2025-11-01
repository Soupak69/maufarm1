import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _supabase = Supabase.instance.client;

  // Initialize notification plugin
  Future<void> initialize() async {
    tz.initializeTimeZones();

    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onNotificationTapped,
    );
  }

  // When user taps a notification
  void _onNotificationTapped(NotificationResponse response) async {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      final taskId = int.tryParse(payload.split('-').first ?? '');
      if (taskId != null) {
        await _supabase
            .from('notifications')
            .update({'is_triggered': true})
            .eq('task_id', taskId);
        print('🔔 Notification $taskId marked as triggered');
      }
    }
  }

  // Save notification to Supabase when scheduled
  Future<void> _saveNotificationToSupabase({
    required int taskId,
    required String title,
    required String body,
    required String notificationType,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('notifications').insert({
        'user_id': userId,
        'task_id': taskId,
        'title': title,
        'body': body,
        'notification_type': notificationType,
        'is_read': false,
        'is_deleted': false,
        'is_triggered': false,
        'created_at': DateTime.now().toIso8601String(),
      });
      print('📝 Saved notification to Supabase');
    } catch (e) {
      print('❌ Error saving notification to Supabase: $e');
    }
  }

  // Schedule task notifications (30, 15, 5 mins before + main)
  Future<void> scheduleTaskNotifications({
    required String taskTitle,
    required DateTime scheduledDateTime,
    required int taskId,
  }) async {
    try {
      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'task_channel_id',
          'Task Notifications',
          channelDescription: 'Reminders for your tasks',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'Task Reminder',
        ),
        iOS: DarwinNotificationDetails(),
      );

      final now = DateTime.now();

      Future<void> schedule(int offsetMinutes, int idOffset, String label) async {
        final reminderTime =
            scheduledDateTime.subtract(Duration(minutes: offsetMinutes));
        if (reminderTime.isAfter(now)) {
          final tzTime = tz.TZDateTime.from(reminderTime, tz.local);
          await flutterLocalNotificationsPlugin.zonedSchedule(
            taskId + idOffset,
            'Task Reminder',
            '$taskTitle ($label)',
            tzTime,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: '$taskId-$label',
          );

          await _saveNotificationToSupabase(
            taskId: taskId,
            title: 'Task Reminder',
            body: '$taskTitle ($label)',
            notificationType: label,
          );

          // Auto-mark as triggered when time arrives
          final delay = reminderTime.difference(now);
          Future.delayed(delay, () async {
            try {
              await _supabase
                  .from('notifications')
                  .update({'is_triggered': true})
                  .eq('task_id', taskId)
                  .eq('notification_type', label);
              print('🔔 Notification $taskId ($label) triggered at $reminderTime');
            } catch (e) {
              print('❌ Failed to mark triggered: $e');
            }
          });

          print('✅ Scheduled $label notification for task $taskId at $tzTime');
        }
      }

      await schedule(30, 3000000, '30min');
      await schedule(15, 2000000, '15min');
      await schedule(5, 1000000, '5min');

      // Main notification
      if (scheduledDateTime.isAfter(now)) {
        final tzScheduledDate = tz.TZDateTime.from(scheduledDateTime, tz.local);
        await flutterLocalNotificationsPlugin.zonedSchedule(
          taskId,
          'Task Reminder',
          taskTitle,
          tzScheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: '$taskId-main',
        );

        await _saveNotificationToSupabase(
          taskId: taskId,
          title: 'Task Reminder',
          body: taskTitle,
          notificationType: 'main',
        );

        final delay = scheduledDateTime.difference(now);
        Future.delayed(delay, () async {
          try {
            await _supabase
                .from('notifications')
                .update({'is_triggered': true})
                .eq('task_id', taskId)
                .eq('notification_type', 'main');
            print('🔔 Main notification $taskId triggered at $scheduledDateTime');
          } catch (e) {
            print('❌ Failed to mark main triggered: $e');
          }
        });

        print('✅ Scheduled main notification for task $taskId at $tzScheduledDate');
      }
    } catch (e, stackTrace) {
      print('❌ Error scheduling notifications: $e');
      print(stackTrace);
    }
  }

  // 🧹 NEW: Cancel all local + Supabase notifications for a task
  Future<void> removeTaskNotifications(int taskId) async {
    try {
      // Cancel all local notifications
      for (final offset in [0, 1000000, 2000000, 3000000, 4000000]) {
        await flutterLocalNotificationsPlugin.cancel(taskId + offset);
      }

      // Soft-delete from Supabase
      await _supabase
          .from('notifications')
          .update({'is_deleted': true})
          .eq('task_id', taskId);

      print('🗑️ Removed notifications for task $taskId (local + Supabase)');
    } catch (e) {
      print('❌ Error removing task notifications: $e');
    }
  }

  // 🗂️ Stream triggered + active notifications
  Stream<List<Map<String, dynamic>>> getNotifications() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
      return (data as List)
          .where((n) =>
              n['user_id'] == userId &&
              n['is_deleted'] == false &&
              n['is_triggered'] == true)
          .cast<Map<String, dynamic>>()
          .toList();
    });
  }

  // Mark notification(s) as read or deleted
  Future<void> markAsRead(int id) async {
    await _supabase.from('notifications').update({'is_read': true}).eq('id', id);
  }

  Future<void> markAllAsRead() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_deleted', false);
  }

  Future<void> deleteNotification(int id) async {
    await _supabase.from('notifications').update({'is_deleted': true}).eq('id', id);
  }

  Future<void> clearAllNotifications() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _supabase
        .from('notifications')
        .update({'is_deleted': true})
        .eq('user_id', userId);
  }
}


