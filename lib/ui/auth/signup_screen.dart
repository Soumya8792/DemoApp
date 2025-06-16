import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:textapp/provider/auth_provider.dart' as myAuth;
import 'package:textapp/ui/bottom_navigationbar.dart';

class SignupScreen extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<myAuth.AuthProvider>(context);
    final size = MediaQuery.of(context).size;
    final bool isLargeScreen = size.width > 600;

    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up'), centerTitle: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isLargeScreen ? size.width * 0.2 : 24,
          vertical: isLargeScreen ? 40 : 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 200,
              child: Lottie.asset(
                'assets/animation/signup.json',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Text('Failed to load animation')),
              ),
            ),

            Center(
              child: Text(
                'Create Account',
                style: TextStyle(
                  fontSize: isLargeScreen ? 32 : 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (provider.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  provider.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),

            _buildTextField(nameController, 'Full Name', Icons.person),
            const SizedBox(height: 16),
            _buildTextField(
              mobileController,
              'Mobile Number',
              Icons.phone,
              type: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              emailController,
              'Email',
              Icons.email,
              type: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildTextField(locationController, 'Location', Icons.location_on),
            const SizedBox(height: 16),
            _buildTextField(
              passwordController,
              'Password',
              Icons.lock,
              isPassword: true,
            ),
            const SizedBox(height: 30),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: provider.isLoading
                    ? null
                    : () async {
                        final name = nameController.text.trim();
                        final mobile = mobileController.text.trim();
                        final email = emailController.text.trim();
                        final location = locationController.text.trim();
                        final password = passwordController.text.trim();

                        if (name.isEmpty &&
                            mobile.isEmpty &&
                            email.isEmpty &&
                            location.isEmpty &&
                            password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All fields are required'),
                            ),
                          );
                          return;
                        } else if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Name is required')),
                          );
                          return;
                        } else if (mobile.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Mobile number is required'),
                            ),
                          );
                          return;
                        } else if (email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Email is required')),
                          );
                          return;
                        } else if (location.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Location is required'),
                            ),
                          );
                          return;
                        } else if (password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password is required'),
                            ),
                          );
                          return;
                        }

                        await provider.signupWithExtraFields(
                          name: name,
                          mobile: mobile,
                          email: email,
                          location: location,
                          password: password,
                        );
                        final user = FirebaseAuth.instance.currentUser;
                        final token = await user?.getIdToken();

                        if (token != null && token.isNotEmpty) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BottomNavScreen(),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(provider.errorMessage!)),
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
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: isLargeScreen ? 20 : 16,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: type,
      obscureText: isPassword,
    );
  }
}
