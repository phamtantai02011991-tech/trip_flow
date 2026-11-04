import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/trip.dart';
import '../../state/trips_provider.dart';
import '../../ui/tokens/app_tokens.dart';
import '../trip/trip_overview_screen.dart';

/// Module 1 + 2 — wizard 3 bước, kết thúc bằng gọi AI dựng lộ trình.
class PlannerWizardScreen extends ConsumerStatefulWidget {
  const PlannerWizardScreen({super.key});

  @override
  ConsumerState<PlannerWizardScreen> createState() => _PlannerWizardScreenState();
}

/// Toạ độ thật của các điểm đến phổ biến (không phải dữ liệu bịa).
class _City {
  const _City(this.name, this.lat, this.lng);
  final String name;
  final double lat;
  final double lng;
}

const _cities = <_City>[
  _City('TP. Hồ Chí Minh', 10.7769, 106.7009),
  _City('Hà Nội', 21.0278, 105.8342),
  _City('Đà Lạt', 11.9404, 108.4583),
  _City('Đà Nẵng', 16.0544, 108.2022),
  _City('Huế', 16.4637, 107.5909),
  _City('Hội An', 15.8801, 108.3380),
  _City('Nha Trang', 12.2388, 109.1967),
  _City('Hạ Long', 20.9101, 107.1839),
  _City('Sa Pa', 22.3364, 103.8438),
  _City('Phú Quốc', 10.2899, 103.9840),
  _City('Ninh Bình', 20.2506, 105.9745),
  _City('Quy Nhơn', 13.7829, 109.2196),
];

const _preferences = <(String, String)>[
  ('nature', 'Thiên nhiên'),
  ('food', 'Ăn uống'),
  ('beach', 'Biển'),
  ('mountain', 'Núi'),
  ('explore', 'Khám phá'),
  ('photo', 'Chụp ảnh'),
  ('culture', 'Văn hoá'),
  ('relax', 'Nghỉ dưỡng'),
];

class _PlannerWizardScreenState extends ConsumerState<PlannerWizardScreen> {
  int _step = 0;

  _City _origin = _cities[0];
  _City? _destination = _cities[2];
  final _titleController = TextEditingController();
  final Set<String> _selectedPrefs = {};
  int _days = 3;
  int _party = 2;
  String _vehicle = 'motorbike';
  String _budgetLevel = 'balanced';
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));

  bool _enableCorridorPoi = true;
  bool _scanGasStation = true;
  bool _scanMechanic = true;
  bool _scanScenicPass = true;
  bool _scanFoodStop = true;

  bool _generating = false;
  int _progressStep = 0;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_generating) return _progressView();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Tạo kế hoạch với AI'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('${_step + 1}/3', style: AppText.label),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _stepIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: switch (_step) {
                0 => _stepWhere(),
                1 => _stepWhat(),
                _ => _stepHow(),
              },
            ),
          ),
          _bottomBar(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- steps
  Widget _stepIndicator() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= _step ? AppColors.coral : AppColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (i < 2) const SizedBox(width: 6),
            ],
          ],
        ),
      );

  Widget _stepWhere() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bạn đi từ đâu?', style: AppText.display),
          const SizedBox(height: 6),
          Text('Chọn nhanh hoặc nhập tên chuyến ở dưới.', style: AppText.bodySm),
          const SizedBox(height: 16),
          _cityPicker('Điểm xuất phát', _origin, (city) {
            if (city != null) setState(() => _origin = city);
          }),
          const SizedBox(height: 16),
          _cityPicker('Điểm đến', _destination, (city) => setState(() => _destination = city),
              allowNull: true),
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Tên chuyến (không bắt buộc)',
              hintText: 'VD: Đà Lạt 3 ngày 2 đêm',
            ),
          ),
        ],
      );

  Widget _cityPicker(
    String label,
    _City? current,
    ValueChanged<_City?> onChanged, {
    bool allowNull = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (allowNull)
              _chip('Để AI gợi ý', current == null, () => onChanged(null)),
            for (final city in _cities)
              _chip(city.name, current?.name == city.name, () => onChanged(city)),
          ],
        ),
      ],
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: active ? AppColors.coral : AppColors.surface,
            borderRadius: AppRadii.pill,
            border: Border.all(color: active ? AppColors.coral : AppColors.line),
          ),
          child: Text(
            label,
            style: AppText.label.copyWith(color: active ? Colors.white : AppColors.textSecondary),
          ),
        ),
      );

  Widget _stepWhat() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bạn thích gì?', style: AppText.display),
          const SizedBox(height: 6),
          Text('Chọn ít nhất một sở thích để AI ưu tiên đúng chỗ.', style: AppText.bodySm),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (code, label) in _preferences)
                _chip(label, _selectedPrefs.contains(code), () {
                  setState(() {
                    if (!_selectedPrefs.remove(code)) _selectedPrefs.add(code);
                  });
                }),
            ],
          ),
          const SizedBox(height: 24),
          Text('Ngân sách', style: AppText.label),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final (code, label) in const [
                ('saver', 'Tiết kiệm'),
                ('balanced', 'Trung bình'),
                ('comfort', 'Thoải mái'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _chip(label, _budgetLevel == code,
                      () => setState(() => _budgetLevel = code)),
                ),
            ],
          ),
        ],
      );

  Widget _stepHow() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thời lượng & Phương tiện', style: AppText.display),
          const SizedBox(height: 6),
          Text(
            'Chọn gói ngày hoặc điều chỉnh theo ý muốn của bạn.',
            style: AppText.bodySm,
          ),
          const SizedBox(height: 16),

          // Presets thời gian đi phượt
          Text('Gói thời gian điển hình', style: AppText.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('1 Ngày (Khám phá)', _days == 1, () => setState(() => _days = 1)),
              _chip('2N1Đ (Cuối tuần)', _days == 2, () => setState(() => _days = 2)),
              _chip('3N2Đ (Trọn vẹn)', _days == 3, () => setState(() => _days = 3)),
              _chip('4N3Đ (Chuyên sâu)', _days == 4, () => setState(() => _days = 4)),
              _chip('Xuyên Việt (7-14N)', _days >= 7, () => setState(() => _days = 7)),
            ],
          ),
          const SizedBox(height: 14),

          _stepper('Số ngày cụ thể', _days, 1, 14, (v) => setState(() => _days = v)),
          const SizedBox(height: 10),
          _stepper('Số người đi cùng', _party, 1, 20, (v) => setState(() => _party = v)),
          const SizedBox(height: 20),

          Text('Phương tiện di chuyển', style: AppText.label),
          const SizedBox(height: 8),
          Column(
            children: [
              _vehicleCard(
                code: 'motorbike',
                icon: Icons.two_wheeler_rounded,
                title: '🏍️ Xe máy đi phượt (Motorbike Road-trip)',
                desc: 'Tối ưu cung đèo ngắm cảnh, vận tốc an toàn 40-45 km/h, ưu tiên trạm xăng & vá xe ven đường.',
              ),
              const SizedBox(height: 8),
              _vehicleCard(
                code: 'car',
                icon: Icons.directions_car_rounded,
                title: '🚗 Ô tô tự lái (Self-drive Car)',
                desc: 'Tối ưu lộ trình cao tốc, trạm dừng chân quy mô lớn, trạm sạc điện EV và bãi đỗ xe an toàn.',
              ),
              const SizedBox(height: 8),
              _vehicleCard(
                code: 'coach',
                icon: Icons.airport_shuttle_rounded,
                title: '🚌 Xe khách / Tour du lịch',
                desc: 'Phù hợp gia đình và nhóm bạn, dừng nghỉ ngơi tại các trạm dừng chân tiêu chuẩn.',
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Tùy chọn Quét Biker Corridor POI
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.route_rounded, color: Color(0xFFFF4B55), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Quét Tiện Ích Ven Tuyến Phượt',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _enableCorridorPoi,
                      activeThumbColor: const Color(0xFFFF4B55),
                      onChanged: (val) => setState(() => _enableCorridorPoi = val),
                    ),
                  ],
                ),
                Text(
                  'Thuật toán Bounding Box quét cây xăng, tiệm sửa xe, đèo săn mây trong bán kính 2km dọc hành lang đường đi.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                if (_enableCorridorPoi) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _poiChip('⛽ Cây xăng', _scanGasStation, () {
                        setState(() => _scanGasStation = !_scanGasStation);
                      }),
                      _poiChip('🔧 Quán sửa xe máy', _scanMechanic, () {
                        setState(() => _scanMechanic = !_scanMechanic);
                      }),
                      _poiChip('☁️ Đèo & Viewpoint', _scanScenicPass, () {
                        setState(() => _scanScenicPass = !_scanScenicPass);
                      }),
                      _poiChip('🍛 Quán ăn ven đường', _scanFoodStop, () {
                        setState(() => _scanFoodStop = !_scanFoodStop);
                      }),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),
          Text('Ngày khởi hành', style: AppText.label),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_rounded, size: 18),
            label: Text(_formatDate(_startDate)),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.coralSoft,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Text(_error!, style: AppText.bodySm.copyWith(color: AppColors.coralDark)),
            ),
          ],
        ],
      );

  Widget _vehicleCard({
    required String code,
    required IconData icon,
    required String title,
    required String desc,
  }) {
    final active = _vehicle == code;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _vehicle = code),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFFF1F2) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? const Color(0xFFFF4B55) : const Color(0xFFE2E8F0),
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 20,
              color: active ? const Color(0xFFFF4B55) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: active ? const Color(0xFF991B1B) : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _poiChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFF4B55) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? const Color(0xFFFF4B55) : const Color(0xFF334155),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : const Color(0xFFCBD5E1),
          ),
        ),
      ),
    );
  }

  Widget _stepper(String label, int value, int min, int max, ValueChanged<int> onChanged) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppText.body)),
        _roundButton(Icons.remove_rounded, value > min ? () => onChanged(value - 1) : null),
        SizedBox(
          width: 56,
          child: Text('$value',
              textAlign: TextAlign.center,
              style: AppText.h2.copyWith(fontSize: 18)),
        ),
        _roundButton(Icons.add_rounded, value < max ? () => onChanged(value + 1) : null),
      ],
    );
  }

  Widget _roundButton(IconData icon, VoidCallback? onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: onTap == null ? AppColors.surfaceAlt : AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.line),
          ),
          child: Icon(icon, size: 18, color: onTap == null ? AppColors.textTertiary : AppColors.ink),
        ),
      );

  Widget _bottomBar() => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(
            children: [
              if (_step > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _step -= 1),
                    child: const Text('Quay lại'),
                  ),
                ),
              if (_step > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(_step == 2 ? 'Tạo lộ trình' : 'Tiếp tục'),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _progressView() => Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 46,
                  height: 46,
                  child: CircularProgressIndicator(color: AppColors.coral, strokeWidth: 3),
                ),
                const SizedBox(height: 24),
                Text('AI đang dựng lộ trình', style: AppText.h2),
                const SizedBox(height: 8),
                Text('Thường mất 5–15 giây.', style: AppText.bodySm),
                const SizedBox(height: 28),
                for (var i = 0; i < _progressLabels.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(
                          i < _progressStep
                              ? Icons.check_circle_rounded
                              : i == _progressStep
                                  ? Icons.radio_button_checked
                                  : Icons.circle_outlined,
                          size: 18,
                          color: i <= _progressStep ? AppColors.coral : AppColors.line,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _progressLabels[i],
                          style: AppText.bodySm.copyWith(
                            color: i <= _progressStep
                                ? AppColors.textPrimary
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );

  static const _progressLabels = [
    'Đang tạo chuyến đi',
    'Đang tìm địa điểm thật phù hợp',
    'Đang xếp lịch và tính chi phí',
  ];

  // ---------------------------------------------------------------- actions
  void _next() {
    if (_step == 1 && _selectedPrefs.isEmpty) {
      setState(() => _error = 'Chọn ít nhất một sở thích để AI hiểu bạn muốn gì.');
      return;
    }
    if (_step < 2) {
      setState(() {
        _error = null;
        _step += 1;
      });
      return;
    }
    _submit();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _submit() async {
    if (_destination != null &&
        _destination!.name == _origin.name) {
      setState(() => _error = 'Điểm đến phải khác điểm xuất phát.');
      return;
    }

    setState(() {
      _generating = true;
      _error = null;
      _progressStep = 0;
    });

    final api = ref.read(tripsApiProvider);
    try {
      final title = _titleController.text.trim().isEmpty
          ? '${_destination?.name ?? 'Khám phá'} · $_days ngày'
          : _titleController.text.trim();

      final Trip created = await api.create(
        title: title,
        originName: _origin.name,
        originLat: _origin.lat,
        originLng: _origin.lng,
        destinationName: _destination?.name,
        destinationLat: _destination?.lat,
        destinationLng: _destination?.lng,
        startDate: _startDate,
        totalDays: _days,
        partySize: _party,
        vehicle: _vehicle,
        budgetLevel: _budgetLevel,
        preferences: _selectedPrefs.toList(),
      );

      setState(() => _progressStep = 1);
      await api.generate(created.id);
      setState(() => _progressStep = 2);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => TripOverviewScreen(tripId: created.id)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _generating = false;
        _error = e.toString();
        _step = 2;
      });
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
