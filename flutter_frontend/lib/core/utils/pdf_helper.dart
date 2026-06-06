import 'dart:typed_data';
import 'pdf_helper_stub.dart'
    if (dart.library.html) 'pdf_helper_web.dart'
    if (dart.library.io) 'pdf_helper_mobile.dart';

/// Interfaz para guardar y abrir archivos PDF de forma multiplataforma.
abstract class PdfHelper {
  Future<void> saveAndOpenPdf(Uint8List bytes, String fileName);
}

/// Fábrica para obtener la implementación correcta según la plataforma.
PdfHelper getPdfHelperInstance() => getPdfHelper();
