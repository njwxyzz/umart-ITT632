import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:umart_app/utils/map_marker_smoother.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const kPrimary = Color(0xFF4C6B3F);
const kAccent = Color(0xFFF27B35);
const kBg = Color(0xFFF5F7F2);
const kWhite = Colors.white;
const kGreen = Color(0xFF00C48C);

const _kCampusCenter = LatLng(6.4497, 100.2704);

// ─── Immutable view models (equality gates rebuilds) ─────────────────────────

class _TrackingStaticData {
  const _TrackingStaticData({
    required this.status,
    required this.productName,
    required this.sellerName,
    required this.buyerLocationLabel,
    required this.note,
    required this.payment,
    required this.totalPrice,
    required this.createdAt,
    required this.displayId,
    required this.isCancelled,
    required this.isPlaced,
    required this.isProcessing,
    required this.isShipped,
    required this.isDelivered,
  });

  final String status;
  final String productName;
  final String sellerName;
  final String buyerLocationLabel;
  final String note;
  final String payment;
  final double totalPrice;
  final dynamic createdAt;
  final String displayId;
  final bool isCancelled;
  final bool isPlaced;
  final bool isProcessing;
  final bool isShipped;
  final bool isDelivered;

  static _TrackingStaticData? fromDoc(DocumentSnapshot doc, String orderId) {
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return null;

    final status = (data['status'] ?? 'Pending').toString();
    final sharing = data['sellerSharing'] == true;

    return _TrackingStaticData(
      status: status,
      productName: (data['productName'] ?? 'Item').toString(),
      sellerName: (data['sellerName'] ?? 'Seller').toString(),
      buyerLocationLabel: (data['buyerLocation'] ?? '').toString(),
      note: (data['note'] ?? '').toString(),
      payment: (data['paymentMethod'] ?? '').toString(),
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
      createdAt: data['createdAt'],
      displayId: _displayId(orderId),
      isCancelled: status == 'Cancelled',
      isPlaced: true,
      isProcessing: ['Processing', 'Shipped', 'Delivered'].contains(status),
      isShipped: ['Shipped', 'Delivered'].contains(status) || sharing,
      isDelivered: status == 'Delivered',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TrackingStaticData &&
          status == other.status &&
          productName == other.productName &&
          sellerName == other.sellerName &&
          buyerLocationLabel == other.buyerLocationLabel &&
          note == other.note &&
          payment == other.payment &&
          totalPrice == other.totalPrice &&
          createdAt == other.createdAt &&
          displayId == other.displayId &&
          isCancelled == other.isCancelled &&
          isProcessing == other.isProcessing &&
          isShipped == other.isShipped &&
          isDelivered == other.isDelivered;

  @override
  int get hashCode => Object.hash(
        status,
        productName,
        sellerName,
        buyerLocationLabel,
        note,
        payment,
        totalPrice,
        createdAt,
        displayId,
        isCancelled,
        isProcessing,
        isShipped,
        isDelivered,
      );
}

class _TrackingLocationData {
  const _TrackingLocationData({
    required this.sellerSharing,
    this.sellerLat,
    this.sellerLng,
  });

  final bool sellerSharing;
  final double? sellerLat;
  final double? sellerLng;

  LatLng? get sellerPoint =>
      sellerLat != null && sellerLng != null ? LatLng(sellerLat!, sellerLng!) : null;

  static _TrackingLocationData fromMap(Map<String, dynamic> data) {
    return _TrackingLocationData(
      sellerSharing: data['sellerSharing'] == true,
      sellerLat: (data['sellerLat'] as num?)?.toDouble(),
      sellerLng: (data['sellerLng'] as num?)?.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TrackingLocationData &&
          sellerSharing == other.sellerSharing &&
          sellerLat == other.sellerLat &&
          sellerLng == other.sellerLng;

  @override
  int get hashCode => Object.hash(sellerSharing, sellerLat, sellerLng);
}

class _TrackingBannerData {
  const _TrackingBannerData({
    required this.status,
    required this.sellerSharing,
    required this.sellerArrived,
    required this.isDelivered,
    required this.isCancelled,
    this.sellerLat,
    this.sellerLng,
  });

  final String status;
  final bool sellerSharing;
  final bool sellerArrived;
  final bool isDelivered;
  final bool isCancelled;
  final double? sellerLat;
  final double? sellerLng;

  static _TrackingBannerData fromMap(Map<String, dynamic> data) {
    return _TrackingBannerData(
      status: (data['status'] ?? 'Pending').toString(),
      sellerSharing: data['sellerSharing'] == true,
      sellerArrived: data['sellerArrived'] == true,
      isDelivered: (data['status'] ?? '') == 'Delivered',
      isCancelled: (data['status'] ?? '') == 'Cancelled',
      sellerLat: (data['sellerLat'] as num?)?.toDouble(),
      sellerLng: (data['sellerLng'] as num?)?.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TrackingBannerData &&
          status == other.status &&
          sellerSharing == other.sellerSharing &&
          sellerArrived == other.sellerArrived &&
          isDelivered == other.isDelivered &&
          isCancelled == other.isCancelled &&
          sellerLat == other.sellerLat &&
          sellerLng == other.sellerLng;

  @override
  int get hashCode =>
      Object.hash(status, sellerSharing, sellerArrived, isDelivered, isCancelled, sellerLat, sellerLng);
}

String _displayId(String docId) =>
    '#UM-${docId.substring(0, docId.length < 6 ? docId.length : 6).toUpperCase()}';

String _formatTimestamp(dynamic ts) {
  if (ts == null) return '—';
  try {
    final dt = (ts as Timestamp).toDate().toLocal();
    return DateFormat('d MMM yyyy, hh:mm a').format(dt);
  } catch (_) {
    return '—';
  }
}

bool _isValidLatLng(LatLng p) {
  final latOk = p.latitude.isFinite && !p.latitude.isNaN && p.latitude >= -90 && p.latitude <= 90;
  final lngOk = p.longitude.isFinite && !p.longitude.isNaN && p.longitude >= -180 && p.longitude <= 180;
  return latOk && lngOk;
}

String _calculateEta(LatLng from, LatLng to) {
  if (!_isValidLatLng(from) || !_isValidLatLng(to)) return 'Calculating...';
  const distance = Distance();
  final metres = distance.as(LengthUnit.Meter, from, to);
  if (metres.isNaN || !metres.isFinite) return 'Calculating...';
  final minutes = (metres / 300 * 3).ceil();
  if (minutes <= 1) return '< 1 min away';
  if (minutes < 60) return '$minutes min away';
  return '${(minutes / 60).floor()} hr ${minutes % 60} min away';
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class TrackingPage extends StatefulWidget {
  final String orderId;
  const TrackingPage({super.key, required this.orderId});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  final ValueNotifier<_TrackingStaticData?> _staticNotifier = ValueNotifier(null);
  final ValueNotifier<_TrackingLocationData> _locationNotifier =
      ValueNotifier(const _TrackingLocationData(sellerSharing: false));
  final ValueNotifier<_TrackingBannerData?> _bannerNotifier = ValueNotifier(null);

  StreamSubscription<DocumentSnapshot>? _orderSub;
  final ValueNotifier<LatLng?> _buyerPinNotifier = ValueNotifier(null);
  Object? _loadError;
  bool _allowBuyerFirestoreUpdates = true;
  bool _isCancellingOrder = false;

  @override
  void initState() {
    super.initState();
    _orderSub = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .snapshots()
        .listen(_onOrderSnapshot, onError: (e) {
      if (mounted) setState(() => _loadError = e);
    });
  }

  @override
  void dispose() {
    _orderSub?.cancel();
    _staticNotifier.dispose();
    _locationNotifier.dispose();
    _bannerNotifier.dispose();
    _buyerPinNotifier.dispose();
    super.dispose();
  }

  void _onOrderSnapshot(DocumentSnapshot doc) {
    if (!doc.exists) {
      if (mounted) setState(() => _loadError = 'not_found');
      return;
    }

    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return;

    final st = (data['status'] ?? '').toString();
    _allowBuyerFirestoreUpdates = st != 'Delivered' && st != 'Cancelled';

    final nextStatic = _TrackingStaticData.fromDoc(doc, widget.orderId);
    if (nextStatic != null && nextStatic != _staticNotifier.value) {
      _staticNotifier.value = nextStatic;
    }

    final nextLoc = _TrackingLocationData.fromMap(data);
    if (nextLoc != _locationNotifier.value) {
      _locationNotifier.value = nextLoc;
    }

    final nextBanner = _TrackingBannerData.fromMap(data);
    if (nextBanner != _bannerNotifier.value) {
      _bannerNotifier.value = nextBanner;
    }

    if (_loadError != null && mounted) {
      setState(() => _loadError = null);
    }
  }

  Future<void> _cancelOrder() async {
    if (_isCancellingOrder) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: const Text(
          'You can only cancel before seller accepts your order. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Order'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isCancellingOrder = true);
    try {
      await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
        'status': 'Cancelled',
        'cancelledBy': 'Buyer',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order cancelled successfully.'),
          backgroundColor: kPrimary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not cancel order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isCancellingOrder = false);
    }
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
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loadError == 'not_found') {
      return const Center(child: Text('Order not found.'));
    }
    if (_loadError != null) {
      return Center(
        child: Text(
          'Failed to load tracking.\n$_loadError',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade700),
        ),
      );
    }

    return ValueListenableBuilder<_TrackingStaticData?>(
      valueListenable: _staticNotifier,
      builder: (context, staticData, _) {
        if (staticData == null) {
          return const Center(
            child: SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(color: kPrimary, strokeWidth: 4),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 260,
                  child: _TrackingLiveMap(
                    orderId: widget.orderId,
                    locationListenable: _locationNotifier,
                    buyerPinNotifier: _buyerPinNotifier,
                    allowFirestoreUpdates: () => _allowBuyerFirestoreUpdates,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<_TrackingBannerData?>(
                valueListenable: _bannerNotifier,
                builder: (context, banner, _) {
                  if (banner == null) return const SizedBox.shrink();
                  return _TrackingStatusCard(
                    banner: banner,
                    buyerPinListenable: _buyerPinNotifier,
                  );
                },
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  _LegendDot(color: kAccent),
                  SizedBox(width: 6),
                  Text('Your Location', style: TextStyle(fontSize: 12, color: Color(0xFF1A1A2E))),
                  SizedBox(width: 20),
                  _LegendDot(color: kPrimary),
                  SizedBox(width: 6),
                  Text('Seller', style: TextStyle(fontSize: 12, color: Color(0xFF1A1A2E))),
                ],
              ),
              const SizedBox(height: 24),
              _TrackingOrderDetails(
                data: staticData,
                orderId: widget.orderId,
                isCancelling: _isCancellingOrder,
                onCancel: _canCancelOrder(staticData.status) ? _cancelOrder : null,
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  bool _canCancelOrder(String status) => status == 'Pending';
}

// ─── Live map (isolated rebuilds) ─────────────────────────────────────────────

class _TrackingLiveMap extends StatefulWidget {
  const _TrackingLiveMap({
    required this.orderId,
    required this.locationListenable,
    required this.buyerPinNotifier,
    required this.allowFirestoreUpdates,
  });

  final String orderId;
  final ValueListenable<_TrackingLocationData> locationListenable;
  final ValueNotifier<LatLng?> buyerPinNotifier;
  final bool Function() allowFirestoreUpdates;

  @override
  State<_TrackingLiveMap> createState() => _TrackingLiveMapState();
}

class _TrackingLiveMapState extends State<_TrackingLiveMap> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final MapMarkerSmoother _buyerSmooth;
  late final MapMarkerSmoother _sellerSmooth;

  StreamSubscription<Position>? _buyerPositionSub;
  _TrackingLocationData _lastLoc = const _TrackingLocationData(sellerSharing: false);

  bool _isLocating = true;
  String? _locationError;
  LatLng? _buyerGps;
  bool _didFitCamera = false;

  Listenable get _markerRepaint => Listenable.merge([
        _buyerSmooth.repaintListenable,
        _sellerSmooth.repaintListenable,
      ]);

  @override
  void initState() {
    super.initState();
    _buyerSmooth = MapMarkerSmoother(this);
    _sellerSmooth = MapMarkerSmoother(this);
    widget.locationListenable.addListener(_onLocationChanged);
    _lastLoc = widget.locationListenable.value;
    _applySellerLocation(_lastLoc);
    _startBuyerGps();
  }

  @override
  void dispose() {
    widget.locationListenable.removeListener(_onLocationChanged);
    _buyerPositionSub?.cancel();
    _buyerSmooth.dispose();
    _sellerSmooth.dispose();
    super.dispose();
  }

  void _onLocationChanged() {
    final loc = widget.locationListenable.value;
    if (loc == _lastLoc) return;
    _lastLoc = loc;
    _applySellerLocation(loc);
  }

  void _applySellerLocation(_TrackingLocationData loc) {
    if (loc.sellerSharing && loc.sellerPoint != null) {
      _sellerSmooth.setTarget(loc.sellerPoint!, _onMarkerTick);
      if (!_didFitCamera) {
        _didFitCamera = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _fitCameraIfPossible());
      }
    } else {
      _sellerSmooth.setTarget(null, _onMarkerTick);
    }
  }

  void _onMarkerTick() {
    // AnimatedBuilder handles repaint; publish buyer pin for ETA card only.
    widget.buyerPinNotifier.value = _buyerSmooth.current ?? _buyerGps;
  }

  Future<void> _startBuyerGps() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _setGpsError('Please enable GPS.');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        _setGpsError('Location permission denied.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _onBuyerPosition(LatLng(pos.latitude, pos.longitude));
      if (widget.allowFirestoreUpdates()) {
        unawaited(
          FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
            'buyerLat': pos.latitude,
            'buyerLng': pos.longitude,
          }),
        );
      }

      await _buyerPositionSub?.cancel();
      _buyerPositionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 8,
        ),
      ).listen((p) async {
        _onBuyerPosition(LatLng(p.latitude, p.longitude));
        if (widget.allowFirestoreUpdates()) {
          try {
            await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
              'buyerLat': p.latitude,
              'buyerLng': p.longitude,
            });
          } catch (_) {}
        }
      });

      if (mounted) setState(() => _isLocating = false);
    } catch (e) {
      _setGpsError('Could not get location: $e');
    }
  }

  void _setGpsError(String msg) {
    if (!mounted) return;
    setState(() {
      _isLocating = false;
      _locationError = msg;
    });
  }

  void _onBuyerPosition(LatLng here) {
    _buyerGps = here;
    _buyerSmooth.setTarget(here, _onMarkerTick);
    widget.buyerPinNotifier.value = _buyerSmooth.current ?? here;
  }

  void _fitCameraIfPossible() {
    final buyer = _buyerSmooth.current ?? _buyerGps;
    final seller = _sellerSmooth.current;
    if (buyer == null || seller == null) return;
    if (!_isValidLatLng(buyer) || !_isValidLatLng(seller)) return;

    final samePoint = (buyer.latitude - seller.latitude).abs() < 0.000001 &&
        (buyer.longitude - seller.longitude).abs() < 0.000001;
    if (samePoint) {
      _mapController.move(buyer, 17);
      return;
    }

    final minLat = buyer.latitude < seller.latitude ? buyer.latitude : seller.latitude;
    final maxLat = buyer.latitude > seller.latitude ? buyer.latitude : seller.latitude;
    final minLng = buyer.longitude < seller.longitude ? buyer.longitude : seller.longitude;
    final maxLng = buyer.longitude > seller.longitude ? buyer.longitude : seller.longitude;

    if ([minLat, maxLat, minLng, maxLng].any((v) => v.isNaN || !v.isFinite)) return;

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng)),
        padding: const EdgeInsets.all(80),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(child: _buildMapStack());
  }

  Widget _buildMapStack() {
    final tileLayer = TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.example.umart_app',
    );

    if (_isLocating) {
      return Stack(
        children: [
          FlutterMap(
            options: const MapOptions(initialCenter: _kCampusCenter, initialZoom: 15),
            children: [tileLayer],
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
                    style: TextStyle(color: kWhite, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_locationError != null) {
      return Stack(
        children: [
          FlutterMap(
            options: const MapOptions(initialCenter: _kCampusCenter, initialZoom: 15),
            children: [tileLayer],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(10),
              color: Colors.black.withValues(alpha: 0.75),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: kAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _locationError!,
                      style: const TextStyle(color: kWhite, fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLocating = true;
                        _locationError = null;
                      });
                      _startBuyerGps();
                    },
                    child: const Text(
                      'Retry',
                      style: TextStyle(color: kGreen, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final initialCenter = _buyerGps ?? _kCampusCenter;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(initialCenter: initialCenter, initialZoom: 15),
      children: [
        tileLayer,
        AnimatedBuilder(
          animation: _markerRepaint,
          builder: (context, _) {
            final buyer = _buyerSmooth.current ?? _buyerGps;
            final seller = _sellerSmooth.current;
            if (buyer == null || seller == null) {
              return const SizedBox.shrink();
            }
            return PolylineLayer(
              polylines: [
                Polyline(
                  points: [seller, buyer],
                  strokeWidth: 3,
                  color: kPrimary.withValues(alpha: 0.6),
                ),
              ],
            );
          },
        ),
        AnimatedBuilder(
          animation: _markerRepaint,
          builder: (context, _) {
            final buyer = _buyerSmooth.current ?? _buyerGps;
            final seller = _sellerSmooth.current;
            final markers = <Marker>[];
            if (buyer != null) {
              markers.add(
                Marker(
                  point: buyer,
                  width: 56,
                  height: 56,
                  child: const _MapPin(color: kAccent, icon: Icons.person_pin_circle_rounded, label: 'You'),
                ),
              );
            }
            if (seller != null) {
              markers.add(
                Marker(
                  point: seller,
                  width: 56,
                  height: 56,
                  child: const _MapPin(
                    color: kPrimary,
                    icon: Icons.delivery_dining_rounded,
                    label: 'Seller',
                  ),
                ),
              );
            }
            return MarkerLayer(markers: markers);
          },
        ),
      ],
    );
  }
}

// ─── Status card (rebuilds on status / ETA fields only) ───────────────────────

class _TrackingStatusCard extends StatelessWidget {
  const _TrackingStatusCard({
    required this.banner,
    required this.buyerPinListenable,
  });

  final _TrackingBannerData banner;
  final ValueListenable<LatLng?> buyerPinListenable;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LatLng?>(
      valueListenable: buyerPinListenable,
      builder: (context, buyerPin, _) {
        var etaText = _defaultEta(banner);
        if (banner.sellerSharing &&
            banner.sellerLat != null &&
            banner.sellerLng != null &&
            buyerPin != null) {
          final seller = LatLng(banner.sellerLat!, banner.sellerLng!);
          if (_isValidLatLng(buyerPin) && _isValidLatLng(seller)) {
            etaText = _calculateEta(seller, buyerPin);
          } else {
            etaText = 'Seller is on the way!';
          }
        }
        return _TrackingStatusCardBody(banner: banner, etaText: etaText);
      },
    );
  }

  String _defaultEta(_TrackingBannerData b) {
    if (b.isDelivered) return 'Order has been delivered!';
    if (b.isCancelled) return 'This order has been cancelled.';
    if (b.sellerArrived) return 'Please meet seller at your pickup point.';
    if (b.sellerSharing) return 'Seller is on the way!';
    return 'Seller is preparing your order...';
  }
}

class _TrackingStatusCardBody extends StatelessWidget {
  const _TrackingStatusCardBody({required this.banner, required this.etaText});

  final _TrackingBannerData banner;
  final String etaText;

  @override
  Widget build(BuildContext context) {
    final sellerSharing = banner.sellerSharing;
    final sellerArrived = banner.sellerArrived;
    final isDelivered = banner.isDelivered;
    final isCancelled = banner.isCancelled;
    final status = banner.status;

    return Container(
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
            color: isDelivered || sellerSharing || sellerArrived ? kWhite : Colors.grey.shade500,
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
                      : isCancelled
                          ? 'Order Cancelled'
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
                        ? kWhite.withValues(alpha: 0.85)
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
                color: kWhite.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.circle, color: kGreen, size: 8),
                  const SizedBox(width: 4),
                  Text(
                    sellerArrived ? 'ARRIVED' : 'LIVE',
                    style: const TextStyle(
                      color: kWhite,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
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

// ─── Static order details (no location stream) ────────────────────────────────

class _TrackingOrderDetails extends StatelessWidget {
  const _TrackingOrderDetails({
    required this.data,
    required this.orderId,
    required this.isCancelling,
    this.onCancel,
  });

  final _TrackingStaticData data;
  final String orderId;
  final bool isCancelling;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.displayId,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _InfoRow(icon: Icons.storefront_rounded, label: 'Seller', value: data.sellerName),
              if (data.buyerLocationLabel.isNotEmpty) ...[
                const Divider(height: 16),
                _InfoRow(
                  icon: Icons.location_on_rounded,
                  label: 'Deliver to',
                  value: data.buyerLocationLabel,
                ),
              ],
              if (data.note.isNotEmpty) ...[
                const Divider(height: 16),
                _InfoRow(icon: Icons.sticky_note_2_outlined, label: 'Note', value: data.note),
              ],
              if (data.payment.isNotEmpty) ...[
                const Divider(height: 16),
                _InfoRow(icon: Icons.payment_rounded, label: 'Payment', value: data.payment),
              ],
              const Divider(height: 16),
              _InfoRow(
                icon: Icons.access_time_rounded,
                label: 'Ordered at',
                value: _formatTimestamp(data.createdAt),
              ),
            ],
          ),
        ),
        if (onCancel != null) ...[
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isCancelling ? null : onCancel,
              icon: isCancelling
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                    )
                  : const Icon(Icons.cancel_outlined, color: Colors.red),
              label: const Text(
                'Cancel Order',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.shade300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        const Text(
          'Order Status',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 16),
        _TimelineStep(
          title: 'Order Placed',
          date: _formatTimestamp(data.createdAt),
          isCompleted: data.isPlaced,
          isLast: false,
          iconData: Icons.receipt_long_rounded,
        ),
        _TimelineStep(
          title: 'Accepted & Processing',
          date: data.isProcessing ? 'Seller is preparing your order' : 'Waiting...',
          isCompleted: data.isProcessing,
          isLast: false,
          iconData: Icons.inventory_2_outlined,
        ),
        _TimelineStep(
          title: 'On the Way',
          date: data.isShipped ? 'Seller is heading to you' : 'Not yet',
          isCompleted: data.isShipped,
          isLast: false,
          iconData: Icons.local_shipping_outlined,
        ),
        _TimelineStep(
          title: 'Delivered',
          date: data.isDelivered ? 'Your order has arrived!' : '—',
          isCompleted: data.isDelivered,
          isLast: true,
          iconData: Icons.check_box_outlined,
        ),
        const SizedBox(height: 24),
        const Text(
          'Your Order',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.fastfood_rounded, color: kPrimary, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'From ${data.sellerName}',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                'RM ${data.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: kGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Small leaf widgets ───────────────────────────────────────────────────────

class _MapPin extends StatelessWidget {
  const _MapPin({required this.color, required this.icon, required this.label});

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
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
                color: color.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: kWhite, size: 18),
        ),
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: kWhite,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
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
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.title,
    required this.date,
    required this.isCompleted,
    required this.isLast,
    required this.iconData,
  });

  final String title;
  final String date;
  final bool isCompleted;
  final bool isLast;
  final IconData iconData;

  @override
  Widget build(BuildContext context) {
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
              child: isCompleted ? const Icon(Icons.check, color: kWhite, size: 14) : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
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
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isCompleted ? FontWeight.w800 : FontWeight.w600,
                  color: isCompleted ? const Color(0xFF1A1A2E) : Colors.grey.shade500,
                ),
              ),
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
