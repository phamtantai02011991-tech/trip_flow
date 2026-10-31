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
          Text('Đi mấy ngày?', style: AppText.display),
          const SizedBox(height: 16),
          _stepper('Số ngày', _days, 1, 14, (v) => setState(() => _days = v)),
          const SizedBox(height: 12),
          _stepper('Số người', _party, 1, 20, (v) => setState(() => _party = v)),
          const SizedBox(height: 20),
          Text('Phương tiện', style: AppText.label),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final (code, label) in const [
                ('motorbike', 'Xe máy'),
                ('car', 'Ô tô'),
                ('coach', 'Xe khách'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child:
                      _chip(label, _vehicle == code, () => setState(() => _vehicle = code)),
                ),
            ],
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
          ? '${_destination?.name ?? 'Khám phá'} · ${_days} ngày'
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
