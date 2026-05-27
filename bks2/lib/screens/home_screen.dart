import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'import_screen.dart';
import 'mixer_screen.dart';
import 'karaoke_screen.dart';
import 'live_screen.dart';
import 'export_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  String? _stemJobId;
  String? _transcriptionJobId;

  final _tabLabels = ['IMPORT', 'MIXER', 'KARAOKE', 'LIVE', 'EXPORT'];
  final _tabIcons = [
    Icons.upload_file_outlined, Icons.tune_outlined, Icons.lyrics_outlined,
    Icons.spatial_audio_outlined, Icons.download_outlined,
  ];
  final _tabIconsActive = [
    Icons.upload_file, Icons.tune, Icons.lyrics,
    Icons.spatial_audio, Icons.download,
  ];

  @override
  Widget build(BuildContext context) {
    final screens = [
      ImportScreen(onStemJobComplete: (id) => setState(() {
        _stemJobId = id; _tab = 1;
      })),
      MixerScreen(stemJobId: _stemJobId,
          onTranscriptionComplete: (id) => setState(() => _transcriptionJobId = id)),
      KaraokeScreen(transcriptionJobId: _transcriptionJobId),
      LiveScreen(stemJobId: _stemJobId, transcriptionJobId: _transcriptionJobId),
      ExportScreen(stemJobId: _stemJobId),
    ];

    return Scaffold(
      backgroundColor: BksColors.bg0,
      body: IndexedStack(index: _tab, children: screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: BksColors.bg1,
          border: Border(top: BorderSide(color: BksColors.border)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: List.generate(5, (i) {
                final active = _tab == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tab = i),
                    child: Container(
                      color: Colors.transparent,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(active ? _tabIconsActive[i] : _tabIcons[i],
                              color: active ? BksColors.gold : BksColors.textMuted,
                              size: 22),
                          const SizedBox(height: 2),
                          Text(_tabLabels[i], style: TextStyle(
                            fontSize: 9, fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: active ? BksColors.gold : BksColors.textMuted,
                          )),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
