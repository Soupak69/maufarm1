import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class NotificationReceivedScreen extends StatefulWidget {
  const NotificationReceivedScreen({super.key});

  @override
  State<NotificationReceivedScreen> createState() => _NotificationReceivedScreenState();
}

class _NotificationReceivedScreenState extends State<NotificationReceivedScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  Set<int> selectedNotifications = {}; // store IDs of selected notifications
  bool isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('notifications')
        .select('*')
        .eq('user_id', user.id)
        .eq('is_deleted', false)
        .eq('is_triggered', true)
        .order('created_at', ascending: false);

    setState(() {
      notifications = List<Map<String, dynamic>>.from(response);
      isLoading = false;
      // reset selection mode if list reloads
      selectedNotifications.clear();
      isSelectionMode = false;
    });
  }

  Future<void> _markAsRead(int id) async {
    await supabase.from('notifications').update({'is_read': true}).eq('id', id);
    await _loadNotifications();
  }

  Future<void> _markAllAsRead() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', user.id)
        .eq('is_deleted', false);
    await _loadNotifications();
  }

  Future<void> _deleteSelected() async {
    if (selectedNotifications.isEmpty) {
      await _clearAll();
      return;
    }

    await supabase
        .from('notifications')
        .update({'is_deleted': true})
        .inFilter('id', selectedNotifications.toList());
    await _loadNotifications();
  }

  Future<void> _clearAll() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    await supabase
        .from('notifications')
        .update({'is_deleted': true})
        .eq('user_id', user.id);
    await _loadNotifications();
  }

  void _toggleSelection(int id) {
    setState(() {
      if (selectedNotifications.contains(id)) {
        selectedNotifications.remove(id);
        if (selectedNotifications.isEmpty) isSelectionMode = false;
      } else {
        selectedNotifications.add(id);
        isSelectionMode = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isSelectionMode
            ? '${selectedNotifications.length} selected'
            : 'Notifications'),
        actions: [
          if (!isSelectionMode)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Mark all as read',
              onPressed: _markAllAsRead,
            ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: isSelectionMode ? 'Delete selected' : 'Delete all',
            onPressed: _deleteSelected,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? const Center(child: Text('No notifications'))
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      final date = DateFormat('MMM d, HH:mm').format(
                        DateTime.parse(notif['created_at']),
                      );

                      final isSelected = selectedNotifications.contains(notif['id']);

                      return GestureDetector(
                        onLongPress: () => _toggleSelection(notif['id']),
                        onTap: () {
                          if (isSelectionMode) {
                            _toggleSelection(notif['id']);
                          } else {
                            if (!notif['is_read']) _markAsRead(notif['id']);
                          }
                        },
                        child: Container(
                          color: isSelected
                              ? Colors.blue.withOpacity(0.2)
                              : Colors.transparent,
                          child: ListTile(
                            leading: Icon(
                              notif['is_read']
                                  ? Icons.notifications_none
                                  : Icons.notifications_active,
                              color: notif['is_read'] ? Colors.grey : Colors.green,
                            ),
                            title: Text(notif['title']),
                            subtitle: Text('${notif['body']}\n$date'),
                            isThreeLine: true,
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
