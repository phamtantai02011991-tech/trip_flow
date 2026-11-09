import 'package:flutter/material.dart';

import '../../core/utils/app_state.dart';
import '../../core/utils/data_models.dart';
import '../../core/utils/vietnamese_utils.dart';
import '../../ui/tokens/app_tokens.dart';
import '../destinations/destination_detail_screen.dart';
import '../restaurants/restaurant_detail_screen.dart';

/// Tìm kiếm hợp nhất: địa điểm du lịch + quán ăn/cà phê + đặc sản.
class GlobalSearchScreen extends StatefulWidget {
  final TripFlowAppState appState;

  const GlobalSearchScreen({super.key, required this.appState});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';
  String _filter = 'all'; // all | destination | restaurant | food

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _matchesAny(List<String> values) {
    final q = _query.trim();
    if (q.isEmpty) return false;
    return values.any((v) => VietnameseUtils.matches(v, q));
  }

  List<_SearchItem> _results() {
    final q = _query.trim();
    if (q.isEmpty) {
      // Gợi ý mặc định: điểm nổi bật + quán có ảnh.
      final featured = widget.appState.allDestinations
          .where((d) => d.isFeatured)
          .take(8)
          .map((d) => _SearchItem.destination(d));
      final foods = widget.appState.allRestaurants
          .where((r) => r.thumbnailUrl != null && r.thumbnailUrl!.isNotEmpty)
          .take(6)
          .map((r) => _SearchItem.restaurant(r));
      return [...featured, ...foods];
    }

    final items = <_SearchItem>[];
    if (_filter == 'all' || _filter == 'destination') {
      for (final d in widget.appState.allDestinations) {
        if (_matchesAny([d.name, d.address, d.description, d.categoryName])) {
          items.add(_SearchItem.destination(d));
        }
      }
    }
    if (_filter == 'all' || _filter == 'restaurant') {
      for (final r in widget.appState.allRestaurants) {
        if (_matchesAny([
          r.name,
          r.address,
          r.cuisineType,
          r.specialties,
          r.specialtyDishes,
        ])) {
          items.add(_SearchItem.restaurant(r));
        }
      }
    }
    if (_filter == 'all' || _filter == 'food') {
      for (final f in widget.appState.localFoodsForSelectedProvince) {
        if (_matchesAny([f.name, f.description, f.storyOrigin])) {
          items.add(_SearchItem.food(f));
        }
      }
    }
    return items.take(60).toList();
  }

  void _open(_SearchItem item) {
    switch (item.type) {
      case 'destination':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DestinationDetailScreen(
              destination: item.destination!,
              appState: widget.appState,
            ),
          ),
        );
      case 'restaurant':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RestaurantDetailScreen(
              restaurant: item.restaurant!,
              appState: widget.appState,
            ),
          ),
        );
      default:
        // Món ăn: mở tỉnh tương ứng để xem chi tiết danh sách đặc sản.
        Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = _results();
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF8F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: Color(0xFF0284C7), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.search,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Tìm địa điểm, quán ăn, đặc sản...',
                    hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  ),
                ),
              ),
              if (_query.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _controller.clear();
                    setState(() => _query = '');
                  },
                  child: const Icon(Icons.close_rounded,
                      size: 18, color: Color(0xFF94A3B8)),
                ),
            ],
          ),
        ),
        actions: const [SizedBox(width: 12)],
      ),
      body: Column(
        children: [
          _filterRow(),
          Expanded(
            child: results.isEmpty
                ? _emptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _resultTile(results[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterRow() => SizedBox(
        height: 46,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          children: [
            for (final (code, label) in const [
              ('all', 'Tất cả'),
              ('destination', 'Địa điểm'),
              ('restaurant', 'Quán ăn'),
              ('food', 'Đặc sản'),
            ])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(label),
                  selected: _filter == code,
                  onSelected: (_) => setState(() => _filter = code),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _filter == code ? Colors.white : AppColors.textSecondary,
                  ),
                  selectedColor: const Color(0xFFE05638),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
          ],
        ),
      );

  Widget _resultTile(_SearchItem item) {
    final image = item.imageUrl;
    final subtitle = item.subtitle;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _open(item),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: image.isNotEmpty
                  ? Image.network(
                      image,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(item),
                    )
                  : _imagePlaceholder(item),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder(_SearchItem item) {
    final icon = item.type == 'destination'
        ? Icons.photo_camera_rounded
        : item.type == 'food'
            ? Icons.ramen_dining_rounded
            : Icons.restaurant_rounded;
    final color = item.type == 'destination'
        ? AppColors.kindSight
        : item.type == 'food'
            ? AppColors.kindCafe
            : AppColors.kindFood;
    return Container(
      width: 56,
      height: 56,
      color: color.withValues(alpha: 0.14),
      child: Icon(icon, color: color),
    );
  }

  Widget _emptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded, size: 54, color: Color(0xFFCBD5E1)),
              const SizedBox(height: 12),
              Text(
                _query.isEmpty
                    ? 'Chưa có dữ liệu gợi ý'
                    : 'Không tìm thấy kết quả cho "$_query"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Thử tìm không dấu (ví dụ: "da lat", "bun cha") hoặc chọn tỉnh/thành khác.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      );
}

class _SearchItem {
  final String type;
  final String title;
  final String subtitle;
  final String imageUrl;
  final DestinationModel? destination;
  final RestaurantModel? restaurant;
  final LocalFoodModel? food;

  const _SearchItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.destination,
    this.restaurant,
    this.food,
  });

  factory _SearchItem.destination(DestinationModel d) => _SearchItem(
        type: 'destination',
        title: d.name,
        subtitle: '${d.categoryName} • ${d.provinceName}',
        imageUrl: d.thumbnailUrl,
        destination: d,
      );

  factory _SearchItem.restaurant(RestaurantModel r) => _SearchItem(
        type: 'restaurant',
        title: r.name,
        subtitle: [
          r.cuisineType,
          r.provinceName,
          if (r.reviewsCount > 0) '⭐ ${r.rating}',
        ].where((s) => s.isNotEmpty).join(' • '),
        imageUrl: r.thumbnailUrl ?? '',
        restaurant: r,
      );

  factory _SearchItem.food(LocalFoodModel f) => _SearchItem(
        type: 'food',
        title: f.name,
        subtitle: 'Đặc sản • ${f.provinceName}',
        imageUrl: f.resolvedThumbnailUrl,
        food: f,
      );
}
