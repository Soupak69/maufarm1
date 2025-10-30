import 'package:flutter/material.dart';
import '../../services/google_auth_service.dart';
import '../../controller/sign_in_controller.dart';
import '../../widgets/bottom_navigation.dart';
import '../auth/sign_up.dart';
import '../auth/forgot_password.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final SignInController _controller = SignInController();
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  bool _loading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _loading = true);

    try {
      await _googleAuthService.signInWithGoogle();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed in successfully!')),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const BottomNavigation ()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleEmailSignIn() async {
    setState(() => _loading = true);
    await _controller.signIn(context);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 179, 245, 181),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/maufarm_logo.png', width: 200),
                const SizedBox(height: 20),

                const Text(
                  'Welcome',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to continue',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 30),

                // Email field
                TextField(
                  onChanged: (val) => setState(() => _controller.setEmail(val)),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    errorText: _controller.emailError.isNotEmpty
                        ? _controller.emailError
                        : null,
                  ),
                ),
                const SizedBox(height: 12),

                // Password field
                TextField(
                  obscureText: true,
                  onChanged: (val) =>
                      setState(() => _controller.setPassword(val)),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    errorText: _controller.passwordError.isNotEmpty
                        ? _controller.passwordError
                        : null,
                  ),
                ),
                const SizedBox(height: 8),

                // Forgot Password Link
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                      );
                    },
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Email/Password Sign-In Button
                ElevatedButton(
                  onPressed: _loading ? null : _handleEmailSignIn,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child:
                       const Text('Sign in with Email'),
                ),

                const SizedBox(height: 20),
                const Text('or', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),

                // Google Sign-In Button
                     ElevatedButton.icon(
                        onPressed: _handleGoogleSignIn,
                        icon: Image.asset(
                          'assets/maufarm_logo.png',
                          height: 24,
                        ),
                        label: const Text('Sign in with Google'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          minimumSize: const Size(double.infinity, 50),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                        onTap: () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SignUpScreen()),
                          );
                        },
                        child: const Text(
                          "No account? Sign up",
                          style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                          fontSize: 16,
                          ),
                        ),
                        ),

                if (_controller.signInMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _controller.signInMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
