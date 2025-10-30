import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../screens/auth/sign_in.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback? onRefresh;
  
  const CustomAppBar({super.key, this.onRefresh});

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> with RouteAware {
  final supabase = Supabase.instance.client;
  String username = '';

  @override
  void initState() {
    super.initState();
    _fetchUsername();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh username when navigating back to this screen
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      _fetchUsername();
    }
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

  @override
  Widget build(BuildContext context) {
    final _ = context.locale;

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
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await supabase.auth.signOut();
            if (context.mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const SignInScreen()),
              );
            }
          },
        ),
      ],
    );
  }
}
