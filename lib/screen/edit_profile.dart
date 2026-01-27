import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _matricController = TextEditingController();
  final _majorController = TextEditingController();
  final _skillsController = TextEditingController();
  final _bioController = TextEditingController();
  final _nameController = TextEditingController(); // Added Name editing

  String? _selectedKulliyyah;
  String? _selectedSemester;
  File? _imageFile;
  bool _isLoading = false;
  String? _currentPhotoUrl;

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
    _populateFields();
  }

  void _populateFields() {
    var data = widget.userData;
    _nameController.text = data['name'] ?? '';
    _matricController.text = data['matric_no'] ?? '';
    _majorController.text = data['major'] ?? '';
    _skillsController.text = data['skills'] ?? '';
    _bioController.text = data['bio'] ?? '';

    // Safety check for dropdowns to ensure value exists in list
    if (_kulliyyahs.contains(data['kulliyyah'])) {
      _selectedKulliyyah = data['kulliyyah'];
    }
    if (_semesters.contains(data['semester'])) {
      _selectedSemester = data['semester'];
    }

    _currentPhotoUrl = data['photo_url'];
  }

  @override
  void dispose() {
    _matricController.dispose();
    _majorController.dispose();
    _skillsController.dispose();
    _bioController.dispose();
    _nameController.dispose();
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
    if (_imageFile == null)
      return _currentPhotoUrl; // Return existing URL if no new image
    try {
      // Use a timestamp to prevent caching issues if overwriting
      String fileName = '${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child(fileName);
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.outfit(
            color: const Color(0xFF1A3B5D),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A3B5D)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Profile Picture Section
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF1A3B5D).withOpacity(0.1),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        image: _getProfileImage(),
                      ),
                      child:
                          _imageFile == null &&
                              (_currentPhotoUrl == null ||
                                  _currentPhotoUrl!.isEmpty)
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

            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _matricController,
              label: 'Matric Number',
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 16),

            _buildDropdown(
              value: _selectedKulliyyah,
              label: 'Kulliyyah (Faculty)',
              icon: Icons.school_outlined,
              items: _kulliyyahs,
              onChanged: (v) => setState(() => _selectedKulliyyah = v),
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _majorController,
              label: 'Major / Specialization',
              icon: Icons.book_outlined,
            ),
            const SizedBox(height: 16),

            _buildDropdown(
              value: _selectedSemester,
              label: 'Current Semester',
              icon: Icons.calendar_today_outlined,
              items: _semesters,
              onChanged: (v) => setState(() => _selectedSemester = v),
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _skillsController,
              label: 'Skills (comma separated)',
              icon: Icons.lightbulb_outline,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _bioController,
              label: 'Bio',
              icon: Icons.info_outline,
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isLoading ? null : _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3B5D),
                foregroundColor: Colors.white,
                elevation: 0,
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
                      'Update Profile',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  DecorationImage? _getProfileImage() {
    if (_imageFile != null) {
      return DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover);
    } else if (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty) {
      return DecorationImage(
        image: NetworkImage(_currentPhotoUrl!),
        fit: BoxFit.cover,
      );
    }
    return null;
  }

  Future<void> _updateProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      String? photoUrl = await _uploadImage(user.uid);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'name': _nameController.text.trim(),
            'matric_no': _matricController.text.trim(),
            'kulliyyah': _selectedKulliyyah,
            'major': _majorController.text.trim(),
            'semester': _selectedSemester,
            'skills': _skillsController.text.trim(),
            'bio': _bioController.text.trim(),
            'email': user.email, // Ensure email is saved/updated
            if (photoUrl != null) 'photo_url': photoUrl,
            'updated_at': FieldValue.serverTimestamp(),
          });

      // Update display name in Auth as well if possible
      if (_nameController.text.isNotEmpty &&
          user.displayName != _nameController.text) {
        await user.updateDisplayName(_nameController.text.trim());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.inter(),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey),
          labelText: label,
          labelStyle: GoogleFonts.inter(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey),
          labelText: label,
          labelStyle: GoogleFonts.inter(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
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
