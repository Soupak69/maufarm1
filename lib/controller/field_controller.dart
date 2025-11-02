import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/field_model.dart';

class FarmController extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<Farm> _fields = [];
  bool _isLoading = false;
  String? _error;

  List<Farm> get fields => _fields;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadfields() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('fields')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _fields = (response as List).map((json) => Farm.fromJson(json)).toList();
    } catch (e) {
      _error = e.toString();
      _fields = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addFarm(Farm farm) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final farmData = farm.toJson();
      farmData['user_id'] = userId;

      await _supabase.from('fields').insert(farmData);
      await loadfields();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateFarm(Farm farm) async {
    try {
      if (farm.id == null) {
        throw Exception('Farm ID is required for update');
      }

      await _supabase.from('fields').update(farm.toJson()).eq('id', farm.id!);
      await loadfields();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteFarm(int farmId) async {
    try {
      await _supabase.from('fields').delete().eq('id', farmId);
      await loadfields();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}