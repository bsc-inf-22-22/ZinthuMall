// =============================================================
// FILE: lib/features/reviews/presentation/screens/reviews_screen.dart
//
// "My Reviews". When opened from a delivered order, the products
// in that order are listed at the top so they can be reviewed.
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/providers/customer_data_providers.dart';
import '../../../../core/providers/customer_session_provider.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/async_states.dart';

class ReviewsScreen extends ConsumerWidget {
  /// Items from a delivered order (`productId`, `productName`), if any.
  final List<Map<String, dynamic>> toReview;
  const ReviewsScreen({super.key, this.toReview = const []});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(customerSessionProvider) != null;
    final reviews = ref.watch(myReviewsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('My Reviews',
            style: GoogleFonts.dmSans(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: !loggedIn
          ? const SignInPrompt(message: 'Sign in to see and write reviews.')
          : reviews.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(myReviewsProvider)),
              data: (list) {
                final reviewedIds = list.map((r) => r['productId']).toSet();
                final pending = toReview.where((i) => !reviewedIds.contains(i['productId'])).toList();
                if (list.isEmpty && pending.isEmpty) {
                  return const EmptyView(
                    emoji: '⭐',
                    title: 'No reviews yet',
                    message: 'After an order is delivered you can review the products from "My Orders".',
                  );
                }
                return ListView(padding: const EdgeInsets.all(16), children: [
                  if (pending.isNotEmpty) ...[
                    Text('Review your purchase',
                        style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    for (final item in pending)
                      Card(
                        elevation: 0,
                        child: ListTile(
                          title: Text(item['productName'] as String, style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                          trailing: TextButton(
                            onPressed: () => _writeReview(context, ref, item['productId'] as int, item['productName'] as String),
                            child: const Text('Write review'),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                  for (final r in list) _ReviewCard(review: r),
                ]);
              },
            ),
    );
  }

  void _writeReview(BuildContext context, WidgetRef ref, int productId, String productName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => WriteReviewSheet(productId: productId, productName: productName),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final rating = review['rating'] as int;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppTheme.radiusMD)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(review['productName'] as String, style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Row(children: [
          for (var i = 1; i <= 5; i++)
            Icon(i <= rating ? Icons.star : Icons.star_border, size: 16, color: AppTheme.accentOrange),
          const SizedBox(width: 8),
          Text(formatDate(review['createdAt'] as String?), style: GoogleFonts.dmSans(color: AppTheme.textHint, fontSize: 12)),
        ]),
        if ((review['comment'] as String?)?.isNotEmpty ?? false) ...[
          const SizedBox(height: 8),
          Text(review['comment'] as String, style: GoogleFonts.dmSans(color: AppTheme.textSecondary)),
        ],
      ]),
    );
  }
}

/// Bottom sheet for writing a review. Also used from the product page.
class WriteReviewSheet extends ConsumerStatefulWidget {
  final int productId;
  final String productName;
  const WriteReviewSheet({super.key, required this.productId, required this.productName});

  @override
  ConsumerState<WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends ConsumerState<WriteReviewSheet> {
  int _rating = 5;
  final _comment = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await ApiService().createReview(productId: widget.productId, rating: _rating, comment: _comment.text);
      ref.invalidate(myReviewsProvider);
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you for your review!')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Review ${widget.productName}',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 1; i <= 5; i++)
              IconButton(
                tooltip: '$i star${i == 1 ? '' : 's'}',
                onPressed: () => setState(() => _rating = i),
                icon: Icon(i <= _rating ? Icons.star : Icons.star_border, color: AppTheme.accentOrange, size: 32),
              ),
          ]),
          const SizedBox(height: 8),
          TextField(
            controller: _comment,
            maxLines: 4,
            maxLength: 2000,
            decoration: InputDecoration(
              hintText: 'What did you think? (optional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Submit Review'),
          ),
        ]),
      );
}
