import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

const kPrimary = Color(0xFF4C6B3F);
const kAccent = Color(0xFFF27B35);
const kBg = Color(0xFFF5F7F2);
const kWhite = Colors.white;

class SellerEditShopPage extends StatefulWidget {
  const SellerEditShopPage({super.key});

  @override
  State<SellerEditShopPage> createState() => _SellerEditShopPageState();
}

class _SellerEditShopPageState extends State<SellerEditShopPage> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _locCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();

  static const List<String> _categories = [
    'Food & Beverages',
    'Preloved Items',
    'Printing Services',
    'Others',
  ];

  String? _category;
  Uint8List? _newImageBytes;
  String? _existingPhotoUrl;
  String _originalStoreName = '';
  bool _loading = true;
  bool _saving = false;
  bool _missingStoreDoc = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadStore();
  }

  Future<void> _loadStore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('stores').doc(uid).get();
      if (!mounted) return;
      final d = doc.data();
      if (!doc.exists || d == null) {
        setState(() {
          _missingStoreDoc = true;
          _loading = false;
        });
        return;
      }
      _originalStoreName = (d['storeName'] ?? '').toString().trim();
      _nameCtrl.text = _originalStoreName;
      _locCtrl.text = (d['storeLocation'] ?? '').toString();
      _descCtrl.text = (d['description'] ?? '').toString();
      final cat = (d['category'] ?? 'Others').toString();
      _category = _categories.contains(cat) ? cat : 'Others';
      final url = (d['storePhotoUrl'] ?? '').toString().trim();
      _existingPhotoUrl = url.isEmpty ? null : url;
      setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 78);
      if (f == null) return;
      final bytes = await f.readAsBytes();
      setState(() => _newImageBytes = bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not pick image: $e')));
      }
    }
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shop name is required.')));
      return;
    }

    setState(() => _saving = true);
    try {
      String photoUrl = _existingPhotoUrl ?? '';

      if (_newImageBytes != null) {
        final ref = FirebaseStorage.instance.ref().child('store_images/$uid.jpg');
        final snap = await ref.putData(_newImageBytes!);
        photoUrl = await snap.ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('stores').doc(uid).update({
        'storeName': name,
        'storeLocation': _locCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'category': _category ?? 'Others',
        if (photoUrl.isNotEmpty) 'storePhotoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (_originalStoreName != name) {
        final products =
            await FirebaseFirestore.instance.collection('products').where('sellerId', isEqualTo: uid).get();
        if (products.docs.isNotEmpty) {
          final batch = FirebaseFirestore.instance.batch();
          for (final doc in products.docs) {
            batch.update(doc.reference, {'sellerName': name});
          }
          await batch.commit();
        }
      }
      _originalStoreName = name;
      _existingPhotoUrl = photoUrl.isNotEmpty ? photoUrl : _existingPhotoUrl;
      _newImageBytes = null;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shop profile saved'), backgroundColor: kPrimary),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (_loading) {
      return Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: kBg,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1A2E), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Edit Shop', style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold)),
        ),
        body: const Center(child: CircularProgressIndicator(color: kPrimary)),
      );
    }

    if (uid == null) {
      return Scaffold(
        backgroundColor: kBg,
        body: const Center(child: Text('Please sign in.')),
      );
    }

    if (_missingStoreDoc) {
      return Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: kBg,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1A2E), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Edit Shop', style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No shop profile found. Complete seller registration first.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1A2E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Shop', style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg_pattern.jpg'),
            repeat: ImageRepeat.repeat,
            opacity: 0.05,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      ClipOval(
                        child: _newImageBytes != null
                            ? Image.memory(_newImageBytes!, width: 104, height: 104, fit: BoxFit.cover)
                            : (_existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty)
                                ? Image.network(
                                    _existingPhotoUrl!,
                                    width: 104,
                                    height: 104,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _placeholderAvatar(),
                                  )
                                : _placeholderAvatar(),
                      ),
                      Positioned(
                        right: -4,
                        bottom: -2,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: kAccent,
                          child: const Icon(Icons.camera_alt_rounded, color: kWhite, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Tap photo to upload shop image',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(height: 28),
              _label('Shop name'),
              _field(controller: _nameCtrl, hint: 'Storefront name buyers see', icon: Icons.store_rounded),
              _label('Location / kolej'),
              _field(controller: _locCtrl, hint: 'e.g. Kolej Dahlia, Bilik 204', icon: Icons.place_rounded),
              _label('Category'),
              Container(
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  value: _category,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.category_rounded, color: Colors.grey.shade400, size: 22),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  dropdownColor: kWhite,
                  borderRadius: BorderRadius.circular(16),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.w600))))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v),
                ),
              ),
              _label('Short description'),
              _field(
                controller: _descCtrl,
                hint: 'What you sell, pickup hours...',
                icon: Icons.edit_note_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: kWhite,
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: kWhite, strokeWidth: 2),
                        )
                      : const Text('Save changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderAvatar() {
    return Container(
      width: 104,
      height: 104,
      color: kPrimary.withOpacity(0.12),
      child: Icon(Icons.storefront_rounded, color: kPrimary.withOpacity(0.45), size: 48),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 18),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1A1A2E),
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
