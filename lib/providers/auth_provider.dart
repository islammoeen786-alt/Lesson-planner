import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  final ApiService _api;
  final FirebaseAuth _firebaseAuth;
  AuthStatus _status = AuthStatus.uninitialized;
  UserProfile? _user;
  String? _error;

  AuthProvider(this._api, {FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance {
    _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);
  }

  AuthStatus get status => _status;
  UserProfile? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> _syncWithBackend() async {
    final response = await _api.get('/auth/me');
    final data = response.data is String
        ? Map<String, dynamic>.from(jsonDecode(response.data))
        : Map<String, dynamic>.from(response.data);
    _user = UserProfile.fromJson(data);
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  void _onAuthStateChanged(User? firebaseUser) async {
    if (_status == AuthStatus.authenticated) return;

    if (firebaseUser == null) {
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    _status = AuthStatus.loading;
    notifyListeners();

    try {
      await _syncWithBackend();
    } catch (_) {
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get fresh token and sync with backend
      final user = _firebaseAuth.currentUser;
      await user?.getIdToken(true);

      await _syncWithBackend();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Login error: $e');
      switch (e.code) {
        case 'user-not-found':
          _error = 'No account found with this email';
          break;
        case 'wrong-password':
          _error = 'Invalid email or password';
          break;
        case 'invalid-credential':
          _error = 'Invalid email or password';
          break;
        case 'too-many-requests':
          _error = 'Too many attempts. Try again later.';
          break;
        default:
          _error = 'Login failed';
      }
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Login backend sync error: $e');
      _error = 'Login failed: unable to sync with server';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final cred = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user?.updateDisplayName(name);

      // Force refresh the ID token so it includes the latest profile
      await cred.user?.getIdToken(true);

      // Sync with backend now (provisions SQLite user) before navigation
      await _syncWithBackend();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Register error: $e');
      switch (e.code) {
        case 'email-already-in-use':
          _error = 'Email already registered';
          break;
        case 'weak-password':
          _error = 'Password is too weak';
          break;
        case 'invalid-email':
          _error = 'Invalid email';
          break;
        default:
          _error = 'Registration failed';
      }
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Register backend sync error: $e');
      _error = 'Registration failed: unable to sync with server';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    try {
      final response = await _api.get('/auth/me');
      final data = response.data is String
          ? Map<String, dynamic>.from(jsonDecode(response.data))
          : Map<String, dynamic>.from(response.data);
      _user = UserProfile.fromJson(data);
      notifyListeners();
    } catch (_) {
      rethrow;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/users/profile', data: data);
      _user = UserProfile.fromJson(response.data);
      notifyListeners();
    } catch (_) {
      rethrow;
    }
  }
}
