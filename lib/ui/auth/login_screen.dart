import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:textapp/provider/auth_provider.dart';
import 'package:textapp/provider/theme_provider.dart';
import 'package:textapp/ui/auth/forgotpassword_screen.dart';
import 'package:textapp/ui/bottom_navigationbar.dart';
import 'signup_screen.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final size = MediaQuery.of(context).size;
    final bool isLargeScreen = size.width > 600;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.brightness_6, color: Colors.deepPurple),
            onSelected: (value) {
              if (value == 'Light') {
                themeProvider.setTheme(ThemeMode.light);
              } else if (value == 'Dark') {
                themeProvider.setTheme(ThemeMode.dark);
              } else {
                themeProvider.setTheme(ThemeMode.system);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'Light', child: Text('Light Mode')),
              PopupMenuItem(value: 'Dark', child: Text('Dark Mode')),
              PopupMenuItem(value: 'System', child: Text('System Default')),
            ],
          ),
        ],
      ),

      // appBar: AppBar(
      //   actions: [
      //     Row(
      //       children: [
      //         const Icon(Icons.light_mode),
      //         Switch(
      //           value: isDarkMode,
      //           onChanged: (value) {
      //             themeProvider.toggleTheme(value);
      //           },
      //         ),
      //         const Icon(Icons.dark_mode),
      //         const SizedBox(width: 12),
      //       ],
      //     ),
      //   ],
      // ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isLargeScreen ? size.width * 0.25 : 24,
            vertical: isLargeScreen ? 80 : 60,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 80,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome Back',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Login to continue',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              if (provider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    provider.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),

              // Email Field
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 20),

              // Password Field
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 30),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: provider.isLoading
                      ? null
                      : () async {
                          final ctx = context; // Save context before `await`
                          await provider.login(
                            emailController.text.trim(),
                            passwordController.text.trim(),
                          );

                          if (ctx.mounted && provider.currentUser != null) {
                            Navigator.pushReplacement(
                              ctx,
                              MaterialPageRoute(
                                builder: (_) => const BottomNavScreen(),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: provider.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Sign Up Link
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SignupScreen()),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: const TextStyle(color: Colors.deepPurple),
                      children: [
                        TextSpan(
                          text: 'Sign up',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Forgot Password Link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ForgotPasswordScreen()),
                    );
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // After your Login Button
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.deepPurple),
                    ),
                  ),
                  icon: SvgPicture.asset(
                    'assets/images/google.svg',
                    height: 30,
                    width: 30,
                  ),
                  label: Text(
                    'Sign in with Google',
                    style: TextStyle(color: Colors.deepPurple, fontSize: 16),
                  ),
                  onPressed: provider.isLoading
                      ? null
                      : () async {
                          await provider.signInWithGoogle();
                          if (provider.currentUser != null) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BottomNavScreen(),
                              ),
                            );
                          }
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
