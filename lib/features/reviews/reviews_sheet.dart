import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../ui/tokens/app_tokens.dart';

/// Đánh giá do người dùng TripFlow viết (không phải rating seed của catalog).
class PlaceReview {
  const PlaceReview({
    required this.id,
    required this.authorName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.isMine = false,
  });

  final int id;
  final String authorName;
  final int rating;
  final String comment;
  final String createdAt;
  final bool isMine;

  factory PlaceReview.fromJson(Map<String, dynamic> json) => PlaceReview(
        id: (json['id'] as num).toInt(),
        authorName: (json['author_name'] ?? 'Khách').toString(),
        rating: (json['rating'] as num?)?.toInt() ?? 5,
        comment: (json['comment'] ?? '').toString(),
        createdAt: (json['created_at'] ?? '').toString(),
        isMine: json['is_mine'] == true,
      );
}

class ReviewSummary {
  const ReviewSummary({
    this.avgRating,
    this.reviewCount = 0,
    this.distribution = const {},
    this.hiddenGem = false,
  });

  final double? avgRating;
  final int reviewCount;
  final Map<String, int> distribution;
  final bool hiddenGem;
}

class ReviewsApi {
  ReviewsApi({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 20),
            ));

  final Dio _dio;

  Future<List<PlaceReview>> list(String placeKey) async {
    final resp = await _dio.get('/reviews/$placeKey');
    return ((resp.data as List?) ?? const [])
        .map((e) => PlaceReview.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<ReviewSummary> summary(String placeKey) async {
    final data = (await _dio.get('/reviews/$placeKey/summary')).data as Map<String, dynamic>;
    final raw = (data['distribution'] as Map?) ?? const {};
    return ReviewSummary(
      avgRating: (data['avg_rating'] as num?)?.toDouble(),
      reviewCount: (data['review_count'] as num?)?.toInt() ?? 0,
      hiddenGem: data['hidden_gem'] == true,
      distribution: {
        for (final e in raw.entries) e.key.toString(): (e.value as num?)?.toInt() ?? 0,
      },
    );
  }

  Future<void> create(
    String placeKey, {
    required int rating,
    required String comment,
    String? authorName,
  }) async {
    await _dio.post('/reviews/$placeKey', data: {
      'rating': rating,
      'comment': comment,
      if (authorName != null && authorName.trim().isNotEmpty) 'author_name': authorName.trim(),
    });
  }
}

/// Sheet xem + viết đánh giá cho một địa điểm.
class ReviewsSheet extends StatefulWidget {
  const ReviewsSheet({super.key, required this.placeKey, required this.placeName});

  final String placeKey;
  final String placeName;

  @override
  State<ReviewsSheet> createState() => _ReviewsSheetState();
}

class _ReviewsSheetState extends State<ReviewsSheet> {
  final _api = ReviewsApi();
  final _comment = TextEditingController();
  final _name = TextEditingController();

  ReviewSummary _summary = const ReviewSummary();
  List<PlaceReview> _items = const [];
  bool _loading = true;
  bool _sending = false;
  int _myRating = 5;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _comment.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.summary(widget.placeKey),
        _api.list(widget.placeKey),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as ReviewSummary;
        _items = results[1] as List<PlaceReview>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                    color: AppColors.line, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text(widget.placeName, style: AppText.h2),
            const SizedBox(height: 10),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator(color: AppColors.coral)),
              )
            else ...[
              _summaryBlock(),
              const SizedBox(height: 18),
              _composeBlock(),
              const SizedBox(height: 18),
              Text('Nhận xét (${_items.length})', style: AppText.h3),
              const SizedBox(height: 8),
              if (_error != null)
                Text(_error!, style: AppText.bodySm.copyWith(color: AppColors.danger))
              else if (_items.isEmpty)
                Text('Chưa có nhận xét. Hãy là người đầu tiên!',
                    style: AppText.bodySm)
              else
                for (final review in _items) _reviewTile(review),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryBlock() {
    final avg = _summary.avgRating;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(
        children: [
          Text(avg == null ? '—' : avg.toStringAsFixed(1),
              style: AppText.display.copyWith(fontSize: 34)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    for (var i = 1; i <= 5; i++)
                      Icon(
                        i <= (avg ?? 0).round() ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 16,
                        color: const Color(0xFFF5B301),
                      ),
                    const SizedBox(width: 6),
                    Text('${_summary.reviewCount} đánh giá', style: AppText.caption),
                  ],
                ),
                const SizedBox(height: 4),
                if (_summary.hiddenGem)
                  Text('Quán ruột — điểm cao, ít người biết',
                      style: AppText.caption.copyWith(color: AppColors.coral)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _composeBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Viết đánh giá của bạn', style: AppText.label),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 1; i <= 5; i++)
              GestureDetector(
                onTap: () => setState(() => _myRating = i),
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    i <= _myRating ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 30,
                    color: const Color(0xFFF5B301),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _name,
          decoration: const InputDecoration(hintText: 'Tên của bạn (không bắt buộc)'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _comment,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Cảm nhận về quán/địa điểm…'),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: _sending ? null : _submit,
          child: Text(_sending ? 'Đang gửi…' : 'Gửi đánh giá'),
        ),
      ],
    );
  }

  Widget _reviewTile(PlaceReview review) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(review.authorName,
                    style: AppText.label.copyWith(color: AppColors.textPrimary)),
                if (review.isMine) ...[
                  const SizedBox(width: 6),
                  Text('(của bạn)', style: AppText.caption.copyWith(color: AppColors.coral)),
                ],
                const Spacer(),
                for (var i = 1; i <= 5; i++)
                  Icon(
                    i <= review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 13,
                    color: const Color(0xFFF5B301),
                  ),
              ],
            ),
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(review.comment, style: AppText.bodySm),
            ],
          ],
        ),
      );

  Future<void> _submit() async {
    if (_comment.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhận xét cần ít nhất 3 ký tự.')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await _api.create(
        widget.placeKey,
        rating: _myRating,
        comment: _comment.text.trim(),
        authorName: _name.text,
      );
      _comment.clear();
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã gửi đánh giá.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Không gửi được: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}
