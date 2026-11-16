import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';

enum CommercialInvoiceFormat { a4, termica }

class CommercialInvoiceService {
  final ApiClient _api;

  CommercialInvoiceService({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  /// Registra el comprobante comercial no fiscal antes de solicitar su PDF.
  /// El backend hace esta operación idempotente para una misma venta.
  Future<void> issue(int saleId) async {
    await _api.post(ApiEndpoints.facturaComercial(saleId));
  }

  Future<Uint8List> download(
    int saleId, {
    CommercialInvoiceFormat format = CommercialInvoiceFormat.a4,
  }) async {
    final bytes = await _api.getBytes(
      ApiEndpoints.facturaComercialPdf(saleId),
      queryParameters: {
        'formato': format == CommercialInvoiceFormat.termica ? 'termica' : 'a4',
      },
    );
    return Uint8List.fromList(bytes);
  }

  Future<File> save(
    int saleId, {
    CommercialInvoiceFormat format = CommercialInvoiceFormat.a4,
  }) async {
    final bytes = await download(saleId, format: format);
    final directory = await getApplicationDocumentsDirectory();
    final suffix = format == CommercialInvoiceFormat.termica ? 'termica' : 'a4';
    final file = File('${directory.path}${Platform.pathSeparator}COM-$saleId-$suffix.pdf');
    return file.writeAsBytes(bytes, flush: true);
  }

  Future<void> openSaved(File file) async {
    final result = await OpenFilex.open(file.path, type: 'application/pdf');
    if (result.type != ResultType.done) {
      throw StateError(result.message);
    }
  }

  Future<void> openEmailComposer({required String subject, required String body}) async {
    final uri = Uri(scheme: 'mailto', queryParameters: {'subject': subject, 'body': body});
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw StateError('No se pudo abrir la aplicación de correo.');
    }
  }

  Future<void> openWhatsApp() async {
    final uri = Uri.parse('https://web.whatsapp.com/');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw StateError('No se pudo abrir WhatsApp Web.');
    }
  }
}
