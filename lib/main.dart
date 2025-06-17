import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:provider/provider.dart';
import 'package:textapp/firebase_options.dart';
import 'package:textapp/provider/auth_provider.dart' as myAuth;
import 'package:textapp/provider/chat_provider.dart';
import 'package:textapp/provider/home_provider.dart';
import 'package:textapp/provider/theme_provider.dart';
import 'package:textapp/ui/auth/login_screen.dart';
import 'package:textapp/ui/bottom_navigationbar.dart';
import 'package:textapp/ui/home/chat_message.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kIsWeb) {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  }

  if (!kIsWeb) {
    final dir = await path_provider.getApplicationDocumentsDirectory();
    await Hive.initFlutter(dir.path);
  } else {
    await Hive.initFlutter();
  }

  Hive.registerAdapter(ChatMessageAdapter());
  if (!Hive.isBoxOpen('chat_messages')) {
    await Hive.openBox<ChatMessage>('chat_messages');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => myAuth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ImageGeneratorProvider()),
        ChangeNotifierProxyProvider<ImageGeneratorProvider, ChatProvider>(
          create: (context) =>
              ChatProvider(context.read<ImageGeneratorProvider>()),
          update: (context, imageProvider, previous) =>
              ChatProvider(imageProvider),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'TextApp',
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: themProvider.themeMode,
            home: const MainPage(),
          );
        },
      ),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const BottomNavScreen();
        } else {
          return LoginScreen();
        }
      },
    );
  }
}

// class MainPage extends StatefulWidget {
//   const MainPage({super.key});

//   @override
//   State<MainPage> createState() => _MainPageState();
// }

// class _MainPageState extends State<MainPage> {
//   bool _isLoading = true;
//   bool _isLoggedIn = false;

//   @override
//   void initState() {
//     super.initState();
//     _checkLogin();
//   }

//   Future<void> _checkLogin() async {
//     final prefs = await SharedPreferences.getInstance();
//     final storedToken = prefs.getString('user_token');
//     final user = FirebaseAuth.instance.currentUser;

//     if (user != null && storedToken != null && storedToken.isNotEmpty) {
//       print("✅ Stored token: $storedToken");

//       final authProvider = Provider.of<myAuth.AuthProvider>(
//         context,
//         listen: false,
//       );
//       await authProvider
//           .fetchUserProfile(); // refresh userData and token if needed

//       setState(() {
//         _isLoggedIn = true;
//       });
//     } else {
//       setState(() {
//         _isLoggedIn = false;
//       });
//     }

//     setState(() {
//       _isLoading = false;
//     });
//   }

//   // Future<void> _checkLogin() async {
//   //   final authProvider = Provider.of<myAuth.AuthProvider>(
//   //     context,
//   //     listen: false,
//   //   );
//   //   final user = FirebaseAuth.instance.currentUser;

//   //   if (user != null) {
//   //     await authProvider.fetchUserProfile();

//   //     if (authProvider.userData != null) {
//   //       setState(() {
//   //         _isLoggedIn = true;
//   //       });
//   //     } else {
//   //       setState(() {
//   //         _isLoggedIn = false;
//   //       });
//   //     }
//   //   } else {
//   //     setState(() {
//   //       _isLoggedIn = false;
//   //     });
//   //   }

//   //   setState(() {
//   //     _isLoading = false;
//   //   });
//   // }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }

//     if (_isLoggedIn) {
//       return BottomNavScreen();
//     } else {
//       return LoginScreen();
//     }
//   }
// }
