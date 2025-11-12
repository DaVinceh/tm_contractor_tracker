import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../utils/theme.dart';
import '../../models/contractor_team_model.dart';
import 'team_detail_screen.dart';

class ExecutiveAllTeamsScreen extends StatefulWidget {
  const ExecutiveAllTeamsScreen({super.key});

  @override
  State<ExecutiveAllTeamsScreen> createState() =>
      _ExecutiveAllTeamsScreenState();
}

class _ExecutiveAllTeamsScreenState extends State<ExecutiveAllTeamsScreen> {
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  List<ContractorTeam> _allTeams = [];
  Map<String, String> _teamSOMap = {}; // team_id -> SO name

  @override
  void initState() {
    super.initState();
    _loadAllTeamsForExecutive();
  }

  Future<void> _loadAllTeamsForExecutive() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final executiveId = authProvider.currentUser!.id;

      // Step 1: Get all SOs under this executive
      final sosSnapshot = await _firestore
          .collection('users')
          .where('manager_id', isEqualTo: executiveId)
          .where('role', isEqualTo: 'so')
          .get();

      if (sosSnapshot.docs.isEmpty) {
        setState(() {
          _isLoading = false;
          _allTeams = [];
        });
        return;
      }

      print('📋 Found ${sosSnapshot.docs.length} SOs under executive');

      // Step 2: Get all teams managed by these SOs
      List<ContractorTeam> teams = [];
      Map<String, String> teamSOMapping = {};

      for (var soDoc in sosSnapshot.docs) {
        final soId = soDoc.id;
        final soName = soDoc.data()['name'] as String;

        print('   Loading teams for SO: $soName ($soId)');

        // Get teams for this SO
        final teamsSnapshot = await _firestore
            .collection('contractor_teams')
            .where('so_id', isEqualTo: soId)
            .get();

        print('   Found ${teamsSnapshot.docs.length} teams for $soName');

        for (var teamDoc in teamsSnapshot.docs) {
          final data = teamDoc.data();
          data['id'] = teamDoc.id;
          final team = ContractorTeam.fromJson(data);
          teams.add(team);
          teamSOMapping[team.teamId] = soName;
        }
      }

      // If no teams found with SO assignments, try loading all teams
      if (teams.isEmpty) {
        print('⚠️ No teams with SO assignments, loading all teams...');
        final allTeamsSnapshot =
            await _firestore.collection('contractor_teams').get();

        for (var teamDoc in allTeamsSnapshot.docs) {
          final data = teamDoc.data();
          data['id'] = teamDoc.id;
          final team = ContractorTeam.fromJson(data);
          teams.add(team);
          teamSOMapping[team.teamId] = 'Unassigned';
        }
      }

      setState(() {
        _allTeams = teams;
        _teamSOMap = teamSOMapping;
        _isLoading = false;
      });

      print('✅ Total teams loaded: ${teams.length}');
    } catch (e) {
      print('❌ Error loading teams: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading teams: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Contractor Teams'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAllTeamsForExecutive,
              child: _allTeams.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _allTeams.length,
                      itemBuilder: (context, index) {
                        final team = _allTeams[index];
                        final soName = _teamSOMap[team.teamId] ?? 'Unknown SO';
                        final stats =
                            adminProvider.getPerformanceStats(team.teamId);
                        return _buildTeamCard(team, soName, stats);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Teams Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No contractor teams are assigned to your Site Officers yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadAllTeamsForExecutive(),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamCard(
      ContractorTeam team, String soName, Map<String, dynamic> stats) {
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.groups,
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
                          team.teamId,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.supervisor_account,
                              size: 14,
                              color: AppTheme.textSecondaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'SO: $soName',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Leader: ${team.leaderName}',
                          style: const TextStyle(
                            fontSize: 12,
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
}
