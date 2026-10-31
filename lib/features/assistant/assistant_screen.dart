import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/assistant_api.dart';
import '../../state/trips_provider.dart';
import '../../ui/tokens/app_tokens.dart';
import '../trip/trip_list_screen.dart' show money;

class _Msg {
  const _Msg({required this.text, required this.fromUser, this.tips = const [], this.applied = const []});
  final String text;
  final bool fromUser;
  final List<String> tips;
  final List<Map<String, dynamic>> applied;
}

/// Module 4 — trợ lý du lịch AI. AI chỉ đề xuất, backend kiểm chứng rồi mới sửa lịch.
class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key, this.tripId});

  final int? tripId;

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _messages = [
    const _Msg(
      text: 'Chào bạn! Mình là trợ lý TripFlow. Hỏi mình về lịch trình, quán ăn, ngân sách '
          'hoặc hành lý cho chuyến đi nhé.',
      fromUser: false,
    ),
  ];
  bool _sending = false;

  static const _suggestions = [
    'Đi Đà Lạt 3 ngày, ưu tiên cảnh đẹp và quán ăn địa phương',
    'Ngân sách 2 triệu cho 2 người đi Đà Lạt đủ không?',
    'Cần chuẩn bị hành lý gì khi đi Sa Pa tháng 11?',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();
    setState(() {
      _messages.add(_Msg(text: text, fromUser: true));
      _sending = true;
    });
    _scrollToEnd();

    try {
      final reply = await AssistantApi().chat(message: text, tripId: widget.tripId);
      if (!mounted) return;
      setState(() {
        _messages.add(_Msg(
          text: reply.reply.isEmpty ? 'Mình chưa có câu trả lời phù hợp.' : reply.reply,
          fromUser: false,
          tips: reply.tips,
          applied: reply.applied,
        ));
        _sending = false;
      });
      if (reply.applied.isNotEmpty) {
        ref.invalidate(tripDetailProvider(widget.tripId ?? 0));
        ref.invalidate(tripsProvider);
      }
      _scrollToEnd();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_Msg(text: 'Lỗi: $e', fromUser: false));
        _sending = false;
      });
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Trợ lý TripFlow'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.auto_awesome_rounded, color: AppColors.coral),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _bubble(_messages[index]),
            ),
          ),
          if (_messages.length == 1) _suggestionRow(),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _bubble(_Msg msg) {
    final isUser = msg.fromUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isUser ? AppColors.coral : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadii.md),
            topRight: const Radius.circular(AppRadii.md),
            bottomLeft: Radius.circular(isUser ? AppRadii.md : 4),
            bottomRight: Radius.circular(isUser ? 4 : AppRadii.md),
          ),
          border: isUser ? null : Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(msg.text,
                style: AppText.body.copyWith(
                    color: isUser ? Colors.white : AppColors.textPrimary, fontSize: 14.5)),
            if (msg.applied.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final action in msg.applied)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 14, color: AppColors.success),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(_describeAction(action),
                            style: AppText.caption.copyWith(color: AppColors.success)),
                      ),
                    ],
                  ),
                ),
            ],
            if (msg.tips.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.coralSoft,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final tip in msg.tips)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text('• $tip', style: AppText.caption.copyWith(color: AppColors.ink)),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _describeAction(Map<String, dynamic> action) {
    switch (action['type']) {
      case 'add_stop':
        return 'Đã thêm "${action['name']}" vào ngày ${action['day']}';
      case 'remove_stop':
        return 'Đã xoá điểm dừng #${action['stop_id']}';
      default:
        return 'Đã cập nhật lịch trình';
    }
  }

  Widget _suggestionRow() => SizedBox(
        height: 46,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _suggestions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) => GestureDetector(
            onTap: () => _send(_suggestions[index]),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.pill,
                border: Border.all(color: AppColors.line),
              ),
              child: Text(_suggestions[index],
                  style: AppText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ),
      );

  Widget _inputBar() => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(
                    hintText: 'Hỏi về chuyến đi của bạn…',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sending ? null : () => _send(),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _sending ? AppColors.line : AppColors.coral,
                    shape: BoxShape.circle,
                  ),
                  child: _sending
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ),
      );
}
