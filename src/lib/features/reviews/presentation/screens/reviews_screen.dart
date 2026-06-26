// =============================================================
// FILE: lib/features/reviews/presentation/screens/reviews_screen.dart
// =============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  int _selectedRating = 0;
  final _reviewCtrl = TextEditingController();
  bool _submitted = false;

  final List<Map<String, dynamic>> _reviews = [
    {
      'name': 'Chisomo Banda', 'rating': 5, 'date': 'Jun 10, 2026',
      'comment': 'Excellent quality! The shirt fits perfectly and the material is great.',
      'verified': true,
    },
    {
      'name': 'Tadala Phiri', 'rating': 4, 'date': 'Jun 8, 2026',
      'comment': 'Good product, delivery was fast. Would recommend to others.',
      'verified': true,
    },
    {
      'name': 'Kondwani Mwale', 'rating': 5, 'date': 'Jun 5, 2026',
      'comment': 'Amazing! Exactly as described. Very happy with my purchase.',
      'verified': false,
    },
    {
      'name': 'Mphatso Chirwa', 'rating': 3, 'date': 'Jun 1, 2026',
      'comment': 'Decent product but took longer than expected to arrive.',
      'verified': true,
    },
  ];

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  double get _averageRating {
    if (_reviews.isEmpty) return 0;
    return _reviews.fold(0.0, (sum, r) => sum + r['rating']) / _reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Reviews & Ratings',
          style: GoogleFonts.dmSans(
            color: Colors.black, fontSize: 16,
            fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Rating summary
          _ratingSummary(),
          const SizedBox(height: 20),

          // Write review
          if (!_submitted) ...[
            _writeReview(),
            const SizedBox(height: 20),
          ],

          // Reviews list
          Text('Customer Reviews (${_reviews.length})',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ..._reviews.map((r) => _reviewCard(r)),
        ]),
      ),
    );
  }

  Widget _ratingSummary() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.borderColor)),
    child: Row(children: [
      // Big rating number
      Column(children: [
        Text(_averageRating.toStringAsFixed(1),
          style: GoogleFonts.playfairDisplay(
            fontSize: 48, fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary)),
        Row(children: List.generate(5, (i) => Icon(
          i < _averageRating.floor()
              ? Icons.star : Icons.star_border,
          size: 16, color: const Color(0xFFFFA500)))),
        const SizedBox(height: 4),
        Text('${_reviews.length} reviews',
          style: GoogleFonts.dmSans(
            color: AppTheme.textHint, fontSize: 12)),
      ]),
      const SizedBox(width: 24),
      // Rating bars
      Expanded(child: Column(
        children: [5, 4, 3, 2, 1].map((star) {
          final count = _reviews.where(
              (r) => r['rating'] == star).length;
          final pct = _reviews.isEmpty
              ? 0.0 : count / _reviews.length;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              Text('$star',
                style: GoogleFonts.dmSans(
                  fontSize: 12, color: AppTheme.textHint)),
              const SizedBox(width: 4),
              const Icon(Icons.star,
                size: 12, color: Color(0xFFFFA500)),
              const SizedBox(width: 6),
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: const Color(0xFFF4F4F2),
                  valueColor: const AlwaysStoppedAnimation(
                    Color(0xFFFFA500)),
                  minHeight: 8))),
              const SizedBox(width: 6),
              Text('$count',
                style: GoogleFonts.dmSans(
                  fontSize: 12, color: AppTheme.textHint)),
            ]),
          );
        }).toList(),
      )),
    ]),
  );

  Widget _writeReview() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.borderColor)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Write a Review',
        style: GoogleFonts.dmSans(
          fontWeight: FontWeight.w700, fontSize: 16)),
      const SizedBox(height: 12),
      Text('Your Rating',
        style: GoogleFonts.dmSans(
          fontSize: 13, color: AppTheme.textSecondary)),
      const SizedBox(height: 8),
      Row(children: List.generate(5, (i) => GestureDetector(
        onTap: () => setState(() => _selectedRating = i + 1),
        child: Icon(
          i < _selectedRating ? Icons.star : Icons.star_border,
          size: 36,
          color: const Color(0xFFFFA500)),
      ))),
      const SizedBox(height: 16),
      TextField(
        controller: _reviewCtrl,
        maxLines: 4,
        decoration: InputDecoration(
          hintText: 'Share your experience with this product...',
          hintStyle: GoogleFonts.dmSans(
            color: AppTheme.textHint, fontSize: 13),
          filled: true,
          fillColor: const Color(0xFFF4F4F2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppTheme.primaryRed, width: 1.5))),
      ),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: () {
          if (_selectedRating == 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select a rating')));
            return;
          }
          if (_reviewCtrl.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please write a review')));
            return;
          }
          setState(() {
            _reviews.insert(0, {
              'name': 'You', 'rating': _selectedRating,
              'date': 'Just now',
              'comment': _reviewCtrl.text.trim(),
              'verified': true,
            });
            _submitted = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Review submitted! Thank you 🙏'),
            backgroundColor: Colors.green.shade700));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryRed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10))),
        child: Text('Submit Review',
          style: GoogleFonts.dmSans(
            color: Colors.white, fontWeight: FontWeight.w700)),
      )),
    ]),
  );

  Widget _reviewCard(Map<String, dynamic> review) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.borderColor)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryRed.withOpacity(0.1),
            shape: BoxShape.circle),
          child: Center(child: Text(
            review['name'].substring(0, 1),
            style: GoogleFonts.dmSans(
              color: AppTheme.primaryRed,
              fontWeight: FontWeight.w700, fontSize: 16)))),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(review['name'],
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700, fontSize: 14)),
              if (review['verified']) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10)),
                  child: Text('Verified',
                    style: GoogleFonts.dmSans(
                      color: Colors.green.shade700,
                      fontSize: 10, fontWeight: FontWeight.w600))),
              ],
            ]),
            Text(review['date'],
              style: GoogleFonts.dmSans(
                color: AppTheme.textHint, fontSize: 11)),
          ],
        )),
        Row(children: List.generate(5, (i) => Icon(
          i < review['rating'] ? Icons.star : Icons.star_border,
          size: 14, color: const Color(0xFFFFA500)))),
      ]),
      const SizedBox(height: 10),
      Text(review['comment'],
        style: GoogleFonts.dmSans(
          fontSize: 13, color: AppTheme.textSecondary,
          height: 1.5)),
    ]),
  );
}
