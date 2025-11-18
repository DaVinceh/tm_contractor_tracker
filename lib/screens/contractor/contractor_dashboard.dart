import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contractor_provider.dart';
import '../../models/task_model.dart';
import '../../utils/theme.dart';
import '../login_selection_screen.dart';
import 'check_in_screen.dart';
import 'task_list_screen.dart';

class ContractorDashboard extends StatefulWidget {
  const ContractorDashboard({super.key});

  @override
  State<ContractorDashboard> createState() => _ContractorDashboardState();
}

class _ContractorDashboardState extends State<ContractorDashboard> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final contractorProvider =
        Provider.of<ContractorProvider>(context, listen: false);

    final user = authProvider.currentUser!;
    // Load today's attendance
    await contractorProvider.loadTodayAttendance(user.id);
    // Load tasks
    await contractorProvider.loadTasks(user.teamId!);
    // Load notifications
    await contractorProvider.loadNotifications(user.teamId!);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final contractorProvider = Provider.of<ContractorProvider>(context);
    final user = authProvider.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contractor Dashboard'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () => _showNotificationsDialog(),
              ),
              if (contractorProvider.unreadNotificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${contractorProvider.unreadNotificationCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Clear check-in status on logout
              contractorProvider.clearCheckInStatus();
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
        child: SingleChildScrollView(
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
                          Icons.person,
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
                            Text(
                              'Team ID: ${user.teamId}',
                              style: const TextStyle(
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

              // Check-in Status Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            contractorProvider.hasCheckedInToday
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: contractorProvider.hasCheckedInToday
                                ? AppTheme.successColor
                                : AppTheme.warningColor,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Today\'s Check-in',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (contractorProvider.hasCheckedInToday)
                        Text(
                          'Checked in at ${_formatTime(contractorProvider.todayAttendance!.checkInTime)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.successColor,
                          ),
                        )
                      else
                        const Text(
                          'You haven\'t checked in today',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.warningColor,
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (!contractorProvider.hasCheckedInToday)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context)
                                  .push(
                                    MaterialPageRoute(
                                      builder: (_) => const CheckInScreen(),
                                    ),
                                  )
                                  .then((_) => _loadData());
                            },
                            icon: const Icon(Icons.location_on),
                            label: const Text('Check In Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
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
                      context,
                      icon: Icons.task_alt,
                      title: 'My Tasks',
                      count: contractorProvider.tasks.length.toString(),
                      color: AppTheme.primaryColor,
                      onTap: () {
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (_) => const TaskListScreen(),
                              ),
                            )
                            .then((_) => _loadData());
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      context,
                      icon: Icons.check_circle,
                      title: 'Completed',
                      count: contractorProvider.tasks
                          .where((t) => t.status == 'completed')
                          .length
                          .toString(),
                      color: AppTheme.successColor,
                      onTap: () {
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (_) => const TaskListScreen(),
                              ),
                            )
                            .then((_) => _loadData());
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Recent Tasks
              const Text(
                'Recent Tasks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (contractorProvider.tasks.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text('No tasks assigned yet'),
                    ),
                  ),
                )
              else
                ..._getSortedTasks(contractorProvider.tasks)
                    .take(5)
                    .map((task) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            _getPriorityColor(task.priority).withOpacity(0.1),
                        child: Icon(
                          _getPriorityIcon(task.priority),
                          color: _getPriorityColor(task.priority),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          _buildPriorityBadge(task.priority),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'Start: ${_formatDate(task.startDate)}${task.endDate != null ? ' • End: ${_formatDate(task.endDate!)}' : ''}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: task.completionPercentage / 100,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getStatusColor(task.status),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${task.completionPercentage.toInt()}% complete',
                                style: const TextStyle(fontSize: 12),
                              ),
                              _buildStatusBadge(task.status),
                            ],
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (_) => const TaskListScreen(),
                              ),
                            )
                            .then((_) => _loadData());
                      },
                    ),
                  );
                }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                count,
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
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  List<Task> _getSortedTasks(List<Task> tasks) {
    final sortedTasks = List<Task>.from(tasks);
    // Sort by priority: high -> medium -> low, then by start date
    sortedTasks.sort((a, b) {
      final priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
      final aPriority = priorityOrder[a.priority.toLowerCase()] ?? 1;
      final bPriority = priorityOrder[b.priority.toLowerCase()] ?? 1;

      if (aPriority != bPriority) {
        return aPriority.compareTo(bPriority);
      }
      return b.startDate.compareTo(a.startDate);
    });
    return sortedTasks;
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.remove;
      case 'low':
        return Icons.arrow_downward;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildPriorityBadge(String priority) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getPriorityColor(priority).withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: _getPriorityColor(priority),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.2),
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.pending;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  void _showNotificationsDialog() {
    final contractorProvider =
        Provider.of<ContractorProvider>(context, listen: false);
    final notifications = contractorProvider.notifications;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: notifications.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: Text('No notifications'),
              )
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: notification.isRead
                          ? null
                          : AppTheme.primaryColor.withOpacity(0.1),
                      child: ListTile(
                        leading: Icon(
                          notification.changeType == 'deleted'
                              ? Icons.delete
                              : notification.changeType == 'restored'
                                  ? Icons.restore
                                  : Icons.update,
                          color: notification.changeType == 'deleted'
                              ? AppTheme.errorColor
                              : notification.changeType == 'restored'
                                  ? AppTheme.successColor
                                  : AppTheme.primaryColor,
                        ),
                        title: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(notification.message),
                        trailing: !notification.isRead
                            ? Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null,
                        onTap: () async {
                          // Mark as read
                          await contractorProvider
                              .markNotificationAsRead(notification.id);

                          // Close dialog
                          if (mounted) Navigator.pop(context);

                          // Navigate to task list where the user can see the updated task
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TaskListScreen(),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
