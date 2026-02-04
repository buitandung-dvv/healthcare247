import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../core/constants/app_colors.dart';
import '../providers/audio_provider.dart';
import '../providers/language_provider.dart';

/// Bottom sheet để chọn nhạc nền
class MusicSelectionSheet extends StatefulWidget {
  const MusicSelectionSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MusicSelectionSheet(),
    );
  }

  @override
  State<MusicSelectionSheet> createState() => _MusicSelectionSheetState();
}

class _MusicSelectionSheetState extends State<MusicSelectionSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load device songs
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AudioProvider>().loadDeviceSongs();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final audioProvider = context.watch<AudioProvider>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  lang.getText(en: 'Music', vi: 'Nhạc'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (audioProvider.isPlaying)
                  IconButton(
                    icon: const Icon(Icons.stop),
                    onPressed: () => audioProvider.stopMusic(),
                    color: AppColors.error,
                  ),
              ],
            ),
          ),

          // Now playing
          if (audioProvider.currentMusicName.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    audioProvider.isPlaying
                        ? Icons.pause_circle
                        : Icons.play_circle,
                    color: AppColors.primary,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.getText(en: 'Now Playing', vi: 'Đang phát'),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          audioProvider.currentMusicName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      audioProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                    onPressed: () {
                      if (audioProvider.isPlaying) {
                        audioProvider.pauseMusic();
                      } else {
                        audioProvider.playMusic();
                      }
                    },
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Tab bar
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: lang.getText(en: 'Bundled', vi: 'Có sẵn')),
              Tab(text: lang.getText(en: 'My Music', vi: 'Nhạc của tôi')),
            ],
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBundledMusicList(audioProvider, lang),
                _buildDeviceMusicList(audioProvider, lang),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBundledMusicList(
    AudioProvider audioProvider,
    LanguageProvider lang,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: AudioProvider.bundledMusic.length,
      itemBuilder: (context, index) {
        final music = AudioProvider.bundledMusic[index];
        final isPlaying = audioProvider.currentBundledMusicId == music.id;

        return ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.music_note,
              color: isPlaying ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          title: Text(
            music.name,
            style: TextStyle(
              fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
              color: isPlaying ? AppColors.primary : null,
            ),
          ),
          subtitle: Text(music.artist),
          trailing:
              isPlaying && audioProvider.isPlaying
                  ? Icon(Icons.equalizer, color: AppColors.primary)
                  : null,
          onTap: () => audioProvider.playBundledMusic(music.id),
        );
      },
    );
  }

  Widget _buildDeviceMusicList(
    AudioProvider audioProvider,
    LanguageProvider lang,
  ) {
    if (!audioProvider.hasPermission) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              lang.getText(
                en: 'Permission required to access music',
                vi: 'Cần quyền truy cập để xem nhạc',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => audioProvider.requestPermission(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: Text(
                lang.getText(en: 'Grant Permission', vi: 'Cấp quyền'),
              ),
            ),
          ],
        ),
      );
    }

    if (audioProvider.deviceSongs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_off, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              lang.getText(
                en: 'No music found on device',
                vi: 'Không tìm thấy nhạc trên thiết bị',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: audioProvider.deviceSongs.length,
      itemBuilder: (context, index) {
        final song = audioProvider.deviceSongs[index];
        final isPlaying = audioProvider.currentSong?.id == song.id;

        return ListTile(
          leading: QueryArtworkWidget(
            id: song.id,
            type: ArtworkType.AUDIO,
            nullArtworkWidget: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.music_note),
            ),
          ),
          title: Text(
            song.title,
            style: TextStyle(
              fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
              color: isPlaying ? AppColors.primary : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            song.artist ?? 'Unknown',
            overflow: TextOverflow.ellipsis,
          ),
          trailing:
              isPlaying && audioProvider.isPlaying
                  ? Icon(Icons.equalizer, color: AppColors.primary)
                  : null,
          onTap: () => audioProvider.playDeviceSong(song),
        );
      },
    );
  }
}
