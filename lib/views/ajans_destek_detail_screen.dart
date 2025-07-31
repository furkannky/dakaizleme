import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/ajans_destek_service.dart';
import '../models/ajans_destek.dart';
import 'ajans_destek_add_edit_screen.dart';
import '../models/user_model.dart';
import '../utils/role_helper.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/pdf_service.dart';

class AjansDestekDetailScreen extends StatefulWidget {
  final String ajansDestekId;

  const AjansDestekDetailScreen({super.key, required this.ajansDestekId});

  @override
  State<AjansDestekDetailScreen> createState() =>
      _AjansDestekDetailScreenState();
}

class _AjansDestekDetailScreenState extends State<AjansDestekDetailScreen>
    with TickerProviderStateMixin {
  // Services and Data
  final AjansDestekService _ajansDestekService = AjansDestekService();
  AjansDestek? _ajansDestek;
  bool _isLoading = true;
  final DateFormat _dateFormat = DateFormat('d MMMM y', 'tr');

  // Animation Controllers
  // Controllers are non-nullable and initialized in initState for certainty.
  late final AnimationController _gradientAnimationController;
  late final Animation<double> _gradientAnimation;

  @override
  void initState() {
    super.initState();
    _loadAjansDestekDetails();

    _gradientAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _gradientAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _gradientAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _gradientAnimationController.dispose();
    super.dispose();
  }

  /// Loads the details of the AjansDestek from the service.
  /// Handles loading state, errors, and updates the UI accordingly.
  Future<void> _loadAjansDestekDetails() async {
    if (!mounted) return; // Ensure the widget is still in the tree

    setState(() {
      _isLoading = true;
    });

    try {
      final ajansDestek = await _ajansDestekService.getAjansDestekById(
        widget.ajansDestekId,
      );
      if (mounted) {
        setState(() {
          _ajansDestek = ajansDestek;
          _isLoading = false;
        });
        debugPrint('Ajans Destek Detayları Yüklendi. Resim URL: ${_ajansDestek?.imageUrl}'); // <<<< Hata ayıklama çıktısı
      }
    } catch (e) {
      debugPrint('Error loading ajans destek details: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Detaylar yüklenirken bir hata oluştu.', isError: true);
      }
    }
  }

  /// Shows a SnackBar message to the user.
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _downloadAsPdf() async {
    if (_ajansDestek == null) return;

    try {
      // İzin durumlarını kontrol et
      bool isStorageGranted = false;
      
      // Android 10 (API 29) ve üzeri için MANAGE_EXTERNAL_STORAGE izni gerekir
      if (await Permission.storage.request().isGranted) {
        isStorageGranted = true;
      } else if (await Permission.manageExternalStorage.request().isGranted) {
        isStorageGranted = true;
      }

      if (!isStorageGranted) {
        if (!mounted) return;
        _showSnackBar('Dosya indirmek için depolama izni gerekli', isError: true);
        await openAppSettings(); // Kullanıcıyı ayarlara yönlendir
        return;
      }

      // Yükleme göstergesini göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // PDF oluştur
      final pdfFile = await PdfService.generateProjectPdf(_ajansDestek!.toFirestore());

      // Yükleme göstergesini kapat
      if (!mounted) return;
      Navigator.of(context).pop();

      // PDF'i açma veya paylaşma seçeneklerini göster
      showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.open_in_browser),
                title: const Text('PDF\'i Aç'),
                onTap: () {
                  Navigator.pop(context);
                  PdfService.openFile(pdfFile);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Paylaş'),
                onTap: () {
                  Navigator.pop(context);
                  Share.shareXFiles([XFile(pdfFile.path)], text: 'Proje Detayları');
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Yükleme göstergesini kapat
      _showSnackBar('PDF oluşturulurken hata: $e', isError: true);
    }
  }

  List<Widget> _buildAppBarActions() {
    final appUser = Provider.of<AppUser?>(context);
    final bool isAdmin = RoleHelper.isAdmin(appUser?.role);
    final bool canEdit = RoleHelper.canEdit(appUser?.role);
    final bool canDelete = RoleHelper.canDelete(appUser?.role);

    return [
      IconButton(
        icon: const Icon(Icons.download),
        tooltip: 'PDF Olarak İndir',
        onPressed: _downloadAsPdf,
      ),
      if (canEdit)
        IconButton(
          icon: const Icon(Icons.edit_rounded),
          tooltip: 'Düzenle',
          onPressed: () {
            if (_ajansDestek != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AjansDestekAddEditScreen(
                    ajansDestek: _ajansDestek,
                  ),
                ),
              ).then((_) {
                _loadAjansDestekDetails();
              });
            }
          },
        ),
      if (canDelete)
        IconButton(
          icon: const Icon(Icons.delete_rounded),
          tooltip: 'Sil',
          onPressed: () => _confirmAndDelete(context, Theme.of(context).colorScheme, Theme.of(context).textTheme),
        ),
    ];
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        'Proje Detayı',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 8, 49, 70),
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      elevation: 4,
      centerTitle: true,
      actions: _buildAppBarActions(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appUser = Provider.of<AppUser?>(context);
    final bool isAdmin = RoleHelper.isAdmin(appUser?.role);
    final bool canEdit = RoleHelper.canEdit(appUser?.role);
    final bool canDelete = RoleHelper.canDelete(appUser?.role);

    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final List<Color> gradientColors1 = [
      colorScheme.primary.withOpacity(0.8),
      colorScheme.secondary.withOpacity(0.8),
    ];
    final List<Color> gradientColors2 = [
      colorScheme.secondary.withOpacity(0.8),
      colorScheme.tertiary.withOpacity(0.8),
    ];

    // If still loading or data is null, show a loading indicator or error message
    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    // If _ajansDestek is null after loading, display an informative message
    if (_ajansDestek == null) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: colorScheme.onPrimary,
        ),
        body: AnimatedBuilder(
          animation: _gradientAnimation,
          builder: (context, child) {
            final currentColors = [
              Color.lerp(
                  gradientColors1[0], gradientColors2[0], _gradientAnimation.value)!,
              Color.lerp(
                  gradientColors1[1], gradientColors2[1], _gradientAnimation.value)!,
            ];
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: currentColors,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.sentiment_dissatisfied_rounded,
                      size: 80,
                      color: colorScheme.onPrimary.withOpacity(0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ajans desteği bulunamadı veya silinmiş olabilir.',
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadAjansDestekDetails,
                      icon: Icon(Icons.refresh, color: colorScheme.onPrimary),
                      label: Text('Yeniden Dene',
                          style: TextStyle(color: colorScheme.onPrimary)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary.withOpacity(0.7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: AnimatedBuilder(
        animation: _gradientAnimation,
        builder: (context, child) {
/*           final currentColors = [
            Color.lerp(
                gradientColors1[0], gradientColors2[0], _gradientAnimation.value)!,
            Color.lerp(
                gradientColors1[1], gradientColors2[1], _gradientAnimation.value)!,
          ]; */
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color.fromARGB(255, 2, 11, 17), Color.fromARGB(255, 47, 116, 172)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                      height:
                          MediaQuery.of(context).padding.top + kToolbarHeight), // Dynamic AppBar height
                  // RESİM EN ÜSTTE
                  if (_ajansDestek!.imageUrl != null &&
                      _ajansDestek!.imageUrl!.isNotEmpty)
                    Hero(
                      tag: 'ajansDestekImage-${_ajansDestek!.id}',
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24.0),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.shadow.withOpacity(0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24.0),
                            child: Image.network(
                              _ajansDestek!.imageUrl!,
                              height: 280,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) {
                                  debugPrint('Image.network: Resim yüklendi: ${_ajansDestek!.imageUrl!}');
                                  return child;
                                }
                                debugPrint('Image.network: Resim yükleniyor: ${_ajansDestek!.imageUrl!} - Progress: ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
                                return Container(
                                  height: 280,
                                  color: colorScheme.surfaceVariant,
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                              : null,
                                          color: colorScheme.primary,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Resim yükleniyor...',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint('Image.network: Resim yüklenirken hata oluştu: $error');
                                return GestureDetector(
                                  onTap: () {
                                    // Reload the image when tapped
                                    setState(() {});
                                  },
                                  child: Container(
                                    height: 280,
                                    color: colorScheme.errorContainer.withOpacity(0.1),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.broken_image_rounded,
                                          color: colorScheme.error,
                                          size: 64,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Resim yüklenemedi',
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: colorScheme.onErrorContainer,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Dokunup tekrar deneyin',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onErrorContainer.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  // PROJE ADI VE destek PROGRAM BİLGİSİ RESMİN ALTINDA
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                      children: [
                        // Proje Adı
                        Text(
                          _ajansDestek!.projeAdi,
                          textAlign: TextAlign.center,
                          style: textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 25,
                            color: colorScheme.onPrimary,
                            shadows: [
                              Shadow(
                                offset: const Offset(2, 2),
                                blurRadius: 3.0,
                                color: Colors.black.withOpacity(0.3),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // destek Programı Bilgisi
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                          ),
                          child: Text(
                            '${_ajansDestek!.destekProgrami} - ${_ajansDestek!.yil}',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // PROJE AÇIKLAMASI PROJE ADININ ALTINDA
                  if (_ajansDestek!.projeAciklamasi != null &&
                      _ajansDestek!.projeAciklamasi!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        color: colorScheme.surface,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('Proje Açıklaması', colorScheme, textTheme),
                              const Divider(height: 24, thickness: 0.5, color: Colors.black12),
                              Text(
                                _ajansDestek!.projeAciklamasi!,
                                style: textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurface,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.justify,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  _buildInfoCard(
                    context,
                    colorScheme,
                    textTheme,
                    children: [
                      _buildSectionTitle(
                          'Genel Bilgiler', colorScheme, textTheme),
                      const Divider(
                          height: 24, thickness: 0.5, color: Colors.black12),
                      _buildInfoRow(
                        Icons.numbers_rounded,
                        'Referans No',
                        _ajansDestek!.referansNo,
                        colorScheme,
                        textTheme,
                      ),
                      _buildInfoRow(
                        Icons.location_on_rounded,
                        'Uygulama İli/İlçesi',
                        '${_ajansDestek!.il}, ${_ajansDestek!.ilce}',
                        colorScheme,
                        textTheme,
                      ),
                      if (_ajansDestek!.latitude != null &&
                          _ajansDestek!.longitude != null)
                        _buildInfoRow(
                          Icons.map_rounded,
                          'Enlem/Boylam',
                          '${_ajansDestek!.latitude!.toStringAsFixed(4)}, ${_ajansDestek!.longitude!.toStringAsFixed(4)}',
                          colorScheme,
                          textTheme,
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildInfoCard(
                    context,
                    colorScheme,
                    textTheme,
                    children: [
                      _buildSectionTitle(
                          'Kurum ve Destek Bilgileri', colorScheme, textTheme),
                      const Divider(
                          height: 24, thickness: 0.5, color: Colors.black12),
                      _buildInfoRow(
                        Icons.corporate_fare_rounded,
                        'Yararlanıcı Adı',
                        _ajansDestek!.yararlaniciAdi,
                        colorScheme,
                        textTheme,
                      ),
                      _buildInfoRow(
                        Icons.category_rounded,
                        'Destek Türü',
                        _ajansDestek!.destekTuru,
                        colorScheme,
                        textTheme,
                      ),
                      _buildInfoRow(
                        Icons.help_outline_rounded,
                        'Desteklenen Alan',
                        _ajansDestek!.desteklenenAlan,
                        colorScheme,
                        textTheme,
                      ),
                      _buildInfoRow(
                        Icons.published_with_changes_rounded,
                        'Proje Durumu',
                        _ajansDestek!.projeDurumu,
                        colorScheme,
                        textTheme,
                      ),
                      _buildInfoRow(
                        Icons.timeline_rounded,
                        'NACE Faaliyet Kısmı',
                        _ajansDestek!.naceFaaliyetKisimi,
                        colorScheme,
                        textTheme,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildInfoCard(
                    context,
                    colorScheme,
                    textTheme,
                    children: [
                      _buildSectionTitle(
                          'Tarih Bilgileri', colorScheme, textTheme),
                      const Divider(
                          height: 24, thickness: 0.5, color: Colors.black12),
                      _buildInfoRow(
                        Icons.event_note_rounded,
                        'Sözleşme İmzalama Tarihi',
                        _ajansDestek!.sozlesmeImzalamaTarihi != null
                            ? _dateFormat.format(_ajansDestek!.sozlesmeImzalamaTarihi!)
                            : 'Belirtilmemiş',
                        colorScheme,
                        textTheme,
                      ),
                      _buildInfoRow(
                        Icons.date_range_rounded,
                        'Proje Başlama Tarihi',
                        _ajansDestek!.projeBaslamaTarihi != null
                            ? _dateFormat.format(_ajansDestek!.projeBaslamaTarihi!)
                            : 'Belirtilmemiş',
                        colorScheme,
                        textTheme,
                      ),
                      _buildInfoRow(
                        Icons.event_rounded,
                        'Proje Bitiş Tarihi',
                        _ajansDestek!.projeBitisTarihi != null
                            ? _dateFormat.format(_ajansDestek!.projeBitisTarihi!)
                            : 'Belirtilmemiş',
                        colorScheme,
                        textTheme,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildInfoCard(
                    context,
                    colorScheme,
                    textTheme,
                    children: [
                      _buildSectionTitle('Mali Bilgiler', colorScheme, textTheme),
                      const Divider(
                          height: 24, thickness: 0.5, color: Colors.black12),
                      _buildInfoRow(
                        Icons.request_quote_rounded,
                        'Teknik Destek Maliyeti',
                        NumberFormat.currency(locale: 'tr_TR', symbol: '₺')
                            .format(_ajansDestek!.teknikDestekMaliyeti),
                        colorScheme,
                        textTheme,
                        isCurrency: true,
                      ),
                      _buildInfoRow(
                        Icons.account_balance_wallet_rounded,
                        'Nihai Hibe', //Sözleşme Destek Tutarı
                        NumberFormat.currency(locale: 'tr_TR', symbol: '₺')
                            .format(_ajansDestek!.sozlesmeDestekTutari),
                        colorScheme,
                        textTheme,
                        isCurrency: true,
                      ),
                      _buildInfoRow(
                        Icons.attach_money_rounded,
                        'Nihai Bütçe',//Sözleşme Bütçesi
                        NumberFormat.currency(locale: 'tr_TR', symbol: '₺')
                            .format(_ajansDestek!.sozlesmeButcesi),
                        colorScheme,
                        textTheme,
                        isCurrency: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Reusable Card widget for displaying sections of information.
  Widget _buildInfoCard(BuildContext context, ColorScheme colorScheme,
      TextTheme textTheme,
      {required List<Widget> children}) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  /// Helper widget for section titles within info cards.
  Widget _buildSectionTitle(
      String title, ColorScheme colorScheme, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  /// Helper widget for displaying a single row of information (icon, label, value).
  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    bool isCurrency = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: textTheme.bodyLarge?.copyWith(
                    color: isCurrency 
                        ? colorScheme.primary 
                        : colorScheme.onSurface,
                    fontWeight: isCurrency 
                        ? FontWeight.bold 
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Handles the confirmation and deletion process for an AjansDestek item.
  Future<void> _confirmAndDelete(BuildContext context,
      ColorScheme colorScheme, TextTheme textTheme) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Desteği Sil',
          style: textTheme.headlineSmall?.copyWith(color: colorScheme.error),
        ),
        content: Text(
          'Bu ajans desteğini kalıcı olarak silmek istediğinizden emin misiniz?',
          style: textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'İptal',
              style: textTheme.labelLarge?.copyWith(color: colorScheme.primary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _ajansDestekService.deleteAjansDestek(
          widget.ajansDestekId,
        );
        if (mounted) {
          Navigator.of(context).pop(); // Go back after successful deletion
          _showSnackBar('Proje başarıyla silindi.');
        }
      } catch (e) {
        debugPrint('Error deleting ajans destek: $e');
        if (mounted) {
          _showSnackBar('Proje silinirken bir hata oluştu.', isError: true);
        }
      }
    }
  }
}
