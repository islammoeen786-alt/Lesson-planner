import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/error_handler.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  final ApiService _api;
  final FirebaseAuth _firebaseAuth;
  AuthStatus _status = AuthStatus.uninitialized;
  UserProfile? _user;
  AppError? _appError;

  AuthProvider(this._api, {FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance {
    _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);
  }

  AuthStatus get status => _status;
  UserProfile? get user => _user;
  String? get error => _appError?.message;
  AppError? get appError => _appError;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  void clearError() {
    _appError = null;
    notifyListeners();
  }

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
    } catch (e) {
      _appError = AppErrorHandler.fromException(e);
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _appError = null;
    notifyListeners();

    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = _firebaseAuth.currentUser;
      await user?.getIdToken(true);

      await _syncWithBackend();
      return true;
    } on FirebaseAuthException catch (e) {
      _appError = AppErrorHandler.fromFirebaseException(e);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _appError = AppErrorHandler.fromException(e);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _status = AuthStatus.loading;
    _appError = null;
    notifyListeners();

    try {
      final cred = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user?.updateDisplayName(name);
      await cred.user?.getIdToken(true);
      await _syncWithBackend();
      return true;
    } on FirebaseAuthException catch (e) {
      _appError = AppErrorHandler.fromFirebaseException(e);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _appError = AppErrorHandler.fromException(e);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _appError = null;
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
    } catch (e) {
      _appError = AppErrorHandler.fromException(e);
      rethrow;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/users/profile', data: data);
      _user = UserProfile.fromJson(response.data);
      _appError = null;
      notifyListeners();
    } catch (e) {
      _appError = AppErrorHandler.fromException(e);
      rethrow;
    }
  }
}
