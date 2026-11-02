import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/timetable_slot.dart';
import '../models/subject.dart';
import '../models/task.dart';
import 'subjects_screen.dart';
import 'timetable_screen.dart';
import 'scratchpad_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const HomeTab(),
    const SubjectsScreen(),
    const TimetableScreen(),
    const ScratchpadScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.home_rounded,
      Icons.menu_book_rounded,
      Icons.calendar_today_rounded,
      Icons.note_alt_rounded,
    ];
    final labels = ['Home', 'Subjects', 'Timetable', 'Scratchpad'];

    return Scaffold(
      backgroundColor: const Color(0xFFF3E7DF),
      body: _tabs[_currentIndex],
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(icons.length, (index) {
              final bool isActive = index == _currentIndex;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _currentIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.symmetric(
                    horizontal: isActive ? 16 : 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icons[index],
                        size: 22,
                        color: isActive
                            ? const Color(0xFF111111)
                            : const Color(0xFF9A9A9A),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 6),
                        Text(
                          labels[index],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111111),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _isLoading = true;
  List<TimetableSlot> _todaySlots = [];
  List<Subject> _subjects = [];
  List<Task> _tasks = [];
  String _currentDay = '';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    // Get current day of the week (e.g. "Monday")
    final String today = DateFormat('EEEE').format(DateTime.now());

    final allSlots = await DBHelper.instance.getTimetableSlots();
    final allSubjects = await DBHelper.instance.getSubjects();
    final allTasks = await DBHelper.instance.getTasks();

    // Filter slots for today
    final todaySlots = allSlots.where((s) => s.dayOfWeek.toLowerCase() == today.toLowerCase()).toList();

    if (!mounted) return;
    setState(() {
      _currentDay = today;
      _todaySlots = todaySlots;
      _subjects = allSubjects;
      _tasks = allTasks;
      _isLoading = false;
    });
  }

  Subject? _getSubjectForSlot(int subjectId) {
    try {
      return _subjects.firstWhere((s) => s.id == subjectId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF1EDE4),
      appBar: AppBar(
        title: Text(
          'Dashboard ($_currentDay)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111111),
          ),
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF111111),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              style: IconButton.styleFrom(
                backgroundColor: const Color(0x99FFFFFF),
                foregroundColor: const Color(0xFF111111),
              ),
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadDashboardData,
            ),
          )
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFD9EED6),
              Color(0xFFF1EDE4),
              Color(0xFFF8DCD2),
            ],
          ),
        ),
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF111111),
            strokeWidth: 3,
          ),
        )
            : RefreshIndicator(
          color: const Color(0xFF111111),
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).padding.top + kToolbarHeight + 12,
              16,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Next Class Hero Card
                Text(
                  'Today\'s Schedule',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 12),
                _todaySlots.isEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xA6FFFFFF),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: const Color(0xCCFFFFFF),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'No classes scheduled for today! Enjoy your day off.',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF8A8A8A),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _todaySlots.length,
                  itemBuilder: (context, index) {
                    final slot = _todaySlots[index];
                    final subject = _getSubjectForSlot(slot.subjectId);
                    final bool isNext = index == 0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isNext
                                  ? const Color(0xFF111111)
                                  : const Color(0xA6FFFFFF),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: isNext
                                    ? const Color(0xFF111111)
                                    : const Color(0xCCFFFFFF),
                                width: 1.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 24,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isNext
                                          ? Icons.access_time_filled_rounded
                                          : Icons.schedule_rounded,
                                      color: isNext
                                          ? const Color(0xFFB8E0B0)
                                          : const Color(0xFF111111),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isNext ? 'NEXT UP TODAY' : 'CLASSES TODAY',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.2,
                                        color: isNext
                                            ? const Color(0xFFB8E0B0)
                                            : const Color(0xFF111111),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  subject != null ? subject.title : 'Class Session',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: isNext
                                        ? Colors.white
                                        : const Color(0xFF111111),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Room / Lab: ${slot.roomNumber}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: isNext
                                        ? const Color(0xB3FFFFFF)
                                        : const Color(0xFF5C5C5C),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Instructor: ${slot.instructor}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: isNext
                                        ? const Color(0xB3FFFFFF)
                                        : const Color(0xFF5C5C5C),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Time: ${slot.startTime} - ${slot.endTime}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: isNext
                                        ? Colors.white
                                        : const Color(0xFF111111),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Active Tasks & Deadlines',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 12),
                _tasks.isEmpty
                    ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(
                    child: Text(
                      'No pending tasks. You are all caught up!',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF8A8A8A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    final subject = _getSubjectForSlot(task.subjectId);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xA6FFFFFF),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xCCFFFFFF),
                                width: 1.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x12000000),
                                  blurRadius: 20,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: task.isCompleted
                                      ? const Color(0x264CAF50)
                                      : const Color(0x26FF9800),
                                ),
                                child: Icon(
                                  task.isCompleted
                                      ? Icons.check_circle_rounded
                                      : Icons.assignment_rounded,
                                  size: 22,
                                  color: task.isCompleted ? Colors.green : Colors.orange,
                                ),
                              ),
                              title: Text(
                                task.title,
                                style: GoogleFonts.plusJakartaSans(
                                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: const Color(0xFF111111),
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Subject: ${subject?.code ?? 'General'} • Due: ${task.dueDate}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF8A8A8A),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}