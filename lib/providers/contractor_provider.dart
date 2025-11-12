import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' hide Task;
import 'package:geolocator/geolocator.dart';
import '../models/attendance_model.dart';
import '../models/task_model.dart';
import '../models/task_update_model.dart';

class ContractorProvider with ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  bool _isLoading = false;
  String? _errorMessage;
  Attendance? _todayAttendance;
  List<Task> _tasks = [];
  List<TaskUpdate> _taskUpdates = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Attendance? get todayAttendance => _todayAttendance;
  List<Task> get tasks => _tasks;
  List<TaskUpdate> get taskUpdates => _taskUpdates;
  bool get hasCheckedInToday => _todayAttendance != null;

  Future<bool> checkIn(String userId, String teamId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage = 'Location permission denied';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Create attendance record - allow multiple check-ins per day
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      final docRef = await _firestore.collection('attendance').add({
        'user_id': userId,
        'team_id': teamId,
        'check_in_time': Timestamp.now(),
        'latitude': position.latitude,
        'longitude': position.longitude,
        'date': Timestamp.fromDate(todayStart),
        'created_at': FieldValue.serverTimestamp(),
      });

      final doc = await docRef.get();
      final data = doc.data()!;
      data['id'] = doc.id;
      _todayAttendance = Attendance.fromJson(data);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadTodayAttendance(String userId) async {
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      // Get the most recent check-in for today (in case of multiple check-ins)
      final snapshot = await _firestore
          .collection('attendance')
          .where('user_id', isEqualTo: userId)
          .where('date', isEqualTo: Timestamp.fromDate(todayStart))
          .orderBy('check_in_time', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        data['id'] = snapshot.docs.first.id;
        _todayAttendance = Attendance.fromJson(data);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadTasks(String teamId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('tasks')
          .where('team_id', isEqualTo: teamId)
          .get();

      _tasks = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Task.fromJson(data);
      }).toList();

      // Sort by start date in memory (no index required)
      _tasks.sort((a, b) => b.startDate.compareTo(a.startDate));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadTaskUpdate({
    required String taskId,
    required String userId,
    required String comment,
    String? imageUrl,
    double? progressUpdate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestore.collection('task_updates').add({
        'task_id': taskId,
        'user_id': userId,
        'image_url': imageUrl,
        'comment': comment,
        'progress_update': progressUpdate,
        'updated_at': Timestamp.now(),
      });

      // Update task completion percentage if provided
      if (progressUpdate != null) {
        await _firestore.collection('tasks').doc(taskId).update({
          'completion_percentage': progressUpdate,
          'status': progressUpdate >= 100 ? 'completed' : 'in_progress',
          'updated_at':
              Timestamp.now(), // Track when task was updated/completed
        });
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> uploadImage(String filePath) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(filePath);

      final ref = _storage.ref().child('task-images/$fileName');
      await ref.putFile(file);

      final imageUrl = await ref.getDownloadURL();

      return imageUrl;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  void clearCheckInStatus() {
    _todayAttendance = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
