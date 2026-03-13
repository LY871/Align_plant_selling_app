import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  Future<User?> createUserWithEmailAndPassword(String email, String password, String userType) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final User? user = cred.user;

      if (user != null) {

        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'userType': userType,
        });
      }
      return user;
    } catch (e) {
      log("Error in createUserWithEmailAndPassword: $e");
      return null;
    }
  }


  Future<User?> loginUserWithEmailAndPassword(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return cred.user;
    } catch (e) {
      log("Error in loginUserWithEmailAndPassword: $e");
      return null;
    }
  }

  // Sign out user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      log("Error in signOut: $e");
    }
  }
}
