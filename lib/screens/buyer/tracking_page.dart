import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const kPrimary = Color(0xFF4C6B3F);
const kAccent  = Color(0xFFF27B35);
const kBg      = Color(0xFFF5F7F2);
const kWhite   = Colors.white;
const kGreen   = Color(0xFF00C48C);

class TrackingPage extends StatefulWidget {
  final String orderId;
  const TrackingPage({super.key, required this.orderId});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  final MapController _mapController = MapController();

  // Buyer GPS
  LatLng? _buyerLocation;
  bool _isLocating = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _fetchBuyerLocation();
  }

  // ─── Buyer GPS ────────────────────────────────────────────────────────────
  Future<void> _fetchBuyerLocation() async {
    setState(() { _isLocating = true; _locationError = null; });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() { _isLocating = false; _locationError = 'Please enable GPS.'; });
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        setState(() { _isLocating = false; _locationError = 'Location permission denied.'; });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() { _buyerLocation = LatLng(pos.latitude, pos.longitude); _isLocating = false; });
    } catch (e) {
      setState(() { _isLocating = false; _locationError = 'Could not get location: $e'; });
    }
  }

  void _fitBothMarkers(LatLng seller) {
    if (_buyerLocation == null) return;
    final buyer = _buyerLocation!;

    // Guard against invalid coordinates that can crash flutter_map on web.
    if (!_isValidLatLng(buyer) || !_isValidLatLng(seller)) return;

    // If both points are essentially the same, avoid bounds fit (can yield NaN).
    final samePoint = (buyer.latitude - seller.latitude).abs() < 0.000001 &&
        (buyer.longitude - seller.longitude).abs() < 0.000001;
    if (samePoint) {
      _mapController.move(buyer, 17);
      return;
    }

    final minLat = buyer.latitude  < seller.latitude  ? buyer.latitude  : seller.latitude;
    final maxLat = buyer.latitude  > seller.latitude  ? buyer.latitude  : seller.latitude;
    final minLng = buyer.longitude < seller.longitude ? buyer.longitude : seller.longitude;
    final maxLng = buyer.longitude > seller.longitude ? buyer.longitude : seller.longitude;

    if ([minLat, maxLat, minLng, maxLng].any((v) => v.isNaN || !v.isFinite)) {
      return;
    }

    _mapController.fitCamera(CameraFit.bounds(
      bounds: LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng)),
      padding: const EdgeInsets.all(80),
    ));
  }

  String _calculateEta(LatLng from, LatLng to) {
    if (!_isValidLatLng(from) || !_isValidLatLng(to)) return 'Calculating...';
    const Distance distance = Distance();
    final metres = distance.as(LengthUnit.Meter, from, to);
    if (metres.isNaN || !metres.isFinite) return 'Calculating...';
    final minutes = (metres / 300 * 3).ceil();
    if (minutes <= 1) return '< 1 min away';
    if (minutes < 60) return '$minutes min away';
    return '${(minutes / 60).floor()} hr ${minutes % 60} min away';
  }

  bool _isValidLatLng(LatLng p) {
    final latOk = p.latitude.isFinite && !p.latitude.isNaN && p.latitude >= -90 && p.latitude <= 90;
    final lngOk = p.longitude.isFinite && !p.longitude.isNaN && p.longitude >= -180 && p.longitude <= 180;
    return latOk && lngOk;
  }

  // ─── Format Firestore Timestamp ──────────────────────────────────────────
  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '—';
    try {
      final dt = (ts as Timestamp).toDate().toLocal();
      return DateFormat('d MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return '—';
    }
  }

  // ─── Derive short display order ID ───────────────────────────────────────
  String _displayId(String docId) =>
      '#UM-${docId.substring(0, min(6, docId.length)).toUpperCase()}';

  int min(int a, int b) => a < b ? a : b;

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
        title: const Text('Track Order',
            style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .snapshots(),
        builder: (context, snapshot) {
          // ── Loading ──────────────────────────────────────────────────────
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(color: kPrimary, strokeWidth: 4),
              ),
            );
          }

          // ── Error / not found ────────────────────────────────────────────
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load tracking.\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Order not found.'));
          }

          // ── Parse Firestore data ─────────────────────────────────────────
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String status        = data['status'] ?? 'Pending';
          final String productName   = data['productName'] ?? 'Item';
          final String sellerName    = data['sellerName'] ?? 'Seller';
          final String buyerLocation = data['buyerLocation'] ?? '';
          final String note          = data['note'] ?? '';
          final String payment       = data['paymentMethod'] ?? '';
          final double totalPrice    = (data['totalPrice'] as num?)?.toDouble() ?? 0.0;
          final dynamic createdAt    = data['createdAt'];
          final bool sellerArrived   = data['sellerArrived'] == true;
          final String displayId     = _displayId(widget.orderId);

          // Seller live location update
          final bool sharing = data['sellerSharing'] == true;
          final lat = (data['sellerLat'] as num?)?.toDouble();
          final lng = (data['sellerLng'] as num?)?.toDouble();

          // Timeline booleans derived from status
          final bool isPlaced = true; // always true once order exists
          final bool isProcessing =
              ['Processing', 'Shipped', 'Delivered'].contains(status);
          final bool isShipped =
              ['Shipped', 'Delivered'].contains(status) || sharing;
          final bool isDelivered = status == 'Delivered';

          LatLng? sellerLocation;
          bool sellerSharing = false;
          String etaText = isDelivered
              ? 'Order has been delivered!'
              : sellerArrived
                  ? 'Please meet seller at your pickup point.'
                  : 'Seller is preparing your order...';

          if (sharing && lat != null && lng != null) {
            sellerSharing = true;
            sellerLocation = LatLng(lat, lng);
            if (_buyerLocation != null && _isValidLatLng(_buyerLocation!) && _isValidLatLng(sellerLocation)) {
              etaText = _calculateEta(sellerLocation, _buyerLocation!);
            } else {
              etaText = 'Seller is on the way!';
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || sellerLocation == null) return;
              _fitBothMarkers(sellerLocation);
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── 1. MAP ─────────────────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 260,
                    child: _buildMap(sellerLocation: sellerLocation),
                  ),
                ),

                const SizedBox(height: 12),

                // ─── 2. ETA / STATUS CARD ────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDelivered
                        ? kGreen
                        : sellerArrived
                            ? kAccent
                            : sellerSharing
                            ? kPrimary
                            : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isDelivered
                            ? Icons.check_circle_rounded
                            : sellerArrived
                                ? Icons.store_mall_directory_rounded
                            : sellerSharing
                                ? Icons.delivery_dining_rounded
                                : Icons.hourglass_empty_rounded,
                        color: isDelivered || sellerSharing ? kWhite : Colors.grey.shade500,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isDelivered
                                  ? 'Order Delivered!'
                                  : sellerArrived
                                      ? 'Seller has arrived!'
                                  : sellerSharing
                                      ? 'Seller is on the way!'
                                      : status == 'Processing'
                                          ? 'Order accepted — preparing now'
                                          : status == 'Rejected'
                                              ? 'Order was rejected'
                                              : 'Waiting for seller to accept',
                              style: TextStyle(
                                color: isDelivered || sellerSharing || sellerArrived
                                    ? kWhite
                                    : Colors.grey.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              etaText,
                              style: TextStyle(
                                color: isDelivered || sellerSharing || sellerArrived
                                    ? kWhite.withOpacity(0.85)
                                    : Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if ((sellerSharing || sellerArrived) && !isDelivered)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: kWhite.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.circle, color: kGreen, size: 8),
                              const SizedBox(width: 4),
                              Text(
                                sellerArrived ? 'ARRIVED' : 'LIVE',
                                style: const TextStyle(color: kWhite, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Legend
                Row(
                  children: [
                    _legendDot(kAccent),
                    const SizedBox(width: 6),
                    const Text('Your Location', style: TextStyle(fontSize: 12, color: Color(0xFF1A1A2E))),
                    const SizedBox(width: 20),
                    _legendDot(kPrimary),
                    const SizedBox(width: 6),
                    const Text('Seller', style: TextStyle(fontSize: 12, color: Color(0xFF1A1A2E))),
                  ],
                ),

                const SizedBox(height: 24),

                // ─── 3. ORDER INFO CARD ──────────────────────────────────
                Text(displayId,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
                const SizedBox(height: 8),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kWhite,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      _infoRow(Icons.storefront_rounded, 'Seller', sellerName),
                      if (buyerLocation.isNotEmpty) ...[
                        const Divider(height: 16),
                        _infoRow(Icons.location_on_rounded, 'Deliver to', buyerLocation),
                      ],
                      if (note.isNotEmpty) ...[
                        const Divider(height: 16),
                        _infoRow(Icons.sticky_note_2_outlined, 'Note', note),
                      ],
                      if (payment.isNotEmpty) ...[
                        const Divider(height: 16),
                        _infoRow(Icons.payment_rounded, 'Payment', payment),
                      ],
                      const Divider(height: 16),
                      _infoRow(Icons.access_time_rounded, 'Ordered at', _formatTimestamp(createdAt)),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ─── 4. TIMELINE ─────────────────────────────────────────
                const Text('Order Status',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
                const SizedBox(height: 16),

                _buildTimelineStep(
                  title: 'Order Placed',
                  date: _formatTimestamp(createdAt),
                  isCompleted: isPlaced,
                  isLast: false,
                  iconData: Icons.receipt_long_rounded,
                ),
                _buildTimelineStep(
                  title: 'Accepted & Processing',
                  date: isProcessing ? 'Seller is preparing your order' : 'Waiting...',
                  isCompleted: isProcessing,
                  isLast: false,
                  iconData: Icons.inventory_2_outlined,
                ),
                _buildTimelineStep(
                  title: 'On the Way',
                  date: isShipped ? 'Seller is heading to you' : 'Not yet',
                  isCompleted: isShipped,
                  isLast: false,
                  iconData: Icons.local_shipping_outlined,
                ),
                _buildTimelineStep(
                  title: 'Delivered',
                  date: isDelivered ? 'Your order has arrived!' : '—',
                  isCompleted: isDelivered,
                  isLast: true,
                  iconData: Icons.check_box_outlined,
                ),

                const SizedBox(height: 24),

                // ─── 5. PRODUCT FROM FIREBASE ────────────────────────────
                const Text('Your Order',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kWhite,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      // Product icon (no imageUrl in Firestore — use icon placeholder)
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.fastfood_rounded, color: kPrimary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(productName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1A2E))),
                            const SizedBox(height: 4),
                            Text('From $sellerName',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text('RM ${totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: kGreen, fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Info row helper ──────────────────────────────────────────────────────
  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: kPrimary),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A2E)),
              children: [
                TextSpan(text: '$label:  ', style: const TextStyle(color: Colors.grey)),
                TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── MAP ─────────────────────────────────────────────────────────────────
  Widget _buildMap({LatLng? sellerLocation}) {
    final tileLayer = TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.example.umart_app', 
    );

    if (_isLocating) {
      return Stack(
        children: [
          FlutterMap(
            options: const MapOptions(initialCenter: LatLng(6.4497, 100.2704), initialZoom: 15),
            children: [tileLayer],
          ),
          Container(
            color: Colors.black26,
            child: const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(color: kGreen),
                SizedBox(height: 12),
                Text('Getting your location...', style: TextStyle(color: kWhite, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ],
      );
    }

    if (_locationError != null) {
      return Stack(
        children: [
          FlutterMap(
            options: const MapOptions(initialCenter: LatLng(6.4497, 100.2704), initialZoom: 15),
            children: [tileLayer],
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(10),
              color: Colors.black.withOpacity(0.75),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: kAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_locationError!, style: const TextStyle(color: kWhite, fontSize: 12))),
                  TextButton(
                    onPressed: _fetchBuyerLocation,
                    child: const Text('Retry', style: TextStyle(color: kGreen, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final center = sellerLocation ?? _buyerLocation ?? const LatLng(6.4497, 100.2704);
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(initialCenter: center, initialZoom: 15),
      children: [
        tileLayer,
        if (sellerLocation != null && _buyerLocation != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [sellerLocation, _buyerLocation!],
                strokeWidth: 3,
                color: kPrimary.withOpacity(0.6),
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (_buyerLocation != null)
              Marker(
                point: _buyerLocation!,
                width: 56, height: 56,
                child: _pinWidget(kAccent, Icons.person_pin_circle_rounded, 'You'),
              ),
            if (sellerLocation != null)
              Marker(
                point: sellerLocation,
                width: 56, height: 56,
                child: _pinWidget(kPrimary, Icons.delivery_dining_rounded, 'Seller'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _pinWidget(Color color, IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color, shape: BoxShape.circle,
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

  Widget _legendDot(Color color) => Container(
        width: 12, height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  Widget _buildTimelineStep({
    required String title, required String date,
    required bool isCompleted, required bool isLast, required IconData iconData,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? kGreen : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: isCompleted ? const Icon(Icons.check, color: kWhite, size: 14) : null,
            ),
            if (!isLast)
              Container(
                width: 2, height: 50,
                color: isCompleted ? kGreen : Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(
                fontSize: 15,
                fontWeight: isCompleted ? FontWeight.w800 : FontWeight.w600,
                color: isCompleted ? const Color(0xFF1A1A2E) : Colors.grey.shade500,
              )),
              const SizedBox(height: 4),
              Text(date, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              if (!isLast) const SizedBox(height: 24),
            ],
          ),
        ),
        Icon(iconData, color: isCompleted ? kGreen : Colors.grey.shade400, size: 24),
      ],
    );
  }
}