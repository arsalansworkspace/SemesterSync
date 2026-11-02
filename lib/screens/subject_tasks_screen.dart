import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../notification_service.dart';
import '../database/db_helper.dart';
import '../models/subject.dart';
import '../models/task.dart';

class SubjectTasksScreen extends StatefulWidget {
  final Subject subject;

  const SubjectTasksScreen({super.key, required this.subject});

  @override
  State<SubjectTasksScreen> createState() => _SubjectTasksScreenState();
}

class _SubjectTasksScreenState extends State<SubjectTasksScreen> {
  List<Task> _tasks = [];
  bool _isLoading = true;

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _selectedDueDate;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    if (widget.subject.id != null) {
      final tasks = await DBHelper.instance.getTasksBySubject(widget.subject.id!);
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    }
  }

  void _showTaskDialog({Task? taskToEdit}) {
    if (taskToEdit != null) {
      _titleController.text = taskToEdit.title;
      _descController.text = taskToEdit.description;
      _selectedDueDate = DateTime.tryParse(taskToEdit.dueDate);
    } else {
      _titleController.clear();
      _descController.clear();
      _selectedDueDate = DateTime.now().add(const Duration(days: 1));
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            // Same look for both text fields in the dialog
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
                taskToEdit == null ? 'Add Task for ${widget.subject.code}' : 'Edit Task',
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
                        'Task Title (e.g. Lab Report 1)',
                        Icons.assignment_rounded,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _descController,
                      maxLines: 2,
                      cursorColor: const Color(0xFF111111),
                      style: dialogTextStyle,
                      decoration: dialogField(
                        'Description / Instructions',
                        Icons.notes_rounded,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.only(left: 14, right: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xCCFFFFFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE6E1D8),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              _selectedDueDate == null
                                  ? 'No Due Date Selected'
                                  : 'Due: ${_selectedDueDate.toString().substring(0, 10)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                color: const Color(0xFF111111),
                              ),
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF111111),
                            ),
                            icon: const Icon(Icons.calendar_today_rounded, size: 18),
                            label: Text(
                              'Pick Date',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: dialogContext,
                                initialDate: _selectedDueDate ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: Color(0xFF111111),
                                        onPrimary: Colors.white,
                                        onSurface: Color(0xFF111111),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setDialogState(() => _selectedDueDate = picked);
                              }
                            },
                          ),
                        ],
                      ),
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
                    final title = _titleController.text.trim();
                    final desc = _descController.text.trim();

                    if (title.isEmpty) return;

                    final task = Task(
                      id: taskToEdit?.id,
                      subjectId: widget.subject.id!,
                      title: title,
                      description: desc,
                      dueDate: (_selectedDueDate ?? DateTime.now()).toString().substring(0, 10),
                      isCompleted: taskToEdit?.isCompleted ?? false,
                    );

                    if (taskToEdit == null) {
                      final taskId = await DBHelper.instance.insertTask(task);

                      if (_selectedDueDate != null) {
                        NotificationService().scheduleDeadlineNotification(
                          id: taskId,
                          taskTitle: task.title,
                          subjectName: widget.subject.code,
                          dueDate: _selectedDueDate!,
                        );
                      }
                    } else {
                      await DBHelper.instance.updateTask(task);

                      if (_selectedDueDate != null && task.id != null) {
                        NotificationService().scheduleDeadlineNotification(
                          id: task.id!,
                          taskTitle: task.title,
                          subjectName: widget.subject.code,
                          dueDate: _selectedDueDate!,
                        );
                      }
                    }

                    if (!mounted) return;
                    Navigator.of(dialogContext).pop();
                    _loadTasks();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111111),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  ),
                  child: Text(
                    taskToEdit == null ? 'Save Task' : 'Update',
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

  void _toggleTaskCompletion(Task task) async {
    final updatedTask = Task(
      id: task.id,
      subjectId: task.subjectId,
      title: task.title,
      description: task.description,
      dueDate: task.dueDate,
      isCompleted: !task.isCompleted,
    );

    await DBHelper.instance.updateTask(updatedTask);

    if (updatedTask.isCompleted && task.id != null) {
      NotificationService().cancelNotification(task.id!);
    }

    _loadTasks();
  }

  void _deleteTask(int id) async {
    await DBHelper.instance.deleteTask(id);
    NotificationService().cancelNotification(id);
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF1EDE4),
      appBar: AppBar(
        title: Text(
          '${widget.subject.code} Tasks',
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
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF111111),
            strokeWidth: 3,
          ),
        )
            : _tasks.isEmpty
            ? Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 44,
                  backgroundColor: Color(0x99FFFFFF),
                  child: Icon(
                    Icons.task_outlined,
                    size: 44,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'No tasks created for ${widget.subject.title} yet.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF8A8A8A),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _showTaskDialog(),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    'Add Task',
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
          ),
        )
            : ListView.builder(
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + kToolbarHeight + 12,
            16,
            100,
          ),
          itemCount: _tasks.length,
          itemBuilder: (context, index) {
            final task = _tasks[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    decoration: BoxDecoration(
                      color: task.isCompleted
                          ? const Color(0x80FFFFFF)
                          : const Color(0xB3FFFFFF),
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
                      leading: Checkbox(
                        value: task.isCompleted,
                        activeColor: const Color(0xFF111111),
                        checkColor: Colors.white,
                        side: const BorderSide(
                          color: Color(0xFF111111),
                          width: 1.6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                        onChanged: (_) => _toggleTaskCompletion(task),
                      ),
                      title: Text(
                        task.title,
                        style: GoogleFonts.plusJakartaSans(
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: task.isCompleted
                              ? const Color(0xFF8A8A8A)
                              : const Color(0xFF111111),
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (task.description.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                task.description,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF5C5C5C),
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x1FFF5252),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.event_rounded,
                                  size: 13,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Due: ${task.dueDate}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                            _showTaskDialog(taskToEdit: task);
                          } else if (value == 'delete') {
                            if (task.id != null) _deleteTask(task.id!);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_rounded,
                                    size: 18, color: Colors.blue),
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
                                    size: 18, color: Colors.red),
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
      floatingActionButton: _tasks.isNotEmpty
          ? FloatingActionButton(
        onPressed: () => _showTaskDialog(),
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