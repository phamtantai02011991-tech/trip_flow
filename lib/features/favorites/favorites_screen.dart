import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_state.dart';
import '../../core/widgets/common_widgets.dart';
import '../destinations/destination_detail_screen.dart';
import '../restaurants/restaurant_detail_screen.dart';

/// Màn hình Danh sách Yêu thích của người dùng (Mục 5.1.10).
class FavoritesScreen extends StatelessWidget {
  final TripFlowAppState appState;

  const FavoritesScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final favDestinations = appState.allDestinations
            .where((d) => appState.favoriteDestinationIds.contains(d.id))
            .toList();
        final favRestaurants = appState.allRestaurants
            .where((r) => appState.favoriteRestaurantIds.contains(r.id))
            .toList();
        final favFoods = appState.allLocalFoods
            .where((f) => appState.favoriteFoodIds.contains(f.id))
            .toList();

        final isEmpty = favDestinations.isEmpty &&
            favRestaurants.isEmpty &&
            favFoods.isEmpty;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Danh Sách Yêu Thích (${appState.totalFavoritesCount})',
            ),
          ),
          body: isEmpty
              ? const EmptyStateView(
                  title: 'Danh sách yêu thích đang trống',
                  message:
                      'Hãy bấm biểu tượng trái tim trên các Địa điểm, Món ăn hoặc Nhà hàng để lưu lại.',
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (favDestinations.isNotEmpty) ...[
                      const Text(
                        'Địa điểm Du lịch đã lưu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...favDestinations.map(
                        (d) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => DestinationDetailScreen(
                                    destination: d,
                                    appState: appState,
                                  ),
                                ),
                              );
                            },
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFCCFBF1),
                              child: Icon(
                                Icons.place_rounded,
                                color: AppTheme.primaryTeal,
                              ),
                            ),
                            title: Text(
                              d.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              '${d.provinceName} • ⭐ ${d.rating}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: IconButton(
                              onPressed: () {
                                appState.toggleDestinationFavorite(d.id);
                              },
                              icon: const Icon(
                                Icons.favorite_rounded,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (favRestaurants.isNotEmpty) ...[
                      const Text(
                        'Nhà hàng & Quán ăn đã lưu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...favRestaurants.map(
                        (r) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => RestaurantDetailScreen(
                                    restaurant: r,
                                    appState: appState,
                                  ),
                                ),
                              );
                            },
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFFEF3C7),
                              child: Icon(
                                Icons.restaurant_rounded,
                                color: Color(0xFFD97706),
                              ),
                            ),
                            title: Text(
                              r.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              '${r.cuisineType} • ${r.priceRange}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: IconButton(
                              onPressed: () {
                                appState.toggleRestaurantFavorite(r.id);
                              },
                              icon: const Icon(
                                Icons.favorite_rounded,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (favFoods.isNotEmpty) ...[
                      const Text(
                        'Món ăn Đặc sản đã lưu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...favFoods.map(
                        (f) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFFFFBEB),
                              child: Icon(
                                Icons.ramen_dining_rounded,
                                color: Color(0xFFD97706),
                              ),
                            ),
                            title: Text(
                              f.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              f.avgPriceRange,
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: IconButton(
                              onPressed: () {
                                appState.toggleFoodFavorite(f.id);
                              },
                              icon: const Icon(
                                Icons.favorite_rounded,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }
}
