// lib/views/project_list_screen.dart
import 'package:flutter/material.dart';
import 'package:dakaizleme/views/ajans_destek_add_edit_screen.dart';
import 'package:dakaizleme/views/ajans_destek_detail_screen.dart';
import 'package:dakaizleme/models/ajans_destek.dart';
import 'package:dakaizleme/services/ajans_destek_service.dart';
import 'package:dakaizleme/views/home_screen.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  final AjansDestekService _ajansDestekService = AjansDestekService();
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Filtreleme Durum Değişkenleri
  String? _selectedStatusFilter;
  String? _selectedYilFilter;
  String? _selectedDestekTuruFilter;
  String? _selectedIlFilter;

  // Dropdown'lar için dinamik listeler
  List<String> _statusOptions = [];
  List<String> _yilOptions = [];
  List<String> _destekTuruOptions = [];
  List<String> _ilOptions = [];

  @override
  void initState() {
    super.initState();
    _fetchFilterOptions();
  }

  Future<void> _fetchFilterOptions() async {
    try {
      final statuses = await _ajansDestekService.getDistinctFieldValues('projeDurumu');
      final mdpYillari = await _ajansDestekService.getDistinctFieldValues('yil');
      final destekTurleri = await _ajansDestekService.getDistinctFieldValues('destekTuru');
      final iller = await _ajansDestekService.getDistinctFieldValues('il');

      setState(() {
        _statusOptions = statuses;
        _yilOptions = mdpYillari;
        _destekTuruOptions = destekTurleri;
        _ilOptions = iller;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Filtre seçenekleri yüklenirken hata oluştu: $e')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _selectedStatusFilter = null;
      _selectedYilFilter = null;
      _selectedDestekTuruFilter = null;
      _selectedIlFilter = null;
    });
    Navigator.pop(context); // Filtreleme dialogunu kapat
  }

  void _showFilterOptions() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filtrele',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Divider(height: 20, thickness: 1),
                  _buildFilterDropdown(
                    setModalState,
                    'Proje Durumu',
                    _statusOptions,
                    _selectedStatusFilter,
                    (value) {
                      setModalState(() {
                        _selectedStatusFilter = value;
                      });
                      setState(() {
                        _selectedStatusFilter = value;
                      });
                    },
                    colorScheme,
                    textTheme,
                  ),
                  _buildFilterDropdown(
                    setModalState,
                    'yil',
                    _yilOptions,
                    _selectedYilFilter,
                    (value) {
                      setModalState(() {
                        _selectedYilFilter = value;
                      });
                      setState(() {
                        _selectedYilFilter = value;
                      });
                    },
                    colorScheme,
                    textTheme,
                  ),
                  _buildFilterDropdown(
                    setModalState,
                    'Destek Türü',
                    _destekTuruOptions,
                    _selectedDestekTuruFilter,
                    (value) {
                      setModalState(() {
                        _selectedDestekTuruFilter = value;
                      });
                      setState(() {
                        _selectedDestekTuruFilter = value;
                      });
                    },
                    colorScheme,
                    textTheme,
                  ),
                  _buildFilterDropdown(
                    setModalState,
                    'İl',
                    _ilOptions,
                    _selectedIlFilter,
                    (value) {
                      setModalState(() {
                        _selectedIlFilter = value;
                      });
                      setState(() {
                        _selectedIlFilter = value;
                      });
                    },
                    colorScheme,
                    textTheme,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _resetFilters,
                        child: Text(
                          'Filtreleri Temizle',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Dialogu kapat
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Uygula',
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterDropdown(
    StateSetter setModalState,
    String title,
    List<String> options,
    String? currentValue,
    ValueChanged<String?> onChanged,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: currentValue,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              filled: true,
              fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            hint: Text(
              'Tümü',
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
            ),
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text('Tümü', style: textTheme.bodyMedium),
              ),
              ...options.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option, style: textTheme.bodyMedium),
                );
              }),
            ],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Tüm Projeler',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 8, 49, 70),
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list_rounded, color: colorScheme.onPrimary),
            tooltip: 'Filtrele',
            onPressed: _showFilterOptions,
          ),
          IconButton(
            icon: Icon(Icons.map_rounded, color: colorScheme.onPrimary),
            tooltip: 'Genel Harita Görünümüne Geç',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const HomeScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Projelerde ara...',
                hintStyle: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: colorScheme.onSurfaceVariant,
                ),
                filled: true,
                fillColor: colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
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
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          // Aktif filtre ve sıralama göstergeleri
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                if (_selectedStatusFilter != null)
                  _buildFilterChip('Durum: $_selectedStatusFilter', () {
                    setState(() {
                      _selectedStatusFilter = null;
                    });
                  }, colorScheme),
                if (_selectedYilFilter != null)
                  _buildFilterChip('Yıl: $_selectedYilFilter', () {
                    setState(() {
                      _selectedYilFilter = null;
                    });
                  }, colorScheme),
                if (_selectedDestekTuruFilter != null)
                  _buildFilterChip('Destek: $_selectedDestekTuruFilter', () {
                    setState(() {
                      _selectedDestekTuruFilter = null;
                    });
                  }, colorScheme),
                if (_selectedIlFilter != null)
                  _buildFilterChip('İl: $_selectedIlFilter', () {
                    setState(() {
                      _selectedIlFilter = null;
                    });
                  }, colorScheme),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: StreamBuilder<List<AjansDestek>>(
                stream: _ajansDestekService.getAjansDestekleri(
                  yil: _selectedYilFilter,
                  destekTuru: _selectedDestekTuruFilter,
                  projeDurumu: _selectedStatusFilter,
                  il: _selectedIlFilter,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 80,
                              color: colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Projeler yüklenirken bir hata oluştu: ${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: textTheme.titleMedium?.copyWith(
                                color: colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_rounded,
                              size: 80,
                              color: colorScheme.onSurfaceVariant.withOpacity(
                                0.6,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Henüz hiç proje eklenmemiş veya seçili filtrelere uygun proje bulunamadı. Yeni bir proje eklemek için aşağıdaki "+" butonuna dokunun.',
                              textAlign: TextAlign.center,
                              style: textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final allProjects = snapshot.data!;
                  final filteredProjects =
                      allProjects.where((project) {
                    return project.projeAdi.toLowerCase().contains(
                                _searchQuery,
                              ) ||
                              project.referansNo.toLowerCase().contains(
                                _searchQuery,
                              ) ||
                              project.yararlaniciAdi.toLowerCase().contains(
                                _searchQuery,
                              ) ||
                              project.il.toLowerCase().contains(_searchQuery) ||
                              project.ilce.toLowerCase().contains(_searchQuery) ||
                              project.destekTuru.toLowerCase().contains(
                                _searchQuery,
                              );
                  }).toList();

                  return Text(
                    'Gösterilen Proje Sayısı: ${filteredProjects.length}',
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<AjansDestek>>(
              stream: _ajansDestekService.getAjansDestekleri(
                yil: _selectedYilFilter,
                destekTuru: _selectedDestekTuruFilter,
                projeDurumu: _selectedStatusFilter,
                il: _selectedIlFilter,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 80,
                            color: colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Projeler yüklenirken bir hata oluştu: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_rounded,
                            size: 80,
                            color: colorScheme.onSurfaceVariant.withOpacity(
                              0.6,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Henüz hiç proje eklenmemiş veya seçili filtrelere uygun proje bulunamadı. Yeni bir proje eklemek için aşağıdaki "+" butonuna dokunun.',
                            textAlign: TextAlign.center,
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final allProjects = snapshot.data!;
                final filteredProjects =
                    allProjects.where((project) {
                  return project.projeAdi.toLowerCase().contains(
                                _searchQuery,
                              ) ||
                              project.referansNo.toLowerCase().contains(
                                _searchQuery,
                              ) ||
                              project.yararlaniciAdi.toLowerCase().contains(
                                _searchQuery,
                              ) ||
                              project.il.toLowerCase().contains(_searchQuery) ||
                              project.ilce.toLowerCase().contains(_searchQuery) ||
                              project.destekTuru.toLowerCase().contains(
                                _searchQuery,
                              );
                }).toList();

                if (filteredProjects.isEmpty && _searchQuery.isNotEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 80,
                            color: colorScheme.onSurfaceVariant.withOpacity(
                              0.6,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aradığınız kriterlerde proje bulunamadı.',
                            textAlign: TextAlign.center,
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return AnimationLimiter(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: filteredProjects.length,
                    itemBuilder: (context, index) {
                      final project = filteredProjects[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(
                          milliseconds: 375,
                        ),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildProjectCard(
                              context,
                              project,
                              colorScheme,
                              textTheme,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (context) => const AjansDestekAddEditScreen(),
                ),
              )
              .then(
                (_) => setState(() {
                  _fetchFilterOptions(); // Yeni proje eklendikten sonra filtre seçeneklerini yenile
                }),
              );
        },
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDelete, ColorScheme colorScheme) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: colorScheme.onPrimaryContainer,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: colorScheme.primaryContainer,
      deleteIcon: Icon(
        Icons.close,
        size: 18,
        color: colorScheme.onPrimaryContainer,
      ),
      onDeleted: onDelete,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
    );
  }

  Widget _buildProjectCard(
    BuildContext context,
    AjansDestek project,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    Color statusColor;
    IconData statusIcon;
    switch (project.projeDurumu.toLowerCase()) {
      case 'proje tamamlandı':
        statusColor = Colors.green.shade600;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'gs onayı yapıldı':
        statusColor = Colors.green.shade600;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'sözleşme imzalandı':
        statusColor = Colors.orange.shade600;
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case 'eksik evrak alınamadı':
        statusColor = Colors.orange.shade600;
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case 'dk değerlendirmesinde başarısız kararı onaylandı':
        statusColor = Colors.red.shade600;
        statusIcon = Icons.cancel_rounded;
        break;
      case 'dk değerlendirmesinde başarısız':
        statusColor = Colors.red.shade600;
        statusIcon = Icons.cancel_rounded;
        break;
      case 'ön incelemede başarısız':
        statusColor = Colors.orange.shade600;
        statusIcon = Icons.cancel_rounded;
        break;
      case 'sözleşme feshedildi':
        statusColor = Colors.orange.shade600;
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case 'ajans tarafından reddedildi':
        statusColor = Colors.red.shade600;
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = colorScheme.onSurfaceVariant;
        statusIcon = Icons.info_rounded;
    }

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 0,
        vertical: 8,
      ),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AjansDestekDetailScreen(ajansDestekId: project.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'ajansDestekImage-${project.id}',
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: project.imageUrl != null && project.imageUrl!.isNotEmpty
                        ? Image.network(
                            project.imageUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (
                              context,
                              child,
                              loadingProgress,
                            ) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: colorScheme.primary,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.broken_image_rounded,
                              size: 40,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          )
                        : Icon(
                            Icons.folder_open_rounded,
                            size: 40,
                            color: colorScheme.onSurfaceVariant,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.projeAdi,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    _buildInfoLine(
                      Icons.person_rounded,
                      'Yararlanıcı: ${project.yararlaniciAdi}',
                      colorScheme,
                      textTheme,
                    ),
                    _buildInfoLine(
                      Icons.location_on_rounded,
                      'Konum: ${project.il}, ${project.ilce}',
                      colorScheme,
                      textTheme,
                    ),
                    if (project.projeBaslamaTarihi != null)
                      _buildInfoLine(
                        Icons.calendar_today_rounded,
                        'Başlangıç: ${_dateFormat.format(project.projeBaslamaTarihi!)}',
                        colorScheme,
                        textTheme,
                      ),
                    const SizedBox(height: 8),
                    _buildStatusChip(
                      project.projeDurumu,
                      statusColor,
                      statusIcon,
                      colorScheme,
                      textTheme,
                    ),
                  ],
                ),
              ),
              if (project.latitude != null && project.longitude != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    child: IconButton(
                      icon: Icon(
                        Icons.map_outlined,
                        color: colorScheme.primary,
                        size: 30,
                      ),
                      tooltip: 'Haritada Göster',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => HomeScreen(
                              initialLatitude: project.latitude!,
                              initialLongitude: project.longitude!,
                              initialProjectName: project.projeAdi,
                              initialProjectId: project.id,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoLine(
    IconData icon,
    String text,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: colorScheme.onSurfaceVariant.withOpacity(0.8),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(
    String status,
    Color color,
    IconData icon,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      constraints: BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              status,
              style: textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}