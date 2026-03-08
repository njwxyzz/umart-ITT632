import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Off-white background
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER OREN (Dari design baru)
            Container(
              padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF7A00), Color(0xFFFFB057)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Current Location', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text('UiTM Perlis, Kolej Dahlia', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        ],
                      ),
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, color: Colors.orange.shade800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  // SEARCH BAR
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'Search for food, parcel...',
                        border: InputBorder.none,
                        icon: Icon(Icons.search, color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // 2. GRID CATEGORIES (Layout dari design lama, tapi kita letak warna pastel!)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Baris Atas (Food besar kiri, Parcel & Printing kanan)
                  Row(
                    children: [
                      // KOTAK FOOD (Besar)
                      Expanded(
                        flex: 1,
                        child: _buildGridCard(
                          title: 'Food',
                          subtitle: 'Order meals nearby',
                          icon: Icons.fastfood_rounded,
                          iconColor: Colors.orange.shade700,
                          bgColor: Colors.orange.shade50,
                          height: 160,
                        ),
                      ),
                      const SizedBox(width: 15),
                      // KOTAK PARCEL & PRINTING (Kecil bertingkat)
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            _buildGridCard(
                              title: 'Parcel',
                              subtitle: 'Send & receive',
                              icon: Icons.local_shipping_rounded,
                              iconColor: Colors.blue.shade700,
                              bgColor: Colors.blue.shade50,
                              height: 72,
                              isSmall: true,
                            ),
                            const SizedBox(height: 16),
                            _buildGridCard(
                              title: 'Printing',
                              subtitle: 'Print & copy',
                              icon: Icons.print_rounded,
                              iconColor: Colors.purple.shade700,
                              bgColor: Colors.purple.shade50,
                              height: 72,
                              isSmall: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  // Baris Bawah (Preloved & More)
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildGridCard(
                          title: 'Preloved',
                          subtitle: 'Buy & sell items',
                          icon: Icons.shopping_bag_rounded,
                          iconColor: Colors.green.shade700,
                          bgColor: Colors.green.shade50,
                          height: 80,
                          isSmall: true,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        flex: 1,
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.more_horiz, color: Colors.grey),
                              SizedBox(height: 4),
                              Text('More', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 3. PROMO BANNER BIRU (Dari design baru)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF007BFF), Color(0xFF00D4FF)], 
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                            child: const Text('EARN EXTRA INCOME', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ),
                          const SizedBox(height: 12),
                          const Text('Turn Your Dorm\nInto a Store!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, height: 1.3)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blue.shade800,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: const Text('Start Earning', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.storefront_rounded, size: 80, color: Colors.white54),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // HELPER FUNCTION: Untuk lukis kotak-kotak Grid tu dengan kemas
  Widget _buildGridCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required double height,
    bool isSmall = false,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor, // Warna pastel supaya tak boring
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: iconColor.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: isSmall 
      // Layout untuk kotak kecil (Icon sebelah text)
      ? Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        )
      // Layout untuk kotak besar (Food) - Icon atas, text bawah
      : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 36),
            ),
            const Spacer(),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
    );
  }
}