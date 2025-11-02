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
  Set<int> selectedNotifications = {};
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSelectionMode
              ? '${selectedNotifications.length} selected'
              : 'Notifications',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        backgroundColor: colorScheme.surface,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actions: [
          if (!isSelectionMode)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Mark all as read',
              onPressed: _markAllAsRead,
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: isSelectionMode ? 'Delete selected' : 'Delete all',
            onPressed: _deleteSelected,
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            )
          : notifications.isEmpty
              ? Center(
                  child: Text(
                    'No notifications',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                )
              : RefreshIndicator(
                  color: colorScheme.primary,
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      final date = DateFormat('MMM d, HH:mm').format(
                        DateTime.parse(notif['created_at']),
                      );

                      final isSelected = selectedNotifications.contains(notif['id']);
                      final isRead = notif['is_read'] ?? false;

                      return GestureDetector(
                        onLongPress: () => _toggleSelection(notif['id']),
                        onTap: () {
                          if (isSelectionMode) {
                            _toggleSelection(notif['id']);
                          } else if (!isRead) {
                            _markAsRead(notif['id']);
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primary.withOpacity(0.15)
                                : colorScheme.surfaceContainerHighest.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary
                                  : isRead
                                      ? Colors.transparent
                                      : colorScheme.primaryContainer,
                              width: isRead ? 0.5 : 1.5,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Icon(
                              isRead
                                  ? Icons.notifications_none_outlined
                                  : Icons.notifications_active_outlined,
                              color: isRead
                                  ? colorScheme.onSurfaceVariant
                                  : colorScheme.primary,
                            ),
                            title: Text(
                              notif['title'] ?? '',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notif['body'] ?? '',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  date,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                            trailing: !isRead
                                ? Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
