import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/purchase_model.dart';
import '../../services/purchase_service.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/loading_indicator.dart';
import '../inventory/supplier_list_screen.dart';
import 'new_purchase_screen.dart';

class PurchaseListScreen extends StatefulWidget {
  final AppState appState;

  const PurchaseListScreen({super.key, required this.appState});

  @override
  State<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends State<PurchaseListScreen> {
  final _purchaseService = PurchaseService();

  List<PurchaseModel> _purchases = [];
  String? _selectedEstado; // null = todas
  bool _loading = true;
  bool _isCreating = false;
  bool _showSuppliers = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await _purchaseService.getPurchases(estado: _selectedEstado);
      if (mounted) {
        setState(() {
          _purchases = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _receivePurchase(PurchaseModel purchase) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recepción de Mercancía'),
        content: Text(
          '¿Confirmas la recepción física de la Compra #${purchase.id} de "${purchase.proveedorNombre ?? "Proveedor"}"?\n\n'
          'Esta acción sumará automáticamente las existencias al inventario y creará las entradas en el Kardex.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Recibir y Actualizar Stock'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await _purchaseService.receivePurchase(purchase.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['mensaje'] ?? 'Compra recibida correctamente.'),
              backgroundColor: AppColors.success,
            ),
          );
          _loadPurchases();
          widget.appState.refreshLowStockCount();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }

  Future<void> _showPurchaseDetail(PurchaseModel purchase) async {
    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder<PurchaseModel>(
        future: _purchaseService.getPurchaseById(purchase.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AlertDialog(
              content: SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }
          final detailed = snapshot.data ?? purchase;
          final isPending = detailed.isPending;

          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Orden de Compra #${detailed.id}'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPending ? AppColors.warningLight : AppColors.successLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    detailed.estado.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isPending ? AppColors.warningDark : const Color(0xFF065F46),
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 580,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Proveedor: ${detailed.proveedorNombre ?? "No especificado"}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    if (detailed.numeroFactura != null && detailed.numeroFactura!.isNotEmpty)
                      Text('Factura de Proveedor: ${detailed.numeroFactura}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    Text('Fecha de compra: ${Formatters.formatDate(detailed.fechaCompra)}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 16),
                    const Text('Detalle de Mercancía Solicitada:',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 8),
                    if (detailed.detalles.isEmpty)
                      const Text('No se encontraron líneas de detalle registradas.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12))
                    else
                      Table(
                        border: TableBorder.all(color: AppColors.border, width: 0.8),
                        columnWidths: const {
                          0: FlexColumnWidth(4),
                          1: FlexColumnWidth(1.5),
                          2: FlexColumnWidth(2),
                          3: FlexColumnWidth(2),
                        },
                        children: [
                          const TableRow(
                            decoration: BoxDecoration(color: Color(0xFFF1F5F9)),
                            children: [
                              Padding(padding: EdgeInsets.all(8), child: Text('Producto', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                              Padding(padding: EdgeInsets.all(8), child: Text('Cant.', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12), textAlign: TextAlign.center)),
                              Padding(padding: EdgeInsets.all(8), child: Text('Costo Unit.', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12), textAlign: TextAlign.end)),
                              Padding(padding: EdgeInsets.all(8), child: Text('Subtotal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12), textAlign: TextAlign.end)),
                            ],
                          ),
                          ...detailed.detalles.map((d) => TableRow(
                            children: [
                              Padding(padding: const EdgeInsets.all(8), child: Text(d.productoNombre ?? 'Producto', style: const TextStyle(fontSize: 12))),
                              Padding(padding: const EdgeInsets.all(8), child: Text('${d.cantidad}', style: const TextStyle(fontSize: 12), textAlign: TextAlign.center)),
                              Padding(padding: const EdgeInsets.all(8), child: Text(Formatters.formatCurrency(d.precioUnitario), style: const TextStyle(fontSize: 12), textAlign: TextAlign.end)),
                              Padding(padding: const EdgeInsets.all(8), child: Text(Formatters.formatCurrency(d.subtotal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.end)),
                            ],
                          )),
                        ],
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        Text(Formatters.formatCurrency(detailed.subtotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Impuestos (ITBIS):', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        Text(Formatters.formatCurrency(detailed.impuestos), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL DE COMPRA:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                        Text(Formatters.formatCurrency(detailed.total), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cerrar'),
              ),
              if (isPending)
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Recibir Mercancía'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _receivePurchase(detailed);
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCreating) {
      return NewPurchaseScreen(
        onSaved: () {
          setState(() => _isCreating = false);
          _loadPurchases();
        },
        onCancel: () => setState(() => _isCreating = false),
      );
    }
    if (_showSuppliers) {
      return SupplierListScreen(
        appState: widget.appState,
        onBack: () => setState(() => _showSuppliers = false),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Órdenes de Compra y Recepción',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_purchases.length} compras registradas',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _showSuppliers = true),
                      icon: const Icon(Icons.business_outlined, size: 18),
                      label: const Text('Proveedores'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _isCreating = true),
                      icon: const Icon(Icons.add_shopping_cart, size: 18),
                      label: const Text('Nueva Orden de Compra'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Filtros de Estado
            Row(
              children: [
                FilterChip(
                  selected: _selectedEstado == null,
                  label: const Text('Todas'),
                  onSelected: (_) {
                    setState(() => _selectedEstado = null);
                    _loadPurchases();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  selected: _selectedEstado == 'pendiente',
                  label: const Text('Pendientes de Recepción'),
                  selectedColor: AppColors.warningLight,
                  onSelected: (_) {
                    setState(() => _selectedEstado = 'pendiente');
                    _loadPurchases();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  selected: _selectedEstado == 'recibida',
                  label: const Text('Recibidas'),
                  selectedColor: AppColors.successLight,
                  onSelected: (_) {
                    setState(() => _selectedEstado = 'recibida');
                    _loadPurchases();
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualizar lista',
                  onPressed: _loadPurchases,
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_error != null)
              ErrorBanner(message: _error!, onRetry: _loadPurchases),

            // Lista de Compras
            Expanded(
              child: _loading
                  ? const LoadingIndicator(message: 'Consultando órdenes de compra...')
                  : _purchases.isEmpty
                      ? EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'No hay órdenes de compra',
                          message:
                              'Registra compras a tus proveedores para surtir el inventario.',
                          buttonText: 'Crear Primera Compra',
                          onAction: () => setState(() => _isCreating = true),
                        )
                      : Card(
                          child: ListView.separated(
                            itemCount: _purchases.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (ctx, index) {
                              final p = _purchases[index];
                              final isPending = p.isPending;

                              return ListTile(
                                onTap: () => _showPurchaseDetail(p),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isPending
                                        ? AppColors.warningLight
                                        : AppColors.successLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    isPending
                                        ? Icons.hourglass_top_rounded
                                        : Icons.check_circle_outline,
                                    color: isPending
                                        ? AppColors.warning
                                        : AppColors.success,
                                    size: 22,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      'Compra #${p.id} • ${p.proveedorNombre ?? "Proveedor"}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (p.numeroFactura != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.border,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Fac: ${p.numeroFactura}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Text(
                                  'Fecha: ${Formatters.formatDate(p.fechaCompra)} • Total: ${Formatters.formatCurrency(p.total)} (Subtotal: ${Formatters.formatCurrency(p.subtotal)})',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isPending
                                            ? AppColors.warningLight
                                            : AppColors.successLight,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        p.estado.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isPending
                                              ? const Color(0xFF92400E)
                                              : const Color(0xFF065F46),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    if (isPending)
                                      ElevatedButton.icon(
                                        onPressed: () => _receivePurchase(p),
                                        icon: const Icon(Icons.inventory_sharp, size: 16),
                                        label: const Text('Recibir Mercancía'),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
