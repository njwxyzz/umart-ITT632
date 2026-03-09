import 'package:flutter/material.dart';

// --- Color Constants ---
const kPrimary      = Color(0xFF4C6B3F); 
const kAccent       = Color(0xFFF27B35); 
const kBg           = Color(0xFFF5F7F2); 
const kWhite        = Colors.white;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _obscurePassword = true;
  String? _selectedCollege;
  
  // Dummy data for college selection
  final List<String> _colleges = [
    'Kolej Dahlia', 
    'Kolej Meranti', 
    'Kolej Delima', 
    'Non-Resident (NR)'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          // 1. TOP GLOW EFFECT (Subtle primary color glow)
          Positioned(
            top: -100,
            left: 0,
            right: 0,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kPrimary.withOpacity(0.15), 
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          // 2. MAIN CONTENT
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.only(bottom: 30.0, top: 10.0),
                      child: Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A2E), size: 28),
                    ),
                  ),

                  // Header Texts
                  const Text(
                    'Register',
                    style: TextStyle(
                      fontSize: 34, 
                      fontWeight: FontWeight.w900, 
                      color: Color(0xFF1A1A2E), 
                      letterSpacing: -0.5
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create an account to continue!',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  
                  const SizedBox(height: 32),

                  // Input 1: Full Name
                  _buildCleanTextField(hint: 'Full Name'),
                  const SizedBox(height: 16),

                  // Input 2: Student ID
                  _buildCleanTextField(hint: 'Student ID'),
                  const SizedBox(height: 16),

                  // Input 3: Email Address
                  _buildCleanTextField(hint: 'Email Address'),
                  const SizedBox(height: 16),

                  // Input 4: College Selection (Dropdown style)
                  Container(
                    decoration: BoxDecoration(
                      color: kWhite,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        hintText: 'Select College',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      ),
                      value: _selectedCollege,
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
                  const SizedBox(height: 16),

                  // Input 5: Phone Number with Country Code Prefix
                  Container(
                    decoration: BoxDecoration(
                      color: kWhite,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // Country Code Prefix
                        Padding(
                          padding: const EdgeInsets.only(left: 20.0, right: 10.0),
                          child: Row(
                            children: [
                              Text('🇲🇾', style: TextStyle(fontSize: 18)), // Malaysia flag emoji
                              SizedBox(width: 8),
                              Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey, size: 20),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 24, color: Colors.grey.shade300),
                        // Phone Number Input
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              hintText: '+60 12-345 6789',
                              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Input 6: Password
                  _buildCleanTextField(
                    hint: '••••••••',
                    isPassword: true,
                  ),

                  const SizedBox(height: 40),

                  // Register Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Implement Firebase Registration Logic here
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Register', 
                        style: TextStyle(color: kWhite, fontSize: 16, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Footer: Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ", 
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14)
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context), // Goes back to Login Page
                        child: const Text(
                          'Log in', 
                          style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold, fontSize: 14)
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // HELPER WIDGET: Clean Text Field matching the reference image
  Widget _buildCleanTextField({required String hint, bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        obscureText: isPassword ? _obscurePassword : false,
        style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          // Add eye icon only if it's a password field
          suffixIcon: isPassword 
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, 
                    color: Colors.grey.shade400, 
                    size: 20
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ) 
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}