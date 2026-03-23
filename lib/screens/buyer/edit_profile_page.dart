import 'package:flutter/material.dart';

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
  // Controllers to hold current user data
  final TextEditingController _nameController = TextEditingController(text: 'Nur Ain Najwa Binti Rajis Kana');
  final TextEditingController _idController = TextEditingController(text: '2023423456');
  final TextEditingController _emailController = TextEditingController(text: 'najwa@student.uitm.edu.my');
  final TextEditingController _phoneController = TextEditingController(text: '012-345 6789');
  
  String? _selectedCollege = 'Kolej Dahlia';
  final List<String> _colleges = ['Kolej Dahlia', 'Kolej Meranti', 'Kolej Delima', 'Non-Resident (NR)'];

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
          // Save Button
          TextButton(
            onPressed: () {
              // TODO: Save updated data to Firebase
              Navigator.pop(context); // Go back after saving
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile updated successfully!'),
                  backgroundColor: kPrimary,
                ),
              );
            },
            child: const Text('Save', style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
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
                    child: const Center(
                      child: Text('N', style: TextStyle(color: kPrimary, fontSize: 40, fontWeight: FontWeight.w800)),
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
            _buildTextField(controller: _idController, icon: Icons.badge_rounded, isReadOnly: true), // Usually ID cannot be changed

            _buildInputLabel('EMAIL ADDRESS'),
            _buildTextField(controller: _emailController, icon: Icons.email_rounded),

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
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.location_on_rounded, color: Colors.grey, size: 22),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
        color: isReadOnly ? Colors.grey.shade100 : kWhite, // Greys out the field if read-only
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