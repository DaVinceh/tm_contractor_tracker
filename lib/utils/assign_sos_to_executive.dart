import 'package:cloud_firestore/cloud_firestore.dart';

/// Script to assign SOs to Executive and verify user setup
Future<void> assignSOsToExecutive() async {
  final firestore = FirebaseFirestore.instance;

  try {
    print('🔍 Checking existing users...');

    // Get all users
    final usersSnapshot = await firestore.collection('users').get();

    if (usersSnapshot.docs.isEmpty) {
      print('❌ No users found in database!');
      return;
    }

    print('\n📋 Found ${usersSnapshot.docs.length} users:');
    for (var doc in usersSnapshot.docs) {
      final data = doc.data();
      print('  - ${doc.id}: ${data['name']} (${data['role']})');
    }

    // Find executive user
    final executiveSnapshot = await firestore
        .collection('users')
        .where('role', isEqualTo: 'executive')
        .get();

    if (executiveSnapshot.docs.isEmpty) {
      print('\n❌ No executive user found!');
      print('   Please create an executive user first.');
      return;
    }

    final executiveId = executiveSnapshot.docs.first.id;
    final executiveName = executiveSnapshot.docs.first.data()['name'];
    print('\n✅ Found executive: $executiveName (ID: $executiveId)');

    // Find SO users
    final soSnapshot = await firestore
        .collection('users')
        .where('role', isEqualTo: 'so')
        .get();

    if (soSnapshot.docs.isEmpty) {
      print('\n❌ No SO users found!');
      print('   Please create SO users first.');
      return;
    }

    print('\n📋 Found ${soSnapshot.docs.length} SO users:');

    // Assign each SO to the executive
    int assignedCount = 0;
    for (var soDoc in soSnapshot.docs) {
      final soData = soDoc.data();
      final soName = soData['name'];
      final currentManagerId = soData['manager_id'];

      if (currentManagerId == executiveId) {
        print('  - $soName: Already assigned to $executiveName ✓');
      } else {
        await firestore.collection('users').doc(soDoc.id).update({
          'manager_id': executiveId,
        });
        print('  - $soName: Assigned to $executiveName ✓');
        assignedCount++;
      }
    }

    if (assignedCount > 0) {
      print(
          '\n✅ Successfully assigned $assignedCount SO(s) to $executiveName!');
    } else {
      print('\n✓ All SOs already assigned correctly.');
    }
  } catch (e) {
    print('\n❌ Error: $e');
  }
}

/// Helper function to create test users if needed
Future<void> createTestUsers() async {
  final firestore = FirebaseFirestore.instance;

  try {
    print('Creating test users...\n');

    // Create Executive user
    await firestore.collection('users').doc('executive1').set({
      'email': 'executive@test.com',
      'name': 'Executive User',
      'role': 'executive',
      'created_at': FieldValue.serverTimestamp(),
    });
    print('✅ Created Executive User');

    // Create SO users
    await firestore.collection('users').doc('so1').set({
      'email': 'so1@test.com',
      'name': 'Site Officer 1',
      'role': 'so',
      'manager_id': 'executive1',
      'created_at': FieldValue.serverTimestamp(),
    });
    print('✅ Created Site Officer 1');

    await firestore.collection('users').doc('so2').set({
      'email': 'so2@test.com',
      'name': 'Site Officer 2',
      'role': 'so',
      'manager_id': 'executive1',
      'created_at': FieldValue.serverTimestamp(),
    });
    print('✅ Created Site Officer 2');

    // Create contractor users for each team
    await firestore.collection('users').doc('contractor1').set({
      'email': 'contractor1@test.com',
      'name': 'Contractor Team 1',
      'role': 'contractor',
      'team_id': 'TEAM001',
      'created_at': FieldValue.serverTimestamp(),
    });
    print('✅ Created Contractor for TEAM001');

    await firestore.collection('users').doc('contractor2').set({
      'email': 'contractor2@test.com',
      'name': 'Contractor Team 2',
      'role': 'contractor',
      'team_id': 'TEAM002',
      'created_at': FieldValue.serverTimestamp(),
    });
    print('✅ Created Contractor for TEAM002');

    await firestore.collection('users').doc('contractor3').set({
      'email': 'contractor3@test.com',
      'name': 'Contractor Team 3',
      'role': 'contractor',
      'team_id': 'TEAM003',
      'created_at': FieldValue.serverTimestamp(),
    });
    print('✅ Created Contractor for TEAM003');

    print('\n✅ All test users created successfully!');
  } catch (e) {
    print('❌ Error creating users: $e');
  }
}
