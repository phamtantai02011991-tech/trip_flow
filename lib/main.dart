import 'dart:io' show HttpOverrides, HttpClient, SecurityContext;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/providers/app_providers.dart';
import 'core/storage/offline_cache_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_state.dart';
import 'features/home/home_screen.dart';
import 'features/assistant/assistant_screen.dart';
import 'features/local_foods/local_foods_screen.dart';
import 'features/nearby/nearby_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/trip/trip_list_screen.dart';

/// HttpOverrides tùy chỉnh để cấp User-Agent hợp lệ cho mọi request tải ảnh và dữ liệu mạng,
/// ngăn chặn việc bị máy chủ CDN (Wikimedia, Cloudflare, ...) chặn 403 Forbidden.
class TripFlowHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..userAgent = 'TripFlow/1.0 (Android; Mobile)';
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Kích hoạt HttpOverrides trên nền tảng di động (Android / iOS)
  if (!kIsWeb) {
    HttpOverrides.global = TripFlowHttpOverrides();
  }
  await OfflineCacheService.instance.init();
  runApp(
    const ProviderScope(
      child: TripFlowApp(),
    ),
  );
}

/// Ứng dụng di động TripFlow (Travel Discovery) sử dụng Riverpod + Dio + Hive Offline-first.
class TripFlowApp extends ConsumerWidget {
  final TripFlowAppState? appState;

  const TripFlowApp({super.key, this.appState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TripFlowAppState resolvedState =
        appState ?? ref.watch(appStateProvider);
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: ResponsivePhoneFrameWrapper(
        child: MainNavigationShell(appState: resolvedState),
      ),
    );
  }
}

/// Tự động hiển thị khung màn hình điện thoại di động khi mở trên trình duyệt máy tính (Chrome/Edge).
class ResponsivePhoneFrameWrapper extends StatefulWidget {
  final Widget child;

  const ResponsivePhoneFrameWrapper({super.key, required this.child});

  @override
  State<ResponsivePhoneFrameWrapper> createState() =>
      _ResponsivePhoneFrameWrapperState();
}

class _ResponsivePhoneFrameWrapperState
    extends State<ResponsivePhoneFrameWrapper> {
  bool _usePhoneFrame = true;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktopViewport =
            kIsWeb && constraints.maxWidth > 540 && constraints.maxHeight > 650;
        if (!isDesktopViewport || !_usePhoneFrame) {
          return Stack(
            children: [
              widget.child,
              if (isDesktopViewport)
                Positioned(
                  right: 16,
                  bottom: 84,
                  child: FloatingActionButton.extended(
                    heroTag: null,
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    onPressed: () => setState(() => _usePhoneFrame = true),
                    icon: const Icon(Icons.smartphone_rounded, size: 18),
                    label: const Text('Khung Điện Thoại'),
                  ),
                ),
            ],
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Container(
                    width: 412,
                    height: (constraints.maxHeight - 32).clamp(620.0, 880.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(44),
                      border: Border.all(
                        color: const Color(0xFF475569),
                        width: 6,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 36,
                          offset: Offset(0, 18),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(34),
                      child: Column(
                        children: [
                          // Thanh Status Bar của Điện thoại
                          Container(
                            height: 28,
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '09:41',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Container(
                                  width: 76,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.signal_cellular_alt_rounded,
                                      size: 14,
                                      color: Color(0xFF0F172A),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.wifi_rounded,
                                      size: 14,
                                      color: Color(0xFF0F172A),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.battery_full_rounded,
                                      size: 15,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: MediaQuery(
                              data: MediaQuery.of(context).copyWith(
                                size: Size(
                                  396,
                                  (constraints.maxHeight - 76)
                                      .clamp(560.0, 820.0),
                                ),
                              ),
                              child: Navigator(
                                onGenerateRoute: (_) => MaterialPageRoute(
                                  builder: (_) => widget.child,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 20,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => setState(() => _usePhoneFrame = false),
                  icon: const Icon(Icons.fullscreen_rounded, size: 18),
                  label: const Text('Mở Rộng Toàn Màn Hình'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Khung điều hướng 5 Tab dưới cùng theo đúng thiết kế Mục 5.2:
/// 1. Khám phá  |  2. Bản đồ  |  3. Lịch trình  |  4. Ẩm thực  |  5. Cá nhân
class MainNavigationShell extends StatelessWidget {
  final TripFlowAppState appState;

  const MainNavigationShell({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final screens = [
          HomeScreen(appState: appState),
          const NearbyScreen(),
          const TripListScreen(),
          const AssistantScreen(),
          LocalFoodsScreen(appState: appState),
          ProfileScreen(appState: appState),
        ];

        return Scaffold(
          extendBody: true,
          body: IndexedStack(
            index: appState.currentTabIndex,
            children: screens,
          ),
          bottomNavigationBar: _buildFloatingBottomBar(context, appState),
        );
      },
    );
  }

  Widget _buildFloatingBottomBar(
      BuildContext context, TripFlowAppState appState) {
    final navItems = [
      (
        icon: Icons.explore_outlined,
        activeIcon: Icons.explore_rounded,
        label: 'Khám phá'
      ),
      (
        icon: Icons.map_outlined,
        activeIcon: Icons.map_rounded,
        label: 'Gần đây'
      ),
      (
        icon: Icons.event_note_outlined,
        activeIcon: Icons.event_note_rounded,
        label: 'Chuyến đi'
      ),
      (
        icon: Icons.auto_awesome_outlined,
        activeIcon: Icons.auto_awesome_rounded,
        label: 'Trợ lý'
      ),
      (
        icon: Icons.ramen_dining_outlined,
        activeIcon: Icons.ramen_dining_rounded,
        label: 'Ẩm thực'
      ),
      (
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Cá nhân'
      ),
    ];

    return SafeArea(
      child: Container(
        height: 60,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE05638).withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: const Color(0xFFEAE3D9),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(navItems.length, (index) {
            final item = navItems[index];
            final isSelected = appState.currentTabIndex == index;

            return GestureDetector(
              onTap: () => appState.setTabIndex(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: isSelected ? 12 : 8,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [
                            Color(0xFFE05638), // Terracotta Brick
                            Color(0xFFF43F5E), // Rose Pink
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFE05638).withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? item.activeIcon : item.icon,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF64748B),
                      size: 20,
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 5),
                      Text(
                        item.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
