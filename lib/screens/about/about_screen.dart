import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tentang')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, size: 48, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('EduTrack', style: Theme.of(context).textTheme.headlineSmall),
                    const Text('Smart Student Planner'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'EduTrack membantu mahasiswa mencatat, memprioritaskan, dan '
              'melacak tenggat tugas kuliah dalam satu aplikasi.',
            ),
            const SizedBox(height: 16),
            const Text('Versi 0.1.0 (PjBL Project)'),
          ],
        ),
      ),
    );
  }
}
