import 'pdf_helper.dart';

/// Stub que se usa cuando ninguna de las librerías específicas (html o io) está disponible.
PdfHelper getPdfHelper() => throw UnsupportedError('No se puede crear el helper sin implementaciones específicas.');
