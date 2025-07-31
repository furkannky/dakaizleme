// lib/views/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuth'ı import etmeyi unutmayın
import '../services/auth_service.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; // Animasyonlar için
import 'package:dakaizleme/views/home_screen.dart'; // HomeScreen'i import ettiğinizden emin olun

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _errorMessage;
  bool _isLoadingAuth = false; // Kimlik doğrulama işlemi için yükleme durumu

  // Animasyon kontrolcüleri
  late AnimationController _gradientAnimationController;
  late Animation<double> _gradientAnimation;

  @override
  void initState() {
    super.initState();

    // Gradyan animasyonu için kontrolcü ve animasyon tanımlamaları
    _gradientAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15), // Animasyon süresi
    )..repeat(reverse: true); // Tekrar et ve tersine dön

    _gradientAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _gradientAnimationController,
        curve: Curves.easeInOutSine, // Daha dinamik bir eğri
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _gradientAnimationController.dispose();
    super.dispose();
  }

  Future<void> _submitAuthForm() async {
    setState(() {
      _errorMessage = null;
      _isLoadingAuth = true; // Start loading
    });

    try {
      print('AuthScreen: Giriş işlemi başlatılıyor...');
      await _authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      print('AuthScreen: AuthService.signInWithEmail tamamlandı.');

      // Giriş başarılı olduktan hemen sonra Firebase'in mevcut kullanıcısını kontrol edelim
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        print('AuthScreen: Giriş başarılı! Mevcut kullanıcı UID: ${currentUser.uid}');
        print('AuthScreen: Kullanıcıyı HomeScreen\'e yönlendiriliyor.');
        // Kullanıcıyı direkt olarak HomeScreen'e yönlendirelim.
        // main.dart'taki StreamBuilder doğru çalışana kadar bu geçici bir çözüm olabilir.
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (Route<dynamic> route) => false, // Tüm yığını temizle
          );
        }
      } else {
        print('AuthScreen: Giriş başarılı oldu ancak FirebaseAuth.currentUser null! Bu beklenmedik bir durum.');
        // Bu durum beklenmez, ancak olursa hata mesajı gösterelim
        if (mounted) {
          setState(() {
            _errorMessage = 'Giriş başarılı ancak oturum bilgisi alınamadı. Lütfen uygulamayı yeniden başlatın.';
            _isLoadingAuth = false;
          });
        }
      }

      // Yükleme durumunu kapat. Yönlendirme zaten yapıldıysa bu setState tetiklenmeyebilir.
      // Ancak hata durumları için bu satır önemli.
      if (mounted && _isLoadingAuth) { // Sadece hala yükleniyorsa setState yap
        setState(() {
          _isLoadingAuth = false;
        });
      }

    } on FirebaseAuthException catch (e) {
      String message = 'Bir hata oluştu, lütfen tekrar deneyin.';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        message = 'Geçersiz e-posta veya şifre.';
      } else if (e.code == 'wrong-password') {
        message = 'Yanlış şifre. Lütfen tekrar deneyin.';
      } else if (e.code == 'network-request-failed') {
        message = 'İnternet bağlantınızı kontrol edin.';
      } else if (e.code == 'invalid-email') {
        message = 'Geçersiz e-posta formatı.';
      }
      print('AuthScreen: FirebaseAuthException hata kodu: ${e.code}, mesaj: $message');
      if (mounted) {
        setState(() {
          _errorMessage = message;
          _isLoadingAuth = false;
        });
      }
    } catch (e) {
      print('AuthScreen: Bilinmeyen bir hata oluştu: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Bilinmeyen bir hata oluştu: $e';
          _isLoadingAuth = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      resizeToAvoidBottomInset: true, // Klavye açıldığında içeriği kaydır
      body: AnimatedBuilder(
        animation: _gradientAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: const [
                  Color.fromARGB(255, 2, 11, 17),
                  Color.fromARGB(255, 47, 116, 172),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: AnimationLimiter(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      // Uygulama Başlığı/Logosu
                      AnimationConfiguration.staggeredList(
                        position: 0,
                        duration: const Duration(milliseconds: 500),
                        child: SlideAnimation(
                          verticalOffset: -50.0,
                          child: FadeInAnimation(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.location_city_rounded, // Uygulama ikonunuz
                                  size: 100,
                                  color: colorScheme.onPrimary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'DAKA İzleme', // Uygulama adınız
                                  style: textTheme.displayMedium?.copyWith(
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    shadows: [
                                      Shadow(
                                        offset: const Offset(2, 2),
                                        blurRadius: 4.0,
                                        color: Colors.black.withOpacity(0.4),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // E-posta Alanı
                      AnimationConfiguration.staggeredList(
                        position: 1,
                        duration: const Duration(milliseconds: 500),
                        child: SlideAnimation(
                          horizontalOffset: -50.0,
                          child: FadeInAnimation(
                            child: TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                labelText: 'E-posta',
                                labelStyle: textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                prefixIcon: Icon(
                                  Icons.email_rounded,
                                  color: colorScheme.secondary,
                                ),
                                filled: true,
                                fillColor: colorScheme.surface.withOpacity(
                                  0.9,
                                ), // Hafif şeffaf
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colorScheme.outline.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Şifre Alanı
                      AnimationConfiguration.staggeredList(
                        position: 2,
                        duration: const Duration(milliseconds: 500),
                        child: SlideAnimation(
                          horizontalOffset: 50.0,
                          child: FadeInAnimation(
                            child: TextField(
                              controller: _passwordController,
                              obscureText: true,
                              style: textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Şifre',
                                labelStyle: textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                prefixIcon: Icon(
                                  Icons.lock_rounded,
                                  color: colorScheme.secondary,
                                ),
                                filled: true,
                                fillColor: colorScheme.surface.withOpacity(
                                  0.9,
                                ), // Hafif şeffaf
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colorScheme.outline.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Hata Mesajı
                      if (_errorMessage != null)
                        AnimationConfiguration.staggeredList(
                          position: 3,
                          duration: const Duration(milliseconds: 500),
                          child: FadeInAnimation(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 20.0),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.errorContainer.withOpacity(
                                    0.8,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: colorScheme.error,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onErrorContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Giriş Butonu
                      AnimationConfiguration.staggeredList(
                        position: 4,
                        duration: const Duration(milliseconds: 500),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: ElevatedButton(
                              onPressed: _isLoadingAuth ? null : _submitAuthForm, // Yükleniyorsa devre dışı bırak
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(
                                  double.infinity,
                                  56,
                                ), // Daha büyük buton

                                backgroundColor: const Color.fromARGB(255, 12, 12, 67),
                                foregroundColor: const Color.fromARGB(255, 9, 9, 62), // Bu renk genellikle onPressed ile birlikte kullanılır
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 8, // Daha belirgin gölge
                                shadowColor: colorScheme.primary.withOpacity(
                                  0.4,
                                ),
                              ),
                              child: _isLoadingAuth
                                  ? CircularProgressIndicator(
                                      color: colorScheme.onPrimary,
                                    ) // Yükleme göstergesi
                                  : Text(
                                      'Giriş Yap', // Sadece "Giriş Yap" olarak değişti
                                      style: textTheme.titleMedium?.copyWith(
                                        color: colorScheme.onPrimary,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Kayıt ol butonu kaldırıldı
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}