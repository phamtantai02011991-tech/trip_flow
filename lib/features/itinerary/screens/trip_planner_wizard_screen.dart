import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_state.dart';
import '../../../core/utils/data_models.dart';
import '../../../core/utils/smart_itinerary_engine.dart';
import 'smart_itinerary_result_screen.dart';

/// Màn hình Wizard Nhập liệu Lập Lịch Trình Thông Minh (Việt hóa 100% theo Ảnh 3)
/// Cho phép:
/// 1. Nhập/chọn Điểm xuất phát & Điểm đến
/// 2. Chọn Thời gian & Số ngày di chuyển (1N, 2N1Đ, 3N2Đ)
/// 3. Chọn Sở thích du lịch theo nhóm chủ đề trực quan
class TripPlannerWizardScreen extends StatefulWidget {
  final TripFlowAppState appState;

  const TripPlannerWizardScreen({super.key, required this.appState});

  @override
  State<TripPlannerWizardScreen> createState() => _TripPlannerWizardScreenState();
}

class _TripPlannerWizardScreenState extends State<TripPlannerWizardScreen> {
  late DestinationModel _selectedOrigin;
  late DestinationModel _selectedDestination;
  int _totalDays = 2; // Mặc định: 2 ngày 1 đêm
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  final Set<String> _selectedPreferences = {
    'heritage',
    'cuisine',
    'top_rated',
    'rest_cafe',
    'street_walk',
  };

  @override
  void initState() {
    super.initState();
    final destinations = widget.appState.destinationsForSelectedProvince;
    if (destinations.isNotEmpty) {
      _selectedOrigin = destinations.first;
      _selectedDestination = destinations.length > 1 ? destinations.last : destinations.first;
    } else {
      _selectedOrigin = widget.appState.allDestinations.first;
      _selectedDestination = widget.appState.allDestinations.last;
    }
  }

  void _onGenerateItinerary() {
    final plan = SmartItineraryEngine.generate(
      province: widget.appState.selectedProvince,
      origin: _selectedOrigin,
      destination: _selectedDestination,
      startDate: _startDate,
      totalDays: _totalDays,
      preferenceIds: _selectedPreferences,
      allDestinations: widget.appState.allDestinations,
      allRestaurants: widget.appState.allRestaurants,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SmartItineraryResultScreen(
          plan: plan,
          appState: widget.appState,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provinceDestinations = widget.appState.destinationsForSelectedProvince.isNotEmpty
        ? widget.appState.destinationsForSelectedProvince
        : widget.appState.allDestinations;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Lập Lịch Trình Thông Minh'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                // 1. Header Banner giới thiệu
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF134E4A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Xây Dựng Lộ Trình Tự Động',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Hệ thống tự động thiết kế tuyến đường, bố trí điểm tham quan, trạm dừng chân nghỉ ngơi và quán ăn đặc sản tại ${widget.appState.selectedProvince.name}.',
                        style: const TextStyle(
                          color: Color(0xFFCCFBF1),
                          fontSize: 12.5,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Bước 1: Điểm xuất phát & Điểm đến
                _buildSectionTitle('1. Tuyến đường di chuyển', 'Chọn điểm bắt đầu và điểm kết thúc hành trình'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      // Điểm xuất phát
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 10),
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D9488),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Điểm xuất phát (Origin)',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<DestinationModel>(
                                  value: _selectedOrigin,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                    ),
                                  ),
                                  items: provinceDestinations.map((d) {
                                    return DropdownMenuItem(
                                      value: d,
                                      child: Text(
                                        d.name,
                                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedOrigin = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Điểm đến
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 10),
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE11D48),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Điểm đến (Destination)',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<DestinationModel>(
                                  value: _selectedDestination,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                    ),
                                  ),
                                  items: provinceDestinations.map((d) {
                                    return DropdownMenuItem(
                                      value: d,
                                      child: Text(
                                        d.name,
                                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedDestination = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // 3. Bước 2: Thời gian & Số ngày
                _buildSectionTitle('2. Thời gian chuyến đi', 'Lựa chọn số ngày và thời điểm khởi hành'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Chọn số ngày
                      Row(
                        children: [
                          _buildDayChoiceCard(
                            days: 1,
                            title: '1 Ngày',
                            subtitle: 'Khám phá nhanh',
                            isSelected: _totalDays == 1,
                            onTap: () => setState(() => _totalDays = 1),
                          ),
                          const SizedBox(width: 10),
                          _buildDayChoiceCard(
                            days: 2,
                            title: '2N 1Đ',
                            subtitle: 'Lộ trình tối ưu',
                            isSelected: _totalDays == 2,
                            onTap: () => setState(() => _totalDays = 2),
                          ),
                          const SizedBox(width: 10),
                          _buildDayChoiceCard(
                            days: 3,
                            title: '3N 2Đ',
                            subtitle: 'Trọn vẹn thắng cảnh',
                            isSelected: _totalDays == 3,
                            onTap: () => setState(() => _totalDays = 3),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Ngày khởi hành
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, color: AppTheme.primaryTeal, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ngày khởi hành',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '${_startDate.day.toString().padLeft(2, '0')}/${_startDate.month.toString().padLeft(2, '0')}/${_startDate.year}',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _startDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setState(() => _startDate = picked);
                              }
                            },
                            icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                            label: const Text('Đổi ngày', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // 4. Bước 3: Sở thích du lịch (What excites you - theo Ảnh 3)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle('3. Bạn yêu thích điều gì?', 'Chọn sở thích để AI cá nhân hóa lịch trình'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCCFBF1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Đã chọn ${_selectedPreferences.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Hiển thị các nhóm sở thích
                ..._buildPreferenceGroups(),
              ],
            ),
          ),

          // Thanh CTA cố định ở đáy
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: _onGenerateItinerary,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                  label: const Text(
                    'Xây Dựng Lịch Trình Thông Minh',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildDayChoiceCard({
    required int days,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0D9488) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? const Color(0xFFCCFBF1) : const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPreferenceGroups() {
    final groups = <String, List<TravelPreferenceItem>>{};
    for (final pref in TravelPreferencesCatalog.allPreferences) {
      groups.putIfAbsent(pref.group, () => []).add(pref);
    }

    return groups.entries.map((entry) {
      final groupName = entry.key;
      final items = entry.value;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              groupName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) {
                final isSelected = _selectedPreferences.contains(item.id);
                return FilterChip(
                  avatar: Text(item.iconEmoji, style: const TextStyle(fontSize: 13)),
                  label: Text(item.title),
                  selected: isSelected,
                  selectedColor: const Color(0xFF0D9488),
                  backgroundColor: const Color(0xFFF1F5F9),
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xFF334155),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedPreferences.add(item.id);
                      } else {
                        if (_selectedPreferences.length > 1) {
                          _selectedPreferences.remove(item.id);
                        }
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      );
    }).toList();
  }
}

