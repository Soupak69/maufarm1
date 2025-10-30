import 'package:flutter/material.dart';
import '../../controller/reset_password_controller.dart';
import '../../screens/auth/sign_in.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? token;
  final String? email;

  const ResetPasswordScreen({
    super.key,
    this.token,
    this.email,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _controller = ResetPasswordController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Set token and email if provided from deep link
    if (widget.token != null) _controller.setToken(widget.token!);
    if (widget.email != null) _controller.setEmail(widget.email!);
    
    _passwordController.addListener(() {
      _controller.setPassword(_passwordController.text);
    });
    _confirmPasswordController.addListener(() {
      _controller.setConfirmPassword(_confirmPasswordController.text);
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 179, 245, 181)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_passwordController.text != _controller.password) {
              _passwordController.text = _controller.password;
              _passwordController.selection = TextSelection.collapsed(offset: _passwordController.text.length);
            }
            if (_confirmPasswordController.text != _controller.confirmPassword) {
              _confirmPasswordController.text = _controller.confirmPassword;
              _confirmPasswordController.selection = TextSelection.collapsed(offset: _confirmPasswordController.text.length);
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/maufarm_logo.png',
                      height: 225,
                      width: 500,
                      alignment: Alignment.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Reset Password',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 25,
                      fontFamily: 'Poppins',
                      color: Color.fromARGB(255, 179, 245, 181),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Enter your new password below.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Show email if available
                  if (widget.email != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        'Email: ${widget.email}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),

                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      labelStyle: const TextStyle(color: Color.fromARGB(255, 179, 245, 181)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                        borderSide: const BorderSide(color: Color.fromARGB(255, 179, 245, 181), width: 2.0),
                      ),
                      helperText: '\u2022 Password must be at least 8 characters\n'
                                  '\u2022 Must contain at least one uppercase letter\n'
                                  '\u2022 Must contain at least one digit',
                      helperStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      helperMaxLines: 5,
                      errorText: _controller.passwordError.isEmpty ? null : _controller.passwordError,
                      errorMaxLines: 3,
                    ),
                    obscureText: true,
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      labelStyle: const TextStyle(color: Color.fromARGB(255, 179, 245, 181)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                        borderSide: const BorderSide(color: Color.fromARGB(255, 179, 245, 181), width: 2.0),
                      ),
                      errorText: _controller.confirmPasswordError.isEmpty ? null : _controller.confirmPasswordError,
                      errorMaxLines: 3,
                    ),
                    obscureText: true,
                  ),

                  const SizedBox(height: 30),

                  Center(
                    child: ElevatedButton(
                      onPressed: _controller.isLoading 
                          ? null 
                          : () {
                              _controller.resetPassword(
                                onSuccess: () {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (context) => const SignInScreen(),
                                    ),
                                    (route) => false,
                                  );
                                },
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 179, 245, 181),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                      ),
                      child: _controller.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Reset Password'),
                    ),
                  ),

                  if (_controller.message.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Center(
                        child: Text(
                          _controller.message,
                          style: TextStyle(
                            color: _controller.isSuccess
                                ? Colors.green
                                : Colors.red,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}