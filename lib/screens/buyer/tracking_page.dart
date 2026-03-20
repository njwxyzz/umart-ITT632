import 'package:flutter/material.dart';
import 'chat_page.dart';

// ─── Color Constants (TEMA HIJAU BARU) ───────────────────────────────────────
const kPrimary      = Color(0xFF4C6B3F); // Olive Green
const kPrimaryLight = Color(0xFF799B61); // Lighter Olive
const kAccent       = Color(0xFFF27B35); // Oren Lembut
const kBg           = Color(0xFFF5F7F2); // Off-white hijau
const kWhite        = Colors.white;

class TrackingPage extends StatelessWidget {
  const TrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: kWhite, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1A2E), size: 16),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text('Track Order', style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: kWhite, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
              child: const Icon(Icons.my_location_rounded, color: Color(0xFF1A1A2E), size: 18),
            ),
          )
        ],
      ),
      // MAGIK BACKGROUND PATTERN .JPG KAT SINI!
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg_pattern.jpg'), // Corak doodle
            repeat: ImageRepeat.repeat,
            opacity: 0.05,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── 1. MAP & FLOATING ETA CARD ───
              SizedBox(
                height: 320,
                child: Stack(
                  children: [
                    // Gambar Peta Placeholder
                    Container(
                      height: 280,
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        image: const DecorationImage(
                          image: NetworkImage('https://images.unsplash.com/photo-1524661135-423995f22d0b?w=800'), // Map aesthetic
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
                      ),
                    ),
                    // Floating ETA Card
                    Positioned(
                      bottom: 0,
                      left: 36,
                      right: 36,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: kWhite,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Estimated Arrival', style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    const Text('10 Mins', style: TextStyle(color: kPrimary, fontSize: 24, fontWeight: FontWeight.w900)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Distance', style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    const Text('1.2 km', style: TextStyle(color: Color(0xFF1A1A2E), fontSize: 18, fontWeight: FontWeight.w800)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Progress Bar Hijau
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: 0.7, // 70% siap
                                minHeight: 8,
                                backgroundColor: kPrimary.withOpacity(0.1),
                                valueColor: const AlwaysStoppedAnimation<Color>(kPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ─── 2. ORDER STATUS TIMELINE ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Order Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
                    const SizedBox(height: 24),
                    
                    // Step 1: Placed
                    _buildTimelineStep(
                      title: 'Order Placed',
                      subtitle: 'We have received your order',
                      time: '12:30 PM',
                      isCompleted: true,
                      isActive: false,
                      isLast: false,
                    ),
                    // Step 2: Preparing
                    _buildTimelineStep(
                      title: 'Preparing',
                      subtitle: 'Your food is being packed',
                      time: '12:35 PM',
                      isCompleted: true,
                      isActive: false,
                      isLast: false,
                    ),
                    // Step 3: On The Way (Active!)
                    _buildTimelineStep(
                      title: 'On the Way',
                      subtitle: 'Runner is heading to you',
                      time: '12:45 PM',
                      isCompleted: false,
                      isActive: true, // Warnakan oren!
                      isLast: false,
                    ),
                    // Step 4: Delivered
                    _buildTimelineStep(
                      title: 'Delivered',
                      subtitle: 'Enjoy your meal!',
                      time: '--:--',
                      isCompleted: false,
                      isActive: false,
                      isLast: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ─── 3. RUNNER INFO CARD ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('YOUR RUNNER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey[500], letterSpacing: 1.2)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kWhite,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        children: [
                          // Gambar Runner
                          Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: const DecorationImage(image: NetworkImage('https://images.unsplash.com/photo-1599566150163-29194dcaad36?w=200'), fit: BoxFit.cover),
                              border: Border.all(color: kPrimary.withOpacity(0.2), width: 2),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Nama & Plate
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Ahmad Faizal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                                      child: const Text('VBB 1234', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black87)),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.star_rounded, color: kAccent, size: 14),
                                    const SizedBox(width: 2),
                                    Text('4.9', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600])),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Butang Chat & Call
                          Row(
                            children: [
                              // Chat Button (Oren)
                              Container(
                                decoration: BoxDecoration(color: kAccent.withOpacity(0.1), shape: BoxShape.circle),
                                child: IconButton(
                                  icon: const Icon(Icons.chat_bubble_rounded, color: kAccent, size: 20),
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatPage()));
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Call Button (Hijau)
                              Container(
                                decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), shape: BoxShape.circle),
                                child: IconButton(
                                  icon: const Icon(Icons.phone_rounded, color: kPrimary, size: 20),
                                  onPressed: () {},
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── WIDGET BANTUAN UNTUK TIMELINE ───
  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required String time,
    required bool isCompleted,
    required bool isActive,
    required bool isLast,
  }) {
    // Tentukan warna berdasarkan status
    Color dotColor = isActive ? kAccent : (isCompleted ? kPrimary : Colors.grey.shade300);
    Color titleColor = isActive ? kAccent : (isCompleted ? const Color(0xFF1A1A2E) : Colors.grey.shade400);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bahagian Ikon & Garisan (Kiri)
        Column(
          children: [
            // Titik (Dot)
            Container(
              width: 16, height: 16,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: isActive ? Border.all(color: kAccent.withOpacity(0.3), width: 4) : null, // Halo effect untuk active
              ),
            ),
            // Garisan (Line)
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? kPrimary : Colors.grey.shade200,
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Bahagian Teks (Kanan)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20.0), // Jarak antara step
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: titleColor)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: isActive ? Colors.grey[600] : Colors.grey[400])),
                  ],
                ),
                Text(time, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isActive ? kAccent : Colors.grey[400])),
              ],
            ),
          ),
        ),
      ],
    );
  }
}