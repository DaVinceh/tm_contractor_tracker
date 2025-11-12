import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExcelExport {
  Future<void> exportReport({
    required Map<String, dynamic> reportData,
    required String period,
  }) async {
    try {
      print('📄 Starting Excel export...');

      // Create a new Excel document
      var excel = Excel.createExcel();

      // Remove default sheet
      excel.delete('Sheet1');

      // Create Summary sheet
      var summarySheet = excel['Summary'];

      // Add header styling
      final headerStyle = CellStyle(
        bold: true,
        fontSize: 12,
        backgroundColorHex: ExcelColor.green,
        fontColorHex: ExcelColor.white,
      );

      // Add report title and period
      summarySheet.cell(CellIndex.indexByString('A1')).value =
          TextCellValue('TM Contractor Tracker - Report Summary');
      summarySheet.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(
        bold: true,
        fontSize: 14,
        fontColorHex: ExcelColor.green700,
      );

      summarySheet.cell(CellIndex.indexByString('A2')).value =
          TextCellValue('Period: ${period.toUpperCase()}');
      summarySheet.cell(CellIndex.indexByString('A3')).value = TextCellValue(
          'Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}');

      // Get tasks and attendance data
      final tasks = reportData['tasks'] as List? ?? [];
      final attendance = reportData['attendance'] as List? ?? [];

      // Summary Statistics (starting at row 5)
      summarySheet.cell(CellIndex.indexByString('A5')).value =
          TextCellValue('SUMMARY STATISTICS');
      summarySheet.cell(CellIndex.indexByString('A5')).cellStyle = headerStyle;

      final totalTasks = tasks.length;
      final completedTasks =
          tasks.where((t) => t['status'] == 'completed').length;
      final inProgressTasks =
          tasks.where((t) => t['status'] == 'in_progress').length;
      final pendingTasks = tasks.where((t) => t['status'] == 'pending').length;

      summarySheet.cell(CellIndex.indexByString('A6')).value =
          TextCellValue('Total Tasks');
      summarySheet.cell(CellIndex.indexByString('B6')).value =
          IntCellValue(totalTasks);

      summarySheet.cell(CellIndex.indexByString('A7')).value =
          TextCellValue('Completed Tasks');
      summarySheet.cell(CellIndex.indexByString('B7')).value =
          IntCellValue(completedTasks);

      summarySheet.cell(CellIndex.indexByString('A8')).value =
          TextCellValue('In Progress Tasks');
      summarySheet.cell(CellIndex.indexByString('B8')).value =
          IntCellValue(inProgressTasks);

      summarySheet.cell(CellIndex.indexByString('A9')).value =
          TextCellValue('Pending Tasks');
      summarySheet.cell(CellIndex.indexByString('B9')).value =
          IntCellValue(pendingTasks);

      summarySheet.cell(CellIndex.indexByString('A10')).value =
          TextCellValue('Total Attendance Records');
      summarySheet.cell(CellIndex.indexByString('B10')).value =
          IntCellValue(attendance.length);

      // Create Tasks sheet
      var tasksSheet = excel['Tasks'];

      // Task headers
      final taskHeaders = [
        'Project #',
        'Project ID',
        'Team ID',
        'Title',
        'Description',
        'Exchange',
        'State',
        'TM Note',
        'Program',
        'LOR ID',
        'Priority',
        'Status',
        'Progress %',
        'Start Date',
        'End Date',
        'Created By',
      ];

      for (var i = 0; i < taskHeaders.length; i++) {
        final cell = tasksSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(taskHeaders[i]);
        cell.cellStyle = headerStyle;
      }

      // Add task data
      for (var i = 0; i < tasks.length; i++) {
        final task = tasks[i];
        final row = i + 1;

        tasksSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = TextCellValue(task['project_number']?.toString() ?? 'N/A');
        tasksSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = TextCellValue(task['project_id']?.toString() ?? 'N/A');
        tasksSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
            .value = TextCellValue(task['team_id']?.toString() ?? 'N/A');
        tasksSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
            .value = TextCellValue(task['title']?.toString() ?? 'N/A');
        tasksSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
            .value = TextCellValue(task['description']?.toString() ?? 'N/A');
        tasksSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
            .value = TextCellValue(task['exchange']?.toString() ?? 'N/A');
        tasksSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
            .value = TextCellValue(task['state']?.toString() ?? 'N/A');
        tasksSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row))
            .value = TextCellValue(task['tm_note']?.toString() ?? 'N/A');
        tasksSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row))
            .value = TextCellValue(task['program']?.toString() ?? 'N/A');
        tasksSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row))
            .value = TextCellValue(task['lor_id']?.toString() ?? 'N/A');
        tasksSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: row))
            .value = TextCellValue(task['priority']?.toString() ?? 'medium');
        tasksSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: row))
            .value = TextCellValue(task['status']?.toString() ?? 'pending');
        tasksSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: row))
            .value = IntCellValue((task['completion_percentage'] as num?)
                ?.toInt() ??
            0);

        // Parse dates
        try {
          final startDate = task['start_date'] is Timestamp
              ? (task['start_date'] as Timestamp).toDate()
              : DateTime.parse(task['start_date'].toString());
          tasksSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: row))
              .value = TextCellValue(DateFormat(
                  'dd/MM/yyyy')
              .format(startDate));
        } catch (e) {
          tasksSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: row))
              .value = TextCellValue('N/A');
        }

        try {
          if (task['end_date'] != null) {
            final endDate = task['end_date'] is Timestamp
                ? (task['end_date'] as Timestamp).toDate()
                : DateTime.parse(task['end_date'].toString());
            tasksSheet
                    .cell(CellIndex.indexByColumnRow(
                        columnIndex: 14, rowIndex: row))
                    .value =
                TextCellValue(DateFormat('dd/MM/yyyy').format(endDate));
          } else {
            tasksSheet
                .cell(
                    CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: row))
                .value = TextCellValue('N/A');
          }
        } catch (e) {
          tasksSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: row))
              .value = TextCellValue('N/A');
        }

        tasksSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 15, rowIndex: row))
            .value = TextCellValue(task['created_by']?.toString() ?? 'N/A');
      }

      // Create Attendance sheet
      var attendanceSheet = excel['Attendance'];

      // Attendance headers
      final attendanceHeaders = [
        'Team ID',
        'User ID',
        'Date',
        'Check-in Time',
        'Latitude',
        'Longitude',
      ];

      for (var i = 0; i < attendanceHeaders.length; i++) {
        final cell = attendanceSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(attendanceHeaders[i]);
        cell.cellStyle = headerStyle;
      }

      // Add attendance data
      for (var i = 0; i < attendance.length; i++) {
        final record = attendance[i];
        final row = i + 1;

        attendanceSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = TextCellValue(record['team_id']?.toString() ?? 'N/A');
        attendanceSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = TextCellValue(record['user_id']?.toString() ?? 'N/A');

        try {
          final date = record['date'] is Timestamp
              ? (record['date'] as Timestamp).toDate()
              : DateTime.parse(record['date'].toString());
          attendanceSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
              .value = TextCellValue(DateFormat('dd/MM/yyyy').format(date));
        } catch (e) {
          attendanceSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
              .value = TextCellValue('N/A');
        }

        try {
          final checkInTime = record['check_in_time'] is Timestamp
              ? (record['check_in_time'] as Timestamp).toDate()
              : DateTime.parse(record['check_in_time'].toString());
          attendanceSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
              .value = TextCellValue(DateFormat(
                  'HH:mm:ss')
              .format(checkInTime));
        } catch (e) {
          attendanceSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
              .value = TextCellValue('N/A');
        }

        attendanceSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
            .value = TextCellValue(record['latitude']?.toString() ?? 'N/A');
        attendanceSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
            .value = TextCellValue(record['longitude']?.toString() ?? 'N/A');
      }

      // Save the file
      final fileName =
          'TM_Report_${period}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

      // Get the temporary directory
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName';

      // Encode and save
      final fileBytes = excel.encode();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

        print('📄 Excel file created: $filePath');
        print('📄 File size: ${fileBytes.length} bytes');

        // Share the file using share_plus
        final result = await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'TM Contractor Tracker - Report Summary',
          text:
              'Report for period: $period\nGenerated: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
        );

        print('📄 Share result: ${result.status}');

        if (result.status == ShareResultStatus.success) {
          print('✅ File shared successfully');
        } else if (result.status == ShareResultStatus.dismissed) {
          print('⚠️ Share dismissed by user');
        }
      } else {
        throw Exception('Failed to encode Excel file');
      }
    } catch (e, stackTrace) {
      print('❌ Error exporting to Excel: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
