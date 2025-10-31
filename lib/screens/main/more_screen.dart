import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/app_bar.dart';
import '../../screens/more_screens/settings.dart';
import '../../screens/more_screens/profile.dart';
import '../../screens/auth/sign_in.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: const CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile
            _buildTile(
              context,
              icon: Icons.person,
              title: 'profile'.tr(),
              showChevron: true,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
                setState(() {});
              },
            ),
            const SizedBox(height: 12.0),

            // Settings
            _buildTile(
              context,
              icon: Icons.settings,
              title: 'settings'.tr(),
              showChevron: true,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
                setState(() {});
              },
            ),
            const SizedBox(height: 12.0),

            // Sign Out (no chevron)
            _buildTile(
              context,
              icon: Icons.logout,
              title: 'sign_out'.tr(),
              iconColor: Colors.redAccent,
              textColor: Colors.redAccent,
              showChevron: false, // 👈 removed chevron
              onTap: () async {
                await supabase.auth.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const SignInScreen()),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showChevron = true,
    Color? iconColor,
    Color? textColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? colorScheme.onSurface),
            const SizedBox(width: 16.0),
            Text(
              title,
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
                color: textColor ?? colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            if (showChevron)
              Icon(Icons.chevron_right, color: colorScheme.onSurface),
          ],
        ),
      ),
    );
  }
}
