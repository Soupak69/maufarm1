import 'package:flutter/material.dart';
import '../../screens/auth/reset_password.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

class DeepLinkHandler {
  static StreamSubscription<Uri>? _subscription;

  static void configDeepLink(BuildContext context) {
    final appLinks = AppLinks();

    _subscription?.cancel();

    _subscription = appLinks.uriLinkStream.listen(
      (uri) {
        _handleDeepLink(context, uri);
      },
      onError: (error) {
        debugPrint('Deep link error: $error');
      },
    );
  }

  static void _handleDeepLink(BuildContext context, Uri uri) {
    if (uri.host == 'reset-password') {
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ResetPasswordScreen(),
          ),
        );
      }
    }
  }


  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}