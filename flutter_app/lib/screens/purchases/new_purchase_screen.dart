import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/product_model.dart';
import '../../models/supplier_model.dart';
import '../../services/inventory_service.dart';
import '../../services/purchase_service.dart';
import '../../services/supplier_service.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/loading_indicator.dart';
import '../inventory/product_form_dialog.dart';

class NewPurchaseScreen extends StatefulWidget {
  final VoidCallback onSaved;
  final VoidCallback onCancel;

  const NewPurchaseScreen({
    super.key,
    required this.onSaved,
    required this.onCancel,
  });

  @override
  State<NewPurchaseScreen> createState() => _NewPurchaseScreenState();
}

class _NewPurchaseScreenState extends State<NewPurchaseScreen> {
  final _purchaseService = PurchaseService();
  final _supplierService = SupplierService();
  final _inventoryService = InventoryService();

  final _facturaController = TextEditingController();
  final _observacionesController = TextEditingController();
  final _impuestosController = TextEditingController(text: '0.00');

  List<SupplierModel> _suppliers = [];
  List<ProductModel> _products = [];
  SupplierModel? _selectedSupplier;

  final List<Map<String, dynamic>> _lineItems = [];
  bool _loading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _facturaController.dispose();
    _observacionesController.dispose();
    _impuestosController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _loading = true);
    try {
      final sups = await _supplierService.getSuppliers();
      final prods = await _inventoryService.getProducts();
      if (mounted) {
        setState(() {
          _suppliers = sups;
          _products = prods;
          if (_suppliers.isNotEmpty) _selectedSupplier = _suppliers.first;
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

  void _addItem(ProductModel product) {
    final existingIndex =
        _lineItems.indexWhere((item) => item['producto_id'] == product.id);

    setState(() {
      if (existingIndex >= 0) {
        _lineItems[existingIndex]['cantidad'] += 1;
      } else {
        _lineItems.add({
          'producto_id': product.id,
          'nombre': product.nombre,
          'codigo': product.codigo,
          'cantidad': 1,
          'precio_unitario': product.precioCompra > 0 ? product.precioCompra : 100.0,
        });
      }
    });
  }

  double get _subtotal {
    return _lineItems.fold<double>(
      0.0,
      (sum, item) => sum + (item['cantidad'] as int) * (item['precio_unitario'] as double),
    );
  }

  double get _impuestos {
    return double.tryParse(_impuestosController.text.replaceAll(',', '.')) ?? 0.0;
  }

  double get _total => _subtotal + _impuestos;

  Future<void> _crearProveedorRapido() async {
    final nombreCtrl = TextEditingController();
    final rncCtrl = TextEditingController();
    final contactoCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();

    final proveedorId = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Registrar proveedor óptico'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Razón social o nombre comercial *',
                  hintText: 'Laboratorio o distribuidor óptico',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: rncCtrl,
                decoration: const InputDecoration(labelText: 'RNC (si aplica)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contactoCtrl,
                decoration: const InputDecoration(labelText: 'Persona de contacto'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: telefonoCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Teléfono'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nombreCtrl.text.trim().isEmpty) return;
              try {
                final id = await _supplierService.createSupplier(SupplierModel(
                  id: 0,
                  nombre: nombreCtrl.text.trim(),
                  rnc: rncCtrl.text.trim().isEmpty ? null : rncCtrl.text.trim(),
                  contacto: contactoCtrl.text.trim().isEmpty ? null : contactoCtrl.text.trim(),
                  telefono: telefonoCtrl.text.trim().isEmpty ? null : telefonoCtrl.text.trim(),
                ));
                if (dialogContext.mounted) Navigator.of(dialogContext).pop(id);
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('No se pudo registrar el proveedor: $e')),
                  );
                }
              }
            },
            child: const Text('Guardar proveedor'),
          ),
        ],
      ),
    );

    nombreCtrl.dispose();
    rncCtrl.dispose();
    contactoCtrl.dispose();
    telefonoCtrl.dispose();
    if (proveedorId == null || !mounted) return;

    final proveedores = await _supplierService.getSuppliers();
    SupplierModel? proveedor;
    for (final item in proveedores) {
      if (item.id == proveedorId) {
        proveedor = item;
        break;
      }
    }
    if (!mounted) return;
    setState(() {
      _suppliers = proveedores;
      _selectedSupplier = proveedor;
    });
  }

  Future<void> _crearProductoDesdeCompra() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => ProductFormDialog(
        onSaved: () async {
          final productos = await _inventoryService.getProducts();
          if (mounted) setState(() => _products = productos);
        },
      ),
    );
  }

  Future<void> _savePurchase() async {
    if (_selectedSupplier == null) {
      setState(() => _error = 'Selecciona un proveedor');
      return;
    }
    if (_lineItems.isEmpty) {
      setState(() => _error = 'Agrega al menos un producto a la compra');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final payloadItems = _lineItems.map((item) => {
        'producto_id': item['producto_id'],
        'cantidad': item['cantidad'],
        'precio_unitario': item['precio_unitario'],
      }).toList();

      await _purchaseService.createPurchase(
        proveedorId: _selectedSupplier!.id,
        numeroFactura: _facturaController.text.trim().isNotEmpty
            ? _facturaController.text.trim()
            : null,
        observaciones: _observacionesController.text.trim().isNotEmpty
            ? _observacionesController.text.trim()
            : null,
        impuestos: _impuestos,
        detalles: payloadItems,
      );

      widget.onSaved();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Cargando catálogo para orden de compra...'),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onCancel,
        ),
        title: const Text('Registrar Orden de Compra de Mercancía'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null) ErrorBanner(message: _error!),

            // Datos de la compra
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Datos del Proveedor y Factura',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<SupplierModel>(
                            initialValue: _selectedSupplier,
                            decoration: const InputDecoration(labelText: 'Proveedor *'),
                            items: _suppliers
                                .map((s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s.nombre),
                                    ))
                                .toList(),
                            onChanged: (val) => setState(() => _selectedSupplier = val),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _crearProveedorRapido,
                          icon: const Icon(Icons.add_business_outlined, size: 18),
                          label: const Text('Nuevo proveedor'),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _facturaController,
                            decoration: const InputDecoration(
                              labelText: 'Nº Factura / Remisión',
                              hintText: 'FAC-PROV-9921',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Selector de productos a agregar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Agregar productos a la orden',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        OutlinedButton.icon(
                          onPressed: _crearProductoDesdeCompra,
                          icon: const Icon(Icons.add_box_outlined, size: 18),
                          label: const Text('Nuevo producto'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _products.take(12).map((p) {
                        return ActionChip(
                          avatar: const Icon(Icons.add, size: 16),
                          label: Text('${p.nombre} (${p.codigo})'),
                          onPressed: () => _addItem(p),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tabla de productos en la orden
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detalle de la Compra',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    if (_lineItems.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'Haz clic en los productos superiores para agregarlos a la orden.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _lineItems.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (ctx, index) {
                          final item = _lineItems[index];
                          final sub = (item['cantidad'] as int) *
                              (item['precio_unitario'] as double);

                          return ListTile(
                            title: Text(
                              item['nombre'],
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text('Código: ${item['codigo']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      if (item['cantidad'] > 1) {
                                        item['cantidad'] -= 1;
                                      } else {
                                        _lineItems.removeAt(index);
                                      }
                                    });
                                  },
                                ),
                                Text(
                                  '${item['cantidad']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, size: 20),
                                  onPressed: () {
                                    setState(() => item['cantidad'] += 1);
                                  },
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    Formatters.formatCurrency(sub),
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 20, color: AppColors.danger),
                                  onPressed: () =>
                                      setState(() => _lineItems.removeAt(index)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    const Divider(height: 32),

                    // Resumen de Totales
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 320,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Subtotal:', style: TextStyle(fontSize: 14)),
                                Text(Formatters.formatCurrency(_subtotal),
                                    style: const TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Impuestos (ITBIS):', style: TextStyle(fontSize: 14)),
                                SizedBox(
                                  width: 120,
                                  child: TextField(
                                    controller: _impuestosController,
                                    textAlign: TextAlign.end,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 8),
                                      prefixText: 'RD\$ ',
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(decimal: true),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('TOTAL COMPRA:',
                                    style: TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w800)),
                                Text(
                                  Formatters.formatCurrency(_total),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _savePurchase,
                  icon: const Icon(Icons.check, size: 18),
                  label: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Registrar Compra (Pendiente)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
