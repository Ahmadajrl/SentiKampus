/// Model data untuk satu pertemuan demonstrasi.
class DemoWeek {
  const DemoWeek({
    required this.week,
    required this.title,
    required this.level,
    required this.focus,
    required this.demoAction,
    required this.evidence,
    required this.capabilities,
  });

  /// Buat DemoWeek dari JSON response GET /api/v1/course/weeks.
  factory DemoWeek.fromJson(Map<String, dynamic> json) {
    return DemoWeek(
      week: (json['week'] as num).toInt(),
      title: json['title'] as String? ?? '',
      level: json['level'] as String? ?? '',
      focus: json['focus'] as String? ?? '',
      demoAction: json['demo_action'] as String? ?? '',
      evidence: json['evidence'] as String? ?? '',
      capabilities: (json['capabilities'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  final int week;
  final String title;
  final String level;
  final String focus;
  final String demoAction;
  final String evidence;
  final List<String> capabilities;

  /// Kembalikan true jika pertemuan ini memiliki kapabilitas tertentu.
  bool has(String capability) => capabilities.contains(capability);
}
