import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  Future<void> checkAuthState() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _loadUserProfile(user.uid);
    }
  }

  Future<bool> contractorLogin(String teamId, String leaderName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Convert to lowercase for case-insensitive comparison
      final normalizedTeamId = teamId.trim().toLowerCase();
      final normalizedLeaderName = leaderName.trim().toLowerCase();

      // Get all contractor teams and match case-insensitively
      final allTeamsSnapshot =
          await _firestore.collection('contractor_teams').get();

      DocumentSnapshot? matchingTeamDoc;
      String? actualTeamId;
      String? actualLeaderName;

      for (var doc in allTeamsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final dbTeamId = (data['team_id'] as String? ?? '').toLowerCase();
        final dbLeaderName =
            (data['leader_name'] as String? ?? '').toLowerCase();

        if (dbTeamId == normalizedTeamId &&
            dbLeaderName == normalizedLeaderName) {
          matchingTeamDoc = doc;
          actualTeamId = data['team_id'] as String;
          actualLeaderName = data['leader_name'] as String;
          break;
        }
      }

      if (matchingTeamDoc == null) {
        _errorMessage = 'Invalid Team ID or Leader Name';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Create or get contractor user with actual (original case) values
      final userSnapshot = await _firestore
          .collection('users')
          .where('team_id', isEqualTo: actualTeamId)
          .where('name', isEqualTo: actualLeaderName)
          .limit(1)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        final userData = userSnapshot.docs.first.data();
        userData['id'] = userSnapshot.docs.first.id;
        _currentUser = AppUser.fromJson(userData);
      } else {
        // Create new contractor user with actual (original case) values
        final newUserRef = await _firestore.collection('users').add({
          'email': '${actualTeamId}_$actualLeaderName@contractor.tm',
          'role': 'contractor',
          'name': actualLeaderName,
          'team_id': actualTeamId,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        final newUserDoc = await newUserRef.get();
        final userData = newUserDoc.data()!;
        userData['id'] = newUserDoc.id;
        _currentUser = AppUser.fromJson(userData);
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

  Future<bool> adminLogin(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _loadUserProfile(credential.user!.uid);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = 'Login failed';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _loadUserProfile(String userId) async {
    try {
      // Try to get user by document ID (Firebase Auth UID)
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        userData['id'] = userDoc.id;
        _currentUser = AppUser.fromJson(userData);
        return;
      }

      // If not found, try to get by email
      final currentUser = _auth.currentUser;
      if (currentUser?.email != null) {
        final userQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: currentUser!.email)
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          final userData = userQuery.docs.first.data();
          userData['id'] = userQuery.docs.first.id;
          _currentUser = AppUser.fromJson(userData);
          return;
        }
      }

      // If still not found, create a basic admin user document
      if (currentUser?.email != null) {
        String role = 'so'; // Default role
        if (currentUser!.email!.contains('executive')) {
          role = 'executive';
        } else if (currentUser.email!.contains('gm')) {
          role = 'gmAgm';
        }

        await _firestore.collection('users').doc(userId).set({
          'email': currentUser.email,
          'role': role,
          'name': currentUser.email!.split('@')[0].toUpperCase(),
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        final newUserDoc =
            await _firestore.collection('users').doc(userId).get();
        final userData = newUserDoc.data()!;
        userData['id'] = newUserDoc.id;
        _currentUser = AppUser.fromJson(userData);
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  Future<void> logout() async {
    try {
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
