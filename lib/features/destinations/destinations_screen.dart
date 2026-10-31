import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_state.dart';
import '../../core/utils/mock_data.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/travel_destination_card.dart';
import 'destination_detail_screen.dart';

/// Màn hình Tìm kiếm và Lọc Địa điểm Du lịch theo Tỉnh/Thành, Danh mục và Từ khóa (Mục 5.1.3).
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
        final kw = _searchController.text.trim().toLowerCase();
        final filtered = widget.appState.destinationsForSelectedProvince.where((d) {
          final matchCat =
              _selectedCategory == 'all' || d.categoryCode == _selectedCategory;
          final matchKw = kw.isEmpty ||
              d.name.toLowerCase().contains(kw) ||
              d.address.toLowerCase().contains(kw) ||
              d.description.toLowerCase().contains(kw);
          return matchCat && matchKw;
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Địa điểm tại ${widget.appState.selectedProvince.name}',
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
                        hintText: 'Tìm tên địa điểm, quận/huyện, từ khóa...',
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

              // Danh sách kết quả hoặc EmptyStateView (TC-09)
              Expanded(
                child: filtered.isEmpty
                    ? EmptyStateView(
                        title: 'Không tìm thấy địa điểm phù hợp',
                        message:
                            'Không có địa điểm nào khớp với từ khóa "${_searchController.text}". Hãy thử từ khóa khác hoặc xóa bộ lọc.',
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
