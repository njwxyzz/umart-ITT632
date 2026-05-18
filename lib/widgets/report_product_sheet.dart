import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const _kPrimary = Color(0xFF4C6B3F);
const _kAccent = Color(0xFFF27B35);

const List<String> kReportReasons = [
  'Scam',
  'Fake Product',
  'Inappropriate Content',
  'Other',
];

/// Opens a bottom sheet for buyers to report a product listing.
Future<void> showReportProductSheet(
  BuildContext context, {
  required String productId,
  required String reportedSellerId,
  String? productName,
}) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please log in to report a product.'),
        backgroundColor: Colors.orange,
      ),
    );
    return Future.value();
  }

  if (user.uid == reportedSellerId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You cannot report your own listing.')),
    );
    return Future.value();
  }

  final trimmedProductId = productId.trim();
  if (trimmedProductId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This product cannot be reported yet. Try again in a moment.'),
        backgroundColor: Colors.orange,
      ),
    );
    return Future.value();
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _ReportProductSheet(
      reporterId: user.uid,
      productId: trimmedProductId,
      reportedSellerId: reportedSellerId,
      productName: productName,
    ),
  );
}

class _ReportProductSheet extends StatefulWidget {
  const _ReportProductSheet({
    required this.reporterId,
    required this.productId,
    required this.reportedSellerId,
    this.productName,
  });

  final String reporterId;
  final String productId;
  final String reportedSellerId;
  final String? productName;

  @override
  State<_ReportProductSheet> createState() => _ReportProductSheetState();
}

class _ReportProductSheetState extends State<_ReportProductSheet> {
  String _selectedReason = kReportReasons.first;
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe the issue so moderators can review it.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'reporterId': widget.reporterId,
        'reportedSellerId': widget.reportedSellerId,
        'productId': widget.productId,
        if ((widget.productName ?? '').trim().isNotEmpty)
          'productName': widget.productName!.trim(),
        'reason': _selectedReason,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted. Our team will review it shortly.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not submit report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _kAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.flag_rounded, color: _kAccent),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Report product',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          Text(
                            'Help keep UMART safe for everyone',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                if ((widget.productName ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.productName!.trim(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Text(
                  'Reason',
                  style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedReason,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF5F7F2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  items: kReportReasons
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          if (value != null) setState(() => _selectedReason = value);
                        },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Description',
                  style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  maxLength: 500,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    hintText: 'Describe what happened or why you are reporting…',
                    filled: true,
                    fillColor: const Color(0xFFF5F7F2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Submit report', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
