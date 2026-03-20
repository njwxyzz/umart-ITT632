import 'package:flutter/material.dart';
import 'login_page.dart';

const kPrimary      = Color(0xFF4C6B3F); 
const kAccent       = Color(0xFFF27B35); 
const kBg           = Color(0xFFF5F7F2); 
const kWhite        = Colors.white;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Data onboarding tanpa icon
  final List<Map<String, dynamic>> _onboardingData = [
    {
      "title": "Welcome to UMART!",
      "desc": "Your ultimate campus marketplace. Buy, sell, and order food easily.",
      "image": "assets/bg_onboard.jpg",
    },
    {
      "title": "Fast Campus Delivery",
      "desc": "Get your food and parcels delivered straight to your hostel or faculty.",
      "image": "assets/bg_onboard2.jpg",
    },
    {
      "title": "Student Community",
      "desc": "Support student runners and preloved sellers within UiTM.",
      "image": "assets/bg_onboard3.jpg",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, 
      body: Stack(
        children: [
          // ─── 1. KAWASAN SLIDE (GAMBAR + TEKS ANIMASI) ───
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _onboardingData.length,
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Gambar Background HD
                  Image.asset(
                    _onboardingData[index]["image"],
                    fit: BoxFit.cover,
                  ),
                  // Gradient Overlay (Kabus Hitam makin pekat kat bawah)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent, 
                          Colors.black.withOpacity(0.4), 
                          Colors.black.withOpacity(0.9) // Bawah gelap sikit nak kasi teks pop!
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Kandungan Teks (Ditolak sikit ke bawah)
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 140.0), // Jarak dari butang bawah
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end, // Letak teks kat bawah
                        children: [
                          // ─── MAGIK ANIMASI SLIDE UP & FADE IN ───
                          TweenAnimationBuilder(
                            // ValueKey ni penting gila supaya animasi reset bila tukar page!
                            key: ValueKey(index), 
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, 30 * (1 - value)), // Tolak dari bawah 30px
                                child: Opacity(
                                  opacity: value, // Pudar ke Jelas
                                  child: child,
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                // Tajuk (Besar & Ada Shadow)
                                Text(
                                  _onboardingData[index]["title"],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 34, // Lebih besar
                                    fontWeight: FontWeight.w900, 
                                    color: kWhite, 
                                    letterSpacing: 0.5,
                                    shadows: [
                                      Shadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, 5))
                                    ]
                                  ), 
                                ),
                                const SizedBox(height: 16),
                                // Deskripsi
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 40),
                                  child: Text(
                                    _onboardingData[index]["desc"],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16, // Lebih besar sikit
                                      color: kWhite.withOpacity(0.95), 
                                      height: 1.5,
                                      fontWeight: FontWeight.w500,
                                      shadows: const [
                                        Shadow(color: Colors.black87, blurRadius: 10, offset: Offset(0, 3))
                                      ]
                                    ), 
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              );
            },
          ),

          // ─── 2. KAWASAN STATIC OVERLAY (BUTANG SKIP, DOTS, NEXT) ───
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Butang Skip
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0, top: 8.0),
                    child: TextButton(
                      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                      child: Text('Skip', style: TextStyle(color: kWhite.withOpacity(0.8), fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ),
                
                // Bahagian Bawah (Dots & Butang)
                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _onboardingData.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            height: 8,
                            width: _currentPage == index ? 24 : 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index ? kAccent : kWhite.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Butang Next / Get Started
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentPage == _onboardingData.length - 1) {
                              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                            } else {
                              _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 5, // Tambah shadow sikit kat butang
                            shadowColor: Colors.black45,
                          ),
                          child: Text(
                            _currentPage == _onboardingData.length - 1 ? 'Get Started' : 'Next',
                            style: const TextStyle(color: kWhite, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}