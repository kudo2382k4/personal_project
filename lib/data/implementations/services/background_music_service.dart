import 'dart:convert';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class MusicTrack {
  final int id;
  final String title;
  final String artist;
  final String url;

  const MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.url,
  });

  factory MusicTrack.fromJson(Map<String, dynamic> json) {
    return MusicTrack(
      id: json['id'] as int,
      title: json['title'] as String,
      artist: json['artist'] as String,
      url: json['url'] as String,
    );
  }
}

class BackgroundMusicService {
  BackgroundMusicService._internal();
  static final BackgroundMusicService instance = BackgroundMusicService._internal();

  final AudioPlayer _player = AudioPlayer();
  List<MusicTrack> _playlist = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _initialized = false;
  String? errorMessage; // <--- Thêm biến lưu lỗi

  bool get isPlaying => _isPlaying;
  MusicTrack? get currentTrack =>
      _playlist.isEmpty ? null : _playlist[_currentIndex];

  /// Khởi động service: load JSON và phát bài đầu tiên
  Future<void> init() async {
    if (_initialized && _playlist.isNotEmpty) return;
    _initialized = true;
    errorMessage = null;

    try {
      final jsonStr = await rootBundle.loadString('assets/audio/tet_music.json');
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final rawList = data['playlist'] as List<dynamic>;
      _playlist = rawList
          .map((e) => MusicTrack.fromJson(e as Map<String, dynamic>))
          .toList();

      // Shuffle để phát ngẫu nhiên mỗi lần mở app
      _playlist.shuffle(Random());

      // Lắng nghe khi bài kết thúc → phát bài tiếp theo
      _player.onPlayerComplete.listen((_) => _playNext());

      await play();
    } catch (e) {
      print("Lỗi đọc JSON nhạc: $e");
      errorMessage = "Lỗi nạp file: ${e.toString().split('\n').first}";
      // Dọn flag để lần sau bấm nút vẫn có thể thử lại
      _initialized = false;
      _isPlaying = false;
    }
  }

  /// Phát bài hiện tại
  Future<void> play() async {
    if (_playlist.isEmpty) return;
    try {
      errorMessage = null; // Reset lỗi trước khi phát
      // Dùng AssetSource để phát nhạc từ thư mục assets/ của ứng dụng
      await _player.play(AssetSource(_playlist[_currentIndex].url));
      _isPlaying = true;
    } catch (e) {
      print("Lỗi phát nhạc: $e"); // In ra lỗi nếu file không tồn tại
      errorMessage = "Lỗi phát: ${e.toString().split('\n').first}";
      _isPlaying = false;
    }
  }

  /// Tạm dừng
  Future<void> pause() async {
    await _player.pause();
    _isPlaying = false;
  }

  /// Bật/Tắt toggle
  Future<void> toggle() async {
    if (_isPlaying) {
      await pause();
    } else {
      if (_playlist.isEmpty) {
        await init();
      } else {
        await _player.resume();
        _isPlaying = true;
      }
    }
  }

  /// Phát bài tiếp theo
  Future<void> _playNext() async {
    if (_playlist.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _playlist.length;
    await play();
  }

  /// Giải phóng tài nguyên
  Future<void> dispose() async {
    await _player.dispose();
  }
}
