import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/attendance_model.dart';
import '../models/task_model.dart';
import '../models/task_update_model.dart';
import '../models/contractor_team_model.dart';

class AdminProvider with ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String? _errorMessage;

  List<ContractorTeam> _teams = [];
  List<AppUser> _subordinates = [];
  List<Attendance> _attendanceRecords = [];
  Map<String, List<Task>> _tasksByTeam = {};
  List<Task> _allTasks = [];
  Map<String, List<TaskUpdate>> _taskUpdatesByTaskId = {};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ContractorTeam> get teams => _teams;
  List<AppUser> get subordinates => _subordinates;
  List<Attendance> get attendanceRecords => _attendanceRecords;
  Map<String, List<Task>> get tasksByTeam => _tasksByTeam;
  List<Task> get tasks => _allTasks;
  Map<String, List<TaskUpdate>> get taskUpdatesByTaskId => _taskUpdatesByTaskId;

  Future<void> loadTeamsForSO(String soId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // First, try to get teams assigned to this SO
      var snapshot = await _firestore
          .collection('contractor_teams')
          .where('so_id', isEqualTo: soId)
          .get();

      // If no teams found, get all teams (for initial setup or unassigned teams)
      if (snapshot.docs.isEmpty) {
        snapshot = await _firestore.collection('contractor_teams').get();
      }

      _teams = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ContractorTeam.fromJson(data);
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSOsForExecutive(String executiveId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('users')
          .where('manager_id', isEqualTo: executiveId)
          .where('role', isEqualTo: 'so')
          .get();

      _subordinates = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return AppUser.fromJson(data);
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllStaff() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', whereIn: ['so', 'executive', 'gmAgm']).get();

      _subordinates = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return AppUser.fromJson(data);
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAttendance(
      {String? teamId, DateTime? startDate, DateTime? endDate}) async {
    try {
      var query = _firestore.collection('attendance').limit(100);

      if (teamId != null) {
        query = query.where('team_id', isEqualTo: teamId)
            as Query<Map<String, dynamic>>;
      }

      if (startDate != null) {
        query = query.where('date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            as Query<Map<String, dynamic>>;
      }

      if (endDate != null) {
        query = query.where('date',
                isLessThanOrEqualTo: Timestamp.fromDate(endDate))
            as Query<Map<String, dynamic>>;
      }

      final snapshot = await query.get();

      _attendanceRecords = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Attendance.fromJson(data);
      }).toList();

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadTasksForTeams(List<String> teamIds) async {
    try {
      if (teamIds.isEmpty) return;

      final snapshot = await _firestore
          .collection('tasks')
          .where('team_id', whereIn: teamIds)
          .get();

      _tasksByTeam.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        final task = Task.fromJson(data);

        if (!_tasksByTeam.containsKey(task.teamId)) {
          _tasksByTeam[task.teamId] = [];
        }
        _tasksByTeam[task.teamId]!.add(task);
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadTasksForAllTeams() async {
    try {
      final snapshot = await _firestore.collection('tasks').get();

      _allTasks = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Task.fromJson(data);
      }).toList();

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Map<String, dynamic> getPerformanceStats(String teamId) {
    final tasks = _tasksByTeam[teamId] ?? [];
    final completedTasks = tasks.where((t) => t.status == 'completed').length;
    final totalTasks = tasks.length;

    double avgCompletion = 0.0;
    if (tasks.isNotEmpty) {
      avgCompletion =
          tasks.map((t) => t.completionPercentage).reduce((a, b) => a + b) /
              tasks.length;
    }

    final teamAttendance =
        _attendanceRecords.where((a) => a.teamId == teamId).toList();
    final today = DateTime.now();
    final last30Days = today.subtract(const Duration(days: 30));
    final recentAttendance =
        teamAttendance.where((a) => a.date.isAfter(last30Days)).length;

    // Rough attendance rate (assuming 30 days, adjust as needed)
    final attendanceRate = (recentAttendance / 30) * 100;

    return {
      'completed_tasks': completedTasks,
      'total_tasks': totalTasks,
      'average_completion': avgCompletion,
      'attendance_rate': attendanceRate > 100 ? 100.0 : attendanceRate,
      'attendance_last_30_days': recentAttendance,
    };
  }

  Future<void> loadTaskUpdates(String taskId) async {
    try {
      // Try with orderBy first
      QuerySnapshot snapshot;
      try {
        snapshot = await _firestore
            .collection('task_updates')
            .where('task_id', isEqualTo: taskId)
            .orderBy('updated_at', descending: true)
            .get();
      } catch (indexError) {
        // If index doesn't exist, fetch without ordering and sort in memory
        print('Firestore index not found, sorting in memory: $indexError');
        snapshot = await _firestore
            .collection('task_updates')
            .where('task_id', isEqualTo: taskId)
            .get();
      }

      final updates = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return TaskUpdate.fromJson(data);
      }).toList();

      // Sort in memory if not already sorted
      updates.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      _taskUpdatesByTaskId[taskId] = updates;
      notifyListeners();
    } catch (e) {
      print('Error loading task updates: $e');
      _errorMessage = e.toString();
      // Set empty list to show "no updates" instead of error
      _taskUpdatesByTaskId[taskId] = [];
      notifyListeners();
    }
  }

  List<TaskUpdate> getTaskUpdates(String taskId) {
    return _taskUpdatesByTaskId[taskId] ?? [];
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
