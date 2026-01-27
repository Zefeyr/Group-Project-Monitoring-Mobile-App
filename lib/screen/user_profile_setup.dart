import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'home.dart';

class UserProfileSetup extends StatefulWidget {
  final String name;
  const UserProfileSetup({super.key, required this.name});

  @override
  State<UserProfileSetup> createState() => _UserProfileSetupState();
}

class _UserProfileSetupState extends State<UserProfileSetup> {
  // ... (existing code)

  final _nameController = TextEditingController();
  final _matricController = TextEditingController();
  final _majorController = TextEditingController();
  final _skillsController = TextEditingController();
  final _bioController = TextEditingController();

  String? _selectedKulliyyah;
  String? _selectedSemester;
  File? _imageFile;
  bool _isLoading = false;

  final List<String> _kulliyyahs = [
    'KICT',
    'Engineering',
    'Economics',
    'Laws',
    'IRKHS',
    'Education',
    'Architecture',
    'Medicine',
    'Pharmacy',
    'Science',
    'Allied Health',
    'Nursing',
    'Dentistry',
    'Languages',
  ];

  final List<String> _semesters = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9+',
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _matricController.dispose();
    _majorController.dispose();
    _skillsController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(String uid) async {
    if (_imageFile == null) return null;
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('$uid.jpg');
      await ref.putFile(_imageFile!);
      return await ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Complete Profile',
          style: GoogleFonts.outfit(
            color: const Color(0xFF1A3B5D),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF1A3B5D)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE0F7FA), Color(0xFF88D3CE), Color(0xFF3F6D9F)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Picture Placeholder
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF1A3B5D).withOpacity(0.5),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                            image: _imageFile != null
                                ? DecorationImage(
                                    image: FileImage(_imageFile!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _imageFile == null
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1A3B5D),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Name
                _buildGlassTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person,
                ),
                const SizedBox(height: 16),

                // Matric Number
                _buildGlassTextField(
                  controller: _matricController,
                  label: 'Matric Number',
                  icon: Icons.numbers,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Kulliyyah Dropdown
                _buildGlassDropdown(
                  value: _selectedKulliyyah,
                  label: 'Kulliyyah (Faculty)',
                  icon: Icons.school,
                  items: _kulliyyahs,
                  onChanged: (v) => setState(() => _selectedKulliyyah = v),
                ),
                const SizedBox(height: 16),

                // Major
                _buildGlassTextField(
                  controller: _majorController,
                  label: 'Major / Specialization',
                  icon: Icons.book,
                ),
                const SizedBox(height: 16),

                // Semester Dropdown
                _buildGlassDropdown(
                  value: _selectedSemester,
                  label: 'Current Semester',
                  icon: Icons.calendar_today,
                  items: _semesters,
                  onChanged: (v) => setState(() => _selectedSemester = v),
                ),
                const SizedBox(height: 16),

                // Skills
                _buildGlassTextField(
                  controller: _skillsController,
                  label: 'Key Skills (e.g., Flutter, Python)',
                  icon: Icons.lightbulb,
                ),
                const SizedBox(height: 16),

                // Bio
                _buildGlassTextField(
                  controller: _bioController,
                  label: 'Bio / About Me',
                  icon: Icons.info_outline,
                  maxLines: 3,
                ),
                const SizedBox(height: 32),

                // Save Button
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No user logged in!'),
                              ),
                            );
                            return;
                          }

                          // Matric Validation
                          if (!RegExp(
                            r'^\d{7}$',
                          ).hasMatch(_matricController.text.trim())) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Matric number must be exactly 7 digits',
                                ),
                              ),
                            );
                            return;
                          }

                          // Basic validation
                          if (_nameController.text.isEmpty ||
                              _matricController.text.isEmpty ||
                              _selectedKulliyyah == null ||
                              _majorController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please fill required fields (Name, Matric, Kulliyyah, Major)',
                                ),
                              ),
                            );
                            return;
                          }

                          setState(() => _isLoading = true);

                          try {
                            String? photoUrl = await _uploadImage(user.uid);

                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .set({
                                  'name': _nameController.text.trim(),
                                  'matric_no': _matricController.text.trim(),
                                  'kulliyyah': _selectedKulliyyah,
                                  'major': _majorController.text.trim(),
                                  'semester': _selectedSemester,
                                  'skills': _skillsController.text.trim(),
                                  'bio': _bioController.text.trim(),
                                  'email': user.email,
                                  'photo_url': photoUrl,
                                  'created_at': FieldValue.serverTimestamp(),
                                });

                            if (!mounted) return;

                            if (!mounted) return;

                            // Clear the stack and return to the root (which is now HomeScreen via StreamBuilder)
                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error saving profile: $e'),
                              ),
                            );
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A3B5D),
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: Colors.black.withOpacity(0.3),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Save & Continue',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(color: Colors.black87),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF1A3B5D)),
          labelText: label,
          labelStyle: GoogleFonts.inter(color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF1A3B5D)),
          labelText: label,
          labelStyle: GoogleFonts.inter(color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 20,
          ),
        ),
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1A3B5D)),
        dropdownColor: Colors.white,
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item, style: GoogleFonts.inter()),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
