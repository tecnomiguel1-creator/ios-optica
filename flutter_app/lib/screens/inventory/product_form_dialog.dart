import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../services/inventory_service.dart';
import '../../widgets/error_banner.dart';

class ProductFormDialog extends StatefulWidget {
  final ProductModel? product;
  final VoidCallback onSaved;

  const ProductFormDialog({super.key, this.product, required this.onSaved});

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _inventoryService = InventoryService();

  late TextEditingController _codigoController;
  late TextEditingController _nombreController;
  late TextEditingController _marcaController;
  late TextEditingController _descripcionController;
  late TextEditingController _precioCompraController;
  late TextEditingController _precioVentaController;
  late TextEditingController _stockMinimoController;

  String _categoria = 'montura';
  bool _isSaving = false;
  String? _error;

  final List<Map<String, String>> _categorias = [
    {'val': 'montura', 'label': 'Monturas'},
    {'val': 'cristal', 'label': 'Cristales oftálmicos'},
    {'val': 'contacto', 'label': 'Lentes de contacto'},
    {'val': 'medicamento', 'label': 'Medicamentos oftálmicos'},
    {'val': 'accesorio', 'label': 'Accesorios y estuches'},
    {'val': 'servicio', 'label': 'Servicios ópticos'},
    {'val': 'taller', 'label': 'Laboratorio y reparaciones'},
    {'val': 'otro', 'label': 'Otros'},
  ];

  @override
  void initState() {
    super.initState();
    _codigoController = TextEditingController(text: widget.product?.codigo ?? '');
    _nombreController = TextEditingController(text: widget.product?.nombre ?? '');
    _marcaController = TextEditingController(text: widget.product?.marca ?? '');
    _descripcionController = TextEditingController(text: widget.product?.descripcion ?? '');
    _precioCompraController = TextEditingController(
        text: widget.product != null ? widget.product!.precioCompra.toString() : '0.00');
    _precioVentaController = TextEditingController(
        text: widget.product != null ? widget.product!.precioVenta.toString() : '0.00');
    _stockMinimoController = TextEditingController(
        text: widget.product != null ? widget.product!.stockMinimo.toString() : '5');
    if (widget.product != null) {
      _categoria = widget.product!.categoria;
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _marcaController.dispose();
    _descripcionController.dispose();
    _precioCompraController.dispose();
    _precioVentaController.dispose();
    _stockMinimoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final pCompra = double.tryParse(_precioCompraController.text.replaceAll(',', '.')) ?? 0.0;
      final pVenta = double.tryParse(_precioVentaController.text.replaceAll(',', '.')) ?? 0.0;
      final sMin = int.tryParse(_stockMinimoController.text) ?? 5;

      if (widget.product == null) {
        final prod = ProductModel(
          id: 0,
          codigo: _codigoController.text.trim(),
          nombre: _nombreController.text.trim(),
          categoria: _categoria,
          marca: _marcaController.text.trim().isNotEmpty ? _marcaController.text.trim() : null,
          descripcion: _descripcionController.text.trim().isNotEmpty
              ? _descripcionController.text.trim()
              : null,
          precioCompra: pCompra,
          precioVenta: pVenta,
          stockActual: 0,
          stockMinimo: sMin,
        );
        await _inventoryService.createProduct(prod);
      } else {
        await _inventoryService.updateProduct(widget.product!.id, {
          'codigo': _codigoController.text.trim(),
          'nombre': _nombreController.text.trim(),
          'categoria': _categoria,
          'marca': _marcaController.text.trim().isNotEmpty ? _marcaController.text.trim() : null,
          'descripcion': _descripcionController.text.trim().isNotEmpty
              ? _descripcionController.text.trim()
              : null,
          'precio_compra': pCompra,
          'precio_venta': pVenta,
          'stock_minimo': sMin,
        });
      }

      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return AlertDialog(
      title: Row(
        children: [
          Icon(isEditing ? Icons.edit_outlined : Icons.add_box_outlined),
          const SizedBox(width: 10),
          Text(isEditing ? 'Editar Producto' : 'Nuevo Producto Óptico'),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error != null) ErrorBanner(message: _error!),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _codigoController,
                        decoration: const InputDecoration(
                          labelText: 'Código / SKU',
                          hintText: 'Automático si se deja vacío',
                          helperText: 'Ejemplo: MON-00001',
                        ),
                        validator: (v) => isEditing && (v == null || v.trim().isEmpty)
                            ? 'El código es requerido al editar'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _categoria,
                        decoration: const InputDecoration(labelText: 'Categoría *'),
                        items: _categorias
                            .map((c) => DropdownMenuItem(
                                  value: c['val'],
                                  child: Text(c['label']!),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _categoria = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Producto *',
                    hintText: 'Montura Ray-Ban Aviator Titanio',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _marcaController,
                        decoration: const InputDecoration(
                          labelText: 'Marca / Fabricante',
                          hintText: 'Ray-Ban, Oakley, etc.',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _stockMinimoController,
                        decoration: const InputDecoration(
                          labelText: 'Stock Mínimo Alerta',
                          hintText: '5',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _precioCompraController,
                        decoration: const InputDecoration(
                          labelText: 'Precio de Compra (Costo)',
                          prefixText: 'RD\$ ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _precioVentaController,
                        decoration: const InputDecoration(
                          labelText: 'Precio de Venta al Público *',
                          prefixText: 'RD\$ ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Requerido' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descripcionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descripción / Características',
                    hintText: 'Material, color, calibre, detalles técnicos...',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(isEditing ? 'Actualizar' : 'Guardar Producto'),
        ),
      ],
    );
  }
}
