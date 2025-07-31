import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';

class PdfService {
  static Future<File> generateProjectPdf(
    Map<String, dynamic> projectData,
  ) async {
    // Türkçe lokalizasyonu yükle
    await initializeDateFormatting('tr_TR', null);

    // Türkçe font yükle
    final fontData = await rootBundle.load("assets/fonts/NotoSans-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);

    final pdf = pw.Document();

    // Tarih formatlayıcı
    final dateFormat = DateFormat('dd MMMM yyyy', 'tr_TR');

    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData(defaultTextStyle: pw.TextStyle(font: ttf)),
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(25),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    'Proje Detayları',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),

                // Proje Bilgileri
                _buildDetailRow('Proje Adi', projectData['projeAdi'] ?? ''),
                _buildDetailRow('Referans No', projectData['referansNo'] ?? ''),
                _buildDetailRow(
                  'Proje Durumu',
                  projectData['projeDurumu'] ?? '',
                ),
                _buildDetailRow(
                  'Destek Programi',
                  projectData['destekProgrami'] ?? '',
                ),
                _buildDetailRow('Destek Türü', projectData['destekTuru'] ?? ''),
                _buildDetailRow(
                  'Yararlanici Adi',
                  projectData['yararlaniciAdi'] ?? '',
                ),

                // Tarih alanları
                if (projectData['projeBaslamaTarihi'] != null)
                  _buildDetailRow(
                    'Proje Baslangiç Tarihi',
                    _formatDate(projectData['projeBaslamaTarihi'], dateFormat),
                  ),

                if (projectData['projeBitisTarihi'] != null)
                  _buildDetailRow(
                    'Proje Bitis Tarihi',
                    _formatDate(projectData['projeBitisTarihi'], dateFormat),
                  ),

                if (projectData['sozlesmeImzalamaTarihi'] != null)
                  _buildDetailRow(
                    'Sözlesme imza tarihi',
                    _formatDate(
                      projectData['sozlesmeImzalamaTarihi'],
                      dateFormat,
                    ),
                  ),

                // Diğer bilgiler
                _buildDetailRow('il', projectData['il'] ?? ''),
                _buildDetailRow('ilçe', projectData['ilce'] ?? ''),
                _buildDetailRow(
                  'Bütçe',
                  '${projectData['sozlesmeButcesi']?.toStringAsFixed(2) ?? '0.00'} ₺',
                ),
                _buildDetailRow(
                  'Destek Tutari',
                  '${projectData['sozlesmeDestekTutari']?.toStringAsFixed(2) ?? '0.00'} ₺',
                ),

                // Proje Açıklaması
                pw.SizedBox(height: 20),
                pw.Text(
                  'Proje Açiklamasi:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 5),
                pw.Text(projectData['projeAciklamasi'] ?? ''),
              ],
            ),
          );
        },
      ),
    );

    return _saveDocument(
      name: 'proje_detay_${projectData['projeAdi']}.pdf',
      pdf: pdf,
    );
  }

  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  static String _formatDate(String? dateString, DateFormat formatter) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return formatter.format(date);
    } catch (e) {
      return dateString;
    }
  }

  // pdf_service.dart dosyasına bu metodu ekleyin
  static Future<void> openFile(File file) async {
    final path = file.path;
    await OpenFile.open(path);
  }

  static Future<File> _saveDocument({
    required String name,
    required pw.Document pdf,
  }) async {
    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(await bytes);
    return file;
  }
}
