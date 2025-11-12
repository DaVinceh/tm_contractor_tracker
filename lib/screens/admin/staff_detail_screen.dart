import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/contractor_team_model.dart';
import '../../utils/theme.dart';
import 'team_detail_screen.dart';

class StaffDetailScreen extends StatefulWidget {
  final AppUser staff;

  const StaffDetailScreen({super.key, required this.staff});

  @override
  State<StaffDetailScreen> createState() => _StaffDetailScreenState();
}

class _StaffDetailScreenState extends State<StaffDetailScreen> {
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  List<ContractorTeam> _teams = [];
  List<AppUser> _subordinates = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStaffData();
  }

  Future<void> _loadStaffData() async {
    setState(() => _isLoading = true);

    try {
      // Load based on role
      if (widget.staff.role.toString().contains('so')) {
        // Load teams for SO
        await _loadSOTeams();
      } else if (widget.staff.role.toString().contains('executive')) {
        // Load SOs under executive
        await _loadExecutiveSOs();
      }

      // Load performance stats
      await _loadStats();

      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Error loading staff data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _loadSOTeams() async {
    final teamsSnapshot = await _firestore
        .collection('contractor_teams')
        .where('so_id', isEqualTo: widget.staff.id)
        .get();

    if (teamsSnapshot.docs.isEmpty) {
      print('⚠️ No teams found for SO: ${widget.staff.name}');
    } else {
      print(
          '✅ Found ${teamsSnapshot.docs.length} teams for SO: ${widget.staff.name}');
    }

    _teams = teamsSnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return ContractorTeam.fromJson(data);
    }).toList();
  }

  Future<void> _loadExecutiveSOs() async {
    final sosSnapshot = await _firestore
        .collection('users')
        .where('manager_id', isEqualTo: widget.staff.id)
        .where('role', isEqualTo: 'so')
        .get();

    if (sosSnapshot.docs.isEmpty) {
      print('⚠️ No SOs found under executive: ${widget.staff.name}');
    } else {
      print(
          '✅ Found ${sosSnapshot.docs.length} SOs under executive: ${widget.staff.name}');
    }

    _subordinates = sosSnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return AppUser.fromJson(data);
    }).toList();
  }

  Future<void> _loadStats() async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    // Load attendance for today
    Query attendanceQuery = _firestore
        .collection('attendance')
        .where('date', isEqualTo: Timestamp.fromDate(todayStart));

    // Load tasks
    Query tasksQuery = _firestore.collection('tasks');

    if (widget.staff.role.toString().contains('so')) {
      // For SO, filter by their teams
      if (_teams.isNotEmpty) {
        final teamIds = _teams.map((t) => t.teamId).toList();
        attendanceQuery = attendanceQuery.where('team_id', whereIn: teamIds);
        tasksQuery = tasksQuery.where('team_id', whereIn: teamIds);
      }
    }

    final attendanceSnapshot = await attendanceQuery.get();
    final tasksSnapshot = await tasksQuery.get();

    final completedTasks = tasksSnapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      return data != null && data['status'] == 'completed';
    }).length;

    _stats = {
      'total_teams': _teams.length,
      'total_sos': _subordinates.length,
      'check_ins_today': attendanceSnapshot.docs.length,
      'total_tasks': tasksSnapshot.docs.length,
      'completed_tasks': completedTasks,
      'completion_rate': tasksSnapshot.docs.isEmpty
          ? 0.0
          : (completedTasks / tasksSnapshot.docs.length * 100),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isSO = widget.staff.role.toString().contains('so');
    final isExecutive = widget.staff.role.toString().contains('executive');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.staff.name),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStaffData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Staff Info Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor:
                                  AppTheme.primaryColor.withOpacity(0.1),
                              child: Icon(
                                isSO
                                    ? Icons.supervisor_account
                                    : Icons.business_center,
                                size: 40,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.staff.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.staff.email,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Chip(
                              label: Text(
                                isSO
                                    ? 'Site Officer'
                                    : isExecutive
                                        ? 'Executive'
                                        : 'Staff',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: AppTheme.primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Performance Stats
                    const Text(
                      'Performance Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        if (isSO)
                          _buildStatCard(
                            'Teams',
                            _stats['total_teams'].toString(),
                            Icons.groups,
                            AppTheme.primaryColor,
                          ),
                        if (isExecutive)
                          _buildStatCard(
                            'Site Officers',
                            _stats['total_sos'].toString(),
                            Icons.supervisor_account,
                            AppTheme.primaryColor,
                          ),
                        _buildStatCard(
                          'Check-ins Today',
                          _stats['check_ins_today'].toString(),
                          Icons.check_circle,
                          AppTheme.successColor,
                        ),
                        _buildStatCard(
                          'Total Tasks',
                          _stats['total_tasks'].toString(),
                          Icons.task_alt,
                          AppTheme.accentColor,
                        ),
                        _buildStatCard(
                          'Completed',
                          _stats['completed_tasks'].toString(),
                          Icons.done_all,
                          AppTheme.successColor,
                        ),
                        _buildStatCard(
                          'Completion Rate',
                          '${_stats['completion_rate'].toInt()}%',
                          Icons.trending_up,
                          AppTheme.accentColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Teams or Subordinates List
                    if (isSO && _teams.isNotEmpty) ...[
                      const Text(
                        'Managed Teams',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._teams.map((team) => _buildTeamCard(team)).toList(),
                    ],

                    if (isExecutive && _subordinates.isNotEmpty) ...[
                      const Text(
                        'Site Officers',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._subordinates.map((so) => _buildSOCard(so)).toList(),
                    ],

                    if (isSO && _teams.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.groups_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No teams assigned',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    if (isExecutive && _subordinates.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.supervisor_account_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No site officers assigned',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamCard(ContractorTeam team) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          child: Icon(Icons.groups, color: Colors.white, size: 20),
        ),
        title: Text(
          team.teamId,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Leader: ${team.leaderName}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TeamDetailScreen(team: team),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSOCard(AppUser so) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.secondaryColor.withOpacity(0.1),
          child: const Icon(
            Icons.supervisor_account,
            color: AppTheme.secondaryColor,
            size: 20,
          ),
        ),
        title: Text(
          so.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(so.email),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StaffDetailScreen(staff: so),
            ),
          );
        },
      ),
    );
  }
}
