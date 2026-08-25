import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';
import '../../utils/constants.dart';
import '../../widgets/report_card.dart';
import 'report_detail_screen.dart';

class MyReportsScreen extends StatefulWidget {
  final bool embedded;
  const MyReportsScreen({super.key, this.embedded = false});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  final ReportService _reportService = ReportService();
  final _searchController = TextEditingController();
  String _filterStatus = 'All';
  String _searchQuery = '';

  final List<String> _filters = [
    'All',
    statusPending,
    statusOngoing,
    statusCompleted,
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ReportModel> _applyFilter(List<ReportModel> all) {
    var list = all;
    if (_filterStatus != 'All') {
      list = list.where((r) => r.status == _filterStatus).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((r) {
        return r.category.toLowerCase().contains(q) ||
            r.description.toLowerCase().contains(q) ||
            r.reportReference.toLowerCase().contains(q) ||
            r.location.toLowerCase().contains(q);
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final body = Column(
      children: [
        if (!widget.embedded)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [gradientStart, gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(width: 8),
                    const Text('My Reports',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),

        // Orange label when embedded
        if (widget.embedded)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [gradientStart, gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: const SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Reports',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text(municipality,
                        style:
                            TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),

        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search reports...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // Filter tabs
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((f) {
                final active = _filterStatus == f;
                return GestureDetector(
                  onTap: () => setState(() => _filterStatus = f),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          active ? gradientStart : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active
                            ? gradientStart
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      f,
                      style: TextStyle(
                        color: active ? Colors.white : Colors.grey,
                        fontWeight: active
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Report list
        Expanded(
          child: StreamBuilder<List<ReportModel>>(
            stream: _reportService.getUserReports(uid),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child:
                        CircularProgressIndicator(color: gradientStart));
              }
              final filtered = _applyFilter(snap.data ?? []);
              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.assignment_outlined,
                          size: 56, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        _filterStatus == 'All'
                            ? 'No reports yet'
                            : 'No $_filterStatus reports',
                        style: const TextStyle(
                            fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      if (_filterStatus == 'All')
                        const Text(
                          'Submit your first concern report',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey),
                        ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: filtered.length,
                itemBuilder: (ctx, i) => ReportCard(
                  report: filtered[i],
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReportDetailScreen(
                        report: filtered[i],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return body;
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: body,
    );
  }
}