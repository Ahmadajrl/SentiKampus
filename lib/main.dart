/// SentiKampus Android — Entry point aplikasi Flutter.
///
/// Arsitektur singkat (P12):
///   main.dart        → entry point, MaterialApp, bottom navigation
///   services/        → ApiService (HTTP ke FastAPI)
///   controllers/     → PredictController (ChangeNotifier)
///   screens/         → PredictPage, JourneyPage, MonitoringPage
///   widgets/         → SentimentBadge, ProbabilityBar, XaiCard, WeekBanner
///   models/          → PredictionResult, DemoWeek
///   data/            → demoWeeks (16 pertemuan, offline)
///   core/            → ApiConfig, AppTheme
///
/// Catatan kurikulum P12:
///   - Web (Streamlit) dan Android (Flutter) memakai **API contract yang sama**.
///   - Di Android Emulator, 10.0.2.2 menunjuk ke host Windows (localhost).
///   - Gunakan --dart-define=API_BASE_URL=http://... untuk override.
library;

import 'package:flutter/material.dart';

import 'controllers/predict_controller.dart';
import 'core/theme/app_theme.dart';
import 'screens/journey_page.dart';
import 'screens/monitoring_page.dart';
import 'screens/predict_page.dart';
import 'services/api_service.dart';

void main() {
  runApp(const SentiKampusApp());
}

class SentiKampusApp extends StatelessWidget {
  const SentiKampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SentiKampus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const _AppShell(),
    );
  }
}

/// Shell utama dengan bottom navigation bar (3 tab).
class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _currentIndex = 0;
  int _selectedWeek = 4;

  // Buat service dan controller sekali agar tidak di-rebuild setiap navigasi.
  late final ApiService _api;
  late final PredictController _predictCtrl;

  @override
  void initState() {
    super.initState();
    _api = ApiService();
    _predictCtrl = PredictController(apiService: _api);
  }

  @override
  void dispose() {
    _predictCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      PredictPage(controller: _predictCtrl),
      const JourneyPage(),
      MonitoringPage(api: _api, week: _selectedWeek),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.psychology_alt_outlined),
            selectedIcon: Icon(Icons.psychology_alt),
            label: 'Prediksi',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Perjalanan',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Monitoring',
          ),
        ],
      ),
    );
  }
}
