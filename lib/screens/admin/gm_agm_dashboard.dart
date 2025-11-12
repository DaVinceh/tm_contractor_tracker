import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../utils/theme.dart';
import '../login_selection_screen.dart';
import 'staff_detail_screen.dart';

class GMAgmDashboard extends StatefulWidget {
  const GMAgmDashboard({super.key});

  @override
  State<GMAgmDashboard> createState() => _GMAgmDashboardState();
}

class _GMAgmDashboardState extends State<GMAgmDashboard> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    await adminProvider.loadAllStaff();
    await adminProvider.loadAttendance();
    // Load all tasks for report/productivity screens
    await adminProvider.loadTasksForAllTeams();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final adminProvider = Provider.of<AdminProvider>(context);
    final user = authProvider.currentUser!;

    final executives = adminProvider.subordinates
        .where((s) => s.role.toString().contains('executive'))
        .toList();
    final sos = adminProvider.subordinates
        .where((s) => s.role.toString().contains('so'))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('GM/AGM Dashboard'),
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
                                Icons.account_balance,
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
                                    'General Manager / Assistant GM',
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
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _buildStatCard(
                          'Executives',
                          executives.length.toString(),
                          Icons.business_center,
                          AppTheme.primaryColor,
                        ),
                        _buildStatCard(
                          'Site Officers',
                          sos.length.toString(),
                          Icons.supervisor_account,
                          AppTheme.secondaryColor,
                        ),
                        _buildStatCard(
                          'Total Staff',
                          adminProvider.subordinates.length.toString(),
                          Icons.people,
                          AppTheme.accentColor,
                        ),
                        _buildStatCard(
                          'Check-ins Today',
                          _getTodayCheckIns(adminProvider).toString(),
                          Icons.check_circle,
                          AppTheme.successColor,
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
                          child: Card(
                            child: InkWell(
                              onTap: () {
                                Navigator.pushNamed(context, '/report_summary');
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.analytics,
                                        size: 32,
                                        color: AppTheme.accentColor,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Report Summary',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Card(
                            child: InkWell(
                              onTap: () {
                                Navigator.pushNamed(context, '/productivity');
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppTheme.successColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.trending_up,
                                        size: 32,
                                        color: AppTheme.successColor,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Productivity',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Analytics Card
                    Card(
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, '/report_summary');
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppTheme.primaryColor,
                                      AppTheme.accentColor
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.analytics,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Comprehensive Reports',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'View analytics, graphs, and export to Excel',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: AppTheme.primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Staff Overview
                    const Text(
                      'Staff Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Executives Section
                    if (executives.isNotEmpty) ...[
                      const Text(
                        'Executives',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...executives.map((exec) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppTheme.primaryColor.withOpacity(0.1),
                              child: const Icon(
                                Icons.business_center,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              exec.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(exec.email),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      StaffDetailScreen(staff: exec),
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 16),
                    ],

                    // Site Officers Section
                    if (sos.isNotEmpty) ...[
                      const Text(
                        'Site Officers',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...sos.map((so) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppTheme.secondaryColor.withOpacity(0.1),
                              child: const Icon(
                                Icons.supervisor_account,
                                color: AppTheme.secondaryColor,
                                size: 20,
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
                                  builder: (_) => StaffDetailScreen(staff: so),
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    ],
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
