import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../models/client_model.dart';
import '../../models/product_model.dart';
import '../../models/sale_model.dart';
import '../../services/client_service.dart';
import '../../services/inventory_service.dart';
import '../../services/sales_service.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/search_input.dart';
import 'insurance_coverage_card.dart';
import 'payment_split.dart';
import 'receipt_dialog.dart';
import 'commercial_invoice_dialog.dart';

class PosScreen extends StatefulWidget {
  final AppState appState;

  const PosScreen({super.key, required this.appState});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

/// Estructura vertical del panel de venta con un único viewport desplazable.
///
/// Mantiene la cabecera y la selección de cliente visibles y permite alcanzar
/// artículos, cobro, totales y ARS aun cuando el contenido sea más alto que la
/// ventana de Windows.
class PosCartViewport extends StatelessWidget {
  final Widget header;
  final Widget clientSection;
  final Widget cartContent;
  final Widget paymentAndTotals;

  const PosCartViewport({
    super.key,
    required this.header,
    required this.clientSection,
    required this.cartContent,
    required this.paymentAndTotals,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 12),
          clientSection,
          const SizedBox(height: 14),
          Expanded(
            child: SingleChildScrollView(
              key: const Key('pos-cart-viewport'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 180),
                    child: cartContent,
                  ),
                  const SizedBox(height: 12),
                  paymentAndTotals,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PosScreenState extends State<PosScreen> {
  final _inventoryService = InventoryService();
  final _clientService = ClientService();
  final _salesService = SalesService();

  final _searchController = TextEditingController();
  final _descuentoController = TextEditingController(text: '0.00');
  final _efectivoController = TextEditingController();
  final _tarjetaController = TextEditingController();
  final _transferenciaController = TextEditingController();

  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  List<ClientModel> _clients = [];
  ClientModel? _selectedClient;
  Map<String, String>? _pendingClient;
  String _clientQuery = '';

  final List<SaleItemModel> _cartItems = [];
  bool _loading = true;
  bool _isProcessing = false;
  String? _paymentIdempotencyKey;

  // Filtros visuales y Cobertura de Seguro Médico
  String? _selectedCategory;
  double _montoSeguroAutorizado = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCatalogAndClients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _descuentoController.dispose();
    _efectivoController.dispose();
    _tarjetaController.dispose();
    _transferenciaController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalogAndClients() async {
    setState(() => _loading = true);
    try {
      final prods = await _inventoryService.getProducts();
      final cls = await _clientService.getClients();
      if (mounted) {
        setState(() {
          _products = prods;
          _filteredProducts = prods;
          _clients = cls;
          _selectedClient = null;
          _loading = false;
        });
        _applyFilters();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch(String query) {
    _applyFilters();
  }

  void _applyFilters() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredProducts = _products.where((p) {
        final matchesQuery = q.isEmpty ||
            p.nombre.toLowerCase().contains(q) ||
            p.codigo.toLowerCase().contains(q) ||
            (p.marca ?? '').toLowerCase().contains(q);
        final matchesCat = _selectedCategory == null ||
            p.categoria.toLowerCase() == _selectedCategory!.toLowerCase();
        return matchesQuery && matchesCat;
      }).toList();
    });
  }

  void _addToCart(ProductModel product) {
    final index = _cartItems.indexWhere((i) => i.productoId == product.id);

    setState(() {
      if (index >= 0) {
        final existing = _cartItems[index];
        final newQty = existing.cantidad + 1;
        _cartItems[index] = SaleItemModel(
          productoId: existing.productoId,
          codigo: existing.codigo,
          nombre: existing.nombre,
          cantidad: newQty,
          precioUnitario: existing.precioUnitario,
          descuento: existing.descuento,
          subtotal: newQty * existing.precioUnitario - existing.descuento,
        );
      } else {
        _cartItems.add(SaleItemModel(
          productoId: product.id,
          codigo: product.codigo,
          nombre: product.nombre,
          cantidad: 1,
          precioUnitario: product.precioVenta,
          descuento: 0.0,
          subtotal: product.precioVenta,
        ));
      }
    });
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      final item = _cartItems[index];
      final newQty = item.cantidad + delta;
      if (newQty <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index] = SaleItemModel(
          productoId: item.productoId,
          codigo: item.codigo,
          nombre: item.nombre,
          cantidad: newQty,
          precioUnitario: item.precioUnitario,
          descuento: item.descuento,
          subtotal: newQty * item.precioUnitario - item.descuento,
        );
      }
    });
  }

  double get _subtotal =>
      _cartItems.fold<double>(0.0, (sum, item) => sum + item.subtotal);

  double get _descuentoSolicitado =>
      double.tryParse(_descuentoController.text.replaceAll(',', '.')) ?? 0.0;

  /// Nunca permite que un descuento visual exceda la mercancía vendida.
  double get _descuento =>
      _descuentoSolicitado.clamp(0.0, _subtotal).toDouble();

  /// El backend vuelve a calcular este importe. Se usa aquí solo para la vista
  /// previa, ponderando la tasa configurada en cada producto.
  double get _impuestos => _itemsConDescuento().fold<double>(0.0, (sum, item) {
        ProductModel? product;
        for (final candidate in _products) {
          if (candidate.id == item.productoId) {
            product = candidate;
            break;
          }
        }
        final rate = product?.itbisRate ?? AppConfig.itbisRate;
        // El backend redondea cada impuesto de línea a dos decimales.
        final lineTax = (item.subtotal * rate * 100).roundToDouble() / 100;
        return sum + lineTax;
      });

  double get _total => (_subtotal - _descuento + _impuestos) > 0
      ? (_subtotal - _descuento + _impuestos)
      : 0.0;

  List<SaleItemModel> get _itemsParaVista =>
      _cartItems.isEmpty ? const [] : _itemsConDescuento();

  double _itbisDeLinea(SaleItemModel item) {
    final product = _products.cast<ProductModel?>().firstWhere(
          (candidate) => candidate?.id == item.productoId,
          orElse: () => null,
        );
    final rate = product?.itbisRate ?? AppConfig.itbisRate;
    return (item.subtotal * rate * 100).roundToDouble() / 100;
  }

  double _amountFrom(TextEditingController controller) =>
      double.tryParse(controller.text.trim().replaceAll(',', '.')) ?? 0.0;

  PaymentSplit get _paymentSplit => PaymentSplit(
        total: _total,
        cash: _amountFrom(_efectivoController),
        card: _amountFrom(_tarjetaController),
        transfer: _amountFrom(_transferenciaController),
      );

  bool get _canProcessSale {
    if (_cartItems.isEmpty || _isProcessing) return false;
    if (_descuentoSolicitado < 0 || _descuentoSolicitado > _subtotal) {
      return false;
    }
    return _paymentSplit.isValid;
  }

  /// Distribuye el descuento general entre las líneas antes de enviarlas al
  /// backend, para que el ticket, inventario y total persistan el mismo monto.
  List<SaleItemModel> _itemsConDescuento() {
    var descuentoPendiente = _descuento;
    return _cartItems.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final bruto = item.cantidad * item.precioUnitario;
      final descuentoLinea = index == _cartItems.length - 1
          ? descuentoPendiente
          : ((bruto / _subtotal) * _descuento * 100).roundToDouble() / 100;
      final descuentoSeguro = descuentoLinea.clamp(0.0, bruto).toDouble();
      descuentoPendiente -= descuentoSeguro;
      return SaleItemModel(
        productoId: item.productoId,
        codigo: item.codigo,
        nombre: item.nombre,
        cantidad: item.cantidad,
        precioUnitario: item.precioUnitario,
        descuento: descuentoSeguro,
        subtotal: bruto - descuentoSeguro,
      );
    }).toList();
  }

  Future<void> _processSale() async {
    if (_cartItems.isEmpty) return;

    if (_descuentoSolicitado < 0 || _descuentoSolicitado > _subtotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'El descuento debe estar entre RD\$ 0.00 y el subtotal de la venta.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final paymentSplit = _paymentSplit;
    final montoEntregado = paymentSplit.received;
    if (!paymentSplit.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Indica el monto recibido para registrar el cobro.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    setState(() => _isProcessing = true);
    final paymentKey = _paymentIdempotencyKey ??=
        'pos-payment-${DateTime.now().microsecondsSinceEpoch}';

    try {
      final res = await _salesService.createSale(
        clienteId: _selectedClient?.id,
        clienteNuevo: _pendingClient,
        tipoComprobante: 'sin_ncf',
        observaciones: 'Venta POS en tienda',
        items: _itemsConDescuento(),
      );

      final ventaId = res['venta_id'] as int;

      final payments = paymentSplit.backendPayments;
      if (payments.length == 1) {
        await _salesService.registerPayment(
          ventaId: ventaId,
          monto: payments.first['monto'] as double,
          metodoPago: payments.first['metodo_pago'] as String,
          montoRecibido: payments.first['monto_recibido'] as double?,
          cambio: payments.first['cambio'] as double?,
          referencia: 'POS-${DateTime.now().millisecondsSinceEpoch % 10000}',
          idempotencyKey: paymentKey,
        );
      } else {
        await _salesService.registerMixedPayments(
            ventaId: ventaId, pagos: payments, idempotencyKey: paymentKey);
      }

      final sale = await _salesService.getSaleById(ventaId);

      if (!mounted) return;

      final cambio = paymentSplit.change;

      setState(() {
        _cartItems.clear();
        _selectedClient = null;
        _pendingClient = null;
        _clientQuery = '';
        _efectivoController.clear();
        _tarjetaController.clear();
        _transferenciaController.clear();
        _descuentoController.text = '0.00';
        _montoSeguroAutorizado = 0.0;
        _paymentIdempotencyKey = null;
      });

      showDialog(
        context: context,
        builder: (ctx) => ReceiptDialog(
          sale: sale,
          montoEntregado: montoEntregado,
          cambio: cambio,
        ),
      );

      _loadCatalogAndClients();
      widget.appState.refreshLowStockCount();
    } catch (e) {
      if (mounted) {
        final text = e.toString();
        if (text.contains('Abre tu caja para cobrar en efectivo')) {
          await showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                      title: const Text('Caja cerrada'),
                      content: const Text(
                          'Abre tu caja para cobrar en efectivo. El carrito se conservará al abrir el turno.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Seguir en POS')),
                        FilledButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              widget.appState
                                  .setActiveSection(AppSection.cashRegister);
                            },
                            child: const Text('Abrir caja')),
                      ]));
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar venta: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _categoryFilterChip(String label, String? cat) {
    final isSelected = _selectedCategory == cat;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedCategory = cat;
          _applyFilters();
        });
      },
      selectedColor: AppColors.primaryLight,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
      ),
    );
  }

  Widget _paymentAmountField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 19),
        prefixText: 'RD\$ ',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _discountField() {
    return TextField(
      controller: _descuentoController,
      decoration: const InputDecoration(
        labelText: 'Descuento en RD\$',
        prefixText: 'RD\$ ',
        helperText: 'Se aplica antes del ITBIS',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    if (_loading) {
      return const Scaffold(
        body: LoadingIndicator(
            message: 'Iniciando terminal Punto de Venta (POS)...'),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Estado operativo del punto de venta.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.successLight,
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline,
                    size: 16, color: Color(0xFF065F46)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ventas e inventario actualizados en tiempo real.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF065F46),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final useSideBySide = isDesktop && constraints.maxWidth >= 1100;
                final catalogHeight = math.max(
                    300.0, math.min(460.0, constraints.maxHeight * .52));
                return useSideBySide
                    ? Row(
                        children: [
                          // Panel Izquierdo: Catálogo de Productos (60%)
                          Expanded(flex: 3, child: _buildCatalogPanel()),
                          const VerticalDivider(
                              width: 1, thickness: 1, color: AppColors.border),
                          // Panel Derecho: Carrito de Compras (40%)
                          Expanded(flex: 2, child: _buildCartPanel()),
                        ],
                      )
                    : CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: catalogHeight,
                              child: _buildCatalogPanel(),
                            ),
                          ),
                          const SliverToBoxAdapter(
                            child: Divider(height: 1, color: AppColors.border),
                          ),
                          // El carrito administra su propio desplazamiento;
                          // no se fuerza una altura mínima que corte ARS.
                          SliverFillRemaining(
                            hasScrollBody: true,
                            child: _buildCartPanel(),
                          ),
                        ],
                      );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogPanel() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Catálogo de Productos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              Text(
                '${_filteredProducts.length} disponibles',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SearchInput(
            controller: _searchController,
            hintText: 'Buscar monturas, cristales, gotas o accesorios...',
            onChanged: _onSearch,
          ),
          const SizedBox(height: 12),

          // Selector de categorías del catálogo óptico
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _categoryFilterChip('Todos', null),
                const SizedBox(width: 8),
                _categoryFilterChip('Monturas', 'montura'),
                const SizedBox(width: 8),
                _categoryFilterChip('Cristales', 'cristal'),
                const SizedBox(width: 8),
                _categoryFilterChip('Lentes Contacto', 'contacto'),
                const SizedBox(width: 8),
                _categoryFilterChip('Medicamentos', 'medicamento'),
                const SizedBox(width: 8),
                _categoryFilterChip('Accesorios', 'accesorio'),
                const SizedBox(width: 8),
                _categoryFilterChip('Servicios', 'servicio'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _filteredProducts.isEmpty
                ? _buildCatalogEmptyState()
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: Responsive.isDesktop(context) ? 3 : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.15,
                    ),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (ctx, index) {
                      final p = _filteredProducts[index];
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: InkWell(
                          onTap: () => _addToCart(p),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        p.codigo,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${p.stockActual} en stock',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: p.isLowStock
                                            ? AppColors.danger
                                            : AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.nombre,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (p.marca != null)
                                      Text(
                                        p.marca!,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      Formatters.formatCurrency(p.precioVenta),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const CircleAvatar(
                                      radius: 14,
                                      backgroundColor: AppColors.primary,
                                      child: Icon(Icons.add,
                                          size: 16, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogEmptyState() => LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: const EmptyState(
              icon: Icons.search_off,
              title: 'No se encontraron productos',
              message: 'Intenta con otro término de búsqueda.',
            ),
          ),
        ),
      );

  Future<void> _openSalesHistory() async {
    final sales = await _salesService.getSales(limite: 100);
    if (!mounted) return;
    final historySearch = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final query = historySearch.text.trim().toLowerCase();
          final filtered = sales.where((sale) =>
              sale.numeroFactura.toLowerCase().contains(query) ||
              sale.id.toString().contains(query)).toList();
          return SafeArea(
              child: SizedBox(
            height: MediaQuery.of(context).size.height * .72,
            child: Column(children: [
              const ListTile(
                  title: Text('Historial de ventas'),
                  subtitle: Text(
                      'Busque por venta o comprobante y seleccione para abrir PDF o reimprimir ticket')),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  key: const Key('sales-history-search'),
                  controller: historySearch,
                  autofocus: true,
                  onChanged: (_) => setSheetState(() {}),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Buscar por venta o comprobante',
                    hintText: 'Ej.: V-00000140 o COM-00000140',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('No se encontraron ventas.'))
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (_, index) {
                            final sale = filtered[index];
                            return ListTile(
                              title: Text(sale.numeroFactura),
                              subtitle: Text(
                                  '${sale.fechaVenta} • ${Formatters.formatCurrency(sale.total)}'),
                              trailing: const Icon(Icons.receipt_long_outlined),
                              onTap: () async {
                                final detail =
                                    await _salesService.getSaleById(sale.id);
                                if (!context.mounted) return;
                                await showDialog<void>(
                                    context: context,
                                    builder: (_) =>
                                        CommercialInvoiceDialog(sale: detail));
                              },
                            );
                          }))
            ]),
          ));
        },
      ),
    );
    historySearch.dispose();
  }

  Widget _buildCartPanel() {
    final paymentSplit = _paymentSplit;
    final itemsVista = _itemsParaVista;
    return PosCartViewport(
      header: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Venta actual',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(
                  'Cajera/o: ${widget.appState.currentUser?.nombre ?? 'Usuario activo'}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          OutlinedButton.icon(
            onPressed: _openSalesHistory,
            icon: const Icon(Icons.history, size: 16),
            label: const Text('Historial', style: TextStyle(fontSize: 12)),
          ),
          if (_cartItems.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () => setState(() => _cartItems.clear()),
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Limpiar', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger)),
            ),
        ],
      ),
      clientSection: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Autocomplete<ClientModel>(
            displayStringForOption: (client) => client.nombreCompleto,
            optionsBuilder: (value) {
              final query = value.text.trim().toLowerCase();
              if (query.isEmpty) return _clients.take(12);
              return _clients.where((client) =>
                  client.nombreCompleto.toLowerCase().contains(query) ||
                  (client.telefono ?? '').contains(query));
            },
            onSelected: (client) => setState(() {
              _selectedClient = client;
              _pendingClient = null;
              _clientQuery = client.nombreCompleto;
            }),
            optionsViewBuilder: (context, onSelected, options) => Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxHeight: 240, maxWidth: 440),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    children: options
                        .map((client) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.person_outline),
                              title: Text(client.nombreCompleto),
                              subtitle: client.telefono == null ||
                                      client.telefono!.isEmpty
                                  ? null
                                  : Text(client.telefono!),
                              trailing: const Icon(Icons.add_circle_outline,
                                  size: 18),
                              onTap: () => onSelected(client),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
            fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: 'Cliente de la venta',
                  hintText: 'Busca por nombre o teléfono',
                  prefixIcon:
                      const Icon(Icons.person_search_outlined, size: 18),
                  suffixIcon: _selectedClient == null
                      ? null
                      : IconButton(
                          tooltip: 'Venta sin cliente asignado',
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            controller.clear();
                            setState(() {
                              _selectedClient = null;
                              _clientQuery = '';
                            });
                          },
                        ),
                ),
                onChanged: (_) {
                  setState(() => _clientQuery = controller.text);
                  if (_selectedClient != null) {
                    setState(() => _selectedClient = null);
                  }
                },
              );
            },
          ),
          if (_selectedClient == null &&
              _clientQuery.trim().isNotEmpty &&
              !_clients.any((client) =>
                  client.nombreCompleto.toLowerCase() ==
                  _clientQuery.trim().toLowerCase()))
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _createQuickClientForSale,
                icon: const Icon(Icons.add_circle_outline, size: 17),
                label: Text(
                    '+ Agregar «${_clientQuery.trim()}» como cliente nuevo'),
              ),
            ),
          if (_selectedClient != null || _pendingClient != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(Icons.person_outline,
                    size: 17, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(
                        _selectedClient?.nombreCompleto ??
                            '${_pendingClient!['nombres']} ${_pendingClient!['apellidos'] ?? ''}'
                                .trim(),
                        style: const TextStyle(fontWeight: FontWeight.w700))),
                TextButton(
                    onPressed: () => setState(() {
                          _selectedClient = null;
                          _pendingClient = null;
                          _clientQuery = '';
                        }),
                    child: const Text('Cambiar')),
              ]),
            ),
          OutlinedButton(
            onPressed: () => setState(() {
              _selectedClient = null;
              _pendingClient = null;
              _clientQuery = '';
            }),
            child: const SizedBox(
                width: double.infinity,
                child: Text('Continuar como consumidor final',
                    textAlign: TextAlign.center)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Selecciona un cliente para historial, receta o venta a crédito. Para venta al contado es opcional.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
      cartContent:
          _cartItems.isEmpty ? _emptySaleState() : _saleLinesTable(itemsVista),
      paymentAndTotals: _paymentAndTotalsPanel(paymentSplit),
    );
  }

  /// Crea un cliente sólo cuando es necesario para la venta actual y lo deja
  /// asignado inmediatamente, sin abandonar el punto de venta.
  Future<void> _createQuickClientForSale() async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: _clientQuery.trim());
    final phone = TextEditingController();
    final email = TextEditingController();
    var saving = false;
    final created = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nuevo cliente para esta venta'),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(
                  controller: name,
                  autofocus: true,
                  decoration:
                      const InputDecoration(labelText: 'Nombre completo *'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Indica el nombre del cliente.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                        labelText: 'Teléfono (opcional)')),
                const SizedBox(height: 12),
                TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration:
                        const InputDecoration(labelText: 'Correo (opcional)')),
              ]),
            ),
          ),
          actions: [
            TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => saving = true);
                      final words = name.text.trim().split(RegExp(r'\s+'));
                      Navigator.pop(ctx, {
                        'nombres': words.first,
                        'apellidos':
                            words.length > 1 ? words.skip(1).join(' ') : '',
                        'telefono': phone.text.trim(),
                        'correo': email.text.trim()
                      });
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Agregar y usar'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    phone.dispose();
    email.dispose();
    if (created != null && mounted) {
      setState(() {
        _pendingClient = created;
        _selectedClient = null;
        _clientQuery =
            '${created['nombres']} ${created['apellidos'] ?? ''}'.trim();
      });
    }
  }

  Widget _emptySaleState() => Container(
        decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border)),
        child: const EmptyState(
            icon: Icons.playlist_add_outlined,
            title: 'Aún no hay artículos',
            message: 'Busca por SKU, nombre o marca y agrégalos a esta venta.'),
      );

  Widget _saleLinesTable(List<SaleItemModel> items) => Container(
        decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(10)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor:
                  const WidgetStatePropertyAll(AppColors.background),
              columnSpacing: 16,
              horizontalMargin: 12,
              columns: const [
                DataColumn(label: Text('SKU')),
                DataColumn(label: Text('DESCRIPCIÓN')),
                DataColumn(label: Text('CANT.')),
                DataColumn(label: Text('PRECIO'), numeric: true),
                DataColumn(label: Text('DESC.'), numeric: true),
                DataColumn(label: Text('ITBIS'), numeric: true),
                DataColumn(label: Text('IMPORTE'), numeric: true),
                DataColumn(label: SizedBox(width: 28)),
              ],
              rows: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return DataRow(cells: [
                  DataCell(Text(item.codigo,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary))),
                  DataCell(SizedBox(
                      width: 150,
                      child: Text(item.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 12)))),
                  DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.remove_circle_outline, size: 17),
                        onPressed: () => _updateQuantity(index, -1)),
                    Text('${item.cantidad}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.add_circle_outline, size: 17),
                        onPressed: () => _updateQuantity(index, 1)),
                  ])),
                  DataCell(Text(Formatters.formatCurrency(item.precioUnitario),
                      style: const TextStyle(fontSize: 12))),
                  DataCell(Text(
                      item.descuento == 0
                          ? '—'
                          : Formatters.formatCurrency(item.descuento),
                      style: const TextStyle(fontSize: 12))),
                  DataCell(Text(Formatters.formatCurrency(_itbisDeLinea(item)),
                      style: const TextStyle(fontSize: 12))),
                  DataCell(Text(
                      Formatters.formatCurrency(
                          item.subtotal + _itbisDeLinea(item)),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 12))),
                  DataCell(IconButton(
                      tooltip: 'Quitar artículo',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close,
                          size: 17, color: AppColors.danger),
                      onPressed: () => _updateQuantity(index, -item.cantidad))),
                ]);
              }).toList(),
            ),
          ),
        ),
      );

  Widget _paymentAndTotalsPanel(PaymentSplit paymentSplit) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppColors.background,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Cobro',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          LayoutBuilder(builder: (context, constraints) {
            final fields = [
              _paymentAmountField(_efectivoController, 'Efectivo recibido',
                  Icons.payments_outlined),
              _paymentAmountField(
                  _tarjetaController, 'Tarjeta', Icons.credit_card_outlined),
              _paymentAmountField(_transferenciaController, 'Transferencia',
                  Icons.account_balance_outlined)
            ];
            return constraints.maxWidth < 600
                ? Column(children: fields)
                : Row(children: [
                    Expanded(child: fields[0]),
                    const SizedBox(width: 10),
                    Expanded(child: fields[1]),
                    const SizedBox(width: 10),
                    Expanded(child: fields[2])
                  ]);
          }),
          const SizedBox(height: 10),
          _discountField(),
          const SizedBox(height: 10),
          InsuranceCoverageCard(
              totalVenta: _total,
              pagosRealizados: paymentSplit.received,
              onMontoAutorizadoChanged: (monto) =>
                  setState(() => _montoSeguroAutorizado = monto),
              onArsChanged: (_) {},
              onNumeroAutorizacionChanged: (_) {}),
          const SizedBox(height: 12),
          _totalRow('Subtotal', _subtotal),
          if (_descuento > 0)
            _totalRow('Descuento comercial', -_descuento,
                color: AppColors.success),
          _totalRow('ITBIS', _impuestos),
          const Divider(height: 18),
          _totalRow('TOTAL A PAGAR', _total, prominent: true),
          if (_montoSeguroAutorizado > 0)
            _totalRow(
                'Copago estimado', math.max(0, _total - _montoSeguroAutorizado),
                color: AppColors.secondaryDark),
          if (paymentSplit.received > 0) ...[
            const SizedBox(height: 8),
            _totalRow(
                paymentSplit.change > 0 ? 'DEVUELTA' : 'RECIBIDO',
                paymentSplit.change > 0
                    ? paymentSplit.change
                    : paymentSplit.received,
                color: AppColors.success,
                prominent: true),
          ],
          if (paymentSplit.received > 0 ||
              paymentSplit.validationMessage != null) ...[
            const SizedBox(height: 8),
            Text(
                paymentSplit.isValid
                    ? 'Pago mixto válido: ${Formatters.formatCurrency(paymentSplit.received)} recibido.'
                    : (paymentSplit.validationMessage ??
                        'Completa los importes de pago.'),
                style: TextStyle(
                    fontSize: 11,
                    color: paymentSplit.isValid
                        ? AppColors.secondaryDark
                        : AppColors.danger,
                    fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 12),
          SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                  onPressed: _canProcessSale ? _processSale : null,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.point_of_sale),
                  label: Text(
                      _isProcessing
                          ? 'Procesando venta...'
                          : 'Cobrar e imprimir comprobante',
                      style: const TextStyle(fontWeight: FontWeight.bold)))),
        ]),
      );

  Widget _totalRow(String label, double amount,
          {Color? color, bool prominent = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label,
              style: TextStyle(
                  fontSize: prominent ? 15 : 12,
                  fontWeight: prominent ? FontWeight.w800 : FontWeight.w500,
                  color: color ?? AppColors.textSecondary)),
          Text(Formatters.formatCurrency(amount),
              style: TextStyle(
                  fontSize: prominent ? 18 : 13,
                  fontWeight: FontWeight.w800,
                  color: color ??
                      (prominent ? AppColors.primary : AppColors.textPrimary))),
        ]),
      );
}
