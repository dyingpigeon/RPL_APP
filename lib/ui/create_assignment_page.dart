import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class CreateAssignmentPage extends StatefulWidget {
  const CreateAssignmentPage({super.key});

  @override
  State<CreateAssignmentPage> createState() => _CreateAssignmentPageState();
}

class _CreateAssignmentPageState extends State<CreateAssignmentPage> {
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();
  PlatformFile? _selectedFile;
  String? _fileUrl;

  @override
  void initState() {
    super.initState();
    _initializeFilePicker();
  }

  Future<void> _initializeFilePicker() async {
    try {
      // Inisialisasi file picker
      await FilePicker.platform.clearTemporaryFiles();
      print("✅ FilePicker initialized successfully");
    } catch (e) {
      print("⚠️ FilePicker initialization warning: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Create Assignment'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text('Add Title (required)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _judulController,
              decoration: const InputDecoration(border: UnderlineInputBorder(), hintText: 'Masukkan judul assignment'),
            ),
            const SizedBox(height: 16),
            const Text('Description', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _deskripsiController,
              maxLines: 4,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                hintText: 'Masukkan deskripsi assignment',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.attach_file, size: 16),
                  label: const Text('Add Attachment', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black12),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                ),
                const SizedBox(width: 8),
                if (_selectedFile != null)
                  Chip(
                    label: Text(
                      _selectedFile!.name.length > 20
                          ? '${_selectedFile!.name.substring(0, 20)}...'
                          : _selectedFile!.name,
                    ),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: _removeSelectedFile,
                  ),
              ],
            ),
            if (_selectedFile != null) ...[
              const SizedBox(height: 8),
              Text(
                'File: ${_selectedFile!.name} (${_formatFileSize(_selectedFile!.size)})',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 16),
            const Text('Add Deadline', style: TextStyle(fontSize: 13, color: Colors.redAccent)),
            const SizedBox(height: 8),
            TextField(
              controller: _deadlineController,
              readOnly: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'YYYY-MM-DD HH:MM:SS',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: () {
                _selectDateTime(context);
              },
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitAssignment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Post'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      print("🔄 Starting file picker...");

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: false, // Penting: set to false untuk menghindari issue
        withReadStream: false, // Penting: set to false untuk menghindari issue
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
          _fileUrl = _selectedFile!.path;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File "${_selectedFile!.name}" berhasil dipilih'),
            duration: const Duration(seconds: 2),
          ),
        );
        print("✅ File selected: ${_selectedFile!.name}");
      } else {
        print("ℹ️ No file selected");
      }
    } catch (e) {
      print("❌ Error picking file: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memilih file: $e'), backgroundColor: Colors.red));
    }
  }

  void _removeSelectedFile() {
    setState(() {
      _selectedFile = null;
      _fileUrl = null;
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  void _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());

      if (pickedTime != null) {
        final DateTime finalDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          _deadlineController.text =
              '${finalDateTime.year}-${finalDateTime.month.toString().padLeft(2, '0')}-${finalDateTime.day.toString().padLeft(2, '0')} '
              '${finalDateTime.hour.toString().padLeft(2, '0')}:${finalDateTime.minute.toString().padLeft(2, '0')}:00';
        });
      }
    }
  }

  void _submitAssignment() {
    if (_selectedFile != null) {
      // TODO: Implement file upload logic
      print("📤 File ready for upload: ${_selectedFile!.name}");
    }

    final assignmentData = {
      "judul": _judulController.text.trim(),
      "deskripsi": _deskripsiController.text.trim(),
      "fileUrl": _fileUrl,
      "deadline": _deadlineController.text.trim(),
    };

    if (assignmentData["judul"]!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Judul assignment harus diisi')));
      return;
    }

    if (assignmentData["deadline"]!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deadline harus diisi')));
      return;
    }

    Navigator.pop(context, assignmentData);
  }

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }
}
