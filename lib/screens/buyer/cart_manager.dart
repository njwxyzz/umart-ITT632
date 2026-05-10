import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // for ValueNotifier and other Flutter basics
import 'package:shared_preferences/shared_preferences.dart';

class CartItem {
  final String productId;
  final String name;
  final double price;
  final double deliveryFee;
  final String imageUrl;
  final String sellerName;
  final String sellerId;
  final String addons;
  int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.deliveryFee,
    required this.imageUrl,
    required this.sellerName,
    required this.sellerId,
    required this.addons,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'price': price,
        'deliveryFee': deliveryFee,
        'imageUrl': imageUrl,
        'sellerName': sellerName,
        'sellerId': sellerId,
        'addons': addons,
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final q = json['quantity'];
    return CartItem(
      productId: json['productId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0,
      imageUrl: json['imageUrl']?.toString() ?? '',
      sellerName: json['sellerName']?.toString() ?? '',
      sellerId: json['sellerId']?.toString() ?? '',
      addons: json['addons']?.toString() ?? '',
      quantity: q is int ? q : int.tryParse('$q') ?? 1,
    );
  }
}

class CartManager {
  static final CartManager instance = CartManager._internal();
  CartManager._internal();

  static const _prefsKey = 'umart_guest_cart_v1';
  static const _prefsTsKey = 'umart_cart_saved_at';

  List<CartItem> items = [];

  //--- NOTIFIER FOR CART ITEM COUNT ---
  final ValueNotifier<int> cartItemCount = ValueNotifier<int>(0);

  User? _prevAuthUser;

  /// Called from [FirebaseAuth.authStateChanges]: first event = cold start,
  /// later events = login / logout transitions.
  Future<void> onAuthEvent(User? user, {required bool isInitial}) async {
    if (isInitial) {
      _prevAuthUser = user;
      if (user != null) {
        await _syncOnColdStart(user.uid);
      }
      return;
    }

    final prev = _prevAuthUser;
    _prevAuthUser = user;

    if (user != null && prev == null) {
      await _syncOnGuestLogin(user.uid);
    }
  }

  /// Load cart from device storage (call once at startup).
  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      items = decoded
          .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      cartItemCount.value = items.length;
    } catch (_) {
      // Keep empty cart if stored data is corrupt.
    }
  }

  /// Writes local cache + Firestore when a user is signed in.
  Future<void> persistCart() async {
    await _persistLocal();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _pushCartToFirestore(user.uid);
    }
  }

  Future<void> _persistLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded =
          jsonEncode(items.map((e) => e.toJson()).toList(growable: false));
      await prefs.setString(_prefsKey, encoded);
      await prefs.setInt(_prefsTsKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  Future<void> _pushCartToFirestore(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'cartItems': items.map((e) => e.toJson()).toList(),
        'cartUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  void addToCart(CartItem item) {
    items.add(item);
    cartItemCount.value = items.length; // shout the new count!
    persistCart();
  }

  void removeFromCart(CartItem item) {
    items.remove(item);
    cartItemCount.value = items.length; // shout the new count!
    persistCart();
  }

  void clearCart() {
    items.clear();
    cartItemCount.value = 0; // shout the new count!
    persistCart();
  }

  double get totalPrice {
    double total = 0;
    for (var item in items) {
      total += (item.price * item.quantity);
    }
    return total;
  }

  // ── Firestore sync strategies ───────────────────────────────────────────

  /// Logged-in app launch: compare local save time vs server `cartUpdatedAt`.
  Future<void> _syncOnColdStart(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localTs = prefs.getInt(_prefsTsKey) ?? 0;

      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      final cloudItems = _parseCartItemsFromDoc(data);

      int cloudMillis = 0;
      final ts = data?['cartUpdatedAt'];
      if (ts is Timestamp) {
        cloudMillis = ts.millisecondsSinceEpoch;
      }

      if (cloudItems.isEmpty && items.isNotEmpty) {
        await persistCart();
        return;
      }
      if (cloudItems.isNotEmpty && items.isEmpty) {
        items = cloudItems;
        cartItemCount.value = items.length;
        await persistCart();
        return;
      }
      if (cloudItems.isEmpty && items.isEmpty) {
        return;
      }

      // Both non-empty: newer source wins (avoids doubling merged carts).
      if (cloudMillis >= localTs) {
        items = cloudItems;
        cartItemCount.value = items.length;
        await persistCart();
      } else {
        await persistCart();
      }
    } catch (_) {}
  }

  /// Guest had local cart, then signed in: merge lines with cloud cart.
  Future<void> _syncOnGuestLogin(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final cloudItems = _parseCartItemsFromDoc(doc.data());
      final merged = _mergeLineItems(items, cloudItems);
      items = merged;
      cartItemCount.value = items.length;
      await persistCart();
    } catch (_) {}
  }

  List<CartItem> _parseCartItemsFromDoc(Map<String, dynamic>? data) {
    if (data == null) return [];
    final raw = data['cartItems'];
    if (raw is! List) return [];
    final out = <CartItem>[];
    for (final e in raw) {
      if (e is Map) {
        try {
          out.add(CartItem.fromJson(Map<String, dynamic>.from(e)));
        } catch (_) {}
      }
    }
    return out;
  }

  static String _lineKey(CartItem i) =>
      '${i.productId}|${i.sellerId}|${i.addons}';

  List<CartItem> _mergeLineItems(List<CartItem> a, List<CartItem> b) {
    final map = <String, CartItem>{};
    void ingest(List<CartItem> list) {
      for (final item in list) {
        final k = _lineKey(item);
        final ex = map[k];
        if (ex == null) {
          map[k] = CartItem(
            productId: item.productId,
            name: item.name,
            price: item.price,
            deliveryFee: item.deliveryFee,
            imageUrl: item.imageUrl,
            sellerName: item.sellerName,
            sellerId: item.sellerId,
            addons: item.addons,
            quantity: item.quantity,
          );
        } else {
          ex.quantity += item.quantity;
        }
      }
    }

    ingest(a);
    ingest(b);
    return map.values.toList();
  }
}
