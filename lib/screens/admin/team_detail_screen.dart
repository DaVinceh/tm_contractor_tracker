import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_provider.dart';
import '../../models/contractor_team_model.dart';
import '../../utils/theme.dart';
import 'admin_task_detail_screen.dart';

class TeamDetailScreen extends StatefulWidget {
  final ContractorTeam team;

  const TeamDetailScreen({super.key, required this.team});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadTeamData();
  }

  Future<void> _loadTeamData() async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    await adminProvider.loadAttendance(teamId: widget.team.teamId);
    await adminProvider.loadTasksForTeams([widget.team.teamId]);
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final stats = adminProvider.getPerformanceStats(widget.team.teamId);
    final teamTasks = adminProvider.tasksByTeam[widget.team.teamId] ?? [];
    final teamAttendance = adminProvider.attendanceRecords
        .where((a) => a.teamId == widget.team.teamId)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Team ${widget.team.teamId}'),
      ),
      body: Column(
        children: [
          // Team Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.group,
                  size: 60,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  'Team ${widget.team.teamId}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Leader: ${widget.team.leaderName}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Stats Cards
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Tasks',
                    '${stats['completed_tasks']}/${stats['total_tasks']}',
                    Icons.task_alt,
                    AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Progress',
                    '${stats['average_completion'].toInt()}%',
                    Icons.trending_up,
                    AppTheme.successColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Attendance',
                    '${stats['attendance_rate'].toInt()}%',
                    Icons.calendar_today,
                    AppTheme.accentColor,
                  ),
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTab('Attendance', 0),
                ),
                Expanded(
                  child: _buildTab('Tasks', 1),
                ),
                Expanded(
                  child: _buildTab('Performance', 2),
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: IndexedStack(
              index: _selectedTabIndex,
              children: [
                _buildAttendanceTab(teamAttendance),
                _buildTasksTab(teamTasks),
                _buildPerformanceTab(stats),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.textSecondaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
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
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceTab(List attendance) {
    if (attendance.isEmpty) {
      return const Center(
        child: Text('No attendance records'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: attendance.length,
      itemBuilder: (context, index) {
        final record = attendance[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppTheme.successColor,
              child: Icon(Icons.check, color: Colors.white),
            ),
            title: Text(
              DateFormat('EEEE, MMMM d, y').format(record.date),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Checked in at ${DateFormat('HH:mm').format(record.checkInTime)}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.location_on, color: AppTheme.primaryColor),
              onPressed: () {
                // Show location on map
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Check-in Location'),
                    content: Text(
                      'Lat: ${record.latitude}\nLong: ${record.longitude}',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildTasksTab(List tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks assigned to this team',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create tasks from the SO Dashboard',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    // Sort tasks by priority and date
    final sortedTasks = List.from(tasks);
    sortedTasks.sort((a, b) {
      final priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
      final aPriority =
          priorityOrder[a.priority?.toLowerCase() ?? 'medium'] ?? 1;
      final bPriority =
          priorityOrder[b.priority?.toLowerCase() ?? 'medium'] ?? 1;

      if (aPriority != bPriority) {
        return aPriority.compareTo(bPriority);
      }
      return b.startDate.compareTo(a.startDate);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedTasks.length,
      itemBuilder: (context, index) {
        final task = sortedTasks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminTaskDetailScreen(task: task),
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
                      Expanded(
                        child: Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildPriorityChip(task.priority ?? 'medium'),
                      const SizedBox(width: 8),
                      _buildStatusChip(task.status),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Date range
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 14, color: AppTheme.textSecondaryColor),
                      const SizedBox(width: 4),
                      Text(
                        'Start: ${DateFormat('dd/MM/yyyy').format(task.startDate)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondaryColor),
                      ),
                      if (task.endDate != null) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.event,
                            size: 14, color: AppTheme.textSecondaryColor),
                        const SizedBox(width: 4),
                        Text(
                          'End: ${DateFormat('dd/MM/yyyy').format(task.endDate!)}',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondaryColor),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: task.completionPercentage / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getStatusColor(task.status),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${task.completionPercentage.toInt()}% Complete',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriorityChip(String priority) {
    Color color;
    switch (priority.toLowerCase()) {
      case 'high':
        color = Colors.red;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      case 'low':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: _getStatusColor(status),
        ),
      ),
    );
  }

  Widget _buildPerformanceTab(Map<String, dynamic> stats) {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final teamTasks = adminProvider.tasksByTeam[widget.team.teamId] ?? [];

    // Calculate task-related metrics
    final highPriorityTasks =
        teamTasks.where((t) => t.priority.toLowerCase() == 'high').length;
    final mediumPriorityTasks =
        teamTasks.where((t) => t.priority.toLowerCase() == 'medium').length;
    final lowPriorityTasks =
        teamTasks.where((t) => t.priority.toLowerCase() == 'low').length;
    final inProgressTasks =
        teamTasks.where((t) => t.status == 'in_progress').length;
    final pendingTasks = teamTasks.where((t) => t.status == 'pending').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task Performance Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Task Performance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPerformanceItem(
                    'Total Tasks',
                    stats['total_tasks'].toString(),
                    Icons.assignment,
                    AppTheme.primaryColor,
                  ),
                  _buildPerformanceItem(
                    'Completed Tasks',
                    stats['completed_tasks'].toString(),
                    Icons.check_circle,
                    AppTheme.successColor,
                  ),
                  _buildPerformanceItem(
                    'In Progress',
                    inProgressTasks.toString(),
                    Icons.pending,
                    AppTheme.accentColor,
                  ),
                  _buildPerformanceItem(
                    'Pending Tasks',
                    pendingTasks.toString(),
                    Icons.radio_button_unchecked,
                    AppTheme.warningColor,
                  ),
                  _buildPerformanceItem(
                    'Average Completion',
                    '${stats['average_completion'].toInt()}%',
                    Icons.trending_up,
                    AppTheme.successColor,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Priority Distribution Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Task Priority Distribution',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPerformanceItem(
                    'High Priority',
                    highPriorityTasks.toString(),
                    Icons.priority_high,
                    Colors.red,
                  ),
                  _buildPerformanceItem(
                    'Medium Priority',
                    mediumPriorityTasks.toString(),
                    Icons.remove,
                    Colors.orange,
                  ),
                  _buildPerformanceItem(
                    'Low Priority',
                    lowPriorityTasks.toString(),
                    Icons.arrow_downward,
                    Colors.green,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Attendance Performance Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attendance Performance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPerformanceItem(
                    'Attendance (30 days)',
                    '${stats['attendance_last_30_days']} days',
                    Icons.calendar_today,
                    AppTheme.primaryColor,
                  ),
                  _buildPerformanceItem(
                    'Attendance Rate',
                    '${stats['attendance_rate'].toInt()}%',
                    Icons.percent,
                    AppTheme.successColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceItem(String label, String value, IconData icon,
      [Color? color]) {
    final itemColor = color ?? AppTheme.primaryColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: itemColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: itemColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return AppTheme.successColor;
      case 'in_progress':
        return AppTheme.primaryColor;
      default:
        return AppTheme.warningColor;
    }
  }
}
