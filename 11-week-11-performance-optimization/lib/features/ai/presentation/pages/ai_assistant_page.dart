import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../routes.dart';
import '../providers/ai_providers.dart';
import 'chat_screen.dart';
import 'image_screen.dart';
import 'ocr_screen.dart';
import 'speech_screen.dart';

class AiAssistantPage extends ConsumerStatefulWidget {
  const AiAssistantPage({super.key});

  @override
  ConsumerState<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends ConsumerState<AiAssistantPage> {
  static const _pages = [
    ChatScreen(),
    OcrScreen(),
    SpeechScreen(),
    ImageScreen(),
  ];

  int _index = 0;

  // Tab dibuat malas: halaman OCR/Suara/Gambar baru dimuat saat pertama
  // dibuka, sehingga frame awal Asisten AI tidak membangun semua panel.
  final Set<int> _visited = {0};

  Future<void> _openSettings() async {
    await context.push(AppRoutes.aiSettings);
    if (!mounted) {
      return;
    }

    ref.invalidate(aiKeyStatusProvider);
    ref.invalidate(aiUsageStatusProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asisten AI'),
        actions: [
          IconButton(
            tooltip: 'Pengaturan AI',
            onPressed: _openSettings,
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          for (var i = 0; i < _pages.length; i++)
            if (_visited.contains(i)) _pages[i] else const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() {
          _index = index;
          _visited.add(index);
        }),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.document_scanner_outlined),
            selectedIcon: Icon(Icons.document_scanner),
            label: 'OCR',
          ),
          NavigationDestination(
            icon: Icon(Icons.mic_none),
            selectedIcon: Icon(Icons.mic),
            label: 'Suara',
          ),
          NavigationDestination(
            icon: Icon(Icons.image_outlined),
            selectedIcon: Icon(Icons.image),
            label: 'Gambar',
          ),
        ],
      ),
    );
  }
}
