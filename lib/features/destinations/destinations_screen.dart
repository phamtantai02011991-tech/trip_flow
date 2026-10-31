import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_state.dart';
import '../../core/utils/mock_data.dart';
import '../../core/widgets/common_widgets.dart';
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
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final dest = filtered[index];
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
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
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFCCFBF1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          dest.categoryName,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.primaryDark,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (dest.isSponsored)
                                        SponsoredBadgeWidget(
                                          label: dest.sponsorLabel,
                                        ),
                                      const Spacer(),
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 16,
                                        color: Colors.amber,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        dest.rating.toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    dest.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dest.address,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    dest.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Nguồn: ${dest.dataSource == "partner" ? "Đối tác" : "Nội bộ xác thực"} • Cập nhật: ${dest.updatedAt}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () {
                                          widget.appState
                                              .addDestinationToActiveItinerary(
                                            dest,
                                          );
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Đã thêm "${dest.name}" vào lịch trình!',
                                              ),
                                              backgroundColor:
                                                  AppTheme.primaryTeal,
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.add_circle_outline_rounded,
                                          size: 16,
                                        ),
                                        label: const Text(
                                          'Thêm lịch trình',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
}
