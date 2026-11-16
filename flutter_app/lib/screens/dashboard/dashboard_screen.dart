import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../models/clinic_models.dart';
import '../../models/patient_model.dart';
import '../../models/product_model.dart';
import '../../models/sale_model.dart';
import '../../services/admin_service.dart';
import '../../services/inventory_service.dart';
import '../../services/patient_service.dart';
import '../../services/sales_service.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  final AppState appState;

  const DashboardScreen({super.key, required this.appState});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _inventoryService = InventoryService();
  final _patientService = PatientService();
  final _salesService = SalesService();
  final _adminService = AdminService();

  bool _loading = true;
  int _patientCount = 0;
  List<ProductModel> _lowStockProducts = [];
  double _todaySalesTotal = 0.0;
  int _todayAppointments = 0;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      // Cargar datos en paralelo con tipos explícitos
      final results = await Future.wait([
        _patientService.getPatients(),
        _inventoryService.getLowStockProducts(),
        _salesService.getSales(),
        _adminService.getAppointments(),
      ]);

      final patients = results[0] as List<PatientModel>;
      final lowStock = results[1] as List<ProductModel>;
      final sales = results[2] as List<SaleModel>;
      final appointments = results[3] as List<AppointmentModel>;

      if (mounted) {
        setState(() {
          _patientCount = patients.length;
          _lowStockProducts = lowStock;
          _todayAppointments = appointments.length;
          _todaySalesTotal = sales.fold<double>(
              0.0, (sum, item) => sum + item.total);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = 'No se pudieron cargar las métricas. Verifica la conexión con el servidor e inténtalo de nuevo.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    if (_loading) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Cargando métricas de ONLY EYES 360...'),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_loadError != null) ...[
                ErrorBanner(message: _loadError!, onRetry: _loadDashboardData),
                const SizedBox(height: 16),
              ],
              // Barra de Bienvenida
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Hola, ${widget.appState.currentUser?.nombre ?? "Doctor"}!',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Resumen operativo de la óptica • ${Formatters.formatDate(DateTime.now().toIso8601String())}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.appState.isBackendConnected
                              ? AppColors.successLight
                              : AppColors.warningLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: widget.appState.isBackendConnected
                                    ? AppColors.success
                                    : AppColors.warning,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.appState.isBackendConnected
                                  ? 'Sistema conectado'
                                  : 'Sin conexión',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: widget.appState.isBackendConnected
                                    ? const Color(0xFF065F46)
                                    : const Color(0xFF92400E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Actualizar métricas',
                        onPressed: _loadDashboardData,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Tarjetas de Métricas (KPIs)
              GridView.count(
                crossAxisCount: isDesktop ? 4 : (Responsive.isTablet(context) ? 2 : 1),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: isDesktop ? 1.7 : (Responsive.isTablet(context) ? 1.9 : 2.2),
                children: [
                  StatCard(
                    title: 'Pacientes Registrados',
                    value: '$_patientCount',
                    subtitle: 'Fichas clínicas activas',
                    icon: Icons.people_alt_outlined,
                    iconColor: AppColors.primary,
                    onTap: () => widget.appState.setActiveSection(AppSection.patients),
                  ),
                  StatCard(
                    title: 'Stock Bajo Crítico',
                    value: '${_lowStockProducts.length}',
                    subtitle: _lowStockProducts.isEmpty
                        ? 'Inventario en niveles óptimos'
                        : 'Requieren orden de compra',
                    icon: Icons.warning_amber_rounded,
                    iconColor: _lowStockProducts.isEmpty
                        ? AppColors.success
                        : AppColors.danger,
                    onTap: () => widget.appState.setActiveSection(AppSection.inventory),
                  ),
                  StatCard(
                    title: 'Ventas de Hoy',
                    value: Formatters.formatCurrency(_todaySalesTotal),
                    subtitle: 'Facturación en caja',
                    icon: Icons.point_of_sale,
                    iconColor: AppColors.secondary,
                    onTap: () => widget.appState.setActiveSection(AppSection.sales),
                  ),
                  StatCard(
                    title: 'Citas del Día',
                    value: '$_todayAppointments',
                    subtitle: 'Consultas ópticas',
                    icon: Icons.calendar_today_outlined,
                    iconColor: AppColors.accent,
                    onTap: () => widget.appState.setActiveSection(AppSection.appointments),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Botones de Acceso Rápido
              const Text(
                'Acciones Rápidas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: () =>
                        widget.appState.setActiveSection(AppSection.sales),
                    icon: const Icon(Icons.shopping_cart_checkout, size: 18),
                    label: const Text('Nueva Venta POS'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        widget.appState.setActiveSection(AppSection.patients),
                    icon: const Icon(Icons.person_add_outlined, size: 18),
                    label: const Text('Registrar Paciente'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        widget.appState.setActiveSection(AppSection.purchases),
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: const Text('Registrar Compra'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        widget.appState.setActiveSection(AppSection.inventory),
                    icon: const Icon(Icons.add_box_outlined, size: 18),
                    label: const Text('Nuevo Producto'),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Alertas de Stock Bajo (Conectado a FastAPI /api/productos/stock-bajo)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.crisis_alert_rounded,
                                  color: AppColors.danger, size: 22),
                              SizedBox(width: 10),
                              Text(
                                'Alertas de Stock Bajo',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () => widget.appState
                                .setActiveSection(AppSection.inventory),
                            child: const Text('Gestionar Inventario →'),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      if (_lowStockProducts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: EmptyState(
                            icon: Icons.check_circle_outline,
                            title: 'Todo en orden',
                            message:
                                'No hay productos con existencias por debajo de su stock mínimo.',
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _lowStockProducts.length > 5
                              ? 5
                              : _lowStockProducts.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (ctx, index) {
                            final prod = _lowStockProducts[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.dangerLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.inventory,
                                    color: AppColors.danger, size: 20),
                              ),
                              title: Text(
                                prod.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                'Código: ${prod.codigo} • Categoría: ${prod.categoria}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${prod.stockActual} en stock',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.danger,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    'Mínimo: ${prod.stockMinimo}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
