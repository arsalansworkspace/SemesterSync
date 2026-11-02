import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../database/db_helper.dart';
import '../models/subject.dart';
import '../models/timetable_slot.dart';
import '../ai_timetable_parser.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TimetableSlot> _slots = [];
  List<Subject> _subjects = [];
  String? _imagePath;
  bool _isLoading = true;

  final List<String> _days = const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  String _selectedDay = 'Monday';

  Subject? _selectedSubject;
  final _roomController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final slots = await DBHelper.instance.getTimetableSlots();
    final subjects = await DBHelper.instance.getSubjects();
    final imagePath = await DBHelper.instance.getTimetableImagePath();

    if (!mounted) return;
    setState(() {
      _slots = slots;
      _subjects = subjects;
      _imagePath = imagePath;
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (!mounted) return;
      setState(() => _isLoading = true);

      final messenger = ScaffoldMessenger.of(context);

      await DBHelper.instance.saveTimetableImagePath(pickedFile.path);

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'AI is extracting schedule & generating subjects...',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: const Color(0xFF111111),
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      );

      final bytes = await pickedFile.readAsBytes();

      // FIXED: Using List<dynamic> here to prevent syntax errors
      final List<dynamic> extractedData = await AiTimetableParser.extractScheduleFromImage(bytes);

      if (extractedData.isNotEmpty) {
        await DBHelper.instance.clearAllTimetableSlots();

        List<Subject> currentSubjects = await DBHelper.instance.getSubjects();

        for (var item in extractedData) {
          String subjectTitle = item['subject'];
          String instructorName = item['instructor'];

          Subject? existingSubject;
          try {
            existingSubject = currentSubjects.firstWhere(
                    (s) => s.title.toLowerCase() == subjectTitle.toLowerCase()
            );
          } catch (_) {
            existingSubject = null;
          }

          int subjectId;

          if (existingSubject != null) {
            subjectId = existingSubject.id!;
          } else {
            String code = subjectTitle.split(' ')
                .take(2)
                .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
                .join('');

            Subject newSub = Subject(
              title: subjectTitle,
              code: code.isNotEmpty ? code : 'SUB',
              instructor: instructorName,
              colorHex: '#3F51B5',
            );

            subjectId = await DBHelper.instance.insertSubject(newSub);

            currentSubjects.add(Subject(
                id: subjectId,
                title: subjectTitle,
                code: newSub.code,
                instructor: instructorName,
                colorHex: newSub.colorHex
            ));
          }

          TimetableSlot newSlot = TimetableSlot(
            subjectId: subjectId,
            dayOfWeek: item['dayOfWeek'],
            startTime: item['startTime'],
            endTime: item['endTime'],
            roomNumber: item['roomNumber'],
            instructor: instructorName,
          );

          await DBHelper.instance.insertTimetableSlot(newSlot);
        }

        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Successfully added classes and generated subjects!',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: const Color(0xFF111111),
              behavior: SnackBarBehavior.floating,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Failed to extract timetable data.',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: const Color(0xFF111111),
              behavior: SnackBarBehavior.floating,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          );
        }
      }

      if (!mounted) return;
      await _loadData();
    }
  }

  void _showAddSlotDialog() {
    if (_subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please add subjects in the "Subjects" tab first.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: const Color(0xFF111111),
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      );
      return;
    }

    _selectedSubject = _subjects.first;
    _roomController.clear();
    _startTimeController.text = '09:00 AM';
    _endTimeController.text = '10:30 AM';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            // Same look for every field in the dialog
            InputDecoration dialogField(String label, IconData icon) {
              return InputDecoration(
                labelText: label,
                labelStyle: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF8A8A8A),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                floatingLabelStyle: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF111111),
                  fontWeight: FontWeight.w700,
                ),
                prefixIcon: Icon(icon, color: const Color(0xFF111111), size: 20),
                filled: true,
                fillColor: const Color(0xCCFFFFFF),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE6E1D8), width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF111111), width: 1.5),
                ),
              );
            }

            final dialogTextStyle = GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111111),
            );

            return AlertDialog(
              backgroundColor: const Color(0xFFF7F3EC),
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              title: Text(
                'Add Class Slot',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111111),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedDay,
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      style: dialogTextStyle,
                      decoration: dialogField('Day of Week', Icons.today_rounded),
                      items: _days.map((day) => DropdownMenuItem(value: day, child: Text(day))).toList(),
                      onChanged: (val) => setDialogState(() => _selectedDay = val!),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<Subject>(
                      initialValue: _selectedSubject,
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      style: dialogTextStyle,
                      decoration: dialogField('Subject', Icons.menu_book_rounded),
                      items: _subjects
                          .map((sub) => DropdownMenuItem(
                        value: sub,
                        child: Text(
                          '${sub.code} - ${sub.title}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                          .toList(),
                      onChanged: (val) => setDialogState(() => _selectedSubject = val),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _roomController,
                      cursorColor: const Color(0xFF111111),
                      style: dialogTextStyle,
                      decoration: dialogField('Room / Lab No. (e.g. CS Lab 2)', Icons.meeting_room_rounded),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _startTimeController,
                      cursorColor: const Color(0xFF111111),
                      style: dialogTextStyle,
                      decoration: dialogField('Start Time (e.g. 09:00 AM)', Icons.access_time_rounded),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _endTimeController,
                      cursorColor: const Color(0xFF111111),
                      style: dialogTextStyle,
                      decoration: dialogField('End Time (e.g. 10:30 AM)', Icons.access_time_filled_rounded),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF8A8A8A),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_selectedSubject == null || _roomController.text.isEmpty) return;

                    final slot = TimetableSlot(
                      subjectId: _selectedSubject!.id!,
                      dayOfWeek: _selectedDay,
                      startTime: _startTimeController.text.trim(),
                      endTime: _endTimeController.text.trim(),
                      roomNumber: _roomController.text.trim(),
                      instructor: _selectedSubject!.instructor,
                    );

                    await DBHelper.instance.insertTimetableSlot(slot);

                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);

                    _loadData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111111),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  ),
                  child: Text(
                    'Save Slot',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteSlot(int id) async {
    await DBHelper.instance.deleteTimetableSlot(id);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _roomController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Space for the clear top bar + tab bar, so content starts below them
    final double topPad = MediaQuery.of(context).padding.top + kToolbarHeight + 76;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF1EDE4),
      appBar: AppBar(
        title: Text(
          'Timetable Vault',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111111),
          ),
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF111111),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Container(
            height: 58,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xB3FFFFFF),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: const Color(0xCCFFFFFF),
                width: 1.5,
              ),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(22),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF8A8A8A),
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(
                  height: 46,
                  icon: Icon(Icons.calendar_view_week_rounded, size: 20),
                  text: 'Weekly Schedule',
                ),
                Tab(
                  height: 46,
                  icon: Icon(Icons.image_rounded, size: 20),
                  text: 'Timetable Image',
                ),
              ],
            ),
          ),
        ),
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
        child: TabBarView(
          controller: _tabController,
          children: [
            _isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF111111),
                strokeWidth: 3,
              ),
            )
                : Column(
              children: [
                SizedBox(height: topPad),
                SizedBox(
                  height: 56,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _days.length,
                    itemBuilder: (context, index) {
                      final day = _days[index];
                      final isSelected = day == _selectedDay;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        child: ChoiceChip(
                          label: Text(day),
                          selected: isSelected,
                          showCheckmark: false,
                          selectedColor: const Color(0xFF111111),
                          backgroundColor: const Color(0xB3FFFFFF),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF111111)
                                : const Color(0xCCFFFFFF),
                            width: 1.5,
                          ),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          labelStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : const Color(0xFF111111),
                          ),
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedDay = day);
                          },
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1, color: Colors.transparent),
                Expanded(
                  child: _getSlotsForDay(_selectedDay).isEmpty
                      ? Center(
                    child: Text(
                      'No classes scheduled for $_selectedDay.',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF8A8A8A),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: _getSlotsForDay(_selectedDay).length,
                    itemBuilder: (context, index) {
                      final slot = _getSlotsForDay(_selectedDay)[index];
                      final subject = _getSubjectForSlot(slot.subjectId);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xB3FFFFFF),
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(
                                  color: const Color(0xCCFFFFFF),
                                  width: 1.5,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x12000000),
                                    blurRadius: 22,
                                    offset: Offset(0, 9),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                leading: const CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Color(0xFF111111),
                                  child: Icon(
                                    Icons.class_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                title: Text(
                                  subject != null
                                      ? '${subject.code} - ${subject.title}'
                                      : 'Class Slot',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: const Color(0xFF111111),
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.access_time_rounded,
                                            size: 14,
                                            color: Color(0xFF111111),
                                          ),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              'Time: ${slot.startTime} - ${slot.endTime}',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF111111),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Room: ${slot.roomNumber} • Instructor: ${slot.instructor}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF8A8A8A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: IconButton(
                                  style: IconButton.styleFrom(
                                    backgroundColor: const Color(0x1FFF5252),
                                  ),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.redAccent,
                                    size: 22,
                                  ),
                                  onPressed: () => _deleteSlot(slot.id!),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            Padding(
              padding: EdgeInsets.only(top: topPad),
              child: Center(
                child: _imagePath == null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 44,
                      backgroundColor: Color(0x99FFFFFF),
                      child: Icon(
                        Icons.image_not_supported_rounded,
                        size: 44,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'No timetable image uploaded yet.',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF8A8A8A),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.upload_rounded),
                      label: Text(
                        'Upload Schedule Image',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111111),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                )
                    : Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xB3FFFFFF),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: const Color(0xCCFFFFFF),
                                width: 1.5,
                              ),
                            ),
                            child: InteractiveViewer(
                              panEnabled: true,
                              minScale: 0.5,
                              maxScale: 4.0,
                              child: Image.network(_imagePath!),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 10, 8, 90),
                      child: TextButton.icon(
                        onPressed: _pickImage,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF111111),
                          backgroundColor: const Color(0xB3FFFFFF),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 12,
                          ),
                        ),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(
                          'Replace Image',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSlotDialog,
        backgroundColor: const Color(0xFF111111),
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
    );
  }

  List<TimetableSlot> _getSlotsForDay(String day) {
    return _slots.where((s) => s.dayOfWeek == day).toList();
  }

  Subject? _getSubjectForSlot(int subjectId) {
    try {
      return _subjects.firstWhere((s) => s.id == subjectId);
    } catch (_) {
      return null;
    }
  }
}