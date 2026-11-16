import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/product_model.dart';
import '../../services/inventory_service.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/search_input.dart';
import 'product_form_dialog.dart';
import 'stock_movement_dialog.dart';

class ProductListScreen extends StatefulWidget {
  final AppState appState;

  const ProductListScreen({super.key, required this.appState});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _inventoryService = InventoryService();
  final _searchController = TextEditingController();

  List<ProductModel> _products = [];
  String? _selectedCategory; // null = todas
  bool _loading = true;
  String? _error;

  final List<Map<String, String?>> _categories = [
    {'label': 'Todos', 'val': null},
    {'label': 'Monturas', 'val': 'montura'},
    {'label': 'Cristales oftálmicos', 'val': 'cristal'},
    {'label': 'Lentes de contacto', 'val': 'contacto'},
    {'label': 'Medicamentos oftálmicos', 'val': 'medicamento'},
    {'label': 'Accesorios', 'val': 'accesorio'},
    {'label': 'Servicios ópticos', 'val': 'servicio'},
    {'label': 'Laboratorio y reparaciones', 'val': 'taller'},
    {'label': 'Otros', 'val': 'otro'},
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await _inventoryService.getProducts(categoria: _selectedCategory);
      if (mounted) {
        setState(() {
          _products = list;
          _loading = false;
        });
        widget.appState.refreshLowStockCount();
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
      _loadProducts();
      return;
    }

    setState(() => _loading = true);
    try {
      final results = await _inventoryService.searchProducts(
        query.trim(),
        categoria: _selectedCategory,
      );
      if (mounted) {
        setState(() {
          _products = results;
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

  void _openProductForm([ProductModel? product]) {
    showDialog(
      context: context,
      builder: (ctx) => ProductFormDialog(
        product: product,
        onSaved: _loadProducts,
      ),
    );
  }

  void _openMovementDialog(ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => StockMovementDialog(
        product: product,
        onSaved: _loadProducts,
      ),
    );
  }

  Future<void> _deactivateProduct(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desactivar Producto'),
        content: Text(
          '¿Deseas dar de baja lógica al producto "${product.nombre}"? No se eliminarán sus ventas ni su historial de kardex.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _inventoryService.deactivateProduct(product.id);
        _loadProducts();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
          );
        }
      }
    }
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
            // Cabecera
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Catálogo e Inventario Óptico',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_products.length} productos registrados',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _openProductForm(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nuevo Producto'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Filtros de Categorías
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((c) {
                  final isSelected = _selectedCategory == c['val'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(c['label']!),
                      onSelected: (_) {
                        setState(() => _selectedCategory = c['val']);
                        _loadProducts();
                      },
                      selectedColor: AppColors.primaryLight,
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Buscador
            Row(
              children: [
                Expanded(
                  child: SearchInput(
                    controller: _searchController,
                    hintText: 'Buscar por código, nombre o marca...',
                    onChanged: (val) {
                      if (val.isEmpty) _loadProducts();
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
                  tooltip: 'Actualizar catálogo',
                  onPressed: _loadProducts,
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_error != null)
              ErrorBanner(message: _error!, onRetry: _loadProducts),

            // Tabla / Lista de Productos
            Expanded(
              child: _loading
                  ? const LoadingIndicator(message: 'Consultando inventario...')
                  : _products.isEmpty
                      ? EmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: 'No hay productos en esta categoría',
                          message:
                              'Registra monturas, cristales o accesorios para gestionar tu stock.',
                          buttonText: 'Registrar Producto',
                          onAction: () => _openProductForm(),
                        )
                      : Card(
                          child: ListView.separated(
                            itemCount: _products.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (ctx, index) {
                              final p = _products[index];
                              final isLow = p.isLowStock;

                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isLow
                                        ? AppColors.dangerLight
                                        : AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    isLow
                                        ? Icons.warning_amber_rounded
                                        : Icons.inventory_2,
                                    color: isLow
                                        ? AppColors.danger
                                        : AppColors.primary,
                                    size: 22,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      p.nombre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.border,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        p.codigo,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (p.marca != null) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        '(${p.marca})',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Text(
                                  'Venta: ${Formatters.formatCurrency(p.precioVenta)} • Costo: ${Formatters.formatCurrency(p.precioCompra)} • Cat: ${p.categoria.toUpperCase()}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Stock badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isLow
                                            ? AppColors.dangerLight
                                            : AppColors.successLight,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${p.stockActual} en stock',
                                        style: TextStyle(
                                          color: isLow
                                              ? AppColors.danger
                                              : AppColors.success,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    IconButton(
                                      icon: const Icon(Icons.sync_alt, size: 18),
                                      tooltip: 'Registrar movimiento Kardex',
                                      onPressed: () => _openMovementDialog(p),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18),
                                      tooltip: 'Editar producto',
                                      onPressed: () => _openProductForm(p),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          size: 18, color: AppColors.danger),
                                      tooltip: 'Desactivar',
                                      onPressed: () => _deactivateProduct(p),
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
