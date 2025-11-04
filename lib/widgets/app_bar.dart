import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/notification/notification_received.dart';
import 'package:easy_localization/easy_localization.dart';

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
  bool hasUnread = false;
  StreamSubscription<List<Map<String, dynamic>>>? _notificationSub;

  @override
  void initState() {
    super.initState();
    _fetchUsername();
    _checkUnreadNotifications();
    _listenToNotifications(); 
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    super.dispose();
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

Future<void> _checkUnreadNotifications() async {
  final user = supabase.auth.currentUser;
  if (user == null) return;

  final response = await supabase
      .from('notifications')
      .select('id')
      .eq('user_id', user.id)
      .eq('is_read', false)
      .eq('is_deleted', false)
      .eq('is_triggered', true); 
  final data = List<Map<String, dynamic>>.from(response);

  if (mounted) {
    setState(() {
      hasUnread = data.isNotEmpty;
    });
  }
}

void _listenToNotifications() {
  final user = supabase.auth.currentUser;
  if (user == null) return;

  _notificationSub = supabase
      .from('notifications:user_id=eq.${user.id}')
      .stream(primaryKey: ['id'])
      .listen((data) {
    final activeNotifications = (data as List)
        .where((n) => n['is_deleted'] == false && n['is_triggered'] == true) 
        .toList();

    final unreadExists = activeNotifications.any((n) => n['is_read'] == false);

    if (mounted) {
      setState(() => hasUnread = unreadExists);
    }
  });
}


  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color.fromARGB(255, 124, 170, 126),
      title: Text(
        username.isNotEmpty ? '${'hi'.tr()}, $username' : '',
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.black),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationReceivedScreen()),
                );
                await _checkUnreadNotifications(); 
              },
            ),
            if (hasUnread)
              const Positioned(
                right: 10,
                top: 10,
                child: CircleAvatar(
                  radius: 5,
                  backgroundColor: Colors.redAccent,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
