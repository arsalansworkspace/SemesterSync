import 'dart:ui';
import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/note.dart';

class ScratchpadScreen extends StatefulWidget {
  const ScratchpadScreen({super.key});

  @override
  State<ScratchpadScreen> createState() => _ScratchpadScreenState();
}

class _ScratchpadScreenState extends State<ScratchpadScreen> {
  List<Note> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    final notes = await DBHelper.instance.getNotes();

    // Sort so newest notes appear first
    notes.sort((a, b) => b.id!.compareTo(a.id!));

    setState(() {
      _notes = notes;
      _isLoading = false;
    });
  }

  void _showNoteEditor({Note? existingNote}) {
    final titleController = TextEditingController(text: existingNote?.title ?? '');
    final contentController = TextEditingController(text: existingNote?.content ?? '');

    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: const Color(0xFFF1EDE4),
          appBar: AppBar(
            title: Text(
              existingNote == null ? 'New Note' : 'Edit Note',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: Color(0xFF111111),
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
                    backgroundColor: const Color(0xFF111111),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.check_rounded),
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final content = contentController.text.trim();

                    if (title.isEmpty && content.isEmpty) {
                      Navigator.pop(context);
                      return;
                    }

                    final note = Note(
                      id: existingNote?.id,
                      title: title.isEmpty ? 'Untitled' : title,
                      content: content,
                      date: DateTime.now().toString().substring(0, 16),
                    );

                    if (existingNote == null) {
                      await DBHelper.instance.insertNote(note);
                    } else {
                      await DBHelper.instance.updateNote(note);
                    }

                    if (!context.mounted) return;
                    Navigator.pop(context);
                    _loadNotes();
                  },
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
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + kToolbarHeight + 8,
                16,
                16,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0x99FFFFFF),
                      borderRadius: BorderRadius.circular(32),
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
                      children: [
                        TextField(
                          controller: titleController,
                          cursorColor: const Color(0xFF111111),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111111),
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Title',
                            hintStyle: TextStyle(
                              color: Color(0xFFA5A5A5),
                              fontWeight: FontWeight.w700,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                        const Divider(
                          height: 24,
                          color: Color(0x1F000000),
                        ),
                        Expanded(
                          child: TextField(
                            controller: contentController,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            cursorColor: const Color(0xFF111111),
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: Color(0xFF3A3A3A),
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Start typing your notes here...',
                              hintStyle: TextStyle(color: Color(0xFFA5A5A5)),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _deleteNote(int id) async {
    await DBHelper.instance.deleteNote(id);
    _loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF1EDE4),
      appBar: AppBar(
        title: const Text(
          'Scratchpad',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 28,
            color: Color(0xFF111111),
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
            : _notes.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircleAvatar(
                radius: 44,
                backgroundColor: Color(0x99FFFFFF),
                child: Icon(
                  Icons.edit_note_rounded,
                  size: 48,
                  color: Color(0xFF111111),
                ),
              ),
              SizedBox(height: 18),
              Text(
                'No notes yet. Tap + to start writing!',
                style: TextStyle(
                  color: Color(0xFF8A8A8A),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        )
            : GridView.builder(
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + kToolbarHeight + 12,
            16,
            100,
          ),
          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.85,
          ),
          itemCount: _notes.length,
          itemBuilder: (context, index) {
            final note = _notes[index];
            return GestureDetector(
              onTap: () => _showNoteEditor(existingNote: note),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: index.isEven
                          ? const Color(0xA6FFFFFF)
                          : const Color(0x80FFF3EE),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xCCFFFFFF),
                        width: 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                note.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: Color(0xFF111111),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _deleteNote(note.id!),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0x1FFF5252),
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Text(
                            note.content,
                            style: const TextStyle(
                              color: Color(0xFF5C5C5C),
                              fontSize: 13.5,
                              height: 1.4,
                            ),
                            overflow: TextOverflow.fade,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: Color(0xFF8A8A8A),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                note.date,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF8A8A8A),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNoteEditor(),
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
}