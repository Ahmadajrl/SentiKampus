/// Widget test dasar untuk SentiKampus Android.
///
/// Memverifikasi bahwa aplikasi dapat dirender tanpa crash dan
/// elemen-elemen utama tampil di layar.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sentikampus_mobile_starter/main.dart';

void main() {
  testWidgets('App renders without crash', (WidgetTester tester) async {
    // Build aplikasi dan render frame pertama.
    await tester.pumpWidget(const SentiKampusApp());

    // Judul aplikasi harus tampil di AppBar.
    expect(find.text('🎓 SentiKampus'), findsOneWidget);
  });

  testWidgets('Bottom navigation has three tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const SentiKampusApp());

    // Tiga tab navigasi harus ada.
    expect(find.text('Prediksi'), findsOneWidget);
    expect(find.text('Perjalanan'), findsOneWidget);
    expect(find.text('Monitoring'), findsOneWidget);
  });

  testWidgets('Navigate to Journey tab shows week list',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SentiKampusApp());

    // Tekan tab Perjalanan.
    await tester.tap(find.text('Perjalanan'));
    await tester.pumpAndSettle();

    // Halaman Perjalanan harus menampilkan header dan minimal P1.
    expect(find.text('Perjalanan 16 Pertemuan'), findsOneWidget);
    expect(find.textContaining('P1'), findsWidgets);
  });

  testWidgets('Predict page shows text input field',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SentiKampusApp());

    // Field input teks harus ada.
    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets('Predict page shows example quick-chips',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SentiKampusApp());

    // Chip contoh cepat Positif / Negatif / Netral harus ada.
    expect(find.text('Positif'), findsOneWidget);
    expect(find.text('Negatif'), findsOneWidget);
    expect(find.text('Netral'), findsOneWidget);
  });
}
