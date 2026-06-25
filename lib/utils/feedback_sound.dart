import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'sound_web.dart' if (dart.library.io) 'sound_stub.dart';

/// Sepete ekleme geri bildirimi: webde sentetik ton, mobilde ses + titreşim.
void playAddFeedback() {
  if (kIsWeb) {
    playWebBeep();
  } else {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.lightImpact();
  }
}
