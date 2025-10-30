import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordController extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  String _token = '';
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  String _passwordError = '';
  String _confirmPasswordError = '';
  String _message = '';
  bool _isLoading = false;
  bool _isSuccess = false;

  String get token => _token;
  String get email => _email;
  String get password => _password;
  String get confirmPassword => _confirmPassword;
  String get passwordError => _passwordError;
  String get confirmPasswordError => _confirmPasswordError;
  String get message => _message;
  bool get isLoading => _isLoading;
  bool get isSuccess => _isSuccess;

  // Setters
  void setToken(String val) {
    _token = val;
    notifyListeners();
  }

  void setEmail(String val) {
    _email = val;
    notifyListeners();
  }

  void setPassword(String val) {
    _password = val;
    _validatePassword();
    notifyListeners();
  }

  void setConfirmPassword(String val) {
    _confirmPassword = val;
    _validateConfirmPassword();
    notifyListeners();
  }

  void _validatePassword() {
    if (_password.isEmpty) {
      _passwordError = 'Password cannot be empty';
    } else if (_password.length < 8) {
      _passwordError = 'Password must be at least 8 characters';
    } else if (!RegExp(r'[A-Z]').hasMatch(_password)) {
      _passwordError = 'Password must contain at least one uppercase letter';
    } else if (!RegExp(r'\d').hasMatch(_password)) {
      _passwordError = 'Password must contain at least one digit';
    } else {
      _passwordError = '';
    }
  }

  void _validateConfirmPassword() {
    if (_confirmPassword != _password) {
      _confirmPasswordError = 'Passwords do not match';
    } else {
      _confirmPasswordError = '';
    }
  }

  Future<void> resetPassword({VoidCallback? onSuccess}) async {
    _validatePassword();
    _validateConfirmPassword();

    if (_passwordError.isNotEmpty || _confirmPasswordError.isNotEmpty) {
      notifyListeners();
      return;
    }

    _isLoading = true;
    _message = '';
    _isSuccess = false;
    notifyListeners();

    try {
      // Updated Supabase reset password call
      await _supabase.auth.updateUser(
        UserAttributes(password: _password),
      );

      _message = 'Password has been reset successfully!';
      _isSuccess = true;
      
      // Call the success callback after a short delay to show the message
      if (onSuccess != null) {
        await Future.delayed(const Duration(seconds: 2));
        onSuccess();
      }
    } on AuthException catch (e) {
      _message = 'Password reset failed: ${e.message}';
      _isSuccess = false;
    } catch (e) {
      _message = 'An error occurred: $e';
      _isSuccess = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset state when leaving the screen
  @override
  void dispose() {
    _token = '';
    _email = '';
    _password = '';
    _confirmPassword = '';
    _passwordError = '';
    _confirmPasswordError = '';
    _message = '';
    _isLoading = false;
    _isSuccess = false;
    super.dispose();
  }
}