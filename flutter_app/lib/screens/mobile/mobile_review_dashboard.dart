import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/clinic_models.dart';
import '../../models/sales_series_point.dart';
import '../../services/admin_service.dart';
import '../../services/reports_service.dart';
import '../../state/app_state.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/loading_indicator.dart';

/// Inicio móvil: lectura rápida para supervisar la óptica, no para sustituir
/// los formularios operativos de Windows.
class MobileReviewDashboard extends StatefulWidget {
  final AppState appState;

  const MobileReviewDashboard({super.key, required this.appState});

  @override
  State<MobileReviewDashboard> createState() => _MobileReviewDashboardState();
}

class _MobileReviewDashboardState extends State<MobileReviewDashboard> {
  final _admin = AdminService();
  final _reports = ReportsService();
  bool _loading = true;
  String? _error;
  FinancialReportSummary? _summary;
  List<SalesSeriesPoint> _series = [];
  List<AppointmentModel> _todayAppointments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _admin.getFinancialReport(),
        _reports.getSalesSeries('dia'),
        _admin.getAppointments(),
      ]);
      final today = DateTime.now();
      final appointments = results[2] as List<AppointmentModel>;
      if (!mounted) return;
      setState(() {
        _summary = results[0] as FinancialReportSummary;
        _series = results[1] as List<SalesSeriesPoint>;
        _todayAppointments = appointments.where((appointment) {
          final date = DateTime.tryParse(appointment.fechaHora);
          return date != null &&
              date.year == today.year &&
              date.month == today.month &&
              date.day == today.day &&
              appointment.estado != 'cancelada';
        }).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo actualizar el resumen. Desliza para reintentar.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const LoadingIndicator(message: 'Actualizando resumen...');
    }
    final summary = _summary ??
        FinancialReportSummary(
          cantidadVentas: 0,
          totalVendido: 0,
          cobrado: 0,
          pendiente: 0,
        );
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          Text(
            'Hola, ${widget.appState.currentUser?.nombre ?? 'equipo'}',
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          const Text(
            'Revisión rápida de la óptica',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          if (_error != null) ...[
            ErrorBanner(message: _error!, onRetry: _load),
            const SizedBox(height: 12),
          ],
          _ConnectionPill(connected: widget.appState.isBackendConnected),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.payments_outlined,
                label: 'Vendido',
                value: Formatters.formatCurrency(summary.totalVendido),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.receipt_long_outlined,
                label: 'Ventas',
                value: '${summary.cantidadVentas}',
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Cobrado',
                value: Formatters.formatCurrency(summary.cobrado),
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.event_available_outlined,
                label: 'Citas hoy',
                value: '${_todayAppointments.length}',
                color: AppColors.accent,
              ),
            ),
          ]),
          const SizedBox(height: 22),
          _SalesChart(points: _series),
          const SizedBox(height: 22),
          _TodayAppointments(
            appointments: _todayAppointments,
            onViewAgenda: () =>
                widget.appState.setActiveSection(AppSection.appointments),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () =>
                widget.appState.setActiveSection(AppSection.appointments),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Agendar una cita'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionPill extends StatelessWidget {
  final bool connected;
  const _ConnectionPill({required this.connected});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: connected ? AppColors.successLight : AppColors.warningLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Icon(connected ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
              size: 18,
              color: connected ? AppColors.success : AppColors.warningDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              connected ? 'Datos sincronizados' : 'Sin conexión al servidor',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: connected ? AppColors.success : AppColors.warningDark,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 19),
            onPressed: () {},
            tooltip: 'Desliza para actualizar',
          )
        ]),
      );
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 12),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
          ]),
        ),
      );
}

class _SalesChart extends StatelessWidget {
  final List<SalesSeriesPoint> points;
  const _SalesChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final max = points.fold<double>(
        0, (value, point) => point.total > value ? point.total : value);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Ventas recientes',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Importe vendido por día',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 18),
          if (points.isEmpty)
            const SizedBox(
              height: 120,
              child: Center(
                  child: Text('Todavía no hay ventas para mostrar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary))),
            )
          else
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: points.take(7).map((point) {
                  final ratio = max == 0 ? 0.0 : point.total / max;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  height: 108 * ratio,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                                point.label.length > 5
                                    ? point.label
                                        .substring(point.label.length - 5)
                                    : point.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 9, color: AppColors.textMuted)),
                          ]),
                    ),
                  );
                }).toList(),
              ),
            ),
        ]),
      ),
    );
  }
}

class _TodayAppointments extends StatelessWidget {
  final List<AppointmentModel> appointments;
  final VoidCallback onViewAgenda;
  const _TodayAppointments(
      {required this.appointments, required this.onViewAgenda});

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(
                child: Text('Citas de hoy',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              ),
              TextButton(
                  onPressed: onViewAgenda, child: const Text('Ver agenda')),
            ]),
            if (appointments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No hay citas para hoy.',
                    style: TextStyle(color: AppColors.textSecondary)),
              )
            else
              ...appointments.take(3).map((appointment) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(Icons.schedule, color: AppColors.primary),
                    ),
                    title: Text(appointment.pacienteNombre ?? 'Paciente',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                        Formatters.formatDateTime(appointment.fechaHora),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  )),
          ]),
        ),
      );
}
