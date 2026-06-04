import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Wajib import untuk Login
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart'; // Make sure this path to HomeScreen is correct
import 'register_page.dart';
import '../admin_web/admin_dashboard_page.dart';
import '../../utils/campus_scope.dart';

const kPrimary      = Color(0xFF4C6B3F); 
const kPrimaryLight = Color(0xFF799B61); 
const kAccent       = Color(0xFFF27B35); 
const kBg           = Color(0xFFF5F7F2); 
const kWhite        = Colors.white;

const _kRememberMeKey = 'login_remember_me';
const _kSavedLoginKey = 'login_saved_identifier';
final _uitmEmailRegex = RegExp(r'^[a-z0-9._%+-]+@student\.uitm\.edu\.my$');

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // --- Controllers for Input Fields ---
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false; // For checkbox
  bool _isLoading = false; // For button loading state
  /// Shown after user tries to log in but email is not verified yet.
  bool _showResendVerification = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  /// Matric-only input is expanded to the UiTM student email used at registration.
  String _resolveLoginEmail(String input) {
    final trimmed = input.trim().toLowerCase();
    if (trimmed.contains('@')) return trimmed;
    return '$trimmed@student.uitm.edu.my';
  }

  Future<void> _loadRememberedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool(_kRememberMeKey) ?? false;
      final saved = prefs.getString(_kSavedLoginKey);
      if (!mounted) return;
      setState(() {
        _rememberMe = remember;
        if (remember && saved != null && saved.isNotEmpty) {
          _emailController.text = saved;
        }
      });
    } catch (_) {}
  }

  Future<void> _saveRememberedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setBool(_kRememberMeKey, true);
        await prefs.setString(
          _kSavedLoginKey,
          _emailController.text.trim().toLowerCase(),
        );
      } else {
        await prefs.setBool(_kRememberMeKey, false);
        await prefs.remove(_kSavedLoginKey);
      }
    } catch (_) {}
  }

  Future<void> _onRememberMeChanged(bool? value) async {
    final checked = value ?? false;
    setState(() => _rememberMe = checked);
    if (!checked) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_kRememberMeKey, false);
        await prefs.remove(_kSavedLoginKey);
      } catch (_) {}
    }
  }

  Future<void> _forgotPassword() async {
    final rawInput = _emailController.text.trim();
    if (rawInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your student ID or email first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final email = _resolveLoginEmail(rawInput);
    final isAdmin = isUmartAdminEmail(email);
    if (!isAdmin && !_uitmEmailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Use your UiTM student email (matricno@student.uitm.edu.my).'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Password reset email sent. Check your Inbox or Spam/Junk folder.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Unable to send password reset email.';
      if (e.code == 'invalid-email') {
        errorMsg = 'Please enter a valid email format.';
      } else if (e.code == 'user-not-found') {
        errorMsg = 'No account found for this email.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _syncFirestoreEmailVerified(User user) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {'emailVerified': true},
        SetOptions(merge: true),
      );
    } catch (_) {
      // Keep this best-effort only. Auth emailVerified is the source of truth.
    }
  }

  Future<void> _resendVerificationEmail() async {
    final email = _resolveLoginEmail(_emailController.text);
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your email and password first to resend verification.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.reload();
      final user = FirebaseAuth.instance.currentUser;
      final isAdmin = isUmartAdminEmail(email);

      if (!isAdmin && user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification email sent. Please check Inbox or Spam/Junk.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your email is already verified. You can log in now.'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Unable to resend verification email.';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'wrong-password') {
        errorMsg = 'Incorrect email or password.';
      } else if (e.code == 'invalid-email') {
        errorMsg = 'Please enter a valid email format.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- Firebase Login Logic ---
  Future<void> _loginUser() async {
    final email = _resolveLoginEmail(_emailController.text);
    final password = _passwordController.text.trim();

    // 1. Check if fields are empty
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both email and password.")),
      );
      return;
    }

    // 2. Start loading
    setState(() => _isLoading = true);

    try {
      // 3. Request login from Firebase
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.reload();
      final user = FirebaseAuth.instance.currentUser;
      final isAdmin = isUmartAdminEmail(email);

      if (!isAdmin && user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          setState(() {
            _isLoading = false;
            _showResendVerification = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please verify your UiTM email first. New verification link sent.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (!isAdmin && user != null && user.emailVerified) {
        _syncFirestoreEmailVerified(user);
      }

      if (!isAdmin && user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final accountStatus = (userDoc.data()?['status'] ?? '').toString().toLowerCase();
        if (accountStatus == 'banned') {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Your account has been suspended. Contact support for help.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      await _saveRememberedCredentials();

      // Stop loading
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showResendVerification = false;
        });
      }

      // 4. If success, navigate to HomeScreen
      if (mounted) {
        if (isAdmin) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminDashboardPage())
          );
        }
        else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen())
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      // Stop loading if error occurs
      setState(() => _isLoading = false);
      
      String errorMsg = "An error occurred.";
      // Customize error messages based on Firebase codes
      if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'wrong-password') {
        errorMsg = 'Incorrect email or password.';
      } else if (e.code == 'invalid-email') {
        errorMsg = 'Please enter a valid email format.';
      }

      // Show error popup
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    // Clean up memory
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          // --- 1. TOP SOFT GLOW EFFECT ---
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

          // --- 2. MAIN CONTENT ---
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // Header Texts
                  const Text(
                    'Sign in to your\nAccount',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E), height: 1.2, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enter your student ID and password to log in',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  
                  const SizedBox(height: 40),

                  // Input 1: Email 
                  _buildCleanTextField(
                    hint: 'Student ID or Email',
                    isPassword: false,
                    controller: _emailController,
                  ),
                  
                  const SizedBox(height: 16),

                  // Input 2: Password
                  _buildCleanTextField(
                    hint: '••••••••',
                    isPassword: true,
                    controller: _passwordController,
                  ),

                  const SizedBox(height: 16),

                  // Remember Me & Forgot Password Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Remember Me Checkbox
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: _isLoading ? null : _onRememberMeChanged,
                              activeColor: kPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Remember me', style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      // Forgot Password Link
                      TextButton(
                        onPressed: _isLoading ? null : _forgotPassword,
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                        child: const Text('Forgot Password ?', style: TextStyle(color: kAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _loginUser, // Disable if loading
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: kWhite) 
                        : const Text('Log In', style: TextStyle(color: kWhite, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  if (_showResendVerification) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: _isLoading ? null : _resendVerificationEmail,
                        child: const Text(
                          'Resend verification email',
                          style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'If email is not received, check your Spam/Junk folder.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),

                  // Sign Up Link at the bottom
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
                        child: const Text('Sign Up', style: TextStyle(color: kAccent, fontWeight: FontWeight.bold, fontSize: 14)),
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

  // HELPER WIDGET: Input Field Without Side Icon
  Widget _buildCleanTextField({required String hint, required bool isPassword, required TextEditingController controller}) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2))
        ],
      ),
      child: TextField(
        controller: controller, // Essential to capture input
        obscureText: isPassword ? _obscurePassword : false,
        style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          // Add eye icon only if it's a password field
          suffixIcon: isPassword 
              ? IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey.shade400, size: 20),
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