import 'package:flutter/material.dart';
import '../../main.dart';
import 'register_page.dart'; 

const kPrimary      = Color(0xFF4C6B3F); 
const kPrimaryLight = Color(0xFF799B61); 
const kAccent       = Color(0xFFF27B35); 
const kBg           = Color(0xFFF5F7F2); 
const kWhite        = Colors.white;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  bool _rememberMe = false; // Untuk checkbox

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          // ─── 1. GLOW LEMBUT KAT ATAS (Ala-ala reference kau) ───
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
                    color: kPrimary.withOpacity(0.15), // Glow warna hijau lembut
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          // ─── 2. KANDUNGAN UTAMA ───
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
              
                  
                  const SizedBox(height: 40),

                  // Tajuk (Rapat Kiri)
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

                  // Kotak Input 1: Email / Student ID
                  _buildCleanTextField(
                    hint: 'Student ID or Email',
                    isPassword: false,
                  ),
                  
                  const SizedBox(height: 16),

                  // Kotak Input 2: Password
                  _buildCleanTextField(
                    hint: '••••••••',
                    isPassword: true,
                  ),

                  const SizedBox(height: 16),

                  // Barisan Remember Me & Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Checkbox Remember Me
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (value) => setState(() => _rememberMe = value!),
                              activeColor: kPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Remember me', style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      // Forgot Password
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                        child: const Text('Forgot Password ?', style: TextStyle(color: kAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Butang Log In (Solid Warna Hijau)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen())),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Kurang sikit bulat dia ikut gambar
                        elevation: 0,
                      ),
                      child: const Text('Log In', style: TextStyle(color: kWhite, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Divider "Or"
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('Or', style: TextStyle(color: Colors.grey.shade500, fontSize: 12))),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Butang Continue with Google
                  _buildSocialButton(
                    text: 'Continue with Google',
                    icon: Icons.g_mobiledata_rounded,
                    iconColor: Colors.red,
                    onTap: () {},
                  ),

                  const SizedBox(height: 16),

                  // Butang Continue with Facebook
                  _buildSocialButton(
                    text: 'Continue with Facebook',
                    icon: Icons.facebook_rounded,
                    iconColor: Colors.blue,
                    onTap: () {},
                  ),

                  const SizedBox(height: 40),

                  // Sign Up Link kat bawah sekali
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

  // WIDGET BANTUAN: Kotak Input Tanpa Ikon Tepi
  Widget _buildCleanTextField({required String hint, required bool isPassword}) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2))
        ],
      ),
      child: TextField(
        obscureText: isPassword ? _obscurePassword : false,
        style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          // Kalau password, letak ikon mata. Kalau tak, kosong je.
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

  // WIDGET BANTUAN: Butang Sosial Full Width
  Widget _buildSocialButton({required String text, required IconData icon, required Color iconColor, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: kWhite,
          side: const BorderSide(color: Colors.transparent), // Takde border keras
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 1, // Kasi bayang-bayang nipis macam dalam gambar
          shadowColor: Colors.black12,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 12),
            Text(text, style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}