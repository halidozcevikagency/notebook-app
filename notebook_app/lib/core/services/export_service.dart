/// Dışa Aktarma Servisi (düzeltilmiş)
/// PDF → PdfGoogleFonts ile Türkçe karakter desteği
/// Markdown → UTF-8 encode ile Türkçe karakter desteği
import 'dart:convert' show utf8;
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/note_model.dart';

class ExportService {
  /// Notu PDF olarak dışa aktar - Türkçe destekli Noto Sans font
  static Future<void> exportAsPdf(
      BuildContext context, NoteModel note, String plainText) async {
    // Türkçe karakter desteği için Google Fonts'tan Noto Sans yükle
    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: font,
        bold: boldFont,
      ),
    );

    final lines = plainText
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              note.title,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              _formatDate(note.updatedAt),
              style: pw.TextStyle(
                font: font,
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 8),
          ],
        ),
        build: (ctx) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: lines.map((line) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Text(
                  line,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 12,
                    lineSpacing: 1.5,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        footer: (ctx) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Notebook',
              style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey500),
            ),
            pw.Text(
              'Sayfa ${ctx.pageNumber} / ${ctx.pagesCount}',
              style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey500),
            ),
          ],
        ),
      ),
    );

    final bytes = await pdf.save();
    final fileName = _sanitizeFileName(note.title);
    _downloadBytes(bytes, '$fileName.pdf', 'application/pdf');
  }

  /// Notu Markdown olarak dışa aktar - UTF-8 encode ile Türkçe desteği
  static void exportAsMarkdown(NoteModel note, String plainText) {
    final sb = StringBuffer();
    sb.writeln('# ${note.title}');
    sb.writeln('');
    sb.writeln('*Son düzenleme: ${_formatDate(note.updatedAt)}*');
    sb.writeln('');
    sb.writeln('---');
    sb.writeln('');

    // Her satırı temiz markdown'a dönüştür
    for (final line in plainText.split('\n')) {
      sb.writeln(line);
    }

    // UTF-8 encode - Türkçe karakterler için kritik!
    final bytes = utf8.encode(sb.toString());
    final fileName = _sanitizeFileName(note.title);
    _downloadBytes(bytes, '$fileName.md', 'text/markdown; charset=utf-8');
  }

  /// Web'de Uint8List byte dosyası indir
  static void _downloadBytes(List<int> bytes, String fileName, String mimeType) {
    final jsBytes = bytes is List<int> ? bytes : bytes.toList();
    final blob = html.Blob([jsBytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String _sanitizeFileName(String name) {
    final sanitized = name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
    return sanitized.isEmpty ? 'untitled' : sanitized;
  }
}
