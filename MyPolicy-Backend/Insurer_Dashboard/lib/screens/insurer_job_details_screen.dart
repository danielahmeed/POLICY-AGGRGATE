import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class InsurerJobDetailsScreen extends StatefulWidget {
  final String jobId;
  final String collectionName;
  final String? fileName;

  const InsurerJobDetailsScreen({
    super.key,
    required this.jobId,
    required this.collectionName,
    this.fileName,
  });

  @override
  State<InsurerJobDetailsScreen> createState() => _InsurerJobDetailsScreenState();
}

class _InsurerJobDetailsScreenState extends State<InsurerJobDetailsScreen> {
  String? _jobStatus;
  String? _jobMessage;
  int _jobProcessed = 0;
  int _jobMatched = 0;
  int _jobUnmatched = 0;
  List<Map<String, dynamic>> _failedLogEntries = [];

  Timer? _pollTimer;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _pollJobStatus();
    });
    _pollJobStatus();
  }

  Future<void> _pollJobStatus() async {
    try {
      final uri = Uri.parse('http://localhost:8082/api/pipeline/jobs/${widget.jobId}');
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
        _loading = false;
      });

      if (_jobStatus == 'COMPLETE' || _jobStatus == 'FAILED') {
        _pollTimer?.cancel();
        _pollTimer = null;
        await _loadFailedLog();
      }
    } catch (_) {
      // ignore transient errors
    }
  }

  Future<void> _loadFailedLog() async {
    try {
      if (widget.collectionName == 'customer_details') {
        return;
      }
      final uri = Uri.parse(
          'http://localhost:8082/api/pipeline/failed-log?collectionName=${widget.collectionName}&limit=50');
      final res = await http.get(uri);
      if (res.statusCode != 200) {
        return;
      }
      final list = jsonDecode(res.body) as List<dynamic>;
      setState(() {
        _failedLogEntries = list.cast<Map<String, dynamic>>();
      });
    } catch (_) {
      // ignore failed_log errors
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingestion Job Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Job ID: ${widget.jobId}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              'Collection: ${widget.collectionName}'
                  '${widget.fileName != null ? ' • File: ${widget.fileName}' : ''}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _loading
                    ? const Center(
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status: ${_jobStatus ?? '-'}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_jobMessage != null && _jobMessage!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              _jobMessage!,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStat('Processed', _jobProcessed),
                              _buildStat('Matched', _jobMatched),
                              _buildStat('Unmatched', _jobUnmatched),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed Log (latest 50)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: _failedLogEntries.isEmpty
                      ? const Text(
                          'No failed_log entries for this collection.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        )
                      : ListView.builder(
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
                                      color: Colors.grey,
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
                                        color: Colors.black87,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, int value) {
    return Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

