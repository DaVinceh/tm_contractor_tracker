import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/user_model.dart';
import '../../utils/theme.dart';
import 'team_detail_screen.dart';

class SOTeamsViewScreen extends StatefulWidget {
  final AppUser so;

  const SOTeamsViewScreen({super.key, required this.so});

  @override
  State<SOTeamsViewScreen> createState() => _SOTeamsViewScreenState();
}

class _SOTeamsViewScreenState extends State<SOTeamsViewScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    await adminProvider.loadTeamsForSO(widget.so.id);
    
    final teamIds = adminProvider.teams.map((t) => t.teamId).toList();
    if (teamIds.isNotEmpty) {
      await adminProvider.loadAttendance();
      await adminProvider.loadTasksForTeams(teamIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.so.name}\'s Teams'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: adminProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : adminProvider.teams.isEmpty
                ? const Center(child: Text('No teams assigned'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: adminProvider.teams.length,
                    itemBuilder: (context, index) {
                      final team = adminProvider.teams[index];
                      final stats = adminProvider.getPerformanceStats(team.teamId);
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TeamDetailScreen(team: team),
                              ),
                            );
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
                                        'Progress',
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
                    },
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
}
