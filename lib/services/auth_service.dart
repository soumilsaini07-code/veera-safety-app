import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  FirebaseAuth? _auth;
  FirebaseDatabase? _db;

  AuthService() {
    try {
      _auth = FirebaseAuth.instance;
      _db = FirebaseDatabase.instance;
    } catch (e) {
      debugPrint("Firebase not initialized: $e");
    }
  }

  // Stream of auth state changes
  Stream<User?> get userStream => _auth?.authStateChanges() ?? Stream.value(null);

  // Get current user ID
  String? get currentUserId => _auth?.currentUser?.uid;

  // Sign up
  Future<UserModel?> signUp(String name, String email, String password, String phone) async {
    if (_auth == null) throw Exception("Firebase not configured");
    try {
      UserCredential credential = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = credential.user;
      if (user != null) {
        UserModel userModel = UserModel(
          uid: user.uid,
          name: name,
          email: email,
          phone: phone,
          createdAt: DateTime.now(),
        );

        // Save to Realtime Database
        await _db?.ref().child('Users').child(user.uid).set(userModel.toMap());
        return userModel;
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  // Login
  Future<User?> login(String email, String password) async {
    if (_auth == null) throw Exception("Firebase not configured");
    try {
      UserCredential credential = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    if (_auth == null) throw Exception("Firebase not configured");
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        UserCredential userCredential = await _auth!.signInWithCredential(credential);
        User? user = userCredential.user;

        if (user != null) {
          UserModel? existingUser = await getUserProfile(user.uid);
          if (existingUser != null) {
            return existingUser;
          } else {
            UserModel userModel = UserModel(
              uid: user.uid,
              name: user.displayName ?? 'Unknown',
              email: user.email ?? 'Unknown',
              phone: user.phoneNumber ?? 'Unknown',
              createdAt: DateTime.now(),
            );
            await _db?.ref().child('Users').child(user.uid).set(userModel.toMap());
            return userModel;
          }
        }
      }
    } catch (e) {
      debugPrint("Google sign-in error: $e");
      rethrow;
    }
    return null;
  }

  // Logout
  Future<void> logout() async {
    await _auth?.signOut();
  }

  // Get User Profile
  Future<UserModel?> getUserProfile(String uid) async {
    if (_db == null) return null;
    try {
      final snapshot = await _db!.ref().child('Users').child(uid).get();
      if (snapshot.exists && snapshot.value != null) {
        return UserModel.fromMap(Map<String, dynamic>.from(snapshot.value as Map), snapshot.key ?? uid);
      }
    } catch (e) {
      print('Error fetching profile: $e');
    }
    return null;
  }
}
