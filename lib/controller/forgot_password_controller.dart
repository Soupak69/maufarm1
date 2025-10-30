import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordController extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  String _email = '';
  String _emailError = '';
  String _message = '';
  bool _isLoading = false;

  String get email => _email;
  String get emailError => _emailError;
  String get message => _message;
  bool get isLoading => _isLoading;

  void setEmail(String value) {
    _email = value;
    _validateEmail();
    notifyListeners();
  }

  void _validateEmail() {
    if (_email.isEmpty) {
      _emailError = 'Email is required';
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_email)) {
      _emailError = 'Please enter a valid email';
    } else {
      _emailError = '';
    }
  }

  Future<void> sendResetLink() async {
    _validateEmail();

    if (_emailError.isNotEmpty) {
      _message = 'Please fix the errors above';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _message = '';
    notifyListeners();

    try {
      await _supabase.auth.resetPasswordForEmail(
        _email,
        redirectTo: 'maufarm://reset-password'
      );

      _message = 'Password reset link sent! Please check your email.';
    } on AuthException catch (e) {
      _message = 'Failed to send reset link: ${e.message}';
    } catch (e) {
      _message = 'An error occurred. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}