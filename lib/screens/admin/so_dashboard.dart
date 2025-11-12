import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../utils/theme.dart';
import '../../models/contractor_team_model.dart';
import '../login_selection_screen.dart';
import 'team_detail_screen.dart';
import 'debug_data_screen.dart';

class SODashboard extends StatefulWidget {
  const SODashboard({super.key});

  @override
  State<SODashboard> createState() => _SODashboardState();
}

class _SODashboardState extends State<SODashboard> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    final user = authProvider.currentUser!;
    await adminProvider.loadTeamsForSO(user.id);

    // Load attendance and tasks for all teams
    final teamIds = adminProvider.teams.map((t) => t.teamId).toList();
    if (teamIds.isNotEmpty) {
      await adminProvider.loadAttendance();
      await adminProvider.loadTasksForTeams(teamIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final adminProvider = Provider.of<AdminProvider>(context);
    final user = authProvider.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SO Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DebugDataScreen()),
              );
            },
            tooltip: 'Create Sample Data',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginSelectionScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: adminProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings,
                                size: 40,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome, ${user.name}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Site Officer',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stats Overview
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Teams',
                            adminProvider.teams.length.toString(),
                            Icons.groups,
                            AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Checked In',
                            '${_getTodayCheckIns(adminProvider)}/${adminProvider.teams.length}',
                            Icons.check_circle,
                            AppTheme.successColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Quick Actions
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            'Report Summary',
                            Icons.assessment,
                            AppTheme.accentColor,
                            () {
                              Navigator.pushNamed(context, '/report_summary');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionCard(
                            'Productivity',
                            Icons.trending_up,
                            AppTheme.successColor,
                            () {
                              Navigator.pushNamed(context, '/productivity');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Teams List
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Teams',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh, size: 20),
                          label: const Text('Refresh'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (adminProvider.teams.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(
                            child: Text('No teams assigned yet'),
                          ),
                        ),
                      )
                    else
                      ...adminProvider.teams.map((team) {
                        final stats =
                            adminProvider.getPerformanceStats(team.teamId);
                        return _buildTeamCard(context, team, stats);
                      }).toList(),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamCard(
    BuildContext context,
    ContractorTeam team,
    Map<String, dynamic> stats,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (_) => TeamDetailScreen(team: team),
                ),
              )
              .then((_) => _loadData());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.group,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Team ${team.teamId}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Leader: ${team.leaderName}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Tasks',
                      '${stats['completed_tasks']}/${stats['total_tasks']}',
                      Icons.task_alt,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Avg Progress',
                      '${stats['average_completion'].toInt()}%',
                      Icons.trending_up,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Attendance',
                      '${stats['attendance_rate'].toInt()}%',
                      Icons.calendar_today,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getTodayCheckIns(AdminProvider provider) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // Get unique team IDs that have checked in today
    final teamsCheckedInToday = provider.attendanceRecords
        .where((a) =>
            a.date.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
            a.date.isBefore(todayEnd))
        .map((a) => a.teamId)
        .toSet() // Remove duplicates
        .length;

    return teamsCheckedInToday;
  }
}
