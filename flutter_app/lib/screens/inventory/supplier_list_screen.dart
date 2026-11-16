import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/supplier_model.dart';
import '../../services/supplier_service.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/search_input.dart';

class SupplierListScreen extends StatefulWidget {
  final AppState appState;
  final VoidCallback? onBack;

  const SupplierListScreen({super.key, required this.appState, this.onBack});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  final _supplierService = SupplierService();
  final _searchController = TextEditingController();

  List<SupplierModel> _suppliers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await _supplierService.getSuppliers();
      if (mounted) {
        setState(() {
          _suppliers = list;
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

  Future<void> _onSearch(String query) async {
    if (query.trim().isEmpty) {
      _loadSuppliers();
      return;
    }

    setState(() => _loading = true);
    try {
      final results = await _supplierService.searchSuppliers(query.trim());
      if (mounted) {
        setState(() {
          _suppliers = results;
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

  void _openSupplierForm([SupplierModel? supplier]) {
    final nameCtrl = TextEditingController(text: supplier?.nombre ?? '');
    final rncCtrl = TextEditingController(text: supplier?.rnc ?? '');
    final contactoCtrl = TextEditingController(text: supplier?.contacto ?? '');
    final telCtrl = TextEditingController(text: supplier?.telefono ?? '');
    final emailCtrl = TextEditingController(text: supplier?.correo ?? '');
    final dirCtrl = TextEditingController(text: supplier?.direccion ?? '');
    var categoria = supplier?.categoria ?? 'Proveedor general';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(supplier == null ? 'Nuevo Proveedor' : 'Editar Proveedor'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Razón Social / Nombre *'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: categoria,
                  decoration: const InputDecoration(labelText: 'Tipo de proveedor'),
                  items: SupplierModel.categories
                      .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) categoria = value;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: rncCtrl,
                        decoration: const InputDecoration(labelText: 'RNC / Identificación'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: contactoCtrl,
                        decoration: const InputDecoration(labelText: 'Persona de Contacto'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: telCtrl,
                        decoration: const InputDecoration(labelText: 'Teléfono'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(labelText: 'Correo Electrónico'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dirCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Dirección'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              try {
                if (supplier == null) {
                  await _supplierService.createSupplier(SupplierModel(
                    id: 0,
                    nombre: nameCtrl.text.trim(),
                    rnc: rncCtrl.text.trim().isNotEmpty ? rncCtrl.text.trim() : null,
                    contacto: contactoCtrl.text.trim().isNotEmpty ? contactoCtrl.text.trim() : null,
                    telefono: telCtrl.text.trim().isNotEmpty ? telCtrl.text.trim() : null,
                    correo: emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
                    direccion: dirCtrl.text.trim().isNotEmpty ? dirCtrl.text.trim() : null,
                    categoria: categoria,
                  ));
                } else {
                  await _supplierService.updateSupplier(
                    supplier.id,
                    SupplierModel(
                      id: supplier.id,
                      nombre: nameCtrl.text.trim(),
                      rnc: rncCtrl.text.trim().isNotEmpty ? rncCtrl.text.trim() : null,
                      contacto: contactoCtrl.text.trim().isNotEmpty ? contactoCtrl.text.trim() : null,
                      telefono: telCtrl.text.trim().isNotEmpty ? telCtrl.text.trim() : null,
                      correo: emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
                      direccion: dirCtrl.text.trim().isNotEmpty ? dirCtrl.text.trim() : null,
                      categoria: categoria,
                    ).toJson(),
                  );
                }
                if (ctx.mounted) Navigator.of(ctx).pop();
                _loadSuppliers();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
                  );
                }
              }
            },
            child: Text(supplier == null ? 'Guardar' : 'Actualizar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Proveedores ópticos',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_suppliers.length} laboratorios, distribuidores y proveedores de insumos',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (widget.onBack != null) ...[
                      OutlinedButton.icon(
                        onPressed: widget.onBack,
                        icon: const Icon(Icons.arrow_back_outlined, size: 18),
                        label: const Text('Compras'),
                      ),
                      const SizedBox(width: 12),
                    ],
                    ElevatedButton.icon(
                      onPressed: () => _openSupplierForm(),
                      icon: const Icon(Icons.add_business_outlined, size: 18),
                      label: const Text('Nuevo Proveedor'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: SearchInput(
                    controller: _searchController,
                    hintText: 'Buscar por nombre, RNC, contacto o teléfono...',
                    onChanged: (val) {
                      if (val.isEmpty) _loadSuppliers();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _onSearch(_searchController.text),
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Buscar'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadSuppliers,
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_error != null)
              ErrorBanner(message: _error!, onRetry: _loadSuppliers),

            Expanded(
              child: _loading
                  ? const LoadingIndicator(message: 'Cargando proveedores...')
                  : _suppliers.isEmpty
                      ? EmptyState(
                          icon: Icons.local_shipping_outlined,
                          title: 'Sin proveedores registrados',
                          message:
                              'Registra laboratorios, distribuidores y proveedores de insumos ópticos.',
                          buttonText: 'Crear Proveedor',
                          onAction: () => _openSupplierForm(),
                        )
                      : Card(
                          child: ListView.separated(
                            itemCount: _suppliers.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (ctx, index) {
                              final s = _suppliers[index];
                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.business, color: AppColors.primary),
                                ),
                                title: Text(
                                  s.nombre,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                                subtitle: Text(
                                  '${s.categoria}\nRNC: ${s.rnc ?? "N/A"} • Contacto: ${s.contacto ?? "Sin contacto"} • Tel: ${s.telefono ?? "N/A"}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                isThreeLine: true,
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  onPressed: () => _openSupplierForm(s),
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
