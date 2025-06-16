import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textapp/service/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService authService = AuthService();

  GoogleSignIn? _googleSignIn;
  Stream<User?> get userStream => _auth.authStateChanges();

  Map<String, dynamic>? userData;
  User? get currentUser => _auth.currentUser;

  bool isLoading = false;
  String? errorMessage;
  String? userToken;

  AuthProvider() {
    if (kDebugMode) {
      print("Initializing AuthProvider on ${kIsWeb ? 'Web' : 'Mobile'}");
    }

    if (!kIsWeb) {
      _googleSignIn = GoogleSignIn();
      trySilentSignIn(); // For mobile
    }

    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        print('✅ User is signed in!');
        await fetchUserProfile();
      } else {
        print('⚠️ User is signed out!');
        userData = null;
      }
      notifyListeners();
    });
  }

  Future<void> fetchUserProfile() async {
    if (currentUser != null) {
      final doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      if (doc.exists) {
        userData = doc.data();
        userToken = await currentUser!.getIdToken();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_token', userToken!);
        print("✅ User Token saved: $userToken");
        notifyListeners();
      }
    }
  }

  Future<void> signupWithExtraFields({
    required String name,
    required String mobile,
    required String email,
    required String location,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': name,
        'mobile': mobile,
        'email': email,
        'location': location,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await fetchUserProfile();
    } on FirebaseAuthException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'Unexpected error occurred.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await fetchUserProfile();
    } on FirebaseAuthException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'Login failed.';
    } finally {
      _setLoading(false);
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      late final UserCredential userCredential;

      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        final googleUser = await _googleSignIn?.signIn();
        if (googleUser == null) return null;

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }

      final user = userCredential.user;
      if (user != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (!userDoc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'name': user.displayName ?? '',
            'email': user.email ?? '',
            'photoUrl': user.photoURL ?? '',
            'mobile': user.phoneNumber ?? '',
            'loginType': 'google',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        await fetchUserProfile();
      }

      return user;
    } catch (e) {
      debugPrint('❌ Google sign-in error: $e');
      rethrow;
    }
  }

  Future<void> trySilentSignIn() async {
    try {
      if (!kIsWeb && _auth.currentUser == null) {
        final account = await _googleSignIn?.signInSilently(
          suppressErrors: true,
        );
        if (account != null) {
          final auth = await account.authentication;
          final credential = GoogleAuthProvider.credential(
            idToken: auth.idToken,
            accessToken: auth.accessToken,
          );
          await _auth.signInWithCredential(credential);
          print('✅ Silent sign-in successful');
        }
      }
    } catch (e) {
      print('❌ Silent sign-in error: $e');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Failed to send password reset email.';
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_token');

    if (!kIsWeb) await _googleSignIn?.signOut();

    await _auth.signOut();
    userData = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    isLoading = value;
    errorMessage = null;
    notifyListeners();
  }

  //====login with api ===
  Future<void> signupUsingAPI({
    required String name,
    required String email,
    required String password,
    required String mobile,
    required String location,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = await authService.signupUser(
        name: name,
        email: email,
        password: password,
        mobileNo: mobile,
        location: location,
      );

      print('✅ Signup API Success: $data');
    } catch (e) {
      errorMessage = e.toString();
      print('Signup Exception: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithEmail() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: 'soumyaengg1234@gmail.com',
            password: 'yourPassword123',
          );

      String? idToken = await userCredential.user!.getIdToken();
      print('Firebase login success. Token: $idToken');

      await authService.sendTokenToBackend(idToken!);
    } on FirebaseAuthException catch (e) {
      print('Login Error: ${e.message}');
    }
  }
}



  // Future<void> fetchUserProfile() async {
  //   if (currentUser != null) {
  //     final doc = await _firestore
  //         .collection('users')
  //         .doc(currentUser!.uid)
  //         .get();
  //     if (doc.exists) {
  //       userData = doc.data();
  //       userToken = await currentUser!.getIdToken();
  //       print("User Token: $userToken");
  //       notifyListeners();
  //     }
  //   }
  // }