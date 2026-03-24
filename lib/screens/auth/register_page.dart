import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // add this for Firebase Auth

// --- Color Constants ---
const kPrimary      = Color(0xFF4C6B3F); 
const kAccent       = Color(0xFFF27B35); 
const kBg           = Color(0xFFF5F7F2); 
const kWhite        = Colors.white;

class RegisterPage extends StatefulWidget { // stateful because we need to manage form state and loading state
  const RegisterPage({super.key});  // constructor

  @override
  State<RegisterPage> createState() => _RegisterPageState(); // create state for this page
}

class _RegisterPageState extends State<RegisterPage> {
  // --- controller for each input field (important to dispose) ---
  final TextEditingController _nameController = TextEditingController(); // for full name input
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;  // to toggle password visibility
  bool _isLoading = false; // to show loading spinner when processing registration
  String? _selectedCollege; // to store selected college from dropdown
  
  // Dummy data for college selection
  final List<String> _colleges = [
    'Kolej Dahlia 1', 
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
    'Non-Resident (NR)'
  ];

  // --- Function to handle user registration ---
  Future<void> _registerUser() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // 1. check if email & password are not empty
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in your email and password.")),
      );
      return;
    }

    // 2. The UiTM Filter (only @student.uitm.edu.my)
    if (!email.endsWith('@student.uitm.edu.my')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sorry, only a verified uitm emails are allowed!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 3. Proses Register
    setState(() {
      _isLoading = true; // start loading
    });

    try {
      // call Firebase Auth to create user with email & password
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // if success, you can also save additional user info (like name, student ID, etc) to Firestore here if needed
      setState(() => _isLoading = false);
      
      if (mounted) { //make sure widget still exist before showing snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Successfully registered! Please login."),
            backgroundColor: Colors.green,
          ),
        );
        // go back to login page after successful registration
        Navigator.pop(context);
      }

    } on FirebaseAuthException catch (e) {
      // if error occurs, stop loading and show error message
      setState(() => _isLoading = false);
      
      String errorMsg = "An error occurred.";
      if (e.code == 'weak-password') {
        errorMsg = 'Password is too weak (minimum 6 characters).';
      } else if (e.code == 'email-already-in-use') {
        errorMsg = 'This email is already in use.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    // dispose all controllers to free up resources
    _nameController.dispose();
    _studentIdController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          // 1. TOP GLOW EFFECT
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
                  _buildCleanTextField(hint: 'Full Name', controller: _nameController),
                  const SizedBox(height: 16),

                  // Input 2: Student ID
                  _buildCleanTextField(hint: 'Student ID', controller: _studentIdController),
                  const SizedBox(height: 16),

                  // Input 3: Email Address
                  _buildCleanTextField(hint: 'Email Address', controller: _emailController, isEmail: true),
                  const SizedBox(height: 16),

                  // Input 4: College Selection
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
                  const SizedBox(height: 16),

                  // Input 5: Phone Number
                  Container(
                    decoration: BoxDecoration(
                      color: kWhite,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 20.0, right: 10.0),
                          child: Row(
                            children: [
                              Text('🇲🇾', style: TextStyle(fontSize: 18)),
                              SizedBox(width: 8),
                              Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey, size: 20),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 24, color: Colors.grey.shade300),
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
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
                    controller: _passwordController,
                  ),

                  const SizedBox(height: 40),

                  // Register Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _registerUser, // Kalau tgh loading, disable butang
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: kWhite) // Tunjuk pusing-pusing kalau loading
                        : const Text(
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
                        onTap: () => Navigator.pop(context),
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

  // HELPER WIDGET (to avoid repeating code for each TextField)
  Widget _buildCleanTextField({
    required String hint, 
    bool isPassword = false, 
    bool isEmail = false,
    TextEditingController? controller
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller, // assign the controller passed from parameters
        obscureText: isPassword ? _obscurePassword : false,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
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