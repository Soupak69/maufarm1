import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpController extends ChangeNotifier {
  final supabase = Supabase.instance.client;
  
  String username = '';
  String email = '';
  String password = '';
  String confirmPassword = '';

  String usernameError = '';
  String emailError = '';
  String passwordError = '';
  String confirmPasswordError = '';
  String signUpMessage = '';

  void setUsername(String val) {
    username = val;
    if (usernameError.isNotEmpty && val.isNotEmpty) {
      usernameError = '';
      notifyListeners();
    }
  }

  void setEmail(String val) {
    email = val;
    if (emailError.isNotEmpty && val.isNotEmpty) {
      emailError = '';
      notifyListeners();
    }
  }

  void setPassword(String val) {
    password = val;
    if (passwordError.isNotEmpty && val.isNotEmpty) {
      passwordError = '';
      notifyListeners();
    }
  }

  void setConfirmPassword(String val) {
    confirmPassword = val;
    if (confirmPasswordError.isNotEmpty && val.isNotEmpty) {
      confirmPasswordError = '';
      notifyListeners();
    }
  }

  bool validate() {
    emailError = '';
    passwordError = '';
    confirmPasswordError = '';
    signUpMessage = '';

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      if (email.isEmpty) emailError = 'Email is required';
      if (password.isEmpty) passwordError = 'Password is required';
      if (confirmPassword.isEmpty) confirmPasswordError = 'Please confirm your password';
      notifyListeners();
      return false;
    }

    if (!emailRegex.hasMatch(email)) {
      emailError = 'Please enter a valid email address';
      notifyListeners();
      return false;
    }

    if (password.length < 8) {
      passwordError = 'Password must be at least 8 characters';
      notifyListeners();
      return false;
    }

    if (!password.contains(RegExp(r'[A-Z]')) || !password.contains(RegExp(r'\d'))) {
      passwordError = 'Password must contain at least one uppercase letter and one digit';
      notifyListeners();
      return false;
    }

    if (confirmPassword != password) {
      confirmPasswordError = 'Passwords do not match';
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  Future<void> signUp() async {
    if (!validate()) return;

    try {
      final res = await supabase.auth.signUp(email: email, password: password);

      if (res.user != null) {
        final userId = res.user!.id;

        
        await supabase.from('user_profile').upsert({
          'id': userId,
          'username': username,
          'full_name': '',
          'created_at': DateTime.now().toIso8601String(),
        }, onConflict: 'id');

        signUpMessage = 'Registration successful! Please check your email to confirm.';

        
        username = '';
        email = '';
        password = '';
        confirmPassword = '';
        emailError = '';
        passwordError = '';
        confirmPasswordError = '';
      }
    } on AuthException catch (e) {
      signUpMessage = 'Signup failed: ${e.message}';
    } on PostgrestException catch (e) {
      signUpMessage = 'Signup succeeded, but failed to create profile: ${e.message}';
    } catch (e) {
      signUpMessage = 'Signup failed: $e';
    }

    notifyListeners();
  }
}
