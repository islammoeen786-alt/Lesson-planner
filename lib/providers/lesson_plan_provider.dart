import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/lesson_plan.dart';

class LessonPlanProvider extends ChangeNotifier {
  final ApiService _api;
  List<LessonPlan> _plans = [];
  bool _isLoading = false;
  int _currentPage = 1;
  int _totalPages = 1;
  int _quotaUsed = 0;
  int _quotaLimit = 20;
  String? _error;
  String _searchQuery = '';
  String? _subjectFilter;
  String? _statusFilter;

  LessonPlanProvider(this._api);

  List<LessonPlan> get plans => _plans;
  bool get isLoading => _isLoading;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get quotaRemaining => _quotaLimit - _quotaUsed;
  int get quotaUsed => _quotaUsed;
  int get quotaLimit => _quotaLimit;
  String? get error => _error;

  Future<void> loadPlans({int page = 1, bool refresh = false}) async {
    if (refresh) _currentPage = 1;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final params = <String, dynamic>{
        'page': refresh ? 1 : _currentPage,
        'limit': 20,
      };
      if (_searchQuery.isNotEmpty) params['search'] = _searchQuery;
      if (_subjectFilter != null) params['subject'] = _subjectFilter;
      if (_statusFilter != null) params['status'] = _statusFilter;

      final response = await _api.get('/lesson-plans', queryParams: params);
      final data = response.data;
      _plans = (data['data'] as List).map((j) => LessonPlan.fromJson(j)).toList();
      _currentPage = data['pagination']['page'];
      _totalPages = data['pagination']['totalPages'];
    } catch (e) {
      _error = 'Failed to load lesson plans';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadQuota() async {
    try {
      final response = await _api.get('/ai/quota');
      final data = response.data;
      final isPro = data['isPro'] == true;
      // If pro, show unlimited
      if (isPro) {
        _quotaUsed = 0;
        _quotaLimit = 999999;
      } else {
        _quotaUsed = data['used'] ?? 0;
        _quotaLimit = data['limit'] ?? 20;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<LessonPlan?> generatePlan({
    required String subject,
    required String gradeLevel,
    required String topic,
    required int durationMinutes,
    List<String>? learningObjectives,
    String? teachingStyle,
    String? extraInstructions,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post('/ai/generate', data: {
        'subject': subject,
        'gradeLevel': gradeLevel,
        'topic': topic,
        'durationMinutes': durationMinutes,
        'learningObjectives': learningObjectives ?? [],
        'teachingStyle': teachingStyle,
        'extraInstructions': extraInstructions,
      });

      final plan = LessonPlan.fromJson(response.data);
      await loadQuota();
      _isLoading = false;
      notifyListeners();
      return plan;
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        _error = data['error'] as String? ?? "Couldn't generate a plan right now. Try again.";
        if (data['quota'] != null) {
          final q = data['quota'];
          if (q['isPro'] == true) {
            _quotaUsed = 0;
            _quotaLimit = 999999;
          } else {
            _quotaUsed = q['used'] ?? _quotaUsed;
            _quotaLimit = q['limit'] ?? _quotaLimit;
          }
        }
      } else {
        _error = "Couldn't generate a plan right now. Try again.";
      }
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<LessonPlan?> updatePlan(int id, Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/lesson-plans/$id', data: data);
      final updated = LessonPlan.fromJson(response.data);
      final idx = _plans.indexWhere((p) => p.id == id);
      if (idx >= 0) _plans[idx] = updated;
      notifyListeners();
      return updated;
    } catch (e) {
      return null;
    }
  }

  Future<LessonPlan?> regenerateSection(int lessonPlanId, String sectionName, {String? context}) async {
    try {
      final response = await _api.post('/ai/regenerate-section', data: {
        'lessonPlanId': lessonPlanId,
        'sectionName': sectionName,
        'context': context ?? '',
      });
      final updated = LessonPlan.fromJson(response.data);
      final idx = _plans.indexWhere((p) => p.id == lessonPlanId);
      if (idx >= 0) _plans[idx] = updated;
      await loadQuota();
      notifyListeners();
      return updated;
    } catch (e) {
      return null;
    }
  }

  void setSearch(String query) {
    _searchQuery = query;
    loadPlans(refresh: true);
  }
}
