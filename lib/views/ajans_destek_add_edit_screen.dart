import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';

import '../models/ajans_destek.dart';
import '../services/ajans_destek_service.dart';
import '../services/storage_service.dart';
import 'map_picker_screen.dart';
import '../utils/app_theme.dart';

class AjansDestekAddEditScreen extends StatefulWidget {
  final AjansDestek? ajansDestek;

  const AjansDestekAddEditScreen({super.key, this.ajansDestek});

  @override
  State<AjansDestekAddEditScreen> createState() => _AjansDestekAddEditScreenState();
}

class _AjansDestekAddEditScreenState extends State<AjansDestekAddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final AjansDestekService _ajansDestekService = AjansDestekService();
  final StorageService _storageService = StorageService();
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');

  late TextEditingController _destekTuruController;
  late TextEditingController _desteklenenAlanController;
  late TextEditingController _mdpAdiController;
  late TextEditingController _projeAdiController;
  late TextEditingController _projeDurumuController;
  late TextEditingController _naceFaaliyetKisimiController;
  late TextEditingController _ilController;
  late TextEditingController _ilceController;
  late TextEditingController _referansNoController;
  late TextEditingController _yararlaniciAdiController;
  late TextEditingController _mdpYiliController;
  late TextEditingController _sozlesmeDestekTutariController;
  late TextEditingController _sozlesmeButcesiController;
  late TextEditingController _teknikDestekMaliyetiController;
  late TextEditingController _projeAciklamasiController;

  double? _latitude;
  double? _longitude;
  late TextEditingController _projeBaslamaTarihiController;
  late TextEditingController _projeBitisTarihiController;
  late TextEditingController _sozlesmeImzalamaTarihiController;

  DateTime? _projeBaslamaTarihi;
  DateTime? _projeBitisTarihi;
  DateTime? _sozlesmeImzalamaTarihi;

  File? _imageFile;
  String? _existingImageUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _destekTuruController = TextEditingController(text: widget.ajansDestek?.destekTuru ?? '');
    _desteklenenAlanController = TextEditingController(text: widget.ajansDestek?.desteklenenAlan ?? '');
    _mdpAdiController = TextEditingController(text: widget.ajansDestek?.destekProgrami ?? '');
    _projeAdiController = TextEditingController(text: widget.ajansDestek?.projeAdi ?? '');
    _projeDurumuController = TextEditingController(text: widget.ajansDestek?.projeDurumu ?? '');
    _naceFaaliyetKisimiController = TextEditingController(text: widget.ajansDestek?.naceFaaliyetKisimi ?? '');
    _referansNoController = TextEditingController(text: widget.ajansDestek?.referansNo ?? '');
    _yararlaniciAdiController = TextEditingController(text: widget.ajansDestek?.yararlaniciAdi ?? '');

    _mdpYiliController = TextEditingController(text: (widget.ajansDestek?.yil ?? 0).toString());
    _sozlesmeDestekTutariController = TextEditingController(text: (widget.ajansDestek?.sozlesmeDestekTutari ?? 0.0).toString());
    _sozlesmeButcesiController = TextEditingController(text: (widget.ajansDestek?.sozlesmeButcesi ?? 0.0).toString());
    _teknikDestekMaliyetiController = TextEditingController(text: (widget.ajansDestek?.teknikDestekMaliyeti ?? 0.0).toString());

    _projeBaslamaTarihi = widget.ajansDestek?.projeBaslamaTarihi;
    _projeBitisTarihi = widget.ajansDestek?.projeBitisTarihi;
    _sozlesmeImzalamaTarihi = widget.ajansDestek?.sozlesmeImzalamaTarihi;

    _projeBaslamaTarihiController = TextEditingController(text: _projeBaslamaTarihi != null ? _dateFormat.format(_projeBaslamaTarihi!) : '');
    _projeBitisTarihiController = TextEditingController(text: _projeBitisTarihi != null ? _dateFormat.format(_projeBitisTarihi!) : '');
    _sozlesmeImzalamaTarihiController = TextEditingController(text: _sozlesmeImzalamaTarihi != null ? _dateFormat.format(_sozlesmeImzalamaTarihi!) : '');

    _latitude = widget.ajansDestek?.latitude;
    _longitude = widget.ajansDestek?.longitude;

    _ilController = TextEditingController(text: widget.ajansDestek?.il ?? '');
    _ilceController = TextEditingController(text: widget.ajansDestek?.ilce ?? '');

    _existingImageUrl = widget.ajansDestek?.imageUrl;
    _projeAciklamasiController = TextEditingController(text: widget.ajansDestek?.projeAciklamasi ?? '');
  }

  @override
  void dispose() {
    _destekTuruController.dispose();
    _desteklenenAlanController.dispose();
    _mdpAdiController.dispose();
    _projeAdiController.dispose();
    _projeDurumuController.dispose();
    _naceFaaliyetKisimiController.dispose();
    _ilController.dispose();
    _ilceController.dispose();
    _referansNoController.dispose();
    _yararlaniciAdiController.dispose();
    _mdpYiliController.dispose();
    _sozlesmeDestekTutariController.dispose();
    _sozlesmeButcesiController.dispose();
    _teknikDestekMaliyetiController.dispose();
    _projeBaslamaTarihiController.dispose();
    _projeBitisTarihiController.dispose();
    _sozlesmeImzalamaTarihiController.dispose();
    _projeAciklamasiController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(
    BuildContext context, {
    required Function(DateTime) onDateSelected,
    required DateTime? initialDate, // initialDate null olabilir
    required TextEditingController controller,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(), // Null ise şimdiki tarihi kullan
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != initialDate) {
      onDateSelected(picked);
      controller.text = _dateFormat.format(picked);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _existingImageUrl = null; // Yeni resim seçildiğinde mevcut URL'yi temizle
      });
    }
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
      _existingImageUrl = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resim kaldırıldı'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _selectLocationFromMap() async {
    final LatLng? pickedLocation = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          initialLocation: _latitude != null && _longitude != null
              ? LatLng(_latitude!, _longitude!)
              : null,
        ),
      ),
    );

    if (pickedLocation != null) {
      setState(() {
        _latitude = pickedLocation.latitude;
        _longitude = pickedLocation.longitude;

        _getAddressFromLatLng(pickedLocation.latitude, pickedLocation.longitude);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Konum güncellendi: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _getAddressFromLatLng(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _ilController.text = place.administrativeArea ?? '';
          _ilceController.text = place.subAdministrativeArea ?? place.locality ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Adres bilgisi alınamadı')),
        );
      }
    }
  }

  Future<void> _saveAjansDestek() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isSaving = true;
    });

    String? newImageUrl = _existingImageUrl;
    if (_imageFile != null) {
      try {
        newImageUrl = await _storageService.uploadProjectImage(_imageFile!);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Resim yüklenirken bir hata oluştu: $e')),
          );
        }
        setState(() {
          _isSaving = false;
        });
        return;
      }
    } else if (widget.ajansDestek != null && _existingImageUrl == null) {
      // Düzenleme modunda resim kaldırıldıysa, URL'yi null yap
      newImageUrl = null;
    }

    final newAjansDestek = AjansDestek(
      id: widget.ajansDestek?.id ?? '',
      destekProgrami: _mdpAdiController.text,
      destekTuru: _destekTuruController.text,
      desteklenenAlan: _desteklenenAlanController.text,
      yil: int.tryParse(_mdpYiliController.text) ?? 0,
      yararlaniciAdi: _yararlaniciAdiController.text,
      referansNo: _referansNoController.text,
      projeAdi: _projeAdiController.text,
      projeDurumu: _projeDurumuController.text,
      naceFaaliyetKisimi: _naceFaaliyetKisimiController.text,
      teknikDestekMaliyeti: double.tryParse(_teknikDestekMaliyetiController.text) ?? 0.0,
      sozlesmeButcesi: double.tryParse(_sozlesmeButcesiController.text) ?? 0.0,
      sozlesmeDestekTutari: double.tryParse(_sozlesmeDestekTutariController.text) ?? 0.0,
      sozlesmeImzalamaTarihi: _sozlesmeImzalamaTarihi,
      projeBaslamaTarihi: _projeBaslamaTarihi,
      projeBitisTarihi: _projeBitisTarihi,
      il: _ilController.text,
      ilce: _ilceController.text,
      latitude: _latitude,
      longitude: _longitude,
      imageUrl: newImageUrl,
      projeAciklamasi: _projeAciklamasiController.text,
    );

    try {
      if (widget.ajansDestek == null) {
        await _ajansDestekService.addAjansDestek(newAjansDestek);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ajans desteği başarıyla eklendi!')),
          );
        }
      } else {
        await _ajansDestekService.updateAjansDestek(newAjansDestek);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ajans desteği başarıyla güncellendi!')),
          );
        }
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ajans desteği kaydedilirken bir hata oluştu: $e')),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // Ortak TextField stilini tanımlayan yardımcı fonksiyon
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(color: AppColors.textDark, fontSize: 16.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: AppColors.borderColor),
          ),
          
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: AppColors.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: AppColors.accent, width: 2.0),
          ),
          filled: true,
          fillColor: AppColors.cardBackground,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        ),
        style: AppTextStyles.bodyText,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
      ),
    );
  }

  // Ortak DatePicker TextFormField stilini tanımlayan yardımcı fonksiyon
  Widget _buildDatePickerFormField({
    required TextEditingController controller,
    required String labelText,
    required DateTime? dateValue,
    required Function(DateTime) onDateSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          
          labelText: labelText,
          labelStyle: AppTextStyles.bodyText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: AppColors.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: AppColors.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: AppColors.accent, width: 2.0),
          ),
          filled: true,
          fillColor: AppColors.cardBackground,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          suffixIcon: const Icon(Icons.calendar_today, color: AppColors.primary),
        ),
        style: AppTextStyles.bodyText,
        onTap: () => _pickDate(
          context,
          onDateSelected: onDateSelected,
          initialDate: dateValue,
          controller: controller,
        ),
      ),
    );
  }

  // Ortak ElevatedButton stilini tanımlayan yardımcı fonksiyon
  Widget _buildElevatedButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.ajansDestek == null ? 'Yeni Ajans Desteği Ekle' : 'Ajans Desteğini Düzenle',
          style: AppTextStyles.appBarTitle,
        ),
        backgroundColor: const Color.fromARGB(255, 8, 49, 70),
        foregroundColor: Colors.white,
        elevation: 4.0,
      ),
      body: _isSaving
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.accent,
              ),
            )
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color.fromARGB(255, 2, 11, 17), Color.fromARGB(255, 47, 116, 172)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _buildTextFormField(
                        controller: _mdpAdiController,
                        labelText: ' destek programı (Opsiyonel)',
                      ),
                      const SizedBox(height: 12),
                      _buildTextFormField(
                        controller: _destekTuruController,
                        labelText: 'Destek Türü',
                        validator: (value) => value == null || value.isEmpty ? 'Lütfen destek türünü girin' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextFormField(
                        controller: _desteklenenAlanController,
                        labelText: 'Desteklenen Alan (Opsiyonel)',
                      ),
                      const SizedBox(height: 12),
                      _buildTextFormField(
                        controller: _mdpYiliController,
                        labelText: ' Yıl',
                        keyboardType: TextInputType.number,
                        validator: (value) => value == null || value.isEmpty ? 'Lütfen destek yılını girin' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextFormField(
                        controller: _yararlaniciAdiController,
                        labelText: 'Yararlanıcı Adı',
                        validator: (value) => value == null || value.isEmpty ? 'Lütfen yararlanıcı adını girin' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextFormField(
                        controller: _referansNoController,
                        labelText: 'Referans No (Opsiyonel)',
                      ),
                      const SizedBox(height: 12),
                      _buildTextFormField(
                        controller: _projeAdiController,
                        labelText: 'Proje Adı',
                        validator: (value) => value == null || value.isEmpty ? 'Lütfen proje adını girin' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextFormField(
                        controller: _projeDurumuController,
                        labelText: 'Proje Durumu',
                        maxLines: 3,
                        validator: (value) => value == null || value.isEmpty ? 'Lütfen proje durumunu girin' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextFormField(
                        controller: _naceFaaliyetKisimiController,
                        labelText: 'NACE Faaliyet Kısmı (Opsiyonel)',
                      ),
                      const SizedBox(height: 12),
                      _buildTextFormField(
                        controller: _teknikDestekMaliyetiController,
                        labelText: 'Teknik Destek Maliyeti (TL) (Opsiyonel)',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      _buildTextFormField(
                        controller: _sozlesmeButcesiController,
                        labelText: 'Nihai Bütçe (TL) (Opsiyonel)',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      _buildTextFormField(
                        controller: _sozlesmeDestekTutariController,
                        labelText: 'Nihai Hibe Tutarı (TL) (Opsiyonel)',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      _buildDatePickerFormField(
                        controller: _sozlesmeImzalamaTarihiController,
                        labelText: 'Sözleşme İmzalama Tarihi',
                        dateValue: _sozlesmeImzalamaTarihi,
                        onDateSelected: (date) => _sozlesmeImzalamaTarihi = date,
                      ),
                      const SizedBox(height: 12),
                      _buildDatePickerFormField(
                        controller: _projeBaslamaTarihiController,
                        labelText: 'Proje Başlama Tarihi',
                        dateValue: _projeBaslamaTarihi,
                        onDateSelected: (date) => _projeBaslamaTarihi = date,
                      ),
                      const SizedBox(height: 12),
                      _buildDatePickerFormField(
                        controller: _projeBitisTarihiController,
                        labelText: 'Proje Bitiş Tarihi',
                        dateValue: _projeBitisTarihi,
                        onDateSelected: (date) => _projeBitisTarihi = date,
                      ),
                      const SizedBox(height: 12),
                      _buildTextFormField(
                        controller: _ilController,
                        labelText: 'İl (Opsiyonel)',
                      ),
                      const SizedBox(height: 12),
                      _buildTextFormField(
                        controller: _ilceController,
                        labelText: 'İlçe (Opsiyonel)',
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                          child: ElevatedButton.icon(
                            onPressed: _selectLocationFromMap,
                            icon: const Icon(Icons.map, size: 20),
                            label: const Text('Haritadan Konum Seç'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ),
                      if (_latitude != null && _longitude != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Seçilen Konum: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                                style: AppTextStyles.locationInfo,
                              ),
                            ],
                          ),
                        ),

                      // Project description field moved to the end as it's a larger field
                      const SizedBox(height: 12),
                      _buildTextFormField(
                        controller: _projeAciklamasiController,
                        labelText: 'Proje Açıklaması (Opsiyonel)',
                        maxLines: 5,
                        keyboardType: TextInputType.multiline,
                        validator: (value) => value == null || value.isEmpty ? 'Lütfen proje açıklamasını girin' : null,
                      ),
                      const SizedBox(height: 20),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _buildElevatedButton(
                            onPressed: _pickImage,
                            icon: Icons.image,
                            label: 'Resim Seç',
                          ),
                          const SizedBox(width: 10),
                          if (_imageFile != null)
                            Flexible(
                              child: Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8.0),
                                      border: Border.all(color: AppColors.textGrey.withOpacity(0.3), width: 1.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 3,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.file(
                                        _imageFile!,
                                        height: 100,
                                        width: 150,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: AppColors.errorRed),
                                    onPressed: _removeImage,
                                  ),
                                ],
                              ),
                            )
                          else if (widget.ajansDestek != null && _existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                            Flexible(
                              child: Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8.0),
                                      border: Border.all(color: AppColors.textGrey.withOpacity(0.3), width: 1.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 3,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.network(
                                        _existingImageUrl!,
                                        height: 100,
                                        width: 150,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: AppColors.errorRed),
                                    onPressed: _removeImage,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveAjansDestek,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 3,
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                widget.ajansDestek == null ? 'Kaydet' : 'Güncelle',
                                style: AppTextStyles.buttonText,
                              ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

// app_theme.dart dosyası (örnek olarak, mevcut projenizde olduğundan emin olun)
class AppColors {
  static const Color primary = Color(0xFF42A5F5); // Mavi tonu
  static const Color accent = Color(0xFFFFA726); // Turuncu tonu
  static const Color backgroundLight = Color(0xFFE3F2FD); // Açık mavi
  static const Color backgroundDarker = Color(0xFFBBDEFB); // Koyu açık mavi
  static const Color cardBackground = Color(0xFFFFFFFF); // Beyaz
  static const Color textDark = Color(0xFF263238); // Koyu gri
  static const Color textGrey = Color(0xFF607D8B); // Orta gri
  static const Color borderColor = Color(0xFF90CAF9); // Açık mavi border
  static const Color errorRed = Color(0xFFEF5350); // Kırmızı hata rengi
}

class AppTextStyles {
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 0.8,
  );
  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    color: AppColors.textDark,
  );
  static const TextStyle locationInfo = TextStyle(
    fontSize: 14,
    color: AppColors.textGrey,
    fontStyle: FontStyle.italic,
  );
  static const TextStyle buttonText = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
}