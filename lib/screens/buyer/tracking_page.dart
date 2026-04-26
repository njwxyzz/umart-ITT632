import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

// ─── Color Constants ──────────────────────────────────────────────────────────
const kPrimary = Color(0xFF4C6B3F);
const kAccent  = Color(0xFFF27B35);
const kBg      = Color(0xFFF5F7F2);
const kWhite   = Colors.white;
const kGreen   = Color(0xFF00C48C);

// ─── Seller fixed location (UiTM Arau, Perlis) ───────────────────────────────
const LatLng kSellerLocation = LatLng(6.4497, 100.2704);

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  final MapController _mapController = MapController();

  LatLng? _buyerLocation;
  bool _isLocating = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _fetchBuyerLocation();
  }

  Future<void> _fetchBuyerLocation() async {
    setState(() {
      _isLocating = true;
      _locationError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLocating = false;
          _locationError = 'Location services are disabled. Please enable GPS.';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          _isLocating = false;
          _locationError = 'Location permission denied. Please allow in Settings.';
        });
        return;
      }

      final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final buyerLatLng = LatLng(pos.latitude, pos.longitude);

      setState(() {
        _buyerLocation = buyerLatLng;
        _isLocating = false;
      });

      // Fit camera to show both pins after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitBothMarkers(buyerLatLng);
      });
    } catch (e) {
      setState(() {
        _isLocating = false;
        _locationError = 'Could not get location: $e';
      });
    }
  }

  void _fitBothMarkers(LatLng buyer) {
    // Build bounds manually — compatible with all flutter_map v6/v7
    final minLat = buyer.latitude < kSellerLocation.latitude
        ? buyer.latitude
        : kSellerLocation.latitude;
    final maxLat = buyer.latitude > kSellerLocation.latitude
        ? buyer.latitude
        : kSellerLocation.latitude;
    final minLng = buyer.longitude < kSellerLocation.longitude
        ? buyer.longitude
        : kSellerLocation.longitude;
    final maxLng = buyer.longitude > kSellerLocation.longitude
        ? buyer.longitude
        : kSellerLocation.longitude;

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(80),
      ),
    );
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
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Track Order',
          style: TextStyle(
              color: Color(0xFF1A1A2E),
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 1. MAP ───────────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(height: 260, child: _buildMap()),
            ),

            const SizedBox(height: 12),

            // Legend
            Row(
              children: [
                _legendDot(kAccent),
                const SizedBox(width: 6),
                const Text('Your Location',
                    style: TextStyle(fontSize: 12, color: Color(0xFF1A1A2E))),
                const SizedBox(width: 20),
                _legendDot(kPrimary),
                const SizedBox(width: 6),
                const Text('Seller / Pickup Point',
                    style: TextStyle(fontSize: 12, color: Color(0xFF1A1A2E))),
              ],
            ),

            const SizedBox(height: 24),

            // ─── 2. ORDER TIMELINE ────────────────────────────────────────
            const Text(
              'Order #UM-9824HGJF',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 24),

            _buildTimelineStep(
              title: 'Order Placed',
              date: '10 Sep 2023, 04:25 PM',
              isCompleted: true,
              isLast: false,
              iconData: Icons.receipt_long_rounded,
            ),
            _buildTimelineStep(
              title: 'In Progress',
              date: '10 Sep 2023, 04:34 PM',
              isCompleted: true,
              isLast: false,
              iconData: Icons.inventory_2_outlined,
            ),
            _buildTimelineStep(
              title: 'Shipped',
              date: 'Expected 10 Sep 2023, 04:50 PM',
              isCompleted: true,
              isLast: false,
              iconData: Icons.local_shipping_outlined,
            ),
            _buildTimelineStep(
              title: 'Delivered',
              date: '10 Sep 2023, 2023',
              isCompleted: false,
              isLast: true,
              iconData: Icons.check_box_outlined,
            ),

            const SizedBox(height: 32),

            // ─── 3. PRODUCTS ──────────────────────────────────────────────
            const Text(
              'Products',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 16),

            _buildProductCard(
              name: 'Cheese & Chocolate Cake',
              variant: 'Slice',
              price: 'RM 5.00',
              imageUrl:
                  'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=200',
            ),
            const SizedBox(height: 12),
            _buildProductCard(
              name: 'Iced Latte',
              variant: 'Large',
              price: 'RM 6.50',
              imageUrl:
                  'https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?w=200',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ─── MAP BUILDER ─────────────────────────────────────────────────────────
  Widget _buildMap() {
    // Shared tile layer
    final tileLayer = TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.example.app',
    );

    // Loading state
    if (_isLocating) {
      return Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: kSellerLocation,
              initialZoom: 15,
            ),
            children: [
              tileLayer,
              MarkerLayer(markers: [_sellerMarker()]),
            ],
          ),
          Container(
            color: Colors.black26,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: kGreen),
                  SizedBox(height: 12),
                  Text(
                    'Getting your location...',
                    style: TextStyle(
                        color: kWhite, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Error state
    if (_locationError != null) {
      return Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: kSellerLocation,
              initialZoom: 15,
            ),
            children: [
              tileLayer,
              MarkerLayer(markers: [_sellerMarker()]),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(10),
              color: Colors.black.withOpacity(0.75),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: kAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _locationError!,
                      style:
                          const TextStyle(color: kWhite, fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: _fetchBuyerLocation,
                    child: const Text('Retry',
                        style: TextStyle(
                            color: kGreen,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // ✅ Normal state — buyer + seller both shown
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _buyerLocation ?? kSellerLocation,
        initialZoom: 14,
      ),
      children: [
        tileLayer,

        // Dashed line between buyer and seller
        // Note: flutter_map v7 uses plain Polyline with strokeWidth,
        // StrokePattern.dashed is v8+. Use a thin dotted effect via opacity.
        if (_buyerLocation != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [_buyerLocation!, kSellerLocation],
                strokeWidth: 3,
                color: kPrimary.withOpacity(0.6),
              ),
            ],
          ),

        // Markers on top
        MarkerLayer(
          markers: [
            if (_buyerLocation != null)
              Marker(
                point: _buyerLocation!,
                width: 56,
                height: 56,
                child: _pinWidget(kAccent, Icons.person_pin_circle_rounded, 'You'),
              ),
            _sellerMarker(),
          ],
        ),
      ],
    );
  }

  Marker _sellerMarker() => Marker(
        point: kSellerLocation,
        width: 56,
        height: 56,
        child: _pinWidget(kPrimary, Icons.storefront_rounded, 'Seller'),
      );

  Widget _pinWidget(Color color, IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Icon(icon, color: kWhite, size: 18),
        ),
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding:
              const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: const TextStyle(
                color: kWhite,
                fontSize: 9,
                fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _legendDot(Color color) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  // ─── TIMELINE ────────────────────────────────────────────────────────────
  Widget _buildTimelineStep({
    required String title,
    required String date,
    required bool isCompleted,
    required bool isLast,
    required IconData iconData,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? kGreen : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: kWhite, size: 14)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
                color:
                    isCompleted ? kGreen : Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isCompleted
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color: isCompleted
                      ? const Color(0xFF1A1A2E)
                      : Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 4),
              Text(date,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500)),
              if (!isLast) const SizedBox(height: 24),
            ],
          ),
        ),
        Icon(iconData,
            color: isCompleted ? kGreen : Colors.grey.shade400,
            size: 24),
      ],
    );
  }

  // ─── PRODUCT CARD ─────────────────────────────────────────────────────────
  Widget _buildProductCard({
    required String name,
    required String variant,
    required String price,
    required String imageUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 60,
                height: 60,
                color: kPrimary.withOpacity(0.1),
                child: const Icon(Icons.image, color: kPrimary),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 4),
                Text(variant,
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 12)),
                const SizedBox(height: 8),
                Text(price,
                    style: const TextStyle(
                        color: kGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}