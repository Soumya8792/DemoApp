import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textapp/provider/auth_provider.dart';
import 'package:textapp/ui/auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.userData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).pop(false), // User pressed No
                      child: const Text('No'),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).pop(true), // User pressed Yes
                      child: const Text('Yes'),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                try {
                  await authProvider.logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                    (Route<dynamic> route) => false,
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
                }
              }
            },
          ),
        ],
      ),
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Column(
                children: [
                  if ((userData['name'] ?? '').isNotEmpty)
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.deepPurple.shade100,
                      child: Text(
                        userData['name'][0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                  if ((userData['name'] ?? '').isNotEmpty)
                    const SizedBox(height: 24),

                  // Name (only if not empty)
                  if ((userData['name'] ?? '').isNotEmpty)
                    Text(
                      userData['name'],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Always show email
                  Text(
                    userData['email'] ?? 'No Email',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  ),

                  const SizedBox(height: 32),

                  // Details card (only if mobile or location exists)
                  if ((userData['mobile'] ?? '').isNotEmpty ||
                      (userData['location'] ?? '').isNotEmpty)
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            if ((userData['mobile'] ?? '').isNotEmpty)
                              _buildProfileRow(
                                icon: Icons.phone,
                                label: 'Mobile',
                                value: userData['mobile'],
                              ),
                            if ((userData['mobile'] ?? '').isNotEmpty &&
                                (userData['location'] ?? '').isNotEmpty)
                              const Divider(height: 32, thickness: 1),
                            if ((userData['location'] ?? '').isNotEmpty)
                              _buildProfileRow(
                                icon: Icons.location_on,
                                label: 'Location',
                                value: userData['location'],
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepPurple),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.deepPurple,
            fontSize: 16,
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
      ],
    );
  }
}
