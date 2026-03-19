import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

import 'insurer_login_screen.dart';
import 'insurer_job_details_screen.dart';

class InsurerPortalScreen extends StatefulWidget {
  const InsurerPortalScreen({super.key});

  @override
  State<InsurerPortalScreen> createState() => _InsurerPortalScreenState();
}

class _InsurerPortalScreenState extends State<InsurerPortalScreen> {
  String? selectedDataType;
  String? fileName;
  PlatformFile? _selectedFile;

  // Job status state
  String? _jobId;
  String? _jobStatus;
  String? _jobMessage;
  int _jobProcessed = 0;
  int _jobMatched = 0;
  int _jobUnmatched = 0;
  bool _isSubmitting = false;

  // Failed log state
  List<Map<String, dynamic>> _failedLogEntries = [];

  Timer? _pollTimer;

  final List<String> dataTypes = [
    'Life Insurance',
    'Health Insurance',
    'Motor Insurance',
  ];

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls'],
      withData: true,
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.single;
        fileName = _selectedFile!.name;
      });
    }
  }

  void _clearFile() {
    setState(() {
      fileName = null;
      _selectedFile = null;
    });
  }

  void _handleLogout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const InsurerLoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout, color: Color(0xFFED1C24)),
              label: const Text(
                'Logout',
                style: TextStyle(
                  color: Color(0xFFED1C24),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // HDFC Logo and Title
              Column(
                children: [
                   SvgPicture.asset(
                    'assets/images/hdfc-bank-logo.svg',
                    height: 60,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Insurer Portal',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              
              // Upload Card
              Container(
                width: 500,
                decoration: BoxDecoration(
                  color: const Color(0xFF0451B5), // Deep blue
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'Upload File',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Data Type Dropdown
                    const Text(
                      'Data Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedDataType,
                          hint: const Text('Choose Data Type'),
                          isExpanded: true,
                          items: dataTypes.map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            setState(() {
                              selectedDataType = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // CSV File Upload
                    const Text(
                      'CSV File',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickFile,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                fileName ?? 'Upload CSV or Excel File',
                                style: TextStyle(
                                  color: fileName == null ? Colors.grey[600] : Colors.black,
                                ),
                              ),
                            ),
                            if (fileName != null) ...[
                              const Icon(Icons.check_circle, color: Colors.green),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _clearFile,
                                child: const Icon(Icons.delete, color: Colors.red),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Submit Button
                    Center(
                      child: SizedBox(
                        width: 180,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: (selectedDataType != null && _selectedFile != null && !_isSubmitting)
                              ? _submitFile
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFED1C24),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Upload & Start Job',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    if (_jobId != null) ...[
                      const Divider(color: Colors.white54),
                      const SizedBox(height: 16),
                      const Text(
                        'Job Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Job ID: $_jobId',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Status: ${_jobStatus ?? '-'}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            if (_jobMessage != null && _jobMessage!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                _jobMessage!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStatChip('Processed', _jobProcessed),
                                _buildStatChip('Matched', _jobMatched),
                                _buildStatChip('Unmatched', _jobUnmatched),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _jobId == null
                              ? null
                              : () {
                                  final collectionName = _mapCollectionName(selectedDataType);
                                  if (collectionName == null || _jobId == null) return;
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => InsurerJobDetailsScreen(
                                        jobId: _jobId!,
                                        collectionName: collectionName,
                                        fileName: fileName,
                                      ),
                                    ),
                                  );
                                },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            'Open full job view',
                            style: TextStyle(
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'Failed Log (latest 50)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxHeight: 220),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _failedLogEntries.isEmpty
                            ? const Text(
                                'No failed_log entries for this upload / collection.',
                                style: TextStyle(fontSize: 12, color: Colors.white70),
                              )
                            : Scrollbar(
                                child: ListView.builder(
                                  itemCount: _failedLogEntries.length,
                                  itemBuilder: (context, index) {
                                    final e = _failedLogEntries[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${e['createdAt'] ?? ''} • ${e['insurer'] ?? ''}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.white70,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            e['validationErrors'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                          if (e['rawData'] != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              jsonEncode(e['rawData']),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.white60,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, int value) {
    return Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  String? _mapCollectionName(String? dataType) {
    switch (dataType) {
      case 'Life Insurance':
        return 'life_insurance';
      case 'Health Insurance':
        return 'health_insurance';
      case 'Motor Insurance':
        return 'auto_insurance';
      default:
        return null;
    }
  }

  Future<void> _submitFile() async {
    if (_selectedFile == null || selectedDataType == null) return;

    final collectionName = _mapCollectionName(selectedDataType);
    if (collectionName == null) return;

    if (_selectedFile!.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected file has no bytes (not supported on this platform).')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _jobId = null;
      _jobStatus = null;
      _jobMessage = null;
      _jobProcessed = 0;
      _jobMatched = 0;
      _jobUnmatched = 0;
      _failedLogEntries = [];
    });

    try {
      final uri = Uri.parse('http://localhost:8082/api/pipeline/upload-async');
      final request = http.MultipartRequest('POST', uri)
        ..fields['collectionName'] = collectionName
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          _selectedFile!.bytes!,
          filename: _selectedFile!.name,
        ));

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      final statusCode = streamedResponse.statusCode;
      final data = jsonDecode(responseBody) as Map<String, dynamic>;

      if (statusCode < 200 || statusCode >= 300) {
        final msg = data['message'] ?? data['error'] ?? 'Upload failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $msg')),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      final jobId = data['jobId']?.toString();
      if (jobId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload succeeded but no jobId returned.')),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      setState(() {
        _jobId = jobId;
        _jobStatus = data['status']?.toString();
        _jobMessage = data['message']?.toString();
      });

      // Start polling job status
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        _pollJobStatus(jobId, collectionName);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _pollJobStatus(String jobId, String collectionName) async {
    try {
      final uri = Uri.parse('http://localhost:8082/api/pipeline/jobs/$jobId');
      final res = await http.get(uri);
      if (res.statusCode != 200) {
        return;
      }
      final job = jsonDecode(res.body) as Map<String, dynamic>;

      setState(() {
        _jobStatus = job['status']?.toString();
        _jobMessage = job['message']?.toString();
        _jobProcessed = (job['totalProcessed'] ?? 0) as int;
        _jobMatched = (job['matched'] ?? 0) as int;
        _jobUnmatched = (job['unmatched'] ?? 0) as int;
      });

      if (_jobStatus == 'COMPLETE' || _jobStatus == 'FAILED') {
        _pollTimer?.cancel();
        _pollTimer = null;
        setState(() {
          _isSubmitting = false;
        });
        await _loadFailedLog(collectionName);
      }
    } catch (_) {
      // ignore transient polling errors
    }
  }

  Future<void> _loadFailedLog(String collectionName) async {
    try {
      final uri = Uri.parse(
          'http://localhost:8082/api/pipeline/failed-log?collectionName=$collectionName&limit=50');
      final res = await http.get(uri);
      if (res.statusCode != 200) {
        return;
      }
      final list = jsonDecode(res.body) as List<dynamic>;
      setState(() {
        _failedLogEntries = list.cast<Map<String, dynamic>>();
      });
    } catch (_) {
      // ignore failed_log load errors for now
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
