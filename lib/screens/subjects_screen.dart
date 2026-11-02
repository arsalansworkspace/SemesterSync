import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/db_helper.dart';
import '../models/subject.dart';
import 'subject_tasks_screen.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  List<Subject> _subjects = [];
  bool _isLoading = true;

  final _titleController = TextEditingController();
  final _codeController = TextEditingController();
  final _instructorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() => _isLoading = true);
    final subjects = await DBHelper.instance.getSubjects();
    setState(() {
      _subjects = subjects;
      _isLoading = false;
    });
  }

  // Dialog to Add or Edit Subject
  void _showSubjectDialog({Subject? subjectToEdit}) {
    if (subjectToEdit != null) {
      _titleController.text = subjectToEdit.title;
      _codeController.text = subjectToEdit.code;
      _instructorController.text = subjectToEdit.instructor;
    } else {
      _clearControllers();
    }

    showDialog(
      context: context,
      builder: (context) {
        // Same look for all three text fields in the dialog
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
            subjectToEdit == null ? 'Add New Subject' : 'Edit Subject',
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
                TextField(
                  controller: _titleController,
                  cursorColor: const Color(0xFF111111),
                  style: dialogTextStyle,
                  decoration: dialogField(
                    'Subject Name (e.g. Mobile App Dev)',
                    Icons.menu_book_rounded,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _codeController,
                  cursorColor: const Color(0xFF111111),
                  style: dialogTextStyle,
                  decoration: dialogField(
                    'Course Code (e.g. CS-301)',
                    Icons.tag_rounded,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _instructorController,
                  cursorColor: const Color(0xFF111111),
                  style: dialogTextStyle,
                  decoration: dialogField(
                    'Instructor Name',
                    Icons.person_rounded,
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () {
                _clearControllers();
                Navigator.pop(context);
              },
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
                final title = _titleController.text.trim();
                final code = _codeController.text.trim();
                final instructor = _instructorController.text.trim();

                if (title.isEmpty || code.isEmpty) return;

                final subject = Subject(
                  id: subjectToEdit?.id,
                  title: title,
                  code: code,
                  instructor: instructor.isEmpty ? 'N/A' : instructor,
                  colorHex: '0xFF3F51B5',
                );

                if (subjectToEdit == null) {
                  await DBHelper.instance.insertSubject(subject);
                } else {
                  await DBHelper.instance.updateSubject(subject);
                }

                _clearControllers();
                if (!mounted) return;
                Navigator.pop(context);
                _loadSubjects();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111111),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              ),
              child: Text(
                subjectToEdit == null ? 'Save Subject' : 'Update',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }

  // Delete Confirmation Dialog
  void _confirmDelete(Subject subject) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF7F3EC),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        title: Text(
          'Delete Subject',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111111),
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${subject.title}"?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14.5,
            height: 1.4,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF5C5C5C),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8A8A8A),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (subject.id != null) {
                await DBHelper.instance.deleteSubject(subject.id!);
                if (!mounted) return;
                Navigator.pop(context);
                _loadSubjects();
              }
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0x1FFF5252),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.red,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearControllers() {
    _titleController.clear();
    _codeController.clear();
    _instructorController.clear();
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF1EDE4),
      appBar: AppBar(
        title: Text(
          'My Subjects',
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
            : _subjects.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 44,
                backgroundColor: Color(0x99FFFFFF),
                child: Icon(
                  Icons.book_outlined,
                  size: 44,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'No subjects added yet.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8A8A8A),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _showSubjectDialog(),
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  'Add Your First Subject',
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
          ),
        )
            : ListView.builder(
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + kToolbarHeight + 12,
            16,
            100,
          ),
          itemCount: _subjects.length,
          itemBuilder: (context, index) {
            final sub = _subjects[index];
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubjectTasksScreen(subject: sub),
                          ),
                        );
                      },
                      leading: CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFF111111),
                        child: Text(
                          sub.code.substring(0, sub.code.length > 4 ? 4 : sub.code.length),
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
                          fontSize: 16,
                          color: const Color(0xFF111111),
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Instructor: ${sub.instructor}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF8A8A8A),
                          ),
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_horiz_rounded,
                          color: Color(0xFF111111),
                        ),
                        color: Colors.white,
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showSubjectDialog(subjectToEdit: sub);
                          } else if (value == 'delete') {
                            _confirmDelete(sub);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_rounded,
                                    size: 20, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text(
                                  'Edit',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_rounded,
                                    size: 20, color: Colors.red),
                                const SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: _subjects.isNotEmpty
          ? FloatingActionButton(
        onPressed: () => _showSubjectDialog(),
        backgroundColor: const Color(0xFF111111),
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(Icons.add_rounded, size: 30),
      )
          : null,
    );
  }
}