import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playCorrectSound() async {
    await _player.play(AssetSource('sounds/correct.mp3'));
  }

  Future<void> playWrongSound() async {
    await _player.play(AssetSource('sounds/wrong.mp3'));
  }

  Future<void> playCompleteSound() async {
    await _player.play(AssetSource('sounds/complete.mp3'));
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
