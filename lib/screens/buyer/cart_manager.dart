import 'package:flutter/material.dart'; // for ValueNotifier and other Flutter basics

class CartItem {
  final String name;
  final double price; 
  final String imageUrl;
  final String sellerName;
  final String addons;
  int quantity;

  CartItem({
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.sellerName,
    required this.addons,
    required this.quantity,
  });
}

class CartManager {
  static final CartManager instance = CartManager._internal();
  CartManager._internal();

  List<CartItem> items = [];
  
  //--- NOTIFIER FOR CART ITEM COUNT ---
  final ValueNotifier<int> cartItemCount = ValueNotifier<int>(0);

  void addToCart(CartItem item) {
    items.add(item);
    cartItemCount.value = items.length; // shout the new count!
  }

  void removeFromCart(CartItem item) {
    items.remove(item);
    cartItemCount.value = items.length; // shout the new count!
  }

  void clearCart() {
    items.clear();
    cartItemCount.value = 0; // shout the new count!
  }

  double get totalPrice {
    double total = 0;
    for (var item in items) {
      total += (item.price * item.quantity);
    }
    return total;
  }
}