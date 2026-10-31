import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_state.dart';
import '../../core/widgets/common_widgets.dart';
import '../restaurants/restaurant_detail_screen.dart';
import '../restaurants/restaurants_screen.dart';

/// Tab 4: Màn hình Ẩm thực — Đặc sản địa phương & Nhà hàng gợi ý (Mục 5.1.5 & Mục 5.2).
/// Cho phép xem đầy đủ:
/// - Câu chuyện nguồn gốc món ăn đặc sản
/// - Nguồn dữ liệu, bản quyền, thời điểm cập nhật lần cuối
/// - Danh sách nhà hàng gợi ý thưởng thức cho từng món ăn.
class LocalFoodsScreen extends StatefulWidget {
  final TripFlowAppState appState;

  const LocalFoodsScreen({super.key, required this.appState});

  @override
  State<LocalFoodsScreen> createState() => _LocalFoodsScreenState();
}

class _LocalFoodsScreenState extends State<LocalFoodsScreen> {
  bool _showRestaurantsTab = false;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final kw = _searchQuery.trim().toLowerCase();
        final foods = widget.appState.localFoodsForSelectedProvince.where((f) {
          if (kw.isEmpty) return true;
          return f.name.toLowerCase().contains(kw) ||
              f.description.toLowerCase().contains(kw) ||
              f.storyOrigin.toLowerCase().contains(kw);
        }).toList();

        final restaurants =
            widget.appState.restaurantsForSelectedProvince.where((r) {
          if (kw.isEmpty) return true;
          return r.name.toLowerCase().contains(kw) ||
              r.cuisineType.toLowerCase().contains(kw) ||
              r.specialtyDishes.toLowerCase().contains(kw) ||
              r.address.toLowerCase().contains(kw);
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Ẩm thực & Đặc sản • ${widget.appState.selectedProvince.name}',
            ),
            actions: [
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          RestaurantsScreen(appState: widget.appState),
                    ),
                  );
                },
                icon: const Icon(Icons.storefront_outlined, size: 18),
                label: const Text('Tất cả quán'),
              ),
            ],
          ),
          body: Column(
            children: [
              // Thanh chuyển đổi Đặc sản / Nhà hàng + Tìm kiếm
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: Text('Đặc sản địa phương (${foods.length})'),
                            selected: !_showRestaurantsTab,
                            selectedColor: AppTheme.primaryTeal,
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: !_showRestaurantsTab
                                  ? Colors.white
                                  : const Color(0xFF334155),
                            ),
                            onSelected: (_) {
                              setState(() => _showRestaurantsTab = false);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            label: Text(
                              'Nhà hàng / Quán ăn (${restaurants.length})',
                            ),
                            selected: _showRestaurantsTab,
                            selectedColor: AppTheme.primaryTeal,
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _showRestaurantsTab
                                  ? Colors.white
                                  : const Color(0xFF334155),
                            ),
                            onSelected: (_) {
                              setState(() => _showRestaurantsTab = true);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: const InputDecoration(
                        hintText:
                            'Tìm món ăn (Cơm tấm, Bánh mì, Phở...) hoặc tên quán...',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: !_showRestaurantsTab
                    ? _buildLocalFoodsList(context, foods)
                    : _buildRestaurantsList(context, restaurants),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocalFoodsList(BuildContext context, List foods) {
    if (foods.isEmpty) {
      return EmptyStateView(
        title: 'Không tìm thấy món ăn đặc sản',
        message: 'Hãy thử tìm với từ khóa khác.',
        onReset: () => setState(() => _searchQuery = ''),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: foods.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final food = foods[index];
        final isFav = widget.appState.isFoodFavorite(food.id);
        final recommendedRests = widget.appState.allRestaurants
            .where((r) => food.recommendedRestaurantIds.contains(r.id))
            .toList();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      food.avgPriceRange,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      widget.appState.toggleFoodFavorite(food.id);
                    },
                    icon: Icon(
                      isFav
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFav ? Colors.redAccent : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Text(
                food.name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                food.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF334155),
                  height: 1.4,
                ),
              ),
              if (food.storyOrigin.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Text(
                    'Câu chuyện ẩm thực: ${food.storyOrigin}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF78350F),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                'Thời điểm thưởng thức: ${food.bestSeasonOrTime}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Nguồn dữ liệu: ${food.licenseInfo} • Cập nhật: ${food.updatedAt}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
              if (recommendedRests.isNotEmpty) ...[
                const Divider(height: 20),
                const Text(
                  'Địa chỉ thưởng thức uy tín gợi ý:',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: recommendedRests.map((rest) {
                    return ActionChip(
                      avatar: const Icon(
                        Icons.restaurant_rounded,
                        size: 15,
                        color: AppTheme.primaryTeal,
                      ),
                      label: Text(
                        rest.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RestaurantDetailScreen(
                              restaurant: rest,
                              appState: widget.appState,
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildRestaurantsList(BuildContext context, List restaurants) {
    if (restaurants.isEmpty) {
      return EmptyStateView(
        title: 'Không tìm thấy nhà hàng phù hợp',
        message: 'Hãy thử từ khóa khác.',
        onReset: () => setState(() => _searchQuery = ''),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: restaurants.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final rest = restaurants[index];
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(14),
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
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (rest.isSponsored) ...[
                  SponsoredBadgeWidget(label: rest.sponsorLabel),
                  const SizedBox(height: 6),
                ],
                Text(
                  rest.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${rest.cuisineType} • ${rest.priceRange} • ⭐ ${rest.rating}',
                    style: const TextStyle(
                      color: AppTheme.primaryDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(rest.address, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    'Giờ mở cửa: ${rest.openingHours} • Cập nhật lần cuối: ${rest.lastUpdatedAt}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            trailing: IconButton(
              tooltip: 'Thêm vào lịch trình',
              onPressed: () {
                widget.appState.addRestaurantToActiveItinerary(rest);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Đã thêm "${rest.name}" vào lịch trình!',
                    ),
                    backgroundColor: AppTheme.primaryTeal,
                  ),
                );
              },
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                color: AppTheme.primaryTeal,
              ),
            ),
          ),
        );
      },
    );
  }
}
