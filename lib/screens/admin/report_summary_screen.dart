import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/theme.dart';
import '../../utils/excel_export.dart';

class ReportSummaryScreen extends StatefulWidget {
  final bool showAllData;

  const ReportSummaryScreen({super.key, this.showAllData = false});

  @override
  State<ReportSummaryScreen> createState() => _ReportSummaryScreenState();
}

class _ReportSummaryScreenState extends State<ReportSummaryScreen> {
  final _firestore = FirebaseFirestore.instance;
  String _selectedPeriod = 'weekly';
  bool _isLoading = false;
  bool _isExporting = false;
  Map<String, dynamic> _reportData = {};

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      DateTime startDate;
      final now = DateTime.now();

      switch (_selectedPeriod) {
        case 'daily':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'weekly':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'monthly':
          startDate = DateTime(now.year, now.month, 1);
          break;
        case 'annually':
          startDate = DateTime(now.year, 1, 1);
          break;
        default:
          startDate = now.subtract(const Duration(days: 7));
      }

      print(
          '📊 Report Summary: Loading data for period $_selectedPeriod from $startDate');

      // Load ALL tasks first to ensure we have data
      final tasksSnapshot = await _firestore.collection('tasks').get();

      final allTasks = tasksSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      print(
          '📊 Report Summary: Found ${allTasks.length} total tasks in database');

      // Filter tasks by period if needed
      List filteredTasks = allTasks;
      if (_selectedPeriod != 'all') {
        filteredTasks = allTasks.where((task) {
          try {
            // Check start_date
            final taskStartDate = task['start_date'] is Timestamp
                ? (task['start_date'] as Timestamp).toDate()
                : DateTime.parse(task['start_date']);

            // For completed tasks, check when they were completed (updated_at or created_at)
            DateTime? completionDate;
            if (task['status'] == 'completed') {
              if (task['updated_at'] != null) {
                try {
                  completionDate = task['updated_at'] is Timestamp
                      ? (task['updated_at'] as Timestamp).toDate()
                      : DateTime.parse(task['updated_at']);
                } catch (e) {
                  print('⚠️ Error parsing updated_at: $e');
                }
              }
              // If no updated_at, try created_at as fallback
              if (completionDate == null && task['created_at'] != null) {
                try {
                  completionDate = task['created_at'] is Timestamp
                      ? (task['created_at'] as Timestamp).toDate()
                      : DateTime.parse(task['created_at']);
                } catch (e) {
                  print('⚠️ Error parsing created_at: $e');
                }
              }
            }

            // For daily period, be more inclusive - show all relevant activity today
            if (_selectedPeriod == 'daily') {
              final today = DateTime(now.year, now.month, now.day);
              final taskStartDay = DateTime(
                  taskStartDate.year, taskStartDate.month, taskStartDate.day);

              // Include if started today
              if (taskStartDay.isAtSameMomentAs(today)) {
                return true;
              }

              // Include if completed today
              if (completionDate != null) {
                final completionDay = DateTime(completionDate.year,
                    completionDate.month, completionDate.day);
                if (completionDay.isAtSameMomentAs(today)) {
                  return true;
                }
              }

              // For tasks without updated_at, include completed tasks from this week
              // This helps show recently completed tasks
              if (task['status'] == 'completed' && completionDate == null) {
                final weekAgo = now.subtract(const Duration(days: 7));
                if (taskStartDate.isAfter(weekAgo)) {
                  return true;
                }
              }

              return false;
            }

            // For other periods, check if task started within period OR completed within period
            final isInPeriod = taskStartDate.isAfter(startDate) ||
                taskStartDate.isAtSameMomentAs(startDate);
            final isCompletedInPeriod = completionDate != null &&
                (completionDate.isAfter(startDate) ||
                    completionDate.isAtSameMomentAs(startDate));

            return isInPeriod || isCompletedInPeriod;
          } catch (e) {
            print('⚠️ Error parsing task date: $e');
            return true; // Include tasks with date errors
          }
        }).toList();
      }

      print(
          '📊 Report Summary: ${filteredTasks.length} tasks match period filter');

      // Load attendance data for the period
      final attendanceSnapshot = await _firestore
          .collection('attendance')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .get();

      final attendanceResponse = attendanceSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      print(
          '📊 Report Summary: ${attendanceResponse.length} attendance records for period');

      setState(() {
        _reportData = {
          'tasks': filteredTasks,
          'all_tasks': allTasks, // Keep all tasks for reference
          'attendance': attendanceResponse as List,
          'startDate': startDate,
          'endDate': now,
        };
        _isLoading = false;
      });

      if (allTasks.isEmpty) {
        print('⚠️ Warning: No tasks found in Firestore!');
        print(
            '   Go to Debug screen (bug icon in SO Dashboard) to create sample tasks.');
      }
    } catch (e) {
      print('❌ Error loading report: $e');
      print('   Stack trace: ${StackTrace.current}');
      setState(() {
        _reportData = {
          'tasks': [],
          'attendance': [],
          'startDate': DateTime.now().subtract(const Duration(days: 7)),
          'endDate': DateTime.now(),
        };
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading report: $e'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _exportToExcel() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final exporter = ExcelExport();
      await exporter.exportReport(
        reportData: _reportData,
        period: _selectedPeriod,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report exported successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _reportData['tasks'] as List? ?? [];
    final attendance = _reportData['attendance'] as List? ?? [];

    print(
        '📊 Building Report Summary: ${tasks.length} tasks, ${attendance.length} attendance records');

    final totalTasks = tasks.length;
    final completedTasks =
        tasks.where((t) => t['status'] == 'completed').length;
    final inProgressTasks =
        tasks.where((t) => t['status'] == 'in_progress').length;
    final pendingTasks = tasks.where((t) => t['status'] == 'pending').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Summary'),
        actions: [
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.download),
            onPressed: _isExporting ? null : _exportToExcel,
            tooltip: 'Export to Excel',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period Selector
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Report Period',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: [
                              _buildPeriodChip('All Time', 'all'),
                              _buildPeriodChip('Daily', 'daily'),
                              _buildPeriodChip('Weekly', 'weekly'),
                              _buildPeriodChip('Monthly', 'monthly'),
                              _buildPeriodChip('Annually', 'annually'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Summary Stats
                  const Text(
                    'Summary Statistics',
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
                      _buildStatCard(
                        'Total Tasks',
                        totalTasks.toString(),
                        Icons.assignment,
                        AppTheme.primaryColor,
                      ),
                      _buildStatCard(
                        'Completed',
                        completedTasks.toString(),
                        Icons.check_circle,
                        AppTheme.successColor,
                      ),
                      _buildStatCard(
                        'In Progress',
                        inProgressTasks.toString(),
                        Icons.pending,
                        AppTheme.accentColor,
                      ),
                      _buildStatCard(
                        'Attendance',
                        attendance.length.toString(),
                        Icons.people,
                        AppTheme.warningColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Task Progress Chart
                  const Text(
                    'Task Progress Distribution',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        height: 250,
                        child: totalTasks > 0
                            ? PieChart(
                                PieChartData(
                                  sections: [
                                    if (completedTasks > 0)
                                      PieChartSectionData(
                                        value: completedTasks.toDouble(),
                                        title: 'Completed\n$completedTasks',
                                        color: AppTheme.successColor,
                                        radius: 80,
                                        titleStyle: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    if (inProgressTasks > 0)
                                      PieChartSectionData(
                                        value: inProgressTasks.toDouble(),
                                        title: 'In Progress\n$inProgressTasks',
                                        color: AppTheme.accentColor,
                                        radius: 80,
                                        titleStyle: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    if (pendingTasks > 0)
                                      PieChartSectionData(
                                        value: pendingTasks.toDouble(),
                                        title: 'Pending\n$pendingTasks',
                                        color: AppTheme.warningColor,
                                        radius: 80,
                                        titleStyle: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                  ],
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 0,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.pie_chart_outline,
                                      size: 64, color: Colors.grey[300]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No task data for selected period',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedPeriod = 'all';
                                      });
                                      _loadReportData();
                                    },
                                    child: const Text('View All Time'),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Attendance Chart
                  const Text(
                    'Attendance Trend',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        height: 250,
                        child: attendance.isNotEmpty
                            ? _buildAttendanceChart(attendance)
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.show_chart,
                                      size: 64, color: Colors.grey[300]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No attendance data for selected period',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Attendance records will appear here',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Task Details Table
                  const Text(
                    'Task Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: tasks.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.inbox_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No tasks available',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Create sample tasks from the Debug screen\nto see data here',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    icon: const Icon(Icons.arrow_back),
                                    label: const Text('Go Back'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columnSpacing: 20,
                              columns: const [
                                DataColumn(label: Text('Project #')),
                                DataColumn(label: Text('Project ID')),
                                DataColumn(label: Text('Description')),
                                DataColumn(label: Text('Exchange')),
                                DataColumn(label: Text('State')),
                                DataColumn(label: Text('TM Note')),
                                DataColumn(label: Text('Program')),
                                DataColumn(label: Text('LOR ID')),
                                DataColumn(label: Text('Priority')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Progress')),
                              ],
                              rows: tasks.map<DataRow>((task) {
                                return DataRow(cells: [
                                  DataCell(
                                      Text(task['project_number'] ?? 'N/A')),
                                  DataCell(Text(task['project_id'] ?? 'N/A')),
                                  DataCell(
                                    SizedBox(
                                      width: 150,
                                      child: Text(
                                        task['title'] ?? 'N/A',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(task['exchange'] ?? 'N/A')),
                                  DataCell(Text(task['state'] ?? 'N/A')),
                                  DataCell(
                                    SizedBox(
                                      width: 100,
                                      child: Text(
                                        task['tm_note'] ?? 'N/A',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(task['program'] ?? 'N/A')),
                                  DataCell(Text(task['lor_id'] ?? 'N/A')),
                                  DataCell(_buildPriorityChip(
                                      task['priority'] ?? 'medium')),
                                  DataCell(_buildStatusChip(
                                      task['status'] ?? 'pending')),
                                  DataCell(Text(
                                      '${task['completion_percentage'] ?? 0}%')),
                                ]);
                              }).toList(),
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),

                  // Export Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isExporting ? null : _exportToExcel,
                      icon: _isExporting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.file_download),
                      label: Text(
                          _isExporting ? 'Exporting...' : 'Export to Excel'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.successColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedPeriod = value;
          });
          _loadReportData();
        }
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceChart(List attendance) {
    try {
      // Group attendance by date
      Map<DateTime, int> attendanceByDate = {};
      for (var record in attendance) {
        try {
          DateTime date;
          if (record['date'] is Timestamp) {
            date = (record['date'] as Timestamp).toDate();
          } else if (record['date'] is String) {
            date = DateTime.parse(record['date']);
          } else {
            continue;
          }

          final dateOnly = DateTime(date.year, date.month, date.day);
          attendanceByDate[dateOnly] = (attendanceByDate[dateOnly] ?? 0) + 1;
        } catch (e) {
          print('⚠️ Error parsing attendance date: $e');
          continue;
        }
      }

      if (attendanceByDate.isEmpty) {
        return Center(
          child: Text(
            'Unable to parse attendance data',
            style: TextStyle(color: Colors.grey[600]),
          ),
        );
      }

      final sortedDates = attendanceByDate.keys.toList()..sort();

      return LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false),
          titlesData: const FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey[300]!),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: sortedDates.asMap().entries.map((entry) {
                return FlSpot(
                  entry.key.toDouble(),
                  attendanceByDate[entry.value]!.toDouble(),
                );
              }).toList(),
              isCurved: true,
              color: AppTheme.primaryColor,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primaryColor.withOpacity(0.2),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      print('❌ Error building attendance chart: $e');
      return Center(
        child: Text(
          'Error displaying chart',
          style: TextStyle(color: Colors.red[600]),
        ),
      );
    }
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
    return Chip(
      label: Text(priority.toUpperCase(), style: const TextStyle(fontSize: 10)),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'completed':
        color = AppTheme.successColor;
        break;
      case 'in_progress':
        color = AppTheme.accentColor;
        break;
      case 'pending':
        color = AppTheme.warningColor;
        break;
      default:
        color = Colors.grey;
    }
    return Chip(
      label: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: const TextStyle(fontSize: 10),
      ),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
