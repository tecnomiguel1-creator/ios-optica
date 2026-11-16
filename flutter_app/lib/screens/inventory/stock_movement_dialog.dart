import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/product_model.dart';
import '../../services/inventory_service.dart';
import '../../widgets/error_banner.dart';

class StockMovementDialog extends StatefulWidget {
  final ProductModel product;
  final VoidCallback onSaved;

  const StockMovementDialog({
    super.key,
    required this.product,
    required this.onSaved,
  });

  @override
  State<StockMovementDialog> createState() => _StockMovementDialogState();
}

class _StockMovementDialogState extends State<StockMovementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _inventoryService = InventoryService();

  final _cantidadController = TextEditingController(text: '1');
  final _motivoController = TextEditingController();
  final _observacionesController = TextEditingController();

  String _tipo = 'entrada'; // entrada | salida | ajuste
  bool _ajusteAumenta = true;
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _cantidadController.dispose();
    _motivoController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final cant = int.tryParse(_cantidadController.text) ?? 0;
    if (cant <= 0) {
      setState(() => _error = 'La cantidad debe ser mayor a 0');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await _inventoryService.recordStockMovement(
        productoId: widget.product.id,
        tipo: _tipo,
        cantidad: cant,
        motivo: _motivoController.text.trim(),
        observaciones: _observacionesController.text.trim().isNotEmpty
            ? _observacionesController.text.trim()
            : null,
        ajusteAumenta: _ajusteAumenta,
      );

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
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.sync_alt_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Movimiento Kardex: ${widget.product.nombre}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null) ErrorBanner(message: _error!),

                // Stock actual
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Stock actual: ${widget.product.stockActual} unidades',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'Código: ${widget.product.codigo}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tipo de Movimiento
                DropdownButtonFormField<String>(
                  initialValue: _tipo,
                  decoration: const InputDecoration(labelText: 'Tipo de Movimiento *'),
                  items: const [
                    DropdownMenuItem(value: 'entrada', child: Text('Entrada (Ingreso a almacén)')),
                    DropdownMenuItem(value: 'salida', child: Text('Salida (Baja manual / merma)')),
                    DropdownMenuItem(value: 'ajuste', child: Text('Ajuste de inventario físico')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _tipo = val);
                  },
                ),
                const SizedBox(height: 12),

                if (_tipo == 'ajuste') ...[
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('+ Incrementa stock')),
                          selected: _ajusteAumenta,
                          onSelected: (_) => setState(() => _ajusteAumenta = true),
                          selectedColor: AppColors.successLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('- Disminuye stock')),
                          selected: !_ajusteAumenta,
                          onSelected: (_) => setState(() => _ajusteAumenta = false),
                          selectedColor: AppColors.dangerLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Cantidad
                TextFormField(
                  controller: _cantidadController,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad de Unidades *',
                    hintText: '1',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),

                // Motivo
                TextFormField(
                  controller: _motivoController,
                  decoration: const InputDecoration(
                    labelText: 'Motivo del Movimiento *',
                    hintText: 'Recepción directa, rotura, conteo físico, etc.',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),

                // Observaciones
                TextFormField(
                  controller: _observacionesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones Adicionales',
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
              : const Text('Registrar en Kardex'),
        ),
      ],
    );
  }
}
