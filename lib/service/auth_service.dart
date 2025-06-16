import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:textapp/service/utils.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserCredential> signupWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<Map<String, dynamic>> signupUser({
    required String name,
    required String email,
    required String password,
    required String mobileNo,
    required String location,
  }) async {
    final url = Uri.parse('$baseurl/auth/signup');

    final headers = {'Content-Type': 'application/json'};

    final body = json.encode({
      "name": name,
      "email": email,
      "password": password,
      "mobileNo": mobileNo,
      "location": location,
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Backend signup failed: ${response.reasonPhrase}');
    }
  }

  Future<void> saveUserToFirestore({
    required String uid,
    required String name,
    required String email,
    required String mobile,
    required String location,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'mobile': mobile,
      'location': location,
    });
  }

  Future<Map<String, dynamic>?> fetchUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) return doc.data();
    return null;
  }

  Future<UserCredential> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> sendTokenToBackend(String token) async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final uri = Uri.parse('$baseurl/auth/login');

    final response = await http.post(uri, headers: headers);

    if (response.statusCode == 200) {
      print('Backend login success: ${response.body}');
    } else {
      print('Backend login failed: ${response.statusCode} ${response.body}');
      throw Exception('Backend login failed');
    }
  }

  Future<User?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = await _auth.signInWithCredential(
      credential,
    );
    final user = userCredential.user;

    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': user.displayName,
          'email': user.email,
          'photoUrl': user.photoURL,
          'loginType': 'google',
        });
      }
    }
    return user;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Future<void> logout() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.remove('user_token');
  //   await _googleSignIn.signOut();
  //   await _auth.signOut();
  // }
}
