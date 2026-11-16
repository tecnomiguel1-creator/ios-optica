import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/sale_model.dart';
import '../../services/sales_service.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/loading_indicator.dart';

/// Historial de consulta para móvil. No incluye cobro, anulación ni edición.
class MobileSalesHistoryScreen extends StatefulWidget {
  const MobileSalesHistoryScreen({super.key});

  @override
  State<MobileSalesHistoryScreen> createState() =>
      _MobileSalesHistoryScreenState();
}

class _MobileSalesHistoryScreenState extends State<MobileSalesHistoryScreen> {
  final _service = SalesService();
  final _search = TextEditingController();
  bool _loading = true;
  String? _error;
  List<SaleModel> _sales = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sales = await _service.getSales(limite: 100);
      if (!mounted) return;
      setState(() {
        _sales = sales;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo cargar el historial de ventas.';
      });
    }
  }

  List<SaleModel> get _filtered {
    final term = _search.text.trim().toLowerCase();
    if (term.isEmpty) return _sales;
    return _sales.where((sale) {
      return sale.numeroFactura.toLowerCase().contains(term) ||
          sale.clienteNombre.toLowerCase().contains(term);
    }).toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: _loading
            ? const LoadingIndicator(message: 'Cargando historial de ventas...')
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                  children: [
                    const Text('Historial de ventas',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    const Text('Consulta las ventas ya registradas.',
                        style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Factura o cliente',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Actualizar',
                          onPressed: _load,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_error != null)
                      ErrorBanner(message: _error!, onRetry: _load),
                    if (_filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 52),
                        child: Center(
                          child: Text('No hay ventas que coincidan.',
                              style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      )
                    else
                      ..._filtered.map(_saleCard),
                  ],
                ),
              ),
      );

  Widget _saleCard(SaleModel sale) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          leading: const CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            child: Icon(Icons.receipt_long_outlined, color: AppColors.primary),
          ),
          title: Text(sale.numeroFactura,
              style: const TextStyle(fontWeight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${sale.clienteNombre}\n${Formatters.formatDateTime(sale.fechaVenta)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          isThreeLine: true,
          trailing: SizedBox(
            width: 92,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(Formatters.formatCurrency(sale.total),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: AppColors.primary)),
                const SizedBox(height: 3),
                Text(sale.estadoPago.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          onTap: () => _showDetails(sale),
        ),
      );

  Future<void> _showDetails(SaleModel sale) async {
    SaleModel detail = sale;
    try {
      detail = await _service.getSaleById(sale.id);
    } catch (_) {
      // El resumen de la venta sigue siendo útil aunque falle el detalle.
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 18),
            Text(detail.numeroFactura,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Text(Formatters.formatDateTime(detail.fechaVenta),
                style: const TextStyle(color: AppColors.textSecondary)),
            const Divider(height: 28),
            _line('Cliente', detail.clienteNombre),
            _line('Total', Formatters.formatCurrency(detail.total)),
            _line('Pagado', Formatters.formatCurrency(detail.montoPagado)),
            _line('Saldo', Formatters.formatCurrency(detail.balancePendiente)),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
              child: const Text('Cerrar'),
            )
          ]),
        ),
      ),
    );
  }

  Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(color: AppColors.textSecondary))),
          const SizedBox(width: 12),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          )
        ]),
      );
}
