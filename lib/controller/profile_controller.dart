import 'package:flutter/material.dart';

class ProfileControllers {
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;

  ProfileControllers()
      : usernameController = TextEditingController(),
        emailController = TextEditingController(),
        newPasswordController = TextEditingController(),
        confirmPasswordController = TextEditingController();

  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  void clearPasswordFields() {
    newPasswordController.clear();
    confirmPasswordController.clear();
  }

  void resetProfileFields(String? username, String? email) {
    usernameController.text = username ?? '';
    emailController.text = email ?? '';
  }
}