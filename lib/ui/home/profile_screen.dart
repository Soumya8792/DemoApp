import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textapp/provider/auth_provider.dart';
import 'package:textapp/provider/theme_provider.dart';
import 'package:textapp/ui/auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userData = authProvider.userData;

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.brightness_6, color: colorScheme.primary),
            onSelected: (value) {
              if (value == 'Light') {
                themeProvider.setTheme(ThemeMode.light);
              } else if (value == 'Dark') {
                themeProvider.setTheme(ThemeMode.dark);
              } else {
                themeProvider.setTheme(ThemeMode.system);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'Light', child: Text('Light Mode')),
              PopupMenuItem(value: 'Dark', child: Text('Dark Mode')),
              PopupMenuItem(value: 'System', child: Text('System Default')),
            ],
          ),
        ],
      ),
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((userData['name'] ?? '').isNotEmpty)
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: colorScheme.primary.withOpacity(0.1),
                        child: Text(
                          userData['name'][0].toUpperCase(),
                          style: textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  if ((userData['name'] ?? '').isNotEmpty)
                    Center(
                      child: Text(
                        userData['name'],
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  Center(
                    child: Text(
                      userData['email'] ?? 'No Email',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  if ((userData['mobile'] ?? '').isNotEmpty ||
                      (userData['location'] ?? '').isNotEmpty)
                    Card(
                      elevation: Theme.of(context).brightness == Brightness.dark
                          ? 3
                          : 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Theme.of(context).cardColor,
                      shadowColor:
                          Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            if ((userData['mobile'] ?? '').isNotEmpty)
                              _buildProfileRow(
                                context,
                                icon: Icons.phone,
                                label: 'Mobile',
                                value: userData['mobile'],
                              ),
                            if ((userData['mobile'] ?? '').isNotEmpty &&
                                (userData['location'] ?? '').isNotEmpty)
                              const Divider(height: 32, thickness: 1),
                            if ((userData['location'] ?? '').isNotEmpty)
                              _buildProfileRow(
                                context,
                                icon: Icons.location_on,
                                label: 'Location',
                                value: userData['location'],
                              ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final shouldLogout = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirm Logout'),
                              content: const Text(
                                'Are you sure you want to logout?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('No'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Yes'),
                                ),
                              ],
                            ),
                          );

                          if (shouldLogout == true) {
                            try {
                              await authProvider.logout();
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => LoginScreen(),
                                ),
                                (Route<dynamic> route) => false,
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Logout failed: $e')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text("Logout"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: colorScheme.primary),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
        ),
        Expanded(child: Text(value, style: textTheme.bodyMedium)),
      ],
    );
  }
}
