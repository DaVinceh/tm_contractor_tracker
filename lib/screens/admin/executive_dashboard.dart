import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../utils/theme.dart';
import '../login_selection_screen.dart';
import 'so_teams_view_screen.dart';
import 'executive_all_teams_screen.dart';

class ExecutiveDashboard extends StatefulWidget {
  const ExecutiveDashboard({super.key});

  @override
  State<ExecutiveDashboard> createState() => _ExecutiveDashboardState();
}

class _ExecutiveDashboardState extends State<ExecutiveDashboard> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    final user = authProvider.currentUser!;
    await adminProvider.loadSOsForExecutive(user.id);
    await adminProvider.loadAttendance();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final adminProvider = Provider.of<AdminProvider>(context);
    final user = authProvider.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Executive Dashboard'),
        actions: [
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
                                Icons.business_center,
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
                                    'Executive',
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
                            'Site Officers',
                            adminProvider.subordinates.length.toString(),
                            Icons.supervisor_account,
                            AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Check-ins',
                            _getTodayCheckIns(adminProvider).toString(),
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
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.analytics,
                                color: AppTheme.accentColor,
                              ),
                            ),
                            title: const Text(
                              'Report Summary',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: const Text(
                                'View detailed analytics and export reports'),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.pushNamed(context, '/report_summary');
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.successColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.trending_up,
                                color: AppTheme.successColor,
                              ),
                            ),
                            title: const Text(
                              'Productivity',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: const Text(
                                'Monitor team performance and progress'),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.pushNamed(context, '/productivity');
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.people,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            title: const Text(
                              'View All Teams',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: const Text('Access all contractor teams'),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const ExecutiveAllTeamsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Site Officers List
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Site Officers',
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
                    if (adminProvider.subordinates.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(
                            child: Text('No site officers assigned'),
                          ),
                        ),
                      )
                    else
                      ...adminProvider.subordinates.map((so) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppTheme.primaryColor.withOpacity(0.1),
                              child: const Icon(
                                Icons.person,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            title: Text(
                              so.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(so.email),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SOTeamsViewScreen(so: so),
                                ),
                              );
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
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  int _getTodayCheckIns(AdminProvider provider) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    return provider.attendanceRecords
        .where(
            (a) => a.date.isAfter(todayStart.subtract(const Duration(days: 1))))
        .length;
  }
}
