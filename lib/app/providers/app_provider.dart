import 'package:flutter/material.dart';
import 'package:wasnaker_core/wasnaker_core.dart';
import '/app/networking/api_service.dart';
import '/config/storage_keys.dart';
import '/config/toast_notification.dart';
import '/bootstrap/decoders.dart';
import '/config/design.dart';
import '/bootstrap/theme.dart';
import '/config/localization.dart';
import 'package:nylo_framework/nylo_framework.dart';

class AppProvider implements NyProvider {

  @override
  setup(Nylo nylo) async {
    await nylo.configure(
      localization: NyLocalizationConfig(
          languageCode: LocalizationConfig.languageCode,
          localeType: LocalizationConfig.localeType,
          assetsDirectory: LocalizationConfig.assetsDirectory
      ),
      loader: DesignConfig.loader,
      logo: DesignConfig.logo,
      themes: appThemes,
      initialThemeId: 'light_theme',
      toastNotifications: ToastNotificationConfig.styles,
      modelDecoders: modelDecoders,
      controllers: controllers,
      apiDecoders: apiDecoders,
      authKey: StorageKeysConfig.auth,
      syncKeys: StorageKeysConfig.syncedOnBoot,
      monitorAppUsage: false,
      showDateTimeInLogs: false,
      broadcastEvents: false,
      useErrorStack: true,
    );

    return nylo;
  }

  @override
  boot(Nylo nylo) async {
    _registerDashboard();
    WidgetsBinding.instance.addObserver(_AuthRefreshObserver());
  }

  void _registerDashboard() {
    // Statistik — placeholder, real data via module API
    DashboardRegistry.registerStat(DashboardStatWidget(
      order: 1,
      builder: () => _StatCard(label: 'Jadwal Minggu Ini', value: '5', icon: Icons.calendar_today),
    ));
    DashboardRegistry.registerStat(DashboardStatWidget(
      order: 2,
      builder: () => _StatCard(label: 'RFQ Masuk', value: '12', icon: Icons.inbox),
    ));
    DashboardRegistry.registerStat(DashboardStatWidget(
      order: 3,
      builder: () => _StatCard(label: 'Billing Bulan Ini', value: 'Rp 4.2M', icon: Icons.receipt_long),
    ));

    // Navigasi — read from Perfex menu_items (no hardcode, no rebuild on change)
    _registerNavFromPerfex();
  }

  void _registerNavFromPerfex() {
    final items = Auth.data()?['staff']?['menu_items'] as List?;
    if (items == null) return;

    for (final item in items) {
      final feature = item['feature'] as String? ?? '';
      final label   = item['label']   as String? ?? feature;
      final icon    = item['icon']    as String? ?? 'fa-solid fa-circle';
      final order   = (item['order']  as num?)?.toInt() ?? 99;

      DashboardRegistry.registerNav(DashboardNavItem(
        label: label,
        order: order,
        iconBuilder: () => FaIconMapper.fromClass(icon),
        onTap: () {},
      ));
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.blue.shade700),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Refreshes staff data (capabilities, membership) from /auth/me
/// every time the app comes back to foreground.
/// Tokens stay the same — only staff fields are updated.
class _AuthRefreshObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    if (Auth.data() == null) return;
    try {
      final response = await api<ApiService>((s) => s.me());
      if (response?['user'] != null) {
        await Auth.set((data) => {
          ...(data as Map? ?? {}),
          'staff': response['user'],
        });
      }
    } catch (_) {}
  }
}
