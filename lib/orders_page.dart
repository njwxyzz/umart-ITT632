import 'package:flutter/material.dart';
import 'tracking_page.dart'; // Wajib import ni untuk butang Track Order!

// ─── Color Constants (TEMA HIJAU BARU) ───────────────────────────────────────
const kPrimary      = Color(0xFF4C6B3F); // Olive Green
const kAccent       = Color(0xFFF27B35); // Oren Lembut
const kBg           = Color(0xFFF5F7F2); // Off-white hijau
const kWhite        = Colors.white;

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

// Kita guna SingleTickerProviderStateMixin untuk buat animasi Tab
class _OrdersPageState extends State<OrdersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        automaticallyImplyLeading: false, // Buang butang back kalau ni main tab
        title: const Text('My Orders', style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.w800, fontSize: 24, letterSpacing: -0.5)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Color(0xFF1A1A2E)),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      // MAGIK BACKGROUND PATTERN .JPG
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg_pattern.jpg'),
            repeat: ImageRepeat.repeat,
            opacity: 0.05,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // ─── CUSTOM TAB BAR (ACTIVE / COMPLETED) ───
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 46,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: kPrimary, // Warna Hijau bila selected
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                labelColor: kWhite,
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'Completed'),
                ],
              ),
            ),
            
            const SizedBox(height: 16),

            // ─── TAB BAR VIEW (KANDUNGAN TAB) ───
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // TAB 1: ACTIVE ORDERS
                  _buildActiveOrdersTab(),

                  // TAB 2: COMPLETED ORDERS
                  _buildCompletedOrdersTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── WIDGET: TAB ACTIVE ORDERS ───
  Widget _buildActiveOrdersTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Kad Order Aktif
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              // Bahagian Atas: Info Kedai & Order
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gambar Makanan/Kedai
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: const DecorationImage(
                        image: NetworkImage('https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=200'), // Gambar Burger
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Info Teks
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(child: Text('Burgers & Wings Co.', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1A1A2E)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            Text('#UM-8291', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey.shade400)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Crispy Chicken Burger, Curly Fries...', style: TextStyle(color: Colors.grey.shade500, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        // Status Badge Oren
                        Row(
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: kAccent, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            const Text('Preparing your food...', style: TextStyle(color: kAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1),
              ),
              
              // Bahagian Bawah: Profil Runner & Butang Track
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Runner Profil Mini (Boleh jadi kosong kalau kedai tengah siapkan)
                  Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 32, height: 32,
                            decoration: const BoxDecoration(shape: BoxShape.circle, image: DecorationImage(image: NetworkImage('https://images.unsplash.com/photo-1599566150163-29194dcaad36?w=100'), fit: BoxFit.cover)),
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(width: 10, height: 10, decoration: BoxDecoration(color: kPrimary, shape: BoxShape.circle, border: Border.all(color: kWhite, width: 2))),
                          )
                        ],
                      ),
                      const SizedBox(width: 8),
                      Text('Ahmad', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade700)),
                    ],
                  ),
                  
                  // Butang Track Order
                  OutlinedButton(
                    onPressed: () {
                      // BUKA LIVE TRACKING PAGE BILA TEKAN!
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackingPage()));
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: kPrimary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Track Order', style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── WIDGET: TAB COMPLETED ORDERS ───
  Widget _buildCompletedOrdersTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_rounded, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("You can also view completed orders\nin your Activity Page.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        ],
      ),
    );
  }
}