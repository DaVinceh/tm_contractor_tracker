import 'package:flutter/material.dart';
import '../../utils/create_sample_tasks.dart';
import '../../utils/assign_sos_to_executive.dart';

/// Debug screen to create sample data
/// Access this from any admin dashboard for testing
class DebugDataScreen extends StatefulWidget {
  const DebugDataScreen({super.key});

  @override
  State<DebugDataScreen> createState() => _DebugDataScreenState();
}

class _DebugDataScreenState extends State<DebugDataScreen> {
  bool _isCreating = false;
  bool _isAssigning = false;
  bool _isCreatingUsers = false;
  String _message = '';

  Future<void> _createSampleData() async {
    setState(() {
      _isCreating = true;
      _message = 'Creating sample tasks...';
    });

    try {
      await createSampleTasks();
      setState(() {
        _isCreating = false;
        _message = '✅ Successfully created 9 sample tasks!\n\n'
            'TEAM001: 3 tasks\n'
            'TEAM002: 3 tasks\n'
            'TEAM003: 3 tasks\n\n'
            'Tasks include various priorities (High/Medium/Low) and statuses (Pending/In Progress/Completed)';
      });
    } catch (e) {
      setState(() {
        _isCreating = false;
        _message = '❌ Error: $e';
      });
    }
  }

  Future<void> _assignSOsToExecutive() async {
    setState(() {
      _isAssigning = true;
      _message = 'Assigning SOs to Executive...';
    });

    try {
      await assignSOsToExecutive();
      setState(() {
        _isAssigning = false;
        _message = '✅ Successfully assigned all SOs to Executive!\n\n'
            'Check the console for detailed output.';
      });
    } catch (e) {
      setState(() {
        _isAssigning = false;
        _message = '❌ Error: $e';
      });
    }
  }

  Future<void> _createTestUsers() async {
    setState(() {
      _isCreatingUsers = true;
      _message = 'Creating test users...';
    });

    try {
      await createTestUsers();
      setState(() {
        _isCreatingUsers = false;
        _message = '✅ Successfully created test users!\n\n'
            'Users created:\n'
            '• Executive User (executive@test.com)\n'
            '• Site Officer 1 (so1@test.com)\n'
            '• Site Officer 2 (so2@test.com)\n'
            '• Contractors for TEAM001, TEAM002, TEAM003\n\n'
            'Check the console for detailed output.';
      });
    } catch (e) {
      setState(() {
        _isCreatingUsers = false;
        _message = '❌ Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug - Create Sample Data'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debug & Setup Tools',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Create Sample Tasks: Generate 9 test tasks with realistic data\n'
                      '2. Assign SOs to Executive: Link all Site Officers to Executive user\n'
                      '3. Create Test Users: Generate test users for all roles\n\n'
                      'Use these tools to quickly set up test data.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isCreating ? null : _createSampleData,
              icon: _isCreating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.add_circle),
              label: Text(_isCreating ? 'Creating...' : 'Create Sample Tasks'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isAssigning ? null : _assignSOsToExecutive,
              icon: _isAssigning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.supervisor_account),
              label: Text(
                  _isAssigning ? 'Assigning...' : 'Assign SOs to Executive'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isCreatingUsers ? null : _createTestUsers,
              icon: _isCreatingUsers
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.people),
              label:
                  Text(_isCreatingUsers ? 'Creating...' : 'Create Test Users'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            if (_message.isNotEmpty)
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Text(
                        _message,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
