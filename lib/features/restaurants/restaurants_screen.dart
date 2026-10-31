import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_state.dart';
import '../../core/widgets/common_widgets.dart';
import 'restaurant_detail_screen.dart';

/// Màn hình Danh sách Nhà hàng & Quán ăn chất lượng cao, đánh giá cao và nhiều bình luận thực tế từ Google Maps.
class RestaurantsScreen extends StatefulWidget {
  final TripFlowAppState appState;

  const RestaurantsScreen({super.key, required this.appState});

  @override
  State<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends State<RestaurantsScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'high_rated', 'most_reviewed', 'specialty'

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final list = widget.appState.filterRestaurants(
          query: _searchQuery,
          filterType: _selectedFilter,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Quán ăn ngon tại ${widget.appState.selectedProvince.name}',
            ),
          ),
          body: Column(
            children: [
              // Thanh tìm kiếm
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Tìm quán, món ngon, địa chỉ hoặc trong bình luận...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Thanh Chips lọc nhanh
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    _buildFilterChip('Tất cả', 'all', Icons.restaurant_menu_rounded),
                    const SizedBox(width: 8),
                    _buildFilterChip('⭐ Đánh giá cao (4.5+)', 'high_rated', Icons.star_rounded),
                    const SizedBox(width: 8),
                    _buildFilterChip('🔥 Nhiều bình luận nhất', 'most_reviewed', Icons.chat_bubble_rounded),
                    const SizedBox(width: 8),
                    _buildFilterChip('🍜 Món đặc trưng', 'specialty', Icons.local_fire_department_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Danh sách nhà hàng
              Expanded(
                child: list.isEmpty
                    ? EmptyStateView(
                        title: 'Không tìm thấy quán ăn phù hợp',
                        message: 'Hãy thử đổi từ khóa tìm kiếm hoặc bỏ bớt tiêu chí lọc.',
                        onReset: () {
                          setState(() {
                            _searchQuery = '';
                            _selectedFilter = 'all';
                          });
                        },
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final rest = list[index];
                          final hasSpecialties = rest.specialties.isNotEmpty;
                          final hasReviews = rest.sampleReviews.isNotEmpty;

                          return Card(
                            elevation: 1.5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => RestaurantDetailScreen(
                                      restaurant: rest,
                                      appState: widget.appState,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Hàng trên: Nhãn tài trợ / Quán yêu thích + Rating Badge
                                    Row(
                                      children: [
                                        if (rest.isSponsored) ...[
                                          SponsoredBadgeWidget(label: rest.sponsorLabel),
                                          const SizedBox(width: 6),
                                        ] else if (rest.isHighRated) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade50,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Colors.red.shade200),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.whatshot_rounded, size: 12, color: Colors.red.shade700),
                                                const SizedBox(width: 3),
                                                Text(
                                                  'Quán được yêu thích',
                                                  style: TextStyle(
                                                    color: Colors.red.shade800,
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        const Spacer(),
                                        // Rating Badge cam vàng hổ phách
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEF3C7),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFFFDE68A)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.star_rounded, size: 15, color: Color(0xFFD97706)),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${rest.rating} (${rest.reviewsCount > 999 ? "${(rest.reviewsCount / 1000).toStringAsFixed(1)}k" : rest.reviewsCount})',
                                                style: const TextStyle(
                                                  color: Color(0xFF92400E),
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Tên nhà hàng & nút thêm lịch trình
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            rest.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Thêm vào lịch trình',
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.only(left: 8),
                                          onPressed: () {
                                            widget.appState.addRestaurantToActiveItinerary(rest);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Đã thêm "${rest.name}" vào lịch trình!'),
                                                backgroundColor: AppTheme.primaryTeal,
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.add_circle_outline_rounded,
                                            color: AppTheme.primaryTeal,
                                            size: 26,
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Ẩm thực & Giá
                                    const SizedBox(height: 4),
                                    Text(
                                      '${rest.cuisineType} • ${rest.priceRange}',
                                      style: const TextStyle(
                                        color: AppTheme.primaryDark,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12.5,
                                      ),
                                    ),

                                    // Món đặc trưng nổi bật
                                    if (hasSpecialties) ...[
                                      const SizedBox(height: 5),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '🍜 ',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          Expanded(
                                            child: Text(
                                              rest.specialties,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade800,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],

                                    // Địa chỉ
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Icon(Icons.place_outlined, size: 14, color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            rest.address,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Trích đoạn bình luận thực tế từ Google Maps
                                    if (hasReviews) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.blueGrey.shade50.withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Icon(Icons.format_quote_rounded, size: 15, color: Colors.blueGrey.shade400),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                '"${rest.sampleReviews.first.text}"',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: Colors.blueGrey.shade800,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 14,
        color: isSelected ? Colors.white : AppTheme.primaryTeal,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
      backgroundColor: Colors.grey.shade100,
      selectedColor: AppTheme.primaryTeal,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryTeal : Colors.grey.shade300,
        ),
      ),
      onSelected: (_) {
        setState(() {
          _selectedFilter = value;
        });
      },
    );
  }
}
