import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../main.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

 
  Future<void> initialize() async {
    tz.initializeTimeZones();
  }

  
  String parseTimeToHHMM(String time) {
    try {
      
      final timeParts = time.trim().split(' ');
      if (timeParts.length == 2) {
        final hourMinute = timeParts[0].split(':');
        int hour = int.parse(hourMinute[0]);
        final minute = hourMinute.length > 1 ? hourMinute[1] : '00';
        final period = timeParts[1].toUpperCase();

        if (period == 'PM' && hour != 12) {
          hour += 12;
        } else if (period == 'AM' && hour == 12) {
          hour = 0;
        }

        return '${hour.toString().padLeft(2, '0')}:$minute:00';
      }
      
      
      return time.contains(':') ? '$time:00' : time;
    } catch (e) {
      print('Error parsing time: $e');
      return time;
    }
  }

  
  Future<void> scheduleTaskNotifications({
    required String taskTitle,
    required DateTime scheduledDateTime,
    required int taskId,
    String? priority,
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

      
      final thirtyMinBefore = scheduledDateTime.subtract(const Duration(minutes: 30));
      if (thirtyMinBefore.isAfter(now)) {
        final tzThirtyMinutesBefore = tz.TZDateTime.from(thirtyMinBefore, tz.local);
        await flutterLocalNotificationsPlugin.zonedSchedule(
          taskId + 3000000, 
          'Task Reminder',
          '$taskTitle (in 30 minutes)',
          tzThirtyMinutesBefore,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

          payload: '$taskId-30min',
        );
        print('✅ Scheduled 30-min notification for task $taskId at $tzThirtyMinutesBefore');
      } else {
        print('⏭️ Skipped 30-min notification (time already passed)');
      }

      
      final fifteenMinBefore = scheduledDateTime.subtract(const Duration(minutes: 15));
      if (fifteenMinBefore.isAfter(now)) {
        final tzFifteenMinutesBefore = tz.TZDateTime.from(fifteenMinBefore, tz.local);
        await flutterLocalNotificationsPlugin.zonedSchedule(
          taskId + 2000000, 
          'Task Reminder',
          '$taskTitle (in 15 minutes)',
          tzFifteenMinutesBefore,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: '$taskId-15min',
        );
        print('✅ Scheduled 15-min notification for task $taskId at $tzFifteenMinutesBefore');
      } else {
        print('⏭️ Skipped 15-min notification (time already passed)');
      }


      final fiveMinBefore = scheduledDateTime.subtract(const Duration(minutes: 5));
      if (fiveMinBefore.isAfter(now)) {
        final tzFiveMinutesBefore = tz.TZDateTime.from(fiveMinBefore, tz.local);
        await flutterLocalNotificationsPlugin.zonedSchedule(
          taskId + 1000000, 
          'Task Reminder',
          '$taskTitle (in 5 minutes)',
          tzFiveMinutesBefore,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: '$taskId-5min',
        );
        print('✅ Scheduled 5-min notification for task $taskId at $tzFiveMinutesBefore');
      } else {
        print('⏭️ Skipped 5-min notification (time already passed)');
      }

      
      if (scheduledDateTime.isAfter(now)) {
        final tzScheduledDate = tz.TZDateTime.from(scheduledDateTime, tz.local);
        await flutterLocalNotificationsPlugin.zonedSchedule(
          taskId,
          'Task Reminder',
          taskTitle,
          tzScheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: '$taskId',
        );
        print('✅ Scheduled main notification for task $taskId at $tzScheduledDate');
      } else {
        print('⏭️ Skipped main notification (time already passed)');
      }

      print('🔔 All notifications scheduled successfully for task $taskId');
    } catch (e, stackTrace) {
      print('❌ Error scheduling notifications: $e');
      print('Stack trace: $stackTrace');
    
    }
  }

  
Future<void> scheduleMissedTaskNotification({
  required int taskId,
  required String taskTitle,
  required DateTime scheduledDateTime,
}) async {
  try {
    final missedTime = scheduledDateTime.add(const Duration(minutes: 30));
    final now = DateTime.now();

    if (missedTime.isBefore(now)) {
      print('⏭️ Skipped missed-task check for $taskId (already past)');
      return;
    }

    final tzMissedTime = tz.TZDateTime.from(missedTime, tz.local);

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'missed_task_channel',
        'Missed Tasks',
        channelDescription: 'Notifies if a task remains pending 30 mins after its time',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'Missed Task Reminder',
      ),
      iOS: DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      taskId + 4000000, 
      'Missed Task',
      'You missed your task: $taskTitle',
      tzMissedTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: '$taskId-missed',
    );

    print('🕒 Scheduled missed-task check for $taskId at $tzMissedTime');
  } catch (e, stackTrace) {
    print('❌ Error scheduling missed-task notification: $e');
    print('Stack trace: $stackTrace');
  }
}


  Future<void> cancelTaskNotifications(int taskId) async {
    try {
      await flutterLocalNotificationsPlugin.cancel(taskId);
      await flutterLocalNotificationsPlugin.cancel(taskId + 1000000); 
      await flutterLocalNotificationsPlugin.cancel(taskId + 2000000); 
      await flutterLocalNotificationsPlugin.cancel(taskId + 3000000); 
      await flutterLocalNotificationsPlugin.cancel(taskId + 4000000);
      print('🗑️ Cancelled all notifications for task $taskId');
    } catch (e) {
      print('❌ Error cancelling notifications: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
      print('🗑️ Cancelled all notifications');
    } catch (e) {
      print('❌ Error cancelling all notifications: $e');
    }
  }
}