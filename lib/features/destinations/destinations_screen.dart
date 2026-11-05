import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_state.dart';
import '../../core/utils/mock_data.dart';
import '../../core/utils/vietnamese_utils.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/travel_destination_card.dart';
import 'destination_detail_screen.dart';

/// Màn hình Tìm kiếm và Lọc Địa điểm Du lịch thông minh Tiếng Việt (có dấu & không dấu)
class DestinationsScreen extends StatefulWidget {
  final TripFlowAppState appState;
  final String initialQuery;
  final String initialCategory;

  const DestinationsScreen({
    super.key,
    required this.appState,
    this.initialQuery = '',
    this.initialCategory = 'all',
  });

  @override
  State<DestinationsScreen> createState() => _DestinationsScreenState();
}

class _DestinationsScreenState extends State<DestinationsScreen> {
  late TextEditingController _searchController;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final kw = _searchController.text.trim();
        final isNational = widget.appState.isNationalMode;

        // Nếu ở chế độ Toàn quốc: tìm kiếm trên toàn bộ điểm đến cả nước
        final baseList = isNational
            ? widget.appState.allDestinations
            : widget.appState.destinationsForSelectedProvince;

        final filtered = baseList.where((d) {
          final matchCat =
              _selectedCategory == 'all' || d.categoryCode == _selectedCategory;
          final matchKw = kw.isEmpty ||
              VietnameseUtils.matches(d.name, kw) ||
              VietnameseUtils.matches(d.address, kw) ||
              VietnameseUtils.matches(d.description, kw);
          return matchCat && matchKw;
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(
              isNational
                  ? 'Tìm Kiếm Điểm Đến Toàn Quốc 🇻🇳'
                  : 'Địa điểm tại ${widget.appState.selectedProvince.name}',
            ),
          ),
          body: Column(
            children: [
              // Thanh tìm kiếm và lọc danh mục
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: isNational
                            ? 'Tìm tên địa danh, tỉnh thành (Đà Lạt, Hà Nội, Sài Gòn...)'
                            : 'Tìm địa điểm tại ${widget.appState.selectedProvince.name}...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.clear_rounded),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: MockDataRepository.categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final cat = MockDataRepository.categories[index];
                          final code = cat['code']!;
                          final isSelected = _selectedCategory == code;
                          return ChoiceChip(
                            label: Text(cat['name']!),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() => _selectedCategory = code);
                            },
                            selectedColor: AppTheme.primaryTeal,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF334155),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Danh sách kết quả hoặc EmptyStateView
              Expanded(
                child: filtered.isEmpty
                    ? EmptyStateView(
                        title: 'Không tìm thấy địa điểm phù hợp',
                        message:
                            'Không có địa điểm nào khớp với từ khóa "${_searchController.text}". Bạn có thể gõ có dấu hoặc không dấu (ví dụ: "da lat", "sai gon", "ha noi").',
                        onReset: () {
                          setState(() {
                            _searchController.clear();
                            _selectedCategory = 'all';
                          });
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final dest = filtered[index];
                          return TravelDestinationCard(
                            destination: dest,
                            appState: widget.appState,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => DestinationDetailScreen(
                                    destination: dest,
                                    appState: widget.appState,
                                  ),
                                ),
                              );
                            },
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
}
