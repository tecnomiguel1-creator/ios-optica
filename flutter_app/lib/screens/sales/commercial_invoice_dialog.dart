import 'dart:io';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/sale_model.dart';
import '../../services/commercial_invoice_service.dart';

class CommercialInvoiceDialog extends StatefulWidget {
  final SaleModel sale;
  final CommercialInvoiceFormat initialFormat;
  final bool openPrintDialog;
  const CommercialInvoiceDialog({
    super.key,
    required this.sale,
    this.initialFormat = CommercialInvoiceFormat.a4,
    this.openPrintDialog = false,
  });

  @override
  State<CommercialInvoiceDialog> createState() =>
      _CommercialInvoiceDialogState();
}

class _CommercialInvoiceDialogState extends State<CommercialInvoiceDialog> {
  final _service = CommercialInvoiceService();
  late CommercialInvoiceFormat _format;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _format = widget.initialFormat;
    if (widget.openPrintDialog) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _saveAndOpen(print: true));
    }
  }

  Future<void> _run(Future<void> Function() action,
      {String? successMessage}) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted && successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo procesar el PDF comercial: $error'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveAndOpen({bool print = false}) => _run(() async {
        await _service.issue(widget.sale.id);
        final File file = await _service.save(widget.sale.id, format: _format);
        await _service.openSaved(file);
        if (print && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Documento abierto para impresión. Selecciona tu impresora (A4 o Térmica) en el visor de Windows.'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      },
          successMessage:
              print ? null : 'Vista previa de factura abierta en visor PDF.');

  Future<void> _saveOnly() => _run(() async {
        await _service.issue(widget.sale.id);
        final File file = await _service.save(widget.sale.id, format: _format);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Archivo guardado exitosamente en: ${file.path}'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      });

  Future<void> _email() => _run(() async {
        final File file = await _service.save(widget.sale.id, format: _format);
        await _service.openEmailComposer(
          subject:
              'Comprobante comercial ${widget.sale.numeroFactura} - ONLY EYES 360',
          body: 'Estimado/a ${widget.sale.clienteNombre},\n\n'
              'Adjunto encontrará el comprobante comercial correspondiente a su compra ${widget.sale.numeroFactura}.\n'
              'Ruta del archivo generado: ${file.path}\n\n'
              '(Nota: Debe adjuntar manualmente este archivo en su cliente de correo)',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Se abrió su cliente de correo. Recuerde adjuntar manualmente: ${file.path}'),
            ),
          );
        }
      });

  Future<void> _whatsApp() => _run(() async {
        final File file = await _service.save(widget.sale.id, format: _format);
        await _service.openWhatsApp();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'PDF generado en: ${file.path}. Por favor, adjunte este archivo en su chat de WhatsApp.'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;
    final cashPayments = widget.sale.pagos
        .where((payment) => payment.metodoPago == 'efectivo')
        .toList();
    final receivedCash = cashPayments
        .where((payment) => payment.montoRecibido != null)
        .fold<double>(0.0, (total, payment) => total + payment.montoRecibido!);
    final appliedCash = cashPayments.fold<double>(
        0.0, (total, payment) => total + payment.monto);
    final change = cashPayments.fold<double>(
        0.0, (total, payment) => total + payment.cambio);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 780,
          maxHeight: media.height * 0.88,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.receipt_long_outlined,
                          color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Comprobante Comercial: ${widget.sale.numeroFactura}',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary),
                          ),
                          Text(
                            'Cliente: ${widget.sale.clienteNombre}  •  Total: ${Formatters.formatCurrency(widget.sale.total)}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    SegmentedButton<CommercialInvoiceFormat>(
                      segments: const [
                        ButtonSegment(
                            value: CommercialInvoiceFormat.a4,
                            label: Text('A4')),
                        ButtonSegment(
                            value: CommercialInvoiceFormat.termica,
                            label: Text('Térmica (80mm)')),
                      ],
                      selected: {_format},
                      onSelectionChanged: _busy
                          ? null
                          : (values) => setState(() => _format = values.first),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _busy ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),

                // Banner Informativo No Fiscal
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppColors.textSecondary, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Comprobante comercial de venta y entrega para control interno de la óptica. El documento se genera como PDF vectorial.',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Resumen de la Venta
                Card(
                  elevation: 0,
                  color: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Resumen del Comprobante',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Fecha de Venta:',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                            Text(Formatters.formatDate(widget.sale.fechaVenta),
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal:',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                            Text(
                                Formatters.formatCurrency(widget.sale.subtotal),
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        if (widget.sale.descuentoTotal > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Descuento aplicado:',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                              Text(
                                  '- ${Formatters.formatCurrency(widget.sale.descuentoTotal)}',
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.success)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Impuestos (ITBIS):',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                            Text(
                                Formatters.formatCurrency(
                                    widget.sale.impuestos),
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total a Facturar:',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w800)),
                            Text(Formatters.formatCurrency(widget.sale.total),
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Monto Pagado / Abono:',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                            Text(
                                Formatters.formatCurrency(
                                    widget.sale.montoPagado),
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        if (receivedCash > 0) ...[
                          const SizedBox(height: 4),
                          _summaryRow('Efectivo recibido:', receivedCash),
                        ],
                        if (cashPayments.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _summaryRow(
                              'Efectivo aplicado a la venta:', appliedCash),
                        ],
                        if (change > 0) ...[
                          const SizedBox(height: 4),
                          _summaryRow('Cambio devuelto:', change,
                              color: AppColors.success, bold: true),
                        ],
                        if (widget.sale.balancePendiente > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Saldo por Cobrar:',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                  Formatters.formatCurrency(
                                      widget.sale.balancePendiente),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Aviso sobre adjuntos en mensajería
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.attachment_outlined,
                          size: 16, color: AppColors.primary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Nota de envío: Los canales de correo y WhatsApp abren la aplicación correspondiente; el archivo PDF generado debe seleccionarse y adjuntarse manualmente.',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.primaryDark),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Botonera de Acciones
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => _saveAndOpen(),
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('Vista Previa'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _saveOnly,
                      icon: const Icon(Icons.save_alt_outlined, size: 18),
                      label: const Text('Guardar PDF'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _email,
                      icon: const Icon(Icons.email_outlined, size: 18),
                      label: const Text('Correo'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _whatsApp,
                      icon: const Icon(Icons.chat_outlined, size: 18),
                      label: const Text('WhatsApp'),
                    ),
                    FilledButton.icon(
                      onPressed: _busy ? null : () => _saveAndOpen(print: true),
                      icon: const Icon(Icons.print_outlined, size: 18),
                      label: Text(
                          _busy ? 'Procesando...' : 'Imprimir / Reimprimir'),
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double value,
          {Color? color, bool bold = false}) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: color ?? AppColors.textSecondary,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(Formatters.formatCurrency(value),
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w600)),
        ],
      );
}
