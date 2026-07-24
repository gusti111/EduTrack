import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:edutrack/core/widgets/statistic_card.dart'; // <-- Gunakan package: import

void main() {
  testWidgets('StatisticCard menampilkan judul, nilai, dan ikon dengan benar',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatisticCard(
            title: 'Selesai',
            value: '5 / 10',
            subtitle: '50% tingkat penyelesaian',
            icon: Icons.check_circle_outline,
            color: Colors.green,
          ),
        ),
      ),
    );

    expect(find.text('Selesai'), findsOneWidget);
    expect(find.text('5 / 10'), findsOneWidget);
    expect(find.text('50% tingkat penyelesaian'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });
}
