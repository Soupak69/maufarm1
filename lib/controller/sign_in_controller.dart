import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/bottom_navigation.dart';

class SignInController extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  String email = '';
  String password = '';

  String emailError = '';
  String passwordError = '';
  String signInMessage = '';

  void setEmail(String val) {
    email = val;
    if (emailError.isNotEmpty && val.isEmpty) {
      emailError = '';
      notifyListeners();
    }
  }

  void setPassword(String val) {
    password = val;
    if (passwordError.isNotEmpty && val.isEmpty) {
      passwordError = '';
      notifyListeners();
    }
  }



  bool validate() {
    emailError = '';
    passwordError = '';
    signInMessage = '';

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (email.isEmpty || password.isEmpty) {
      if (email.isEmpty) emailError = 'Email is required';
      if (password.isEmpty) passwordError = 'Password is required';
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

    notifyListeners();
    return true;
  }

  Future<void> signIn(BuildContext context) async {
  if (!validate()) return;

  try {
    final res = await supabase.auth.signInWithPassword(email: email, password: password);
    if (res.user != null) {
      signInMessage = '';
      email = '';
      password = '';
      emailError = '';
      passwordError = '';

      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const BottomNavigation()),
      );
    }
  } catch (e) {
    signInMessage = 'SignIn failed';
  }

  notifyListeners();
}
}