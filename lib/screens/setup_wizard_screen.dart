import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import '../models/subject.dart';
import 'home_dashboard_screen.dart';

class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  final _titleController = TextEditingController();
  final _codeController = TextEditingController();
  final _instructorController = TextEditingController();
  List<Subject> _addedSubjects = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  // Load existing subjects from database on screen open
  Future<void> _fetchSubjects() async {
    setState(() => _isLoading = true);
    final subjects = await DBHelper.instance.getSubjects();
    setState(() {
      _addedSubjects = subjects;
      _isLoading = false;
    });
  }

  void _addSubject() async {
    final title = _titleController.text.trim();
    final code = _codeController.text.trim();
    final instructor = _instructorController.text.trim();

    if (title.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in both Subject Name and Course Code.',
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

    final newSubject = Subject(
      title: title,
      code: code,
      instructor: instructor.isEmpty ? 'N/A' : instructor,
      colorHex: '0xFF3F51B5',
    );

    // Save to database
    await DBHelper.instance.insertSubject(newSubject);

    // Clear input fields
    _titleController.clear();
    _codeController.clear();
    _instructorController.clear();

    // Refresh subject list from SQLite
    await _fetchSubjects();
  }

  void _finishSetup() async {
    if (_addedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please add at least one subject to continue.',
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSetupComplete', true);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeDashboardScreen()),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _codeController.dispose();
    _instructorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Same look for all three text fields
    InputDecoration fieldStyle(String label, IconData icon) {
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
        fillColor: const Color(0xB3FFFFFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xCCFFFFFF), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF111111), width: 1.5),
        ),
      );
    }

    final fieldTextStyle = GoogleFonts.plusJakartaSans(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF111111),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF1EDE4),
      appBar: AppBar(
        title: Text(
          'Semester Setup',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111111),
          ),
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF111111),
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
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + kToolbarHeight + 8,
            16,
            16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add Your Subjects for this Semester',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 14),

              // Glass card that holds the form
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0x80FFFFFF),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xCCFFFFFF),
                        width: 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 30,
                          offset: Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _titleController,
                          cursorColor: const Color(0xFF111111),
                          style: fieldTextStyle,
                          decoration: fieldStyle(
                            'Subject Name (e.g., Mobile App Dev)',
                            Icons.menu_book_rounded,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _codeController,
                          cursorColor: const Color(0xFF111111),
                          style: fieldTextStyle,
                          decoration: fieldStyle(
                            'Course Code (e.g., CS-301)',
                            Icons.tag_rounded,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _instructorController,
                          cursorColor: const Color(0xFF111111),
                          style: fieldTextStyle,
                          decoration: fieldStyle(
                            'Instructor Name',
                            Icons.person_rounded,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: _addSubject,
                          icon: const Icon(Icons.add_rounded),
                          label: Text(
                            'Add Subject',
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
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),
              Text(
                'Added Subjects:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _isLoading
                    ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF111111),
                    strokeWidth: 3,
                  ),
                )
                    : _addedSubjects.isEmpty
                    ? Center(
                  child: Text(
                    'No subjects added yet. Add one above!',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF8A8A8A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
                    : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _addedSubjects.length,
                  itemBuilder: (context, index) {
                    final sub = _addedSubjects[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
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
                                horizontal: 14,
                                vertical: 4,
                              ),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFF111111),
                                child: Text(
                                  sub.code.substring(
                                    0,
                                    sub.code.length > 3 ? 3 : sub.code.length,
                                  ),
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              title: Text(
                                '${sub.code} - ${sub.title}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: const Color(0xFF111111),
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  'Instructor: ${sub.instructor}',
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
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _finishSetup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB8E0B0),
                  foregroundColor: const Color(0xFF111111),
                  elevation: 0,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: Text(
                  'Complete Setup & Continue',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}