import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/error_handler.dart';
import '../services/local_storage_service.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  final ApiService _api;
  final FirebaseAuth _firebaseAuth;
  AuthStatus _status = AuthStatus.uninitialized;
  UserProfile? _user;
  AppError? _appError;
  bool _initialSyncDone = false;
  int _profileVersion = 0;
  Timer? _refreshTimer;

  static const String _cacheKey = 'auth_user_profile';

  int get profileVersion => _profileVersion;

  AuthProvider(this._api, {FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance {
    debugPrint('[AuthProvider] Created, listening to auth state');
    _loadCachedProfile();
    _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);
  }

  void startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (_status == AuthStatus.authenticated) {
        debugPrint('[AuthProvider] Periodic auto-refresh triggered');
        try {
          await refreshProfile();
          debugPrint('[AuthProvider] Periodic auto-refresh succeeded');
        } catch (e) {
          debugPrint('[AuthProvider] Periodic auto-refresh failed: $e');
        }
      }
    });
    debugPrint('[AuthProvider] Periodic refresh timer started (30s)');
  }

  void stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    debugPrint('[AuthProvider] Periodic refresh timer stopped');
  }

  AuthStatus get status => _status;
  UserProfile? get user => _user;
  String? get error => _appError?.message;
  AppError? get appError => _appError;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  void clearError() {
    _appError = null;
    notifyListeners();
  }

  Future<void> _loadCachedProfile() async {
    try {
      final cached = await LocalStorageService.getJson(_cacheKey);
      if (cached != null && !_initialSyncDone) {
        _user = UserProfile.fromJson(cached);
        _status = AuthStatus.authenticated;
        debugPrint('[AuthProvider] Loaded cached profile: email=${_user!.email} isPro=${_user!.isPro} plan=${_user!.plan}');
        notifyListeners();
      } else if (cached != null && _initialSyncDone) {
        debugPrint('[AuthProvider] Skipped cache load - sync already completed');
      }
    } catch (e) {
      debugPrint('[AuthProvider] Cache load error: $e');
    }
  }

  Future<void> _saveCachedProfile() async {
    if (_user == null) return;
    try {
      await LocalStorageService.setJson(_cacheKey, _user!.toJson());
      debugPrint('[AuthProvider] Cached profile: email=${_user!.email} isPro=${_user!.isPro} plan=${_user!.plan}');
    } catch (e) {
      debugPrint('[AuthProvider] Cache save error: $e');
    }
  }

  Future<void> _clearCachedProfile() async {
    await LocalStorageService.remove(_cacheKey);
    debugPrint('[AuthProvider] Cleared cached profile');
  }

  Future<void> _syncWithBackend() async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final response = await _api.get('/auth/me', queryParams: {'_t': ts});
    final data = response.data is String
        ? Map<String, dynamic>.from(jsonDecode(response.data))
        : Map<String, dynamic>.from(response.data);
    final previousPro = _user?.isPro;
    final previousPlan = _user?.plan;
    _user = UserProfile.fromJson(data);
    _status = AuthStatus.authenticated;
    _profileVersion++;
    await _saveCachedProfile();
    _initialSyncDone = true;
    debugPrint('[AuthProvider] Backend sync complete: email=${_user!.email} isPro=${_user!.isPro} plan=${_user!.plan} version=$_profileVersion');
    if (previousPro != null && previousPro != _user!.isPro) {
      debugPrint('[AuthProvider] ^^^ PRO STATUS CHANGED: $previousPro -> ${_user!.isPro} ^^^');
    }
    if (previousPlan != null && previousPlan != _user!.plan) {
      debugPrint('[AuthProvider] ^^^ PLAN CHANGED: $previousPlan -> ${_user!.plan} ^^^');
    }
    notifyListeners();
  }

  void _onAuthStateChanged(User? firebaseUser) async {
    debugPrint('[AuthProvider] Auth state changed: user=${firebaseUser?.email ?? "null"} status=$_status initialSyncDone=$_initialSyncDone');

    if (firebaseUser == null) {
      _user = null;
      _status = AuthStatus.unauthenticated;
      await _clearCachedProfile();
      _initialSyncDone = false;
      _profileVersion = 0;
      notifyListeners();
      return;
    }

    if (_initialSyncDone && _status == AuthStatus.authenticated) {
      debugPrint('[AuthProvider] Already synced, refreshing profile in background');
      try {
        await refreshProfile();
        debugPrint('[AuthProvider] Background refresh succeeded');
      } catch (e) {
        debugPrint('[AuthProvider] Background refresh failed: $e');
      }
      return;
    }

    _status = AuthStatus.loading;
    notifyListeners();

    try {
      await _syncWithBackend();
    } catch (e) {
      _appError = AppErrorHandler.fromException(e);
      debugPrint('[AuthProvider] Initial sync failed: $e');
      if (_user == null) {
        _status = AuthStatus.unauthenticated;
      } else {
        _status = AuthStatus.authenticated;
      }
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
    _initialSyncDone = false;
    _profileVersion = 0;
    await _clearCachedProfile();
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    try {
      debugPrint('[AuthProvider] Refresh profile started');
      final ts = DateTime.now().millisecondsSinceEpoch;
      final response = await _api.get('/auth/me', queryParams: {'_t': ts});
      final data = response.data is String
          ? Map<String, dynamic>.from(jsonDecode(response.data))
          : Map<String, dynamic>.from(response.data);
      final previous = _user;
      _user = UserProfile.fromJson(data);
      _profileVersion++;
      await _saveCachedProfile();
      debugPrint('[AuthProvider] Refresh complete: email=${_user!.email} isPro=${_user!.isPro} plan=${_user!.plan} version=$_profileVersion');
      if (previous != null && previous.isPro != _user!.isPro) {
        debugPrint('[AuthProvider] ^^^ PRO STATUS CHANGED: ${previous.isPro} -> ${_user!.isPro} ^^^');
      }
      if (previous != null && previous.plan != _user!.plan) {
        debugPrint('[AuthProvider] ^^^ PLAN CHANGED: ${previous.plan} -> ${_user!.plan} ^^^');
      }
      _appError = null;
      notifyListeners();
    } catch (e) {
      _appError = AppErrorHandler.fromException(e);
      debugPrint('[AuthProvider] Refresh failed: $e');
      rethrow;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/users/profile', data: data);
      _user = UserProfile.fromJson(response.data);
      _profileVersion++;
      await _saveCachedProfile();
      _appError = null;
      notifyListeners();
    } catch (e) {
      _appError = AppErrorHandler.fromException(e);
      rethrow;
    }
  }

  @override
  void dispose() {
    stopPeriodicRefresh();
    super.dispose();
  }
}
