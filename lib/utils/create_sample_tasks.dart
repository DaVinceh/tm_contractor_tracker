import 'package:cloud_firestore/cloud_firestore.dart';

/// Script to create sample tasks for testing the reporting features
/// Run this from your main.dart temporarily or create a separate script file
Future<void> createSampleTasks() async {
  final firestore = FirebaseFirestore.instance;

  // Sample tasks for TEAM001
  final team001Tasks = [
    {
      'id': 'TASK001',
      'team_id': 'TEAM001',
      'title': 'Fiber Cable Installation - Downtown Area',
      'description':
          'Install fiber optic cables in the downtown business district',
      'start_date':
          DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
      'end_date':
          DateTime.now().add(const Duration(days: 23)).toIso8601String(),
      'completion_percentage': 35.0,
      'status': 'in_progress',
      'created_by': 'SO001',
      'created_at':
          DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
      'project_number': 'PRJ-2024-001',
      'project_id': 'TMB-DT-001',
      'exchange': 'Downtown Exchange',
      'state': 'CA',
      'tm_note': 'Priority installation for commercial clients',
      'program': 'T-Mobile Network Expansion',
      'lor_id': 'LOR-CA-001',
      'priority': 'high',
    },
    {
      'id': 'TASK002',
      'team_id': 'TEAM001',
      'title': 'Equipment Setup - Cell Tower Alpha',
      'description': 'Install and configure 5G equipment at Tower Alpha site',
      'start_date':
          DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      'end_date':
          DateTime.now().add(const Duration(days: 11)).toIso8601String(),
      'completion_percentage': 60.0,
      'status': 'in_progress',
      'created_by': 'SO001',
      'created_at':
          DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      'project_number': 'PRJ-2024-002',
      'project_id': 'TMB-TW-002',
      'exchange': 'West Metro',
      'state': 'CA',
      'tm_note': 'Requires specialized equipment training',
      'program': 'T-Mobile 5G Rollout',
      'lor_id': 'LOR-CA-002',
      'priority': 'high',
    },
    {
      'id': 'TASK003',
      'team_id': 'TEAM001',
      'title': 'Site Survey - Residential Zone B',
      'description': 'Conduct site survey for future cable installation',
      'start_date':
          DateTime.now().add(const Duration(days: 5)).toIso8601String(),
      'end_date':
          DateTime.now().add(const Duration(days: 12)).toIso8601String(),
      'completion_percentage': 0.0,
      'status': 'pending',
      'created_by': 'SO001',
      'created_at': DateTime.now().toIso8601String(),
      'project_number': 'PRJ-2024-003',
      'project_id': 'TMB-RS-003',
      'exchange': 'Suburban North',
      'state': 'CA',
      'tm_note': 'Coordinate with local authorities for permits',
      'program': 'T-Mobile Network Expansion',
      'lor_id': 'LOR-CA-003',
      'priority': 'medium',
    },
  ];

  // Sample tasks for TEAM002
  final team002Tasks = [
    {
      'id': 'TASK004',
      'team_id': 'TEAM002',
      'title': 'Underground Cable Maintenance',
      'description': 'Repair and maintain underground cable infrastructure',
      'start_date':
          DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      'end_date': DateTime.now().add(const Duration(days: 9)).toIso8601String(),
      'completion_percentage': 75.0,
      'status': 'in_progress',
      'created_by': 'SO001',
      'created_at':
          DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      'project_number': 'PRJ-2024-004',
      'project_id': 'TMB-UC-004',
      'exchange': 'East District',
      'state': 'CA',
      'tm_note': 'Emergency maintenance required',
      'program': 'T-Mobile Infrastructure Maintenance',
      'lor_id': 'LOR-CA-004',
      'priority': 'high',
    },
    {
      'id': 'TASK005',
      'team_id': 'TEAM002',
      'title': 'Antenna Alignment - Tower Bravo',
      'description': 'Adjust antenna positioning for optimal signal coverage',
      'start_date':
          DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
      'end_date':
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'completion_percentage': 100.0,
      'status': 'completed',
      'created_by': 'SO001',
      'created_at':
          DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
      'project_number': 'PRJ-2024-005',
      'project_id': 'TMB-TW-005',
      'exchange': 'South Metro',
      'state': 'CA',
      'tm_note': 'Completed ahead of schedule',
      'program': 'T-Mobile Signal Optimization',
      'lor_id': 'LOR-CA-005',
      'priority': 'medium',
    },
    {
      'id': 'TASK006',
      'team_id': 'TEAM002',
      'title': 'Network Testing - Zone 3',
      'description': 'Perform comprehensive network testing in Zone 3',
      'start_date':
          DateTime.now().add(const Duration(days: 2)).toIso8601String(),
      'end_date': DateTime.now().add(const Duration(days: 9)).toIso8601String(),
      'completion_percentage': 0.0,
      'status': 'pending',
      'created_by': 'SO001',
      'created_at': DateTime.now().toIso8601String(),
      'project_number': 'PRJ-2024-006',
      'project_id': 'TMB-NT-006',
      'exchange': 'Central Hub',
      'state': 'CA',
      'tm_note': 'Requires coordination with network ops team',
      'program': 'T-Mobile Quality Assurance',
      'lor_id': 'LOR-CA-006',
      'priority': 'low',
    },
  ];

  // Sample tasks for TEAM003
  final team003Tasks = [
    {
      'id': 'TASK007',
      'team_id': 'TEAM003',
      'title': 'Emergency Repair - Highway Route 5',
      'description': 'Emergency cable repair on Highway Route 5',
      'start_date':
          DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      'end_date': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
      'completion_percentage': 80.0,
      'status': 'in_progress',
      'created_by': 'SO001',
      'created_at':
          DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      'project_number': 'PRJ-2024-007',
      'project_id': 'TMB-ER-007',
      'exchange': 'Highway District',
      'state': 'CA',
      'tm_note': 'Critical repair affecting multiple customers',
      'program': 'T-Mobile Emergency Response',
      'lor_id': 'LOR-CA-007',
      'priority': 'high',
    },
    {
      'id': 'TASK008',
      'team_id': 'TEAM003',
      'title': 'Equipment Upgrade - Cell Site Charlie',
      'description': 'Replace outdated equipment with new 5G hardware',
      'start_date':
          DateTime.now().subtract(const Duration(days: 14)).toIso8601String(),
      'end_date':
          DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      'completion_percentage': 100.0,
      'status': 'completed',
      'created_by': 'SO001',
      'created_at':
          DateTime.now().subtract(const Duration(days: 14)).toIso8601String(),
      'project_number': 'PRJ-2024-008',
      'project_id': 'TMB-UP-008',
      'exchange': 'North Regional',
      'state': 'CA',
      'tm_note': 'Successfully upgraded to latest 5G technology',
      'program': 'T-Mobile Technology Modernization',
      'lor_id': 'LOR-CA-008',
      'priority': 'medium',
    },
    {
      'id': 'TASK009',
      'team_id': 'TEAM003',
      'title': 'Preventive Maintenance - Tower Network',
      'description': 'Scheduled preventive maintenance for tower network',
      'start_date':
          DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      'end_date':
          DateTime.now().add(const Duration(days: 21)).toIso8601String(),
      'completion_percentage': 0.0,
      'status': 'pending',
      'created_by': 'SO001',
      'created_at': DateTime.now().toIso8601String(),
      'project_number': 'PRJ-2024-009',
      'project_id': 'TMB-PM-009',
      'exchange': 'Regional Network',
      'state': 'CA',
      'tm_note': 'Quarterly maintenance schedule',
      'program': 'T-Mobile Preventive Maintenance',
      'lor_id': 'LOR-CA-009',
      'priority': 'low',
    },
  ];

  try {
    print('Creating sample tasks for TEAM001...');
    for (var task in team001Tasks) {
      await firestore.collection('tasks').doc(task['id'] as String).set(task);
    }

    print('Creating sample tasks for TEAM002...');
    for (var task in team002Tasks) {
      await firestore.collection('tasks').doc(task['id'] as String).set(task);
    }

    print('Creating sample tasks for TEAM003...');
    for (var task in team003Tasks) {
      await firestore.collection('tasks').doc(task['id'] as String).set(task);
    }

    print('✅ Successfully created 9 sample tasks (3 per team)');
    print('   - TEAM001: 3 tasks (1 pending, 2 in_progress)');
    print('   - TEAM002: 3 tasks (1 pending, 1 in_progress, 1 completed)');
    print('   - TEAM003: 3 tasks (1 pending, 1 in_progress, 1 completed)');
  } catch (e) {
    print('❌ Error creating sample tasks: $e');
  }
}
