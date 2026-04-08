import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Color Constants ---
const kPrimary      = Color(0xFF4C6B3F); 
const kAccent       = Color(0xFFF27B35); 
const kBg           = Color(0xFFF5F7F2); 
const kWhite        = Colors.white;

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // Controllers dibiarkan kosong dulu, nanti Firebase isikan
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  String? _selectedCollege;
  final List<String> _colleges = ['Kolej Dahlia 1', 
    'Kolej Dahlia 2' , 
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
    'Non-Resident (NR)'];

  bool _isLoading = true; // Untuk tunjuk loading masa mula-mula buka page
  bool _isSaving = false; // Untuk elak user tekan butang Save banyak kali

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserData();
  }

  // --- MAGIK 1: TARIK DATA DARI FIREBASE ---
  Future<void> _fetchCurrentUserData() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        _emailController.text = currentUser.email ?? ''; // E-mel sentiasa dari Auth

        // Tarik data dari laci 'users'
        var userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
        
        if (userDoc.exists) {
          var data = userDoc.data()!;
          _nameController.text = data['fullName'] ?? '';
          _idController.text = data['studentId'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          
          if (data['college'] != null && _colleges.contains(data['college'])) {
            _selectedCollege = data['college'];
          }
        }
      }
    } catch (e) {
      print("Error tarik data: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- MAGIK 2: SIMPAN DATA KE FIREBASE ---
  Future<void> _saveProfileData() async {
    setState(() {
      _isSaving = true;
    });

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Kita pakai SetOptions(merge: true) supaya dia update apa yang patut je
        // Dia takkan padam benda lain dalam laci tu
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set({
          'fullName': _nameController.text.trim(),
          'studentId': _idController.text.trim(),
          'phone': _phoneController.text.trim(),
          'college': _selectedCollege,
        }, SetOptions(merge: true));

        if (mounted) {
          Navigator.pop(context); // Tutup page ni lepas berjaya
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully! 🎉'),
              backgroundColor: kPrimary,
            ),
          );
        }
      }
    } catch (e) {
      print("Error simpan data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
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
    // Ambil huruf pertama nama untuk letak kat profile picture bulat tu
    String initial = _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'U';

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
          // Butang Save
          _isLoading
              ? const SizedBox.shrink() // Kalau tengah loading, sorok butang save
              : TextButton(
                  onPressed: _isSaving ? null : _saveProfileData, // Disable kalau tengah save
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2))
                      : const Text('Save', style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
          const SizedBox(width: 8),
        ],
      ),
      
      // Kalau tengah loading (tarik data), kita tunjuk spinner pusing-pusing
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: kPrimary))
        : SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // --- Profile Picture Edit Section ---
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: kPrimary.withOpacity(0.3), width: 2),
                      ),
                      child: Center(
                        child: Text(initial, style: const TextStyle(color: kPrimary, fontSize: 40, fontWeight: FontWeight.w800)),
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
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
              const SizedBox(height: 40),

              // --- Form Fields ---
              _buildInputLabel('FULL NAME'),
              _buildTextField(controller: _nameController, icon: Icons.person_rounded),

              _buildInputLabel('STUDENT ID'),
              _buildTextField(controller: _idController, icon: Icons.badge_rounded), 

              _buildInputLabel('EMAIL ADDRESS'),
              // Emel di-lock (readOnly) supaya user tak rosakkan login Firebase Auth dorang
              _buildTextField(controller: _emailController, icon: Icons.email_rounded, isReadOnly: true),

              _buildInputLabel('PHONE NUMBER'),
              _buildTextField(controller: _phoneController, icon: Icons.phone_rounded, isPhone: true),

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
                  initialValue: _selectedCollege,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                  items: _colleges.map((String val) {
                    return DropdownMenuItem(
                      value: val, 
                      child: Text(val, style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500))
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCollege = val),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
    );
  }

  // Helper Widget for Labels
  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label, 
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E), letterSpacing: 0.5)
        ),
      ),
    );
  }

  // Helper Widget for TextFields
  Widget _buildTextField({required TextEditingController controller, required IconData icon, bool isReadOnly = false, bool isPhone = false}) {
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
        style: TextStyle(fontSize: 15, color: isReadOnly ? Colors.grey.shade600 : Colors.black87, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}