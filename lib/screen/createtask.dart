import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateTaskScreen extends StatefulWidget {
  final String projectId;
  final List<String> projectMembers;

  const CreateTaskScreen({
    super.key,
    required this.projectId,
    required this.projectMembers,
  });

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final Color primaryBlue = const Color(0xFF1A3B5D);
  final TextEditingController _taskNameController = TextEditingController();
  String? _selectedMember;
  DateTime? _selectedDate;
  bool _isLoading = false;

  Future<void> _saveTask({bool addAnother = false}) async {
    if (_taskNameController.text.isEmpty ||
        _selectedMember == null ||
        _selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Add task to sub-collection
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .collection('tasks')
          .add({
            'taskName': _taskNameController.text.trim(),
            'assignedTo': _selectedMember,
            'deadline': Timestamp.fromDate(_selectedDate!),
            'status': 'Pending',
            'createdAt': FieldValue.serverTimestamp(),
          });

      // 2. Update main project header with the most recent task name
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .update({'activeTask': _taskNameController.text.trim()});

      if (mounted) {
        if (addAnother) {
          // Reset fields for the next task
          _taskNameController.clear();
          setState(() {
            _selectedMember = null;
            _selectedDate = null;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Task added! Create the next one.")),
          );
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          "Assign Tasks",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: primaryBlue,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Task Details", style: _labelStyle()),
                  const SizedBox(height: 10),
                  _buildTextField(),

                  const SizedBox(height: 30),

                  Text("Assign to member", style: _labelStyle()),
                  const SizedBox(height: 10),
                  _buildMemberDropdown(),

                  const SizedBox(height: 30),

                  Text("Due Date", style: _labelStyle()),
                  const SizedBox(height: 10),
                  _buildDatePicker(),

                  const SizedBox(height: 40),

                  // ACTION BUTTONS
                  _buildSubmitButton(
                    label: "Save & Add Another",
                    onPressed: () => _saveTask(addAnother: true),
                    isSecondary: true,
                  ),
                  const SizedBox(height: 12),
                  _buildSubmitButton(
                    label: "Finish & Return",
                    onPressed: () => _saveTask(addAnother: false),
                    isSecondary: false,
                  ),
                ],
              ),
            ),
    );
  }

  TextStyle _labelStyle() => GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: primaryBlue,
  );

  Widget _buildTextField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: TextField(
        controller: _taskNameController,
        decoration: InputDecoration(
          hintText: "e.g., Build Database",
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
          hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
        ),
      ),
    );
  }

  Widget _buildMemberDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMember,
          isExpanded: true,
          hint: Text("Select a member", style: GoogleFonts.inter(fontSize: 14)),
          items: widget.projectMembers.map((email) {
            return DropdownMenuItem(
              value: email,
              child: Text(email, style: GoogleFonts.inter(fontSize: 14)),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedMember = val),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2030),
        );
        if (picked != null) setState(() => _selectedDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedDate == null
                  ? "Select Deadline"
                  : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
              style: GoogleFonts.inter(
                color: _selectedDate == null ? Colors.grey : primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(Icons.calendar_month_rounded, color: primaryBlue, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton({
    required String label,
    required VoidCallback onPressed,
    required bool isSecondary,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary ? Colors.white : primaryBlue,
          foregroundColor: isSecondary ? primaryBlue : Colors.white,
          side: isSecondary ? BorderSide(color: primaryBlue) : BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: isSecondary ? 0 : 2,
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
