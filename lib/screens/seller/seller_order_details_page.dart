import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const kPrimary = Color(0xFF4C6B3F);
const kAccent  = Color(0xFFF27B35);
const kBg      = Color(0xFFF5F7F2);
const kWhite   = Colors.white;
const kGreen   = Color(0xFF00C48C);

class SellerOrderDetailsPage extends StatefulWidget {
  final String orderId;
  final String buyerName;
  final String address;
  final String phone;
  final double buyerLat;   // pass buyer's real lat from order doc
  final double buyerLng;   // pass buyer's real lng from order doc

  const SellerOrderDetailsPage({
    super.key,
    required this.orderId,
    required this.buyerName,
    required this.address,
    required this.phone,
    required this.buyerLat,
    required this.buyerLng,
  });

  @override
  State<SellerOrderDetailsPage> createState() => _SellerOrderDetailsPageState();
}

class _SellerOrderDetailsPageState extends State<SellerOrderDetailsPage> {
  final MapController _mapController = MapController();

  LatLng? _sellerLocation;           // seller's live GPS
  StreamSubscription<Position>? _positionStream; // GPS stream
  bool _isSharing = false;           // true while seller is actively sharing
  bool _isStarting = false;          // loading spinner for start button
  Timer? _demoMoveTimer;             // demo movement timer
  bool _isDemoMoving = false;        // demo mode flag

  late LatLng _buyerLatLng;

  @override
  void initState() {
    super.initState();
    _buyerLatLng = LatLng(widget.buyerLat, widget.buyerLng);
    _restoreSharingState();
  }

  @override
  void dispose() {
    // Cancel local GPS stream only. Keep Firestore sharing flag as-is so
    // seller can auto-resume next time this page opens.
    _stopSharing(clearRemote: false);
    super.dispose();
  }

  Future<void> _restoreSharingState() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get();
      final data = doc.data();
      if (data == null) return;

      final wasSharing = data['sellerSharing'] == true;
      if (wasSharing) {
        // Auto resume live GPS stream if seller had sharing enabled earlier.
        await _startSharing();
      }
    } catch (_) {
      // Silent fail to avoid blocking the page UI.
    }
  }

  // ─── Start broadcasting seller location to Firestore ─────────────────────
  Future<void> _startSharing() async {
    _demoMoveTimer?.cancel();
    _isDemoMoving = false;
    if (_positionStream != null) return; // Prevent duplicate subscriptions
    setState(() => _isStarting = true);

    // 1. Permission check
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnack('Please enable GPS first.');
      setState(() => _isStarting = false);
      return;
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      _showSnack('Location permission denied.');
      setState(() => _isStarting = false);
      return;
    }

    // 2. Subscribe to live GPS stream
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // update every 5 metres moved
      ),
    ).listen((Position pos) async {
      final latLng = LatLng(pos.latitude, pos.longitude);
      final metresToBuyer = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        _buyerLatLng.latitude,
        _buyerLatLng.longitude,
      );
      final arrived = metresToBuyer <= 25;

      // 3. Write to Firestore orders/{orderId}
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'sellerLat': pos.latitude,
        'sellerLng': pos.longitude,
        'sellerSharing': true,
        'sellerArrived': arrived,
        if (arrived) 'sellerArrivedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _sellerLocation = latLng;
          _isSharing = true;
          _isStarting = false;
        });

        // Move map camera to keep seller in view
        _mapController.move(latLng, _mapController.camera.zoom);
      }
    });
  }

  // ─── Stop sharing location ────────────────────────────────────────────────
  Future<void> _stopSharing({bool clearRemote = true}) async {
    _demoMoveTimer?.cancel();
    _demoMoveTimer = null;
    _isDemoMoving = false;
    await _positionStream?.cancel();
    _positionStream = null;

    if (clearRemote) {
      // Clear seller location from Firestore so buyer sees "offline"
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'sellerLat': FieldValue.delete(),
        'sellerLng': FieldValue.delete(),
        'sellerSharing': false,
      });
    }

    if (mounted) {
      setState(() {
        _isSharing = false;
        _sellerLocation = null;
      });
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Future<void> _startDemoMovement() async {
    // Stop real GPS stream so demo coordinates are not overridden.
    await _positionStream?.cancel();
    _positionStream = null;

    if (_isDemoMoving) return;
    setState(() {
      _isSharing = true;
      _isDemoMoving = true;
    });

    // Small loop around buyer location for testing live movement.
    final path = <LatLng>[
      LatLng(_buyerLatLng.latitude + 0.0009, _buyerLatLng.longitude - 0.0007),
      LatLng(_buyerLatLng.latitude + 0.0005, _buyerLatLng.longitude - 0.0002),
      LatLng(_buyerLatLng.latitude + 0.0002, _buyerLatLng.longitude + 0.0002),
      LatLng(_buyerLatLng.latitude - 0.0001, _buyerLatLng.longitude + 0.0004),
      LatLng(_buyerLatLng.latitude + 0.0003, _buyerLatLng.longitude + 0.0001),
      LatLng(_buyerLatLng.latitude + 0.0007, _buyerLatLng.longitude - 0.0004),
      LatLng(_buyerLatLng.latitude, _buyerLatLng.longitude), // simulate arrival
    ];
    int i = 0;

    Future<void> pushPoint(LatLng p) async {
      final metresToBuyer = Geolocator.distanceBetween(
        p.latitude,
        p.longitude,
        _buyerLatLng.latitude,
        _buyerLatLng.longitude,
      );
      final arrived = metresToBuyer <= 25;
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'sellerLat': p.latitude,
        'sellerLng': p.longitude,
        'sellerSharing': true,
        'sellerArrived': arrived,
        if (arrived) 'sellerArrivedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      setState(() {
        _sellerLocation = p;
      });
      _mapController.move(p, _mapController.camera.zoom);
    }

    await pushPoint(path.first);
    _demoMoveTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!_isDemoMoving) {
        timer.cancel();
        return;
      }
      i = (i + 1) % path.length;
      await pushPoint(path[i]);
    });
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
          onPressed: () {
            _stopSharing(clearRemote: false);
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Order Details',
          style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 1. MAP ───────────────────────────────────────────────────
            Container(
              height: 260,
              width: double.infinity,
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              clipBehavior: Clip.antiAlias,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _buyerLatLng,
                  initialZoom: 15,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.app',
                  ),

                  // Line from seller to buyer (only when seller is sharing)
                  if (_sellerLocation != null)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [_sellerLocation!, _buyerLatLng],
                          strokeWidth: 3,
                          color: kPrimary.withOpacity(0.6),
                        ),
                      ],
                    ),

                  MarkerLayer(
                    markers: [
                      // Buyer pin (fixed)
                      Marker(
                        point: _buyerLatLng,
                        width: 56,
                        height: 56,
                        child: _pinWidget(kAccent, Icons.person_pin_circle_rounded, 'Buyer'),
                      ),
                      // Seller pin (live, only when sharing)
                      if (_sellerLocation != null)
                        Marker(
                          point: _sellerLocation!,
                          width: 56,
                          height: 56,
                          child: _pinWidget(kPrimary, Icons.delivery_dining_rounded, 'You'),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // ─── 2. SHARE LOCATION TOGGLE CARD ───────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isSharing ? kGreen : Colors.grey.shade200,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (_isSharing ? kGreen : Colors.grey.shade400).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: _isSharing ? kGreen : Colors.grey.shade400,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isSharing ? 'Sharing live location' : 'Share your location',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _isSharing ? kGreen : const Color(0xFF1A1A2E),
                            ),
                          ),
                          Text(
                            _isSharing
                                ? 'Buyer can see you on the map'
                                : 'Let buyer track your delivery',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    _isStarting
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: kGreen))
                        : Switch(
                            value: _isSharing,
                            activeThumbColor: kGreen,
                            onChanged: (val) => val ? _startSharing() : _stopSharing(),
                          ),
                  ],
                ),
              ),
            ),

            // ─── DEMO MOVE BUTTON (for web testing without DevTools) ───────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isDemoMoving
                      ? () => _stopSharing()
                      : () async => _startDemoMovement(),
                  icon: Icon(
                    _isDemoMoving ? Icons.stop_circle_outlined : Icons.play_circle_outline_rounded,
                    color: kPrimary,
                  ),
                  label: Text(
                    _isDemoMoving ? 'Stop Demo Move Seller' : 'Demo Move Seller',
                    style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: kPrimary.withOpacity(0.35)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),

            if (_isDemoMoving)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: kAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kAccent.withOpacity(0.35)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.science_rounded, color: kAccent, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'DEMO MODE ACTIVE',
                        style: TextStyle(
                          color: kAccent,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // ─── 3. BUYER INFO ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order ${widget.orderId}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E)),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.grey.shade200,
                          child: const Icon(Icons.person, color: Colors.grey),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.buyerName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14, color: kAccent),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(widget.address,
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.call, color: kGreen),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text('Items Ordered',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 12),
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('orders')
                        .doc(widget.orderId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(16)),
                          child: const Center(child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2)),
                        );
                      }
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(16)),
                          child: Text('Could not load items.', style: TextStyle(color: Colors.grey.shade600)),
                        );
                      }
                      final data = snapshot.data!.data()!;
                      final productName = (data['productName'] ?? 'Item').toString().trim();
                      final totalPrice = (data['totalPrice'] as num?)?.toDouble() ?? 0.0;
                      final cartNote = (data['note'] ?? '').toString().trim();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(16)),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    productName.isEmpty ? 'Item' : productName,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, height: 1.35),
                                    maxLines: 6,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'RM ${totalPrice.toStringAsFixed(2)}',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          if (cartNote.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                'Buyer note: $cartNote',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ─── 4. MARK AS DELIVERED ─────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              await _stopSharing();
              await FirebaseFirestore.instance
                  .collection('orders')
                  .doc(widget.orderId)
                  .update({'status': 'Delivered'});
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Mark as Delivered',
                style: TextStyle(color: kWhite, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _pinWidget(Color color, IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Icon(icon, color: kWhite, size: 18),
        ),
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
          child: Text(label, style: const TextStyle(color: kWhite, fontSize: 9, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}