import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/sale_model.dart';
import '../../services/commercial_invoice_service.dart';
import 'commercial_invoice_dialog.dart';

class ReceiptDialog extends StatelessWidget {
  final SaleModel sale;
  final double? montoEntregado;
  final double cambio;

  const ReceiptDialog({
    super.key,
    required this.sale,
    this.montoEntregado,
    this.cambio = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final displayedChange = cambio > 0 ? cambio : sale.cambioTotal;
    final cashPayments = sale.pagos
        .where((payment) => payment.metodoPago == 'efectivo')
        .toList();
    final persistedReceived = cashPayments
        .where((payment) => payment.montoRecibido != null)
        .fold<double?>(
            null, (total, payment) => (total ?? 0) + payment.montoRecibido!);
    final receivedCash = montoEntregado ?? persistedReceived;
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Comprobante de Venta'),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Cabecera Ticket
                Image.asset('assets/branding/only_eyes_logo.jpg', height: 42),
                const SizedBox(height: 6),
                const Text(
                  AppConfig.appName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const Text(
                  'Datos comerciales configurados en Administración > Datos del negocio',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                const Divider(thickness: 1, color: Colors.black26),

                // Datos Factura
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('No: ${sale.numeroFactura}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                    Text(sale.fechaVenta,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Cliente:',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    Text(sale.clienteNombre,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12)),
                  ],
                ),
                const Divider(thickness: 1, color: Colors.black26),

                // Lista de Items
                const Text(
                    'SKU · DESCRIPCIÓN · CANTIDAD · PRECIO · DESCUENTO · TOTAL',
                    style:
                        TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...sale.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.codigo}\n${item.nombre}\n${item.cantidad} x ${Formatters.formatCurrency(item.precioUnitario)} · Desc. ${Formatters.formatCurrency(item.descuento)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Text(
                          Formatters.formatCurrency(item.subtotal),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(thickness: 1, color: Colors.black26),

                // Totales
                _ReceiptRow(
                    label: 'Subtotal:',
                    value: Formatters.formatCurrency(sale.subtotal)),
                if (sale.descuentoTotal > 0)
                  _ReceiptRow(
                    label: 'Descuento aplicado:',
                    value: '-${Formatters.formatCurrency(sale.descuentoTotal)}',
                  ),
                _ReceiptRow(
                    label: 'ITBIS / Impuestos:',
                    value: Formatters.formatCurrency(sale.impuestos)),
                const Divider(height: 16),
                _ReceiptRow(
                  label: 'TOTAL A PAGAR:',
                  value: Formatters.formatCurrency(sale.total),
                  isBold: true,
                  fontSize: 15,
                ),
                if (sale.pagos.isNotEmpty) ...[
                  if (cashPayments.isNotEmpty && receivedCash != null)
                    _ReceiptRow(
                      label: 'Efectivo recibido:',
                      value: Formatters.formatCurrency(receivedCash),
                    ),
                  if (cashPayments.isNotEmpty)
                    _ReceiptRow(
                      label: 'Efectivo aplicado a la venta:',
                      value: Formatters.formatCurrency(
                          cashPayments.fold<double>(
                              0.0, (total, payment) => total + payment.monto)),
                    ),
                  ...sale.pagos
                      .where((payment) => payment.metodoPago != 'efectivo')
                      .map(
                        (pago) => _ReceiptRow(
                          label:
                              '${pago.metodoPago[0].toUpperCase()}${pago.metodoPago.substring(1)} aplicada:',
                          value: Formatters.formatCurrency(pago.monto),
                        ),
                      ),
                ] else
                  _ReceiptRow(
                    label: montoEntregado == null
                        ? 'Pago recibido:'
                        : 'Efectivo entregado:',
                    value: Formatters.formatCurrency(
                      montoEntregado ?? sale.montoPagado,
                    ),
                  ),
                if (displayedChange > 0)
                  _ReceiptRow(
                    label: 'Cambio devuelto:',
                    value: Formatters.formatCurrency(displayedChange),
                    color: AppColors.success,
                    isBold: true,
                  ),
                if (sale.balancePendiente > 0)
                  _ReceiptRow(
                    label: 'Balance Pendiente:',
                    value: Formatters.formatCurrency(sale.balancePendiente),
                    color: AppColors.danger,
                    isBold: true,
                  ),

                const SizedBox(height: 16),
                const Divider(thickness: 1, color: Colors.black26),
                const Text(
                  '¡Gracias por confiar en ONLY EYES 360!\nConsulte las condiciones comerciales configuradas por la óptica.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        OutlinedButton.icon(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => CommercialInvoiceDialog(sale: sale),
          ),
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
          label: const Text('Factura PDF'),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            // El ticket debe salir desde este botón. Antes se abría un diálogo
            // que intentaba imprimir en su primer cuadro; si el visor tardaba
            // en responder, el archivo térmico podía no llegar a guardarse.
            final messenger = ScaffoldMessenger.of(context);
            try {
              final service = CommercialInvoiceService();
              await service.issue(sale.id);
              final file = await service.save(sale.id,
                  format: CommercialInvoiceFormat.termica);
              await service.openSaved(file);
              if (context.mounted) {
                messenger.showSnackBar(const SnackBar(
                  content: Text(
                      'Ticket térmico abierto. Selecciona la impresora térmica en el visor de Windows.'),
                  backgroundColor: AppColors.primary,
                ));
              }
            } catch (error) {
              if (context.mounted) {
                messenger.showSnackBar(SnackBar(
                  content: Text('No se pudo abrir el ticket térmico: $error'),
                  backgroundColor: AppColors.danger,
                ));
              }
            }
          },
          icon: const Icon(Icons.print_outlined, size: 18),
          label: const Text('Imprimir Ticket'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Aceptar'),
        ),
      ],
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final double fontSize;
  final Color? color;

  const _ReceiptRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.fontSize = 12,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: fontSize, color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
