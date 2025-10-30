import 'package:flutter/material.dart';
import '../../controller/sign_up_controller.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _controller = SignUpController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    _usernameController.addListener(() {
      _controller.setUsername(_usernameController.text);
    });
    _emailController.addListener(() {
      _controller.setEmail(_emailController.text);
    });
    _passwordController.addListener(() {
      _controller.setPassword(_passwordController.text);
    });
    _confirmPasswordController.addListener(() {
      _controller.setConfirmPassword(_confirmPasswordController.text);
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose(); 
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_usernameController.text != _controller.username) {
              _usernameController.text = _controller.username;
              _usernameController.selection = TextSelection.collapsed(offset: _usernameController.text.length);
            }
            if (_emailController.text != _controller.email) {
              _emailController.text = _controller.email;
              _emailController.selection = TextSelection.collapsed(offset: _emailController.text.length);
            }
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
                    'Create your account',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 25,
                      fontFamily: 'Poppins',
                      color:  Color.fromARGB(255, 179, 245, 181),
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: const TextStyle(color: Color.fromARGB(255, 179, 245, 181)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color:  Color.fromARGB(255, 179, 245, 181), width: 2.0),
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      errorText: _controller.usernameError.isEmpty ? null : _controller.usernameError,
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Color.fromARGB(255, 179, 245, 181)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color:  Color.fromARGB(255, 179, 245, 181), width: 2.0),
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      errorText: _controller.emailError.isEmpty ? null : _controller.emailError,
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color:  Color.fromARGB(255, 179, 245, 181)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                        borderSide: const BorderSide(color:  Color.fromARGB(255, 179, 245, 181), width: 2.0),
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
                      labelStyle: const TextStyle(color:  Color.fromARGB(255, 179, 245, 181)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                        borderSide: const BorderSide(color:  Color.fromARGB(255, 179, 245, 181), width: 2.0),
                      ),
                      errorText: _controller.confirmPasswordError.isEmpty ? null : _controller.confirmPasswordError,
                      errorMaxLines: 3,
                    ),
                    obscureText: true,
                  ),

                  const SizedBox(height: 30),

                  Center(
                    child: ElevatedButton(
                      onPressed: () => _controller.signUp(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 179, 245, 181),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                      ),
                      child: const Text(
                        'Sign Up',
                      ),
                    ),
                  ),

                  if (_controller.signUpMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Center(
                        child: Text(
                          _controller.signUpMessage,
                          style: TextStyle(
                            color: _controller.signUpMessage.startsWith('Signup failed') ? Colors.red : Colors.green,
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