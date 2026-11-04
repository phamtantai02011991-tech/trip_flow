import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_state.dart';

/// Màn hình Danh sách 10 Tỉnh / Thành phố Du lịch Trọng điểm Việt Nam (Mục 5.1.2).
/// Hỗ trợ:
/// - Thẻ Tổng quan Bản đồ Du lịch Việt Nam (10 Tỉnh/Thành phố • 4 Vùng miền)
/// - Tìm kiếm nhanh Tỉnh/Thành phố theo tên, mã tỉnh, thành phố du lịch (Sa Pa, Hạ Long, Hội An, Nha Trang, Đà Lạt, Phú Quốc...)
/// - Lọc theo 4 Vùng miền: `Tất cả`, `Bắc Bộ`, `Trung Bộ`, `Tây Nguyên`, `Nam Bộ`.
class ProvincesScreen extends StatefulWidget {
  final TripFlowAppState appState;

  const ProvincesScreen({super.key, required this.appState});

  @override
  State<ProvincesScreen> createState() => _ProvincesScreenState();
}

class _ProvincesScreenState extends State<ProvincesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRegion = 'Tất cả';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _countByRegion(String region) {
    if (region == 'Tất cả') {
      return widget.appState.provinces.length;
    }
    return widget.appState.provinces.where((p) => p.region == region).length;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final allProvinces = widget.appState.provinces;
        final filteredProvinces = widget.appState.filterProvinces(
          region: _selectedRegion,
          query: _searchQuery,
        );

        final totalDestinations = allProvinces.fold<int>(
          0,
          (sum, p) => sum + p.destinationCount,
        );
        final totalFoods = allProvinces.fold<int>(
          0,
          (sum, p) => sum + p.foodCount,
        );
        final totalRestaurants = allProvinces.fold<int>(
          0,
          (sum, p) => sum + p.restaurantCount,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Chọn Tỉnh / Thành Phố Khám Phá'),
          ),
          body: Column(
            children: [
              // 1. Banner Tổng quan Du lịch Việt Nam + Ô tìm kiếm + Chip lọc vùng miền
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thẻ tổng quan Du lịch Việt Nam
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D9488), Color(0xFF115E59)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.travel_explore_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Bản đồ Du lịch Việt Nam • ${allProvinces.length} Tỉnh/Thành phố • 4 Vùng miền',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tổng cộng $totalDestinations Địa điểm • $totalFoods Đặc sản • $totalRestaurants Nhà hàng dọc lộ trình',
                            style: const TextStyle(
                              color: Color(0xFFCCFBF1),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Ô tìm kiếm Tỉnh/Thành phố
                    TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText:
                            'Tìm tỉnh/thành (VD: Đà Lạt, Phú Quốc, Hạ Long, Sa Pa, Huế...)',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF64748B),
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                                icon: const Icon(Icons.clear_rounded, size: 18),
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Thanh ChoiceChip lọc theo 4 Vùng miền
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.appState.availableRegions.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final region = widget.appState.availableRegions[idx];
                          final isSelected = _selectedRegion == region;
                          final count = _countByRegion(region);

                          return ChoiceChip(
                            label: Text('$region ($count)'),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() {
                                _selectedRegion = region;
                              });
                            },
                            selectedColor: AppTheme.primaryTeal.withValues(
                              alpha: 0.16,
                            ),
                            labelStyle: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? AppTheme.primaryDark
                                  : const Color(0xFF475569),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Thẻ Toàn Quốc 🇻🇳 Đặc Biệt (Chế độ Toàn quốc)
              if (_selectedRegion == 'Tất cả' && _searchQuery.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      widget.appState.selectNational();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: widget.appState.isNationalMode
                              ? const Color(0xFFFF4B55)
                              : const Color(0xFF334155),
                          width: widget.appState.isNationalMode ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF0F172A).withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF4B55)
                                  .withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.public_rounded,
                              color: Color(0xFFFF4B55),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Toàn quốc 🇻🇳 — Khám Phá Việt Nam',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (widget.appState.isNationalMode) ...[
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        size: 16,
                                        color: Color(0xFF10B981),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Tổng quan 63 tỉnh thành • Danh thắng 3 miền Bắc - Trung - Nam',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 3. Danh sách Tỉnh/Thành phố sau khi lọc
              Expanded(
                child: filteredProvinces.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_off_outlined,
                                size: 48,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Không tìm thấy tỉnh/thành phù hợp với từ khóa "$_searchQuery"',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                    _selectedRegion = 'Tất cả';
                                  });
                                },
                                child: const Text('Hiển thị lại tất cả 10 tỉnh/thành'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredProvinces.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final prov = filteredProvinces[index];
                          final isSelected =
                              prov.id == widget.appState.selectedProvince.id;

                          return InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              widget.appState.selectProvince(prov);
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryTeal
                                      : const Color(0xFFE2E8F0),
                                  width: isSelected ? 2.2 : 1.0,
                                ),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryTeal.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          prov.code,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.primaryTeal,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          prov.name,
                                          style: const TextStyle(
                                            fontSize: 16.5,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryTeal,
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: const Text(
                                            'Đang chọn',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    prov.description,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF475569),
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 6,
                                    children: [
                                      _InfoChip(
                                        icon: Icons.place_outlined,
                                        label:
                                            '${prov.destinationCount} Địa điểm',
                                      ),
                                      _InfoChip(
                                        icon: Icons.ramen_dining_outlined,
                                        label: '${prov.foodCount} Đặc sản',
                                      ),
                                      _InfoChip(
                                        icon: Icons.restaurant_outlined,
                                        label:
                                            '${prov.restaurantCount} Nhà hàng',
                                      ),
                                      _InfoChip(
                                        icon: Icons.public_outlined,
                                        label: 'Vùng: ${prov.region}',
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF475569)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}
