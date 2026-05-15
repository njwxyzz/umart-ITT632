import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

// --- Color Constants ---
const kPrimary = Color(0xFF4C6B3F);
const kAccent = Color(0xFFF27B35);
const kBg = Color(0xFFF5F7F2);
const kWhite = Colors.white;

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  String? _selectedCollege;
  String? _profileImageUrl;
  Uint8List? _newProfileImageBytes;
  bool _hadProfileImageOnLoad = false;
  bool _photoRemoved = false;

  final List<String> _colleges = [
    'Kolej Dahlia 1',
    'Kolej Dahlia 2',
    'Kolej Dahlia 3',
    'Kolej Kesinai 1',
    'Kolej Kesinai 2',
    'Kolej Kesinai 3',
    'Kolej Cengal 1',
    'Kolej Cengal 2',
    'Kolej Cengal 3',
    'Kolej Cengal 4',
    'Kolej Cengal 5',
    'Kolej Cengal 6',
    'Kolej Cengal 7',
    'Non-Resident (NR)',
  ];

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserData();
  }

  Future<void> _fetchCurrentUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        _emailController.text = currentUser.email ?? '';

        final userDoc =
            await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();

        if (userDoc.exists) {
          final data = userDoc.data()!;
          _nameController.text = data['fullName'] ?? '';
          _idController.text = data['studentId'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          final rawImage = (data['profileImage'] ?? data['photoUrl'] ?? data['imageUrl'] ?? '')
              .toString()
              .trim();
          if (rawImage.isNotEmpty) {
            _profileImageUrl = rawImage;
            _hadProfileImageOnLoad = true;
          }

          if (data['college'] != null && _colleges.contains(data['college'])) {
            _selectedCollege = data['college'];
          }
        }
      }
    } catch (e) {
      debugPrint('Error tarik data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      const removeAction = 'remove';
      final choice = await showModalBottomSheet<String>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: kPrimary),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded, color: kPrimary),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              if (_profileImageUrl != null ||
                  _newProfileImageBytes != null ||
                  _hadProfileImageOnLoad)
                ListTile(
                  leading: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400),
                  title: Text('Remove photo', style: TextStyle(color: Colors.red.shade400)),
                  onTap: () => Navigator.pop(ctx, removeAction),
                ),
            ],
          ),
        ),
      );

      if (!mounted || choice == null) return;

      if (choice == removeAction) {
        setState(() {
          _newProfileImageBytes = null;
          _profileImageUrl = null;
          _photoRemoved = true;
        });
        return;
      }

      final source = choice == 'camera' ? ImageSource.camera : ImageSource.gallery;
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _newProfileImageBytes = bytes;
        _profileImageUrl = null;
        _photoRemoved = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick image: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<String?> _uploadProfileImage(String uid) async {
    if (_newProfileImageBytes == null) return null;

    final ref = FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');
    final snap = await ref.putData(
      _newProfileImageBytes!,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return snap.ref.getDownloadURL();
  }

  Future<void> _saveProfileData() async {
    setState(() => _isSaving = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final payload = <String, dynamic>{
        'fullName': _nameController.text.trim(),
        'studentId': _idController.text.trim(),
        'phone': _phoneController.text.trim(),
        'college': _selectedCollege,
      };

      if (_newProfileImageBytes != null) {
        final imageUrl = await _uploadProfileImage(currentUser.uid);
        if (imageUrl != null && imageUrl.isNotEmpty) {
          payload['profileImage'] = imageUrl;
        }
      } else if (_photoRemoved && _hadProfileImageOnLoad) {
        payload['profileImage'] = FieldValue.delete();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .set(payload, SetOptions(merge: true));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully! 🎉'),
            backgroundColor: kPrimary,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error simpan data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildAvatar(String initial) {
    final border = Border.all(color: kPrimary.withOpacity(0.3), width: 2);

    Widget child;
    if (_newProfileImageBytes != null) {
      child = ClipOval(
        child: Image.memory(_newProfileImageBytes!, width: 100, height: 100, fit: BoxFit.cover),
      );
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      child = ClipOval(
        child: Image.network(
          _profileImageUrl!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialAvatar(initial),
        ),
      );
    } else {
      child = _initialAvatar(initial);
    }

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(shape: BoxShape.circle, border: border),
      clipBehavior: Clip.hardEdge,
      child: child,
    );
  }

  Widget _initialAvatar(String initial) {
    return Container(
      color: kPrimary.withOpacity(0.1),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(color: kPrimary, fontSize: 40, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initial =
        _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1A2E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveProfileData,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isSaving ? null : _pickProfileImage,
                    child: Stack(
                      children: [
                        _buildAvatar(initial),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: kPrimary,
                              shape: BoxShape.circle,
                              border: Border.all(color: kWhite, width: 3),
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: kWhite, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to change profile photo',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 32),
                  _buildInputLabel('FULL NAME'),
                  _buildTextField(controller: _nameController, icon: Icons.person_rounded),
                  _buildInputLabel('STUDENT ID'),
                  _buildTextField(controller: _idController, icon: Icons.badge_rounded),
                  _buildInputLabel('EMAIL ADDRESS'),
                  _buildTextField(
                    controller: _emailController,
                    icon: Icons.email_rounded,
                    isReadOnly: true,
                  ),
                  _buildInputLabel('PHONE NUMBER'),
                  _buildTextField(
                    controller: _phoneController,
                    icon: Icons.phone_rounded,
                    isPhone: true,
                  ),
                  _buildInputLabel('COLLEGE / LOCATION'),
                  Container(
                    decoration: BoxDecoration(
                      color: kWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.location_on_rounded, color: Colors.grey, size: 22),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      value: _selectedCollege,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                      items: _colleges
                          .map(
                            (val) => DropdownMenuItem(
                              value: val,
                              child: Text(
                                val,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _selectedCollege = val),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A2E),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    bool isReadOnly = false,
    bool isPhone = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isReadOnly ? Colors.grey.shade100 : kWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        readOnly: isReadOnly,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        style: TextStyle(
          fontSize: 15,
          color: isReadOnly ? Colors.grey.shade600 : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
