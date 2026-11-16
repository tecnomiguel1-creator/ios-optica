import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../models/clinic_models.dart';
import '../../services/admin_service.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';

class LabOrdersScreen extends StatefulWidget {
  final AppState appState;

  const LabOrdersScreen({super.key, required this.appState});

  @override
  State<LabOrdersScreen> createState() => _LabOrdersScreenState();
}

class _LabOrdersScreenState extends State<LabOrdersScreen>
    with SingleTickerProviderStateMixin {
  final _adminService = AdminService();
  late TabController _tabController;

  List<LabOrderModel> _labOrders = [];
  List<RepairModel> _repairs = [];
  bool _loading = true;

  String _searchQuery = '';
  String _selectedStatusFilter = 'todos'; // todos | pendientes | proceso | listos | entregados

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _adminService.getLabOrders(),
      _adminService.getRepairs(),
    ]);

    if (mounted) {
      setState(() {
        _labOrders = results[0] as List<LabOrderModel>;
        _repairs = results[1] as List<RepairModel>;
        _loading = false;
      });
    }
  }

  // Filtros de Lentes
  List<LabOrderModel> get _filteredLabOrders {
    return _labOrders.where((order) {
      final matchesSearch = _searchQuery.isEmpty ||
          (order.codigo ?? 'PED-${order.id}').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (order.clienteNombre?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (order.tipoCristal?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (order.tipoMontura?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (order.laboratorio?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      if (!matchesSearch) return false;

      final st = order.estado.toLowerCase();
      switch (_selectedStatusFilter) {
        case 'pendientes':
          return st == 'pendiente' || st == 'recibido' || st == 'en_preparacion';
        case 'proceso':
          return st == 'en_laboratorio' || st == 'en_taller' || st == 'en_proceso';
        case 'listos':
          return st == 'listo' || st == 'lista' || st == 'terminado';
        case 'entregados':
          return st == 'entregado' || st == 'entregada';
        default:
          return true;
      }
    }).toList();
  }

  // Filtros de Reparaciones
  List<RepairModel> get _filteredRepairs {
    return _repairs.where((rep) {
      final matchesSearch = _searchQuery.isEmpty ||
          (rep.codigo ?? 'REP-${rep.id}').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (rep.clienteNombre?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          rep.tipo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          rep.descripcion.toLowerCase().contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      final st = rep.estado.toLowerCase();
      switch (_selectedStatusFilter) {
        case 'pendientes':
          return st == 'recibido' || st == 'recibida' || st == 'pendiente';
        case 'proceso':
          return st == 'en_revision' || st == 'en_reparacion' || st == 'en_proceso';
        case 'listos':
          return st == 'listo' || st == 'lista' || st == 'reparado';
        case 'entregados':
          return st == 'entregado' || st == 'entregada';
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera Principal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Taller Óptico y Laboratorio',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Gestión de biselado, montaje de cristales, tallado y reparación de monturas',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showNewRepairDialog(context),
                      icon: const Icon(Icons.build_outlined, size: 18),
                      label: const Text('Nueva Reparación'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.warningDark,
                        side: const BorderSide(color: AppColors.warningDark),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showNewLabOrderDialog(context),
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text('Nueva Orden de Lentes'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Tarjetas KPI de Estado del Taller
            _buildWorkshopKpiBar(isDesktop),
            const SizedBox(height: 16),

            // Pestañas de Navegación del Taller (Lentes vs Reparaciones)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: [
                  Tab(
                    icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                    text: 'Órdenes de Lentes y Biselado (${_labOrders.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.handyman_outlined, size: 18),
                    text: 'Taller de Reparaciones (${_repairs.length})',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Barra de Búsqueda y Filtros de Estado
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: _tabController.index == 0
                          ? 'Buscar por orden, cliente, montura, cristales o laboratorio...'
                          : 'Buscar por reparación, cliente, descripción o daño...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 12),
                _buildFilterChips(),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Actualizar lista',
                  icon: const Icon(Icons.refresh, color: AppColors.primary),
                  onPressed: _loadAllData,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Contenido de la Pestaña
            Expanded(
              child: _loading
                  ? const LoadingIndicator(message: 'Cargando órdenes del taller óptico...')
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildLabOrdersView(),
                        _buildRepairsView(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Barra de Indicadores KPI
  Widget _buildWorkshopKpiBar(bool isDesktop) {
    final pendingLenses = _labOrders.where((o) => o.estado == 'pendiente' || o.estado == 'en_preparacion').length;
    final inLabLenses = _labOrders.where((o) => o.estado == 'en_laboratorio').length;
    final readyLenses = _labOrders.where((o) => o.estado == 'listo').length;
    final inRepair = _repairs.where((r) => r.estado == 'en_reparacion' || r.estado == 'en_revision' || r.estado == 'recibido').length;

    return Row(
      children: [
        _buildMiniKpi('Pendientes / Cristales', '$pendingLenses', AppColors.warning, Icons.pending_actions_outlined),
        const SizedBox(width: 12),
        _buildMiniKpi('En Taller / Laboratorio', '$inLabLenses', AppColors.info, Icons.precision_manufacturing_outlined),
        const SizedBox(width: 12),
        _buildMiniKpi('Listos para Entrega', '$readyLenses', AppColors.success, Icons.check_circle_outline),
        const SizedBox(width: 12),
        _buildMiniKpi('Reparaciones Activas', '$inRepair', AppColors.primary, Icons.handyman_outlined),
      ],
    );
  }

  Widget _buildMiniKpi(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Chips de Filtro de Estado
  Widget _buildFilterChips() {
    final filters = [
      {'key': 'todos', 'label': 'Todos'},
      {'key': 'pendientes', 'label': 'Pendientes'},
      {'key': 'proceso', 'label': 'En Proceso'},
      {'key': 'listos', 'label': 'Listos'},
      {'key': 'entregados', 'label': 'Entregados'},
    ];

    return Wrap(
      spacing: 6,
      children: filters.map((f) {
        final isSelected = _selectedStatusFilter == f['key'];
        return ChoiceChip(
          label: Text(f['label']!, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          selected: isSelected,
          selectedColor: AppColors.primaryLight,
          labelStyle: TextStyle(color: isSelected ? AppColors.primary : AppColors.textSecondary),
          onSelected: (selected) {
            if (selected) setState(() => _selectedStatusFilter = f['key']!);
          },
        );
      }).toList(),
    );
  }

  // Vista de Órdenes de Lentes
  Widget _buildLabOrdersView() {
    final list = _filteredLabOrders;
    if (list.isEmpty) {
      return const EmptyState(
        icon: Icons.remove_red_eye_outlined,
        title: 'No hay órdenes de lentes en esta vista',
        message: 'Utilice el botón "Nueva Orden de Lentes" para registrar un trabajo de taller o cambie los filtros.',
      );
    }

    return Card(
      child: ListView.separated(
        itemCount: list.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, index) {
          final o = list[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: const Icon(Icons.remove_red_eye, color: AppColors.primary, size: 20),
            ),
            title: Row(
              children: [
                Text(
                  o.codigo ?? 'ORD-${o.id.toString().padLeft(4, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Montaje de Lentes', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    o.clienteNombre ?? 'Cliente #${o.clienteId}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cristales: ${o.tipoCristal ?? "Estándar"} • Montura: ${o.tipoMontura ?? "No especificada"}\n'
                    'Taller / Lab: ${o.laboratorio ?? "Taller Interno"} • Promesa: ${o.fechaEstimada != null ? Formatters.formatDate(o.fechaEstimada!) : "Sin fecha definida"}',
                    style: const TextStyle(fontSize: 12, height: 1.3),
                  ),
                  if (o.precio > 0 || o.abono > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Precio: ${Formatters.formatCurrency(o.precio)}  |  Abono: ${Formatters.formatCurrency(o.abono)}  |  Saldo: ${Formatters.formatCurrency(o.saldo)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: o.saldo > 0 ? AppColors.danger : AppColors.success,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusChip(o.estado, isLabOrder: true, id: o.id),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Ver detalle de orden',
                  icon: const Icon(Icons.visibility_outlined, size: 20, color: AppColors.primary),
                  onPressed: () => _showLabOrderDetailDialog(context, o),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Vista de Reparaciones
  Widget _buildRepairsView() {
    final list = _filteredRepairs;
    if (list.isEmpty) {
      return const EmptyState(
        icon: Icons.handyman_outlined,
        title: 'No hay reparaciones en esta vista',
        message: 'Utilice el botón "Nueva Reparación" para registrar trabajos de soldadura, plaquetas o ajuste.',
      );
    }

    return Card(
      child: ListView.separated(
        itemCount: list.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, index) {
          final r = list[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: AppColors.warning.withValues(alpha: 0.12),
              child: const Icon(Icons.handyman, color: AppColors.warningDark, size: 20),
            ),
            title: Row(
              children: [
                Text(
                  r.codigo ?? 'REP-${r.id.toString().padLeft(4, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    r.tipo.toUpperCase(),
                    style: const TextStyle(fontSize: 10, color: AppColors.warningDark, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    r.clienteNombre ?? 'Cliente #${r.clienteId}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daño / Trabajo: ${r.descripcion}\n'
                    'Recepción: ${r.fechaIngreso != null ? Formatters.formatDate(r.fechaIngreso!) : "Hoy"} • Promesa: ${r.fechaEstimada != null ? Formatters.formatDate(r.fechaEstimada!) : "Sin fecha definida"}',
                    style: const TextStyle(fontSize: 12, height: 1.3),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Costo: ${Formatters.formatCurrency(r.costo)}  |  Abono: ${Formatters.formatCurrency(r.abono)}  |  Saldo: ${Formatters.formatCurrency(r.saldo)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: r.saldo > 0 ? AppColors.danger : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusChip(r.estado, isLabOrder: false, id: r.id),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Ver detalle de reparación',
                  icon: const Icon(Icons.visibility_outlined, size: 20, color: AppColors.primary),
                  onPressed: () => _showRepairDetailDialog(context, r),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Chip de Estado con Dropdown Rápido
  Widget _buildStatusChip(String estado, {required bool isLabOrder, required int id}) {
    Color bg;
    Color fg;
    String display;

    switch (estado.toLowerCase()) {
      case 'pendiente':
      case 'recibido':
      case 'recibida':
        bg = AppColors.warningLight;
        fg = const Color(0xFF92400E);
        display = 'Pendiente / Recibido';
        break;
      case 'en_laboratorio':
      case 'en_taller':
      case 'en_reparacion':
      case 'en_proceso':
      case 'en_revision':
        bg = AppColors.infoLight;
        fg = const Color(0xFF0369A1);
        display = 'En Taller';
        break;
      case 'listo':
      case 'lista':
      case 'reparado':
        bg = AppColors.successLight;
        fg = const Color(0xFF065F46);
        display = 'Listo para Entrega';
        break;
      case 'entregado':
      case 'entregada':
        bg = const Color(0xFFE2E8F0);
        fg = const Color(0xFF334155);
        display = 'Entregado';
        break;
      default:
        bg = AppColors.dangerLight;
        fg = AppColors.danger;
        display = estado;
    }

    return PopupMenuButton<String>(
      initialValue: estado,
      tooltip: 'Cambiar estado del trabajo',
      onSelected: (newStatus) async {
        final messenger = ScaffoldMessenger.of(context);
        try {
          if (isLabOrder) {
            await _adminService.updateLabOrderState(id, newStatus);
          } else {
            await _adminService.updateRepairState(id, newStatus);
          }
          if (mounted) {
            _loadAllData();
            messenger.showSnackBar(
              SnackBar(
                content: Text('Trabajo #$id actualizado a: $newStatus'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            messenger.showSnackBar(
              SnackBar(content: Text('Error al cambiar estado: $e'), backgroundColor: AppColors.danger),
            );
          }
        }
      },
      itemBuilder: (_) => isLabOrder
          ? const [
              PopupMenuItem(value: 'pendiente', child: Text('Pendiente / En Espera')),
              PopupMenuItem(value: 'en_laboratorio', child: Text('En Taller / Biselado')),
              PopupMenuItem(value: 'listo', child: Text('Listo para Entrega')),
              PopupMenuItem(value: 'entregado', child: Text('Entregado al Cliente')),
              PopupMenuItem(value: 'cancelado', child: Text('Cancelado')),
            ]
          : const [
              PopupMenuItem(value: 'recibido', child: Text('Recibido en Banco')),
              PopupMenuItem(value: 'en_reparacion', child: Text('En Reparación / Soldadura')),
              PopupMenuItem(value: 'listo', child: Text('Listo para Entrega')),
              PopupMenuItem(value: 'entregado', child: Text('Entregado al Cliente')),
              PopupMenuItem(value: 'cancelado', child: Text('Cancelado')),
            ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(display, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 16, color: fg),
          ],
        ),
      ),
    );
  }

  // Diálogo de Detalle de Orden de Lentes
  void _showLabOrderDetailDialog(BuildContext context, LabOrderModel o) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.remove_red_eye, color: AppColors.primary),
            const SizedBox(width: 10),
            Text('Ficha de Trabajo: ORD-${o.id.toString().padLeft(4, '0')}'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Cliente / Paciente', o.clienteNombre ?? 'Cliente #${o.clienteId}'),
                _buildDetailRow('Tipo de Lente / Cristales', o.tipoCristal ?? 'No especificado'),
                _buildDetailRow('Montura', o.tipoMontura ?? 'No especificada'),
                _buildDetailRow('Laboratorio / Responsable', o.laboratorio ?? 'Taller Interno'),
                _buildDetailRow('Fecha de Recepción', o.fechaPedido != null ? Formatters.formatDate(o.fechaPedido!) : 'Hoy'),
                _buildDetailRow('Fecha Estimada de Entrega', o.fechaEstimada != null ? Formatters.formatDate(o.fechaEstimada!) : 'No definida'),
                _buildDetailRow('Estado del Trabajo', o.estado.toUpperCase()),
                const Divider(),
                _buildDetailRow('Precio Pactado', Formatters.formatCurrency(o.precio)),
                _buildDetailRow('Abono Registrado', Formatters.formatCurrency(o.abono)),
                _buildDetailRow('Saldo Pendiente', Formatters.formatCurrency(o.saldo)),
                if (o.observaciones != null && o.observaciones!.isNotEmpty) ...[
                  const Divider(),
                  const Text('Observaciones Técnicas:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(o.observaciones!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  // Diálogo de Detalle de Reparación
  void _showRepairDetailDialog(BuildContext context, RepairModel r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.handyman, color: AppColors.warningDark),
            const SizedBox(width: 10),
            Text('Ficha de Reparación: REP-${r.id.toString().padLeft(4, '0')}'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Cliente', r.clienteNombre ?? 'Cliente #${r.clienteId}'),
                _buildDetailRow('Tipo de Trabajo', r.tipo.toUpperCase()),
                _buildDetailRow('Descripción del Daño', r.descripcion),
                _buildDetailRow('Responsable Técnico', r.responsable ?? 'Taller Central ONLY EYES'),
                _buildDetailRow('Fecha de Recepción', r.fechaIngreso != null ? Formatters.formatDate(r.fechaIngreso!) : 'Hoy'),
                _buildDetailRow('Fecha Estimada de Entrega', r.fechaEstimada != null ? Formatters.formatDate(r.fechaEstimada!) : 'No definida'),
                _buildDetailRow('Estado', r.estado.toUpperCase()),
                const Divider(),
                _buildDetailRow('Costo de Reparación', Formatters.formatCurrency(r.costo)),
                _buildDetailRow('Abono Registrado', Formatters.formatCurrency(r.abono)),
                _buildDetailRow('Saldo Pendiente', Formatters.formatCurrency(r.saldo)),
                if (r.observaciones != null && r.observaciones!.isNotEmpty) ...[
                  const Divider(),
                  const Text('Observaciones:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(r.observaciones!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  // Diálogo: Nueva Orden de Lentes
  void _showNewLabOrderDialog(BuildContext context) {
    final clientCtrl = TextEditingController(text: '1');
    final labCtrl = TextEditingController(text: 'Laboratorio Óptico Santo Domingo');
    final cristalCtrl = TextEditingController(text: 'Policarbonato Antirreflejo');
    final monturaCtrl = TextEditingController(text: 'Montura Acetato Negra');
    final precioCtrl = TextEditingController(text: '3500.00');
    final abonoCtrl = TextEditingController(text: '1500.00');
    final obsCtrl = TextEditingController();
    DateTime? selectedDate = DateTime.now().add(const Duration(days: 3));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nueva Orden de Lentes y Biselado'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: clientCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'ID del Cliente / Paciente *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: cristalCtrl.text,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Cristales / Lente *',
                      prefixIcon: Icon(Icons.lens_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Policarbonato Antirreflejo', child: Text('Policarbonato Antirreflejo (AR)')),
                      DropdownMenuItem(value: 'Progresivo Digital BlueShield', child: Text('Progresivo Digital BlueShield')),
                      DropdownMenuItem(value: 'Monofocal Blanco CR-39', child: Text('Monofocal Blanco CR-39')),
                      DropdownMenuItem(value: 'Fotocromático Transitions', child: Text('Fotocromático Transitions Gen 8')),
                      DropdownMenuItem(value: 'Bifocal Flat-Top 28', child: Text('Bifocal Flat-Top 28')),
                      DropdownMenuItem(value: 'Alto Índice 1.67 Antirreflejo', child: Text('Alto Índice 1.67 Antirreflejo')),
                    ],
                    onChanged: (val) {
                      if (val != null) cristalCtrl.text = val;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: monturaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Montura (Marca, Material o Propia) *',
                      prefixIcon: Icon(Icons.visibility_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: labCtrl.text,
                    decoration: const InputDecoration(
                      labelText: 'Taller / Laboratorio Asignado *',
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Laboratorio Óptico Santo Domingo', child: Text('Laboratorio Óptico Santo Domingo')),
                      DropdownMenuItem(value: 'Taller Interno ONLY EYES', child: Text('Taller Interno ONLY EYES (Biselado local)')),
                      DropdownMenuItem(value: 'MegaLab Santiago', child: Text('MegaLab Santiago')),
                      DropdownMenuItem(value: 'Laboratorio Nacional', child: Text('Laboratorio Nacional')),
                    ],
                    onChanged: (val) {
                      if (val != null) labCtrl.text = val;
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Fecha Estimada de Entrega:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      selectedDate != null ? Formatters.formatDate(selectedDate!.toIso8601String()) : 'Seleccionar fecha',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.calendar_today, color: AppColors.primary),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 3)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: precioCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Precio (RD\$)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: abonoCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Abono Inicial (RD\$)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: obsCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Observaciones de Biselado / Montaje'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final clienteId = int.tryParse(clientCtrl.text.trim()) ?? 1;
                final pr = double.tryParse(precioCtrl.text.trim()) ?? 0.0;
                final ab = double.tryParse(abonoCtrl.text.trim()) ?? 0.0;

                final order = LabOrderModel(
                  id: 0,
                  clienteId: clienteId,
                  laboratorio: labCtrl.text.trim(),
                  tipoCristal: cristalCtrl.text.trim(),
                  tipoMontura: monturaCtrl.text.trim(),
                  fechaEstimada: selectedDate?.toIso8601String().substring(0, 10),
                  estado: 'en_laboratorio',
                  precio: pr,
                  abono: ab,
                  observaciones: obsCtrl.text.trim().isNotEmpty ? obsCtrl.text.trim() : null,
                );

                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                try {
                  await _adminService.createLabOrder(order);
                  if (mounted) {
                    _loadAllData();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Orden enviada al taller con éxito'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Error al registrar orden: $e'), backgroundColor: AppColors.danger),
                    );
                  }
                }
              },
              child: const Text('Guardar Orden'),
            ),
          ],
        ),
      ),
    );
  }

  // Diálogo: Nueva Reparación de Montura
  void _showNewRepairDialog(BuildContext context) {
    final clientCtrl = TextEditingController(text: '1');
    final tipoCtrl = TextEditingController(text: 'Soldadura de puente');
    final descCtrl = TextEditingController(text: 'Montura metálica fracturada en puente nasal');
    final costoCtrl = TextEditingController(text: '850.00');
    final abonoCtrl = TextEditingController(text: '500.00');
    final obsCtrl = TextEditingController();
    DateTime? selectedDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nueva Reparación de Montura'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: clientCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'ID del Cliente *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: tipoCtrl.text,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Reparación *',
                      prefixIcon: Icon(Icons.build_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Soldadura de puente', child: Text('Soldadura de puente metálico')),
                      DropdownMenuItem(value: 'Soldadura de charnela', child: Text('Soldadura / unión de charnela')),
                      DropdownMenuItem(value: 'Cambio de plaquetas', child: Text('Cambio de plaquetas y tornillos')),
                      DropdownMenuItem(value: 'Ajuste y alineación', child: Text('Ajuste de frente y nivelación de varillas')),
                      DropdownMenuItem(value: 'Reemplazo de terminales', child: Text('Reemplazo de terminales plásticos')),
                      DropdownMenuItem(value: 'Hilo de nylon ranurado', child: Text('Reemplazo de nylon en montura al aire')),
                    ],
                    onChanged: (val) {
                      if (val != null) tipoCtrl.text = val;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Descripción del daño / Servicio a realizar *',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Fecha Estimada de Entrega:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      selectedDate != null ? Formatters.formatDate(selectedDate!.toIso8601String()) : 'Seleccionar fecha',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.calendar_today, color: AppColors.primary),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 60)),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: costoCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Costo Reparación (RD\$)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: abonoCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Abono Inicial (RD\$)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: obsCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Observaciones del Banco de Taller'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final clienteId = int.tryParse(clientCtrl.text.trim()) ?? 1;
                final cst = double.tryParse(costoCtrl.text.trim()) ?? 0.0;
                final ab = double.tryParse(abonoCtrl.text.trim()) ?? 0.0;

                final repair = RepairModel(
                  id: 0,
                  clienteId: clienteId,
                  tipo: tipoCtrl.text.trim(),
                  descripcion: descCtrl.text.trim(),
                  costo: cst,
                  abono: ab,
                  fechaEstimada: selectedDate?.toIso8601String().substring(0, 10),
                  estado: 'recibido',
                  observaciones: obsCtrl.text.trim().isNotEmpty ? obsCtrl.text.trim() : null,
                );

                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                try {
                  await _adminService.createRepair(repair);
                  if (mounted) {
                    _loadAllData();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Reparación registrada en el taller'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Error al registrar reparación: $e'), backgroundColor: AppColors.danger),
                    );
                  }
                }
              },
              child: const Text('Guardar Reparación'),
            ),
          ],
        ),
      ),
    );
  }
}
