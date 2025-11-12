import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/admin_provider.dart';
import '../../models/task_model.dart';
import '../../utils/theme.dart';

class ProductivityScreen extends StatefulWidget {
  const ProductivityScreen({super.key});

  @override
  State<ProductivityScreen> createState() => _ProductivityScreenState();
}

class _ProductivityScreenState extends State<ProductivityScreen> {
  bool _isLoading = false;
  List<Task> _allTasks = [];
  String _selectedGrouping = 'team'; // team or lor_id

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final adminProvider = context.read<AdminProvider>();
      await adminProvider.loadTasksForAllTeams();
      setState(() {
        _allTasks = adminProvider.tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tasks: $e')),
        );
      }
    }
  }

  Map<String, Map<String, dynamic>> _getProductivityByGroup() {
    final Map<String, Map<String, dynamic>> productivity = {};

    for (var task in _allTasks) {
      String groupKey;
      if (_selectedGrouping == 'team') {
        groupKey = task.teamId;
      } else {
        groupKey = task.lorId ?? 'Unassigned';
      }

      if (!productivity.containsKey(groupKey)) {
        productivity[groupKey] = {
          'total': 0,
          'completed': 0,
          'in_progress': 0,
          'pending': 0,
          'avg_completion': 0.0,
          'tasks': <Task>[],
        };
      }

      productivity[groupKey]!['total'] = productivity[groupKey]!['total'] + 1;
      productivity[groupKey]!['tasks'].add(task);

      switch (task.status) {
        case 'completed':
          productivity[groupKey]!['completed']++;
          break;
        case 'in_progress':
          productivity[groupKey]!['in_progress']++;
          break;
        case 'pending':
          productivity[groupKey]!['pending']++;
          break;
      }
    }

    // Calculate average completion
    productivity.forEach((key, value) {
      final tasks = value['tasks'] as List<Task>;
      if (tasks.isNotEmpty) {
        final totalCompletion = tasks.fold<double>(
          0.0,
          (sum, task) => sum + task.completionPercentage,
        );
        value['avg_completion'] = totalCompletion / tasks.length;
      }
    });

    return productivity;
  }

  @override
  Widget build(BuildContext context) {
    final productivity = _getProductivityByGroup();
    final sortedKeys = productivity.keys.toList()
      ..sort((a, b) {
        final aAvg = productivity[a]!['avg_completion'] as double;
        final bAvg = productivity[b]!['avg_completion'] as double;
        return bAvg.compareTo(aAvg); // Sort descending by completion
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productivity Dashboard'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Grouping selector
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Group by: ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('Team'),
                        selected: _selectedGrouping == 'team',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedGrouping = 'team');
                          }
                        },
                        selectedColor: Colors.deepPurple,
                        labelStyle: TextStyle(
                          color: _selectedGrouping == 'team'
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('LOR ID'),
                        selected: _selectedGrouping == 'lor_id',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedGrouping = 'lor_id');
                          }
                        },
                        selectedColor: Colors.deepPurple,
                        labelStyle: TextStyle(
                          color: _selectedGrouping == 'lor_id'
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                // Overall productivity chart
                if (productivity.isNotEmpty)
                  Container(
                    height: 250,
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Average Completion by Group',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: 100,
                                  barTouchData: BarTouchData(
                                    enabled: true,
                                    touchTooltipData: BarTouchTooltipData(
                                      getTooltipItem:
                                          (group, groupIndex, rod, rodIndex) {
                                        final key = sortedKeys[group.x.toInt()];
                                        return BarTooltipItem(
                                          '$key\n${rod.toY.toStringAsFixed(1)}%',
                                          const TextStyle(color: Colors.white),
                                        );
                                      },
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          if (value.toInt() <
                                              sortedKeys.length) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 8.0),
                                              child: Text(
                                                sortedKeys[value.toInt()],
                                                style: const TextStyle(
                                                    fontSize: 10),
                                              ),
                                            );
                                          }
                                          return const Text('');
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                        getTitlesWidget: (value, meta) {
                                          return Text('${value.toInt()}%');
                                        },
                                      ),
                                    ),
                                    topTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  barGroups:
                                      sortedKeys.asMap().entries.map((entry) {
                                    final avgCompletion = productivity[entry
                                        .value]!['avg_completion'] as double;
                                    return BarChartGroupData(
                                      x: entry.key,
                                      barRods: [
                                        BarChartRodData(
                                          toY: avgCompletion,
                                          color: _getColorForCompletion(
                                              avgCompletion),
                                          width: 30,
                                        )
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Detailed list
                Expanded(
                  child: productivity.isEmpty
                      ? const Center(
                          child: Text('No productivity data available'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: sortedKeys.length,
                          itemBuilder: (context, index) {
                            final key = sortedKeys[index];
                            final data = productivity[key]!;
                            final avgCompletion =
                                data['avg_completion'] as double;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ExpansionTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      _getColorForCompletion(avgCompletion),
                                  child: Text(
                                    '${avgCompletion.toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${data['total']} tasks • ${data['completed']} completed',
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            _buildStatColumn(
                                              'Completed',
                                              data['completed'].toString(),
                                              AppTheme.successColor,
                                            ),
                                            _buildStatColumn(
                                              'In Progress',
                                              data['in_progress'].toString(),
                                              AppTheme.accentColor,
                                            ),
                                            _buildStatColumn(
                                              'Pending',
                                              data['pending'].toString(),
                                              AppTheme.warningColor,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Tasks:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...(data['tasks'] as List<Task>)
                                            .map((task) {
                                          return ListTile(
                                            dense: true,
                                            contentPadding: EdgeInsets.zero,
                                            leading: Icon(
                                              _getIconForStatus(task.status),
                                              color: _getColorForStatus(
                                                  task.status),
                                              size: 20,
                                            ),
                                            title: Text(
                                              task.title,
                                              style:
                                                  const TextStyle(fontSize: 13),
                                            ),
                                            subtitle: Text(
                                              '${task.completionPercentage}% • ${task.priority}',
                                              style:
                                                  const TextStyle(fontSize: 11),
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Color _getColorForCompletion(double completion) {
    if (completion >= 75) return AppTheme.successColor;
    if (completion >= 50) return AppTheme.accentColor;
    if (completion >= 25) return AppTheme.warningColor;
    return Colors.red;
  }

  Color _getColorForStatus(String status) {
    switch (status) {
      case 'completed':
        return AppTheme.successColor;
      case 'in_progress':
        return AppTheme.accentColor;
      case 'pending':
        return AppTheme.warningColor;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForStatus(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.pending;
      case 'pending':
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }
}
