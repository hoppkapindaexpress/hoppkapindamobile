import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import '../../routes/app_router.dart';
import '../auth/auth_service.dart';

/// MP4 video intro splash screen.
///
/// Intro videosu oynar → tamamlanınca otomatik onboarding/login'e geçer.
/// Video yüklenemezse (assets eksik, hata) eski animasyonlu fallback devreye girer.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _videoReady = false;
  bool _videoFailed = false;

  // Fallback animasyon (video açılmazsa)
  late final AnimationController _fallbackController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final Animation<double> _scale = CurvedAnimation(
    parent: _fallbackController,
    curve: Curves.easeOutBack,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _fallbackController,
    curve: const Interval(0.2, 1, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    // Tam ekran — status bar / nav bar gizle
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final controller = VideoPlayerController.asset(
        'assets/videos/intro.mp4',
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _videoController = controller;
        _videoReady = true;
      });

      // Video bitince navigate et
      controller.addListener(_onVideoUpdate);
      await controller.play();
    } catch (_) {
      // Asset bulunamazsa veya hata olursa fallback'e düş
      if (!mounted) return;
      setState(() => _videoFailed = true);
      _fallbackController.forward();
      await Future.delayed(const Duration(milliseconds: 2200));
      _navigateNext();
    }
  }

  void _onVideoUpdate() {
    final ctrl = _videoController;
    if (ctrl == null) return;
    final pos = ctrl.value.position;
    final dur = ctrl.value.duration;
    // Video bitti mi? (son 200ms tolerans)
    if (dur.inMilliseconds > 0 &&
        pos.inMilliseconds >= dur.inMilliseconds - 200) {
      ctrl.removeListener(_onVideoUpdate);
      _navigateNext();
    }
  }

  Future<void> _navigateNext() async {
    if (!mounted) return;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('onboarding_seen') ?? false;

    if (!seen) {
      if (mounted) context.go(AppRoutes.onboarding);
      return;
    }

    // Kayıtlı oturum varsa role'e göre yönlendir.
    // Oturum yoksa giriş ekranına ZORLAMIYORUZ — misafir olarak devam
    // ediyormuş gibi direkt home'a gidiyor; giriş kontrolü zaten sepette var.
    final session = await AuthService.restoreSession();
    if (!mounted) return;

    if (session == null) {
      context.go(AppRoutes.home);
    } else if (session.role == 'courier') {
      context.go(AppRoutes.courierOrders);
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _videoController?.removeListener(_onVideoUpdate);
    _videoController?.dispose();
    _fallbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Video hazır → tam ekran oynat
    if (_videoReady && _videoController != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _videoController!.value.size.width,
              height: _videoController!.value.size.height,
              child: VideoPlayer(_videoController!),
            ),
          ),
        ),
      );
    }

    // Yükleniyor veya fallback animasyon
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5A00D6), Color(0xFF4400A8), Color(0xFF7B3BE0)],
          ),
        ),
        child: Stack(
          children: [
            // Dekoratif arka plan daireleri
            Positioned(
              top: -60, right: -40,
              child: _glassCircle(180, 0.10),
            ),
            Positioned(
              bottom: -50, left: -50,
              child: _glassCircle(160, 0.08),
            ),
            // Video yükleniyor göstergesi
            if (!_videoFailed)
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 32, height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            // Fallback logo animasyonu
            if (_videoFailed)
              Center(
                child: ScaleTransition(
                  scale: _scale,
                  child: FadeTransition(
                    opacity: _fade,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _LogoCard(),
                        SizedBox(height: 24),
                        Text(
                          'Hopp Kapında',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Aklına geleni kapına getiriyoruz',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Alt loading (fallback)
            if (_videoFailed)
              Positioned(
                bottom: 60, left: 0, right: 0,
                child: Center(
                  child: FadeTransition(
                    opacity: _fade,
                    child: const SizedBox(
                      width: 28, height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation(Colors.white70),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _glassCircle(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(opacity),
          shape: BoxShape.circle,
        ),
      );
}

class _LogoCard extends StatelessWidget {
  const _LogoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Icon(
        Icons.delivery_dining_rounded,
        size: 64,
        color: Color(0xFF5A00D6),
      ),
    );
  }
}
