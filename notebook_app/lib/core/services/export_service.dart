/// Dışa Aktarma Servisi
/// Not içeriğini PDF veya Markdown olarak dışa aktarır
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/note_model.dart';

class ExportService {
  /// Notu PDF olarak dışa aktar (web download)
  static Future<void> exportAsPdf(BuildContext context, NoteModel note, String plainText) async {
    final pdf = pw.Document();

    // Metni satırlara böl
    final lines = plainText.split('\n');
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              note.title,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              _formatDate(note.updatedAt),
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 8),
          ],
        ),
        build: (context) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: lines.map((line) {
              if (line.trim().isEmpty) {
                return pw.SizedBox(height: 8);
              }
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(
                  line,
                  style: const pw.TextStyle(
                    fontSize: 12,
                    lineSpacing: 1.5,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Notebook App',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
            ),
            pw.Text(
              'Page ${context.pageNumber} / ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
            ),
          ],
        ),
      ),
    );

    // PDF'i byte array olarak al ve tarayıcıda indir
    final bytes = await pdf.save();
    final fileName = _sanitizeFileName(note.title);
    _downloadFile(bytes, '$fileName.pdf', 'application/pdf');
  }

  /// Notu Markdown olarak dışa aktar (web download)
  static void exportAsMarkdown(NoteModel note, String plainText) {
    final sb = StringBuffer();
    
    // Başlık
    sb.writeln('# ${note.title}');
    sb.writeln('');
    sb.writeln('*Last edited: ${_formatDate(note.updatedAt)}*');
    sb.writeln('');
    sb.writeln('---');
    sb.writeln('');
    
    // İçerik
    sb.writeln(plainText);

    final content = sb.toString();
    final bytes = content.codeUnits;
    final fileName = _sanitizeFileName(note.title);
    _downloadFile(bytes, '$fileName.md', 'text/markdown');
  }

  /// Web'de dosya indirme
  static void _downloadFile(dynamic bytes, String fileName, String mimeType) {
    final blob = html.Blob([bytes], mimeType);
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
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim().isEmpty
        ? 'untitled'
        : name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
  }
}
