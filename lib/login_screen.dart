// ============================================================
//  UMART — Login Screen (matched to Home Screen aesthetic)
//  File: login_screen.dart
//
//  Aesthetic: Clean, light, card-based — mirrors the home
//  screen's off-white background, blue + orange palette,
//  white cards with soft shadows, pill buttons, and
//  rounded border radii.
//
//  No third-party packages required.
// ============================================================

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
//  STANDALONE ENTRY (remove if integrating into existing app)
// ─────────────────────────────────────────────────────────────
void main() => runApp(const _PreviewApp());

class _PreviewApp extends StatelessWidget {
  const _PreviewApp();
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        home: const LoginScreen(),
      );
}

// ─────────────────────────────────────────────────────────────
//  DESIGN TOKENS  (mirrors home screen tokens)
// ─────────────────────────────────────────────────────────────
abstract class _T {
  // Core palette — same as home screen
  static const bg        = Color(0xFFF2F3F5); // off-white background
  static const blue      = Color(0xFF0052FF); // electric blue (primary)
  static const blueDim   = Color(0xFF003FCC); // deeper blue (gradient end)
  static const blueGlow  = Color(0x330052FF); // blue shadow
  static const orange    = Color(0xFFFF6B00); // neon orange (accent)
  static const white     = Colors.white;

  // Surfaces
  static const card      = Colors.white;
  static const fieldBg   = Color(0xFFF7F8FA);

  // Text
  static const textHigh  = Color(0xFF1A1A2E); // near-black
  static const textMid   = Color(0xFF64748B); // slate-500
  static const textLow   = Color(0xFFB0BBCB); // slate-300

  // Borders
  static const border    = Color(0xFFE8ECF2);
  static const borderFocus = Color(0xFF0052FF);

  // Spacing
  static const double pagePad = 24.0;
  static const double cardRad = 20.0;
  static const double fieldRad = 14.0;
  static const double btnRad  = 30.0;
}

// ─────────────────────────────────────────────────────────────
//  LOGIN SCREEN
// ─────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure    = true;
  bool _isLoading  = false;

  // Entry animation
  late final AnimationController _entry;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _fadeAnim  = CurvedAnimation(parent: _entry, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _entry.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) setState(() => _isLoading = false);
  }

  // ── BUILD ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _T.bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                _T.pagePad, top + 24, _T.pagePad, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Brand lockup ────────────────────────────
                _buildBrandLockup(),

                const SizedBox(height: 40),

                // ── Decorative hero badge ────────────────────
                _buildHeroBadge(),

                const SizedBox(height: 32),

                // ── Greeting ─────────────────────────────────
                _buildGreeting(),

                const SizedBox(height: 28),

                // ── Form card ────────────────────────────────
                _buildFormCard(),

                const SizedBox(height: 24),

                // ── Divider ──────────────────────────────────
                _buildDivider(),

                const SizedBox(height: 18),

                // ── Google SSO ───────────────────────────────
                _buildGoogleButton(),

                const SizedBox(height: 32),

                // ── Register link ────────────────────────────
                _buildRegisterRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Brand Lockup ─────────────────────────────────────────
  Widget _buildBrandLockup() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_T.blue, _T.blueDim],
            ),
            boxShadow: const [
              BoxShadow(
                  color: _T.blueGlow, blurRadius: 16, spreadRadius: 1),
            ],
          ),
          child: const Center(
            child: Text(
              'U',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'UMART',
          style: TextStyle(
            color: _T.textHigh,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 5,
          ),
        ),
      ],
    );
  }

  // ── Hero Badge ───────────────────────────────────────────
  Widget _buildHeroBadge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(_T.cardRad),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon cluster
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEFF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.storefront_rounded,
                    color: _T.blue, size: 32),
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: _T.orange,
                    shape: BoxShape.circle,
                    border: Border.all(color: _T.white, width: 2),
                  ),
                  child: const Icon(Icons.bolt,
                      color: Colors.white, size: 13),
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your campus, at your fingertips',
                  style: TextStyle(
                    color: _T.textHigh,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Food · Parcels · Preloved · More',
                  style: TextStyle(
                    color: _T.textMid,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                // Mini pills
                Row(
                  children: [
                    _MiniPill(
                        label: 'Free Delivery',
                        color: _T.orange),
                    const SizedBox(width: 6),
                    _MiniPill(
                        label: 'UiTM Only',
                        color: _T.blue),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Greeting ─────────────────────────────────────────────
  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome back 👋',
          style: TextStyle(
            color: _T.textHigh,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              color: _T.textMid,
              fontSize: 14,
            ),
            children: [
              TextSpan(text: 'Sign in to your '),
              TextSpan(
                text: 'UiTM student',
                style: TextStyle(
                  color: _T.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(text: ' marketplace'),
            ],
          ),
        ),
      ],
    );
  }

  // ── Form Card ────────────────────────────────────────────
  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(_T.cardRad),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email
          _SoftField(
            controller: _emailCtrl,
            label: 'Email address',
            hint: 'student@student.uitm.edu.my',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 16),

          // Password
          _SoftField(
            controller: _passwordCtrl,
            label: 'Password',
            hint: 'Enter your password',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscure,
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscure = !_obscure),
              child: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: _T.textLow,
                size: 18,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {},
              child: const Text(
                'Forgot password?',
                style: TextStyle(
                  color: _T.blue,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Sign-in button — orange pill matching home CTA style
          _PillButton(
            label: 'Sign in',
            isLoading: _isLoading,
            onPressed: _handleLogin,
            color: _T.orange,
          ),
        ],
      ),
    );
  }

  // ── Divider ───────────────────────────────────────────────
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: _T.border),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or continue with',
            style: TextStyle(color: _T.textLow, fontSize: 12),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: _T.border),
        ),
      ],
    );
  }

  // ── Google Button ─────────────────────────────────────────
  Widget _buildGoogleButton() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: _T.white,
          borderRadius: BorderRadius.circular(_T.fieldRad),
          border: Border.all(color: _T.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomPaint(
              size: const Size(18, 18),
              painter: _GoogleIconPainter(),
            ),
            const SizedBox(width: 10),
            const Text(
              'Continue with Google',
              style: TextStyle(
                color: _T.textHigh,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Register Row ──────────────────────────────────────────
  Widget _buildRegisterRow() {
    return Center(
      child: RichText(
        text: TextSpan(
          text: "New to UMART?  ",
          style: const TextStyle(color: _T.textMid, fontSize: 14),
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EEFF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Create account →',
                    style: TextStyle(
                      color: _T.blue,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SOFT INPUT FIELD
// ─────────────────────────────────────────────────────────────
class _SoftField extends StatefulWidget {
  const _SoftField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;

  @override
  State<_SoftField> createState() => _SoftFieldState();
}

class _SoftFieldState extends State<_SoftField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: _T.textMid,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 7),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_T.fieldRad),
            border: Border.all(
              color: _focused ? _T.borderFocus : _T.border,
              width: _focused ? 1.5 : 1.0,
            ),
            color: _focused
                ? const Color(0xFFF0F4FF)
                : _T.fieldBg,
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: _T.blue.withOpacity(0.08),
                      blurRadius: 12,
                    )
                  ]
                : [],
          ),
          child: Focus(
            onFocusChange: (v) => setState(() => _focused = v),
            child: TextField(
              controller: widget.controller,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              style: const TextStyle(
                color: _T.textHigh,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              cursorColor: _T.blue,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle:
                    const TextStyle(color: _T.textLow, fontSize: 14),
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(
                    widget.icon,
                    color: _focused ? _T.blue : _T.textLow,
                    size: 18,
                  ),
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 48, minHeight: 48),
                suffixIcon: widget.suffixIcon != null
                    ? Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: widget.suffixIcon,
                      )
                    : null,
                suffixIconConstraints:
                    const BoxConstraints(minWidth: 40, minHeight: 40),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PILL BUTTON  (matches "Order Now" style on home screen)
// ─────────────────────────────────────────────────────────────
class _PillButton extends StatefulWidget {
  const _PillButton({
    required this.label,
    required this.onPressed,
    required this.isLoading,
    required this.color,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color color;

  @override
  State<_PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<_PillButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pulse.reverse(),
      onTapUp: (_) {
        _pulse.forward();
        widget.onPressed();
      },
      onTapCancel: () => _pulse.forward(),
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) =>
            Transform.scale(scale: _pulse.value, child: child),
        child: Container(
          height: 52,
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(_T.btnRad),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  MINI PILL BADGE  (same style as food card badges)
// ─────────────────────────────────────────────────────────────
class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  GOOGLE ICON PAINTER  (no asset needed)
// ─────────────────────────────────────────────────────────────
class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2;

    const tau = 3.14159265 * 2;

    final segments = [
      (0.0,      tau * 0.25, const Color(0xFF4285F4)),
      (tau * 0.25, tau * 0.25, const Color(0xFF34A853)),
      (tau * 0.50, tau * 0.25, const Color(0xFFFBBC05)),
      (tau * 0.75, tau * 0.25, const Color(0xFFEA4335)),
    ];

    for (final seg in segments) {
      final paint = Paint()
        ..color = seg.$3
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r - 1.3),
        seg.$1 - tau / 4,
        seg.$2,
        false,
        paint,
      );
    }

    // White notch
    final notchPaint = Paint()
      ..color = _T.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawLine(Offset(cx, cy), Offset(size.width + 1, cy), notchPaint);

    // Blue horizontal bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(cx + 0.5, cy), Offset(size.width - 0.5, cy), barPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}