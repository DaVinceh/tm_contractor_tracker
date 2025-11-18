import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/task_model.dart';
import '../../models/contractor_team_model.dart';
import '../../utils/theme.dart';

class TaskManagementScreen extends StatefulWidget {
  const TaskManagementScreen({super.key});

  @override
  State<TaskManagementScreen> createState() => _TaskManagementScreenState();
}

class _TaskManagementScreenState extends State<TaskManagementScreen> {
  String? _selectedTeamFilter;
  bool _showDeleted = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await adminProvider.loadTeamsForSO(authProvider.currentUser!.id);
    final teamIds = adminProvider.teams.map((t) => t.teamId).toList();
    if (teamIds.isNotEmpty) {
      await adminProvider.loadTasksForTeams(teamIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    // Get all tasks from all teams
    List<Task> allTasks = [];
    for (var teamTasks in adminProvider.tasksByTeam.values) {
      allTasks.addAll(teamTasks);
    }

    // Apply filters
    List<Task> filteredTasks = allTasks.where((task) {
      if (_selectedTeamFilter != null && task.teamId != _selectedTeamFilter) {
        return false;
      }
      if (!_showDeleted && task.isDeleted) {
        return false;
      }
      if (_showDeleted && !task.isDeleted) {
        return false;
      }
      return true;
    }).toList();

    // Sort by date
    filteredTasks.sort((a, b) => b.startDate.compareTo(a.startDate));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
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
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedTeamFilter,
                        decoration: const InputDecoration(
                          labelText: 'Filter by Team',
                          prefixIcon: Icon(Icons.filter_list),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Teams'),
                          ),
                          ...adminProvider.teams.map((team) {
                            return DropdownMenuItem(
                              value: team.teamId,
                              child: Text('Team ${team.teamId}'),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedTeamFilter = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilterChip(
                      label: Text(_showDeleted ? 'Deleted' : 'Active'),
                      selected: _showDeleted,
                      onSelected: (value) {
                        setState(() {
                          _showDeleted = value;
                        });
                      },
                      selectedColor: AppTheme.errorColor.withOpacity(0.2),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Task List
          Expanded(
            child: adminProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _showDeleted
                                  ? Icons.delete_outline
                                  : Icons.assignment_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _showDeleted
                                  ? 'No deleted tasks'
                                  : 'No tasks found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = filteredTasks[index];
                            return _buildTaskCard(task, authProvider);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: _showDeleted
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddTaskDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Task'),
            ),
    );
  }

  Widget _buildTaskCard(Task task, AuthProvider authProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Team ${task.teamId}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildPriorityChip(task.priority),
                const SizedBox(width: 8),
                _buildStatusChip(task.status),
                const Spacer(),
                if (task.isDeleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'DELETED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (task.lorId != null && task.lorId!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'LOR ID: ${task.lorId}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 14, color: AppTheme.textSecondaryColor),
                const SizedBox(width: 4),
                Text(
                  'Start: ${DateFormat('dd/MM/yyyy').format(task.startDate)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                if (task.endDate != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.event,
                      size: 14, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 4),
                  Text(
                    'End: ${DateFormat('dd/MM/yyyy').format(task.endDate!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: task.completionPercentage / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getStatusColor(task.status),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${task.completionPercentage.toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (task.isDeleted)
                  TextButton.icon(
                    onPressed: () => _restoreTask(task),
                    icon: const Icon(Icons.restore, size: 18),
                    label: const Text('Restore'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.successColor,
                    ),
                  )
                else ...[
                  TextButton.icon(
                    onPressed: () => _showEditTaskDialog(task),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                  ),
                  TextButton.icon(
                    onPressed: () => _confirmDeleteTask(task),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  void _showAddTaskDialog() {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (adminProvider.teams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No teams available. Please create a team first.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        teams: adminProvider.teams,
        createdBy: authProvider.currentUser!.id,
        onTaskAdded: _loadData,
      ),
    );
  }

  void _showEditTaskDialog(Task task) {
    showDialog(
      context: context,
      builder: (context) => EditTaskDialog(
        task: task,
        onTaskUpdated: _loadData,
      ),
    );
  }

  Future<void> _confirmDeleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text(
          'Are you sure you want to delete "${task.title}"?\n\n'
          'This will hide the task from contractors but keep it in your records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      final success = await adminProvider.deleteTask(task.id, task.teamId);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task deleted successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(adminProvider.errorMessage ?? 'Failed to delete task'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _restoreTask(Task task) async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final success = await adminProvider.restoreTask(task.id, task.teamId);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task restored successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(adminProvider.errorMessage ?? 'Failed to restore task'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}

// Add Task Dialog
class AddTaskDialog extends StatefulWidget {
  final List<ContractorTeam> teams;
  final String createdBy;
  final VoidCallback onTaskAdded;

  const AddTaskDialog({
    super.key,
    required this.teams,
    required this.createdBy,
    required this.onTaskAdded,
  });

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _lorIdController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedTeam;
  String _selectedPriority = 'medium';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  @override
  void dispose() {
    _lorIdController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Task'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedTeam,
                decoration: const InputDecoration(
                  labelText: 'Select Team *',
                  prefixIcon: Icon(Icons.group),
                ),
                items: widget.teams.map((team) {
                  return DropdownMenuItem(
                    value: team.teamId,
                    child: Text('Team ${team.teamId} - ${team.leaderName}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTeam = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a team';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lorIdController,
                decoration: const InputDecoration(
                  labelText: 'LOR ID (Optional)',
                  prefixIcon: Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title *',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a task title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  prefixIcon: Icon(Icons.priority_high),
                ),
                items: const [
                  DropdownMenuItem(value: 'high', child: Text('High')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Start Date'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() {
                      _startDate = date;
                    });
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: const Text('End Date (Optional)'),
                subtitle: Text(
                  _endDate != null
                      ? DateFormat('dd/MM/yyyy').format(_endDate!)
                      : 'Not set',
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate:
                        _endDate ?? _startDate.add(const Duration(days: 7)),
                    firstDate: _startDate,
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() {
                      _endDate = date;
                    });
                  }
                },
                trailing: _endDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _endDate = null;
                          });
                        },
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitTask,
          child: const Text('Add Task'),
        ),
      ],
    );
  }

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) return;

    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    final success = await adminProvider.createTask(
      teamId: _selectedTeam!,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      priority: _selectedPriority,
      startDate: _startDate,
      endDate: _endDate,
      createdBy: widget.createdBy,
      lorId: _lorIdController.text.trim().isEmpty
          ? null
          : _lorIdController.text.trim(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task added successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context);
        widget.onTaskAdded();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(adminProvider.errorMessage ?? 'Failed to add task'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}

// Edit Task Dialog
class EditTaskDialog extends StatefulWidget {
  final Task task;
  final VoidCallback onTaskUpdated;

  const EditTaskDialog({
    super.key,
    required this.task,
    required this.onTaskUpdated,
  });

  @override
  State<EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _progressController;

  late String _selectedPriority;
  late DateTime _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController =
        TextEditingController(text: widget.task.description);
    _progressController = TextEditingController(
      text: widget.task.completionPercentage.toInt().toString(),
    );
    _selectedPriority = widget.task.priority;
    _startDate = widget.task.startDate;
    _endDate = widget.task.endDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Task'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title *',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a task title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  prefixIcon: Icon(Icons.priority_high),
                ),
                items: const [
                  DropdownMenuItem(value: 'high', child: Text('High')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _progressController,
                decoration: const InputDecoration(
                  labelText: 'Progress (%)',
                  prefixIcon: Icon(Icons.percent),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter progress percentage';
                  }
                  final progress = double.tryParse(value);
                  if (progress == null || progress < 0 || progress > 100) {
                    return 'Please enter a value between 0 and 100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Start Date'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() {
                      _startDate = date;
                    });
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: const Text('End Date'),
                subtitle: Text(
                  _endDate != null
                      ? DateFormat('dd/MM/yyyy').format(_endDate!)
                      : 'Not set',
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate:
                        _endDate ?? _startDate.add(const Duration(days: 7)),
                    firstDate: _startDate,
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() {
                      _endDate = date;
                    });
                  }
                },
                trailing: _endDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _endDate = null;
                          });
                        },
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitUpdate,
          child: const Text('Update Task'),
        ),
      ],
    );
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    final success = await adminProvider.updateTask(
      taskId: widget.task.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      priority: _selectedPriority,
      startDate: _startDate,
      endDate: _endDate,
      completionPercentage: double.parse(_progressController.text),
      teamId: widget.task.teamId,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task updated successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context);
        widget.onTaskUpdated();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(adminProvider.errorMessage ?? 'Failed to update task'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
