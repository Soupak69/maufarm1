import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback? onRefresh;

  const CustomAppBar({super.key, this.onRefresh});

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  final supabase = Supabase.instance.client;
  String username = '';

  @override
  void initState() {
    super.initState();
    _fetchUsername();
  }

  Future<void> _fetchUsername() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('user_profile')
        .select('username')
        .eq('id', user.id)
        .maybeSingle();

    if (response != null && mounted) {
      setState(() {
        username = response['username'] ?? '';
      });
    }
  }

  Future<void> _showTestNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'test_channel_id',
      'Test Notifications',
      channelDescription: 'Demo channel for local notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Notification Test',
      'It works! 🎉',
      details,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        username.isNotEmpty ? '${'hi'.tr()}, $username' : '',
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 169, 238, 172),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.black),
          onPressed: _showTestNotification, // ✅ Trigger notification
        ),
      ],
    );
  }
}
