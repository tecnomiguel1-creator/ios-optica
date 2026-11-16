import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/sale_model.dart';
import '../../models/sales_series_point.dart';
import '../../services/admin_service.dart';
import '../../services/reports_service.dart';
import '../../services/sales_service.dart';
import '../../state/app_state.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/stat_card.dart';

class ReportsDashboardScreen extends StatefulWidget {
  final AppState appState;
  const ReportsDashboardScreen({super.key, required this.appState});

  @override
  State<ReportsDashboardScreen> createState() => _ReportsDashboardScreenState();
}

class _ReportsDashboardScreenState extends State<ReportsDashboardScreen> {
  final _admin = AdminService();
  final _reports = ReportsService();
  final _sales = SalesService();
  String _period = 'dia';
  bool _loading = true;
  String? _error;
  List<SalesSeriesPoint> _series = [];
  List<AccountReceivableModel> _receivables = [];
  double _sold = 0;
  double _collected = 0;
  double _pending = 0;
  int _saleCount = 0;

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
      final summary = await _admin.getFinancialReport();
      final series = await _reports.getSalesSeries(_period);
      final accounts = await _sales.getAccountsReceivable();
      if (!mounted) return;
      setState(() {
        _sold = summary.totalVendido;
        _collected = summary.cobrado;
        _pending = summary.pendiente;
        _saleCount = summary.cantidadVentas;
        _series = series;
        _receivables = accounts;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error =
              'No se pudieron cargar los reportes. Verifica la conexión e inténtalo de nuevo.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: _loading
            ? const LoadingIndicator(message: 'Cargando reportes reales...')
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(padding: const EdgeInsets.all(24), children: [
                  const Text('Reportes y Estadísticas',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  const Text(
                      'Ventas, cobros y saldos pendientes calculados desde las operaciones registradas.',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  if (_error != null)
                    ErrorBanner(message: _error!, onRetry: _load),
                  const SizedBox(height: 18),
                  LayoutBuilder(builder: (context, box) {
                    final width = box.maxWidth < 650
                        ? box.maxWidth
                        : (box.maxWidth - 36) / 4;
                    return Wrap(spacing: 12, runSpacing: 12, children: [
                      SizedBox(
                          width: width,
                          child: StatCard(
                              title: 'Ventas del mes',
                              value: Formatters.formatCurrency(_sold),
                              icon: Icons.trending_up,
                              iconColor: AppColors.primary)),
                      SizedBox(
                          width: width,
                          child: StatCard(
                              title: 'Cobrado',
                              value: Formatters.formatCurrency(_collected),
                              icon: Icons.payments_outlined,
                              iconColor: AppColors.success)),
                      SizedBox(
                          width: width,
                          child: StatCard(
                              title: 'Por cobrar',
                              value: Formatters.formatCurrency(_pending),
                              icon: Icons.account_balance_wallet_outlined,
                              iconColor: AppColors.warning)),
                      SizedBox(
                          width: width,
                          child: StatCard(
                              title: 'Ventas',
                              value: _saleCount.toString(),
                              icon: Icons.receipt_long_outlined,
                              iconColor: AppColors.info)),
                    ]);
                  }),
                  const SizedBox(height: 20),
                  Card(
                      child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(children: [
                                  Icon(Icons.bar_chart_outlined,
                                      color: AppColors.primary),
                                  SizedBox(width: 10),
                                  Text('Ventas y cobros',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold))
                                ]),
                                const SizedBox(height: 12),
                                Wrap(spacing: 8, children: [
                                  _periodButton('dia', 'Por día'),
                                  _periodButton('mes', 'Por mes'),
                                  _periodButton('ano', 'Por año'),
                                ]),
                                const SizedBox(height: 22),
                                SalesBars(points: _series),
                                const SizedBox(height: 10),
                                const Row(children: [
                                  Legend(
                                      color: AppColors.primary,
                                      label: 'Ventas'),
                                  SizedBox(width: 18),
                                  Legend(
                                      color: AppColors.secondary,
                                      label: 'Cobrado')
                                ]),
                              ]))),
                  const SizedBox(height: 20),
                  _receivablesCard(),
                ]),
              ),
      );

  Widget _periodButton(String value, String label) => ChoiceChip(
        label: Text(label),
        selected: _period == value,
        selectedColor: AppColors.primaryLight,
        labelStyle: TextStyle(
            color:
                _period == value ? AppColors.primary : AppColors.textSecondary,
            fontWeight: FontWeight.w600),
        onSelected: (_) {
          if (_period != value) {
            setState(() => _period = value);
            _load();
          }
        },
      );

  Widget _receivablesCard() {
    final total = _receivables.fold<double>(0, (sum, item) => sum + item.saldo);
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.request_quote_outlined,
                    color: AppColors.warning),
                const SizedBox(width: 10),
                const Expanded(
                    child: Text('Cuentas por cobrar',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold))),
                Text(Formatters.formatCurrency(total),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.warningDark)),
              ]),
              const SizedBox(height: 6),
              const Text('Clientes con saldo pendiente o pagos parciales.',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              if (_receivables.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No hay cuentas pendientes.',
                        style: TextStyle(color: AppColors.textSecondary)))
              else
                ..._receivables.map((a) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                          backgroundColor: AppColors.warningLight,
                          child: Icon(Icons.person_outline,
                              color: AppColors.warningDark)),
                      title: Text(a.clienteNombreCompleto),
                      subtitle: Text(
                          'Venta #${a.ventaId} · ${Formatters.formatDate(a.fechaVenta)} · Pagado: ${Formatters.formatCurrency(a.montoPagado)}'),
                      trailing: Text(Formatters.formatCurrency(a.saldo),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.danger)),
                    )),
            ])));
  }
}

class SalesBars extends StatelessWidget {
  final List<SalesSeriesPoint> points;
  const SalesBars({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
          height: 180,
          child: Center(
              child: Text('Aún no hay ventas en este período.',
                  style: TextStyle(color: AppColors.textSecondary))));
    }
    final max = points.fold<double>(
        0, (value, item) => item.total > value ? item.total : value);
    final step = max / 4;
    return SizedBox(
        height: 220,
        child: Row(children: [
          SizedBox(
              width: 58,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(
                    5,
                    (index) => Text(
                          Formatters.formatCurrency(step * (4 - index)),
                          style: const TextStyle(
                              fontSize: 9, color: AppColors.textSecondary),
                        )),
              )),
          const SizedBox(width: 8),
          Expanded(
              child: LayoutBuilder(
                  builder: (context, box) => Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: points.map((point) {
                          final ratio = max == 0 ? 0.0 : point.total / max;
                          final collected = point.total == 0
                              ? 0.0
                              : point.collected / point.total;
                          return Expanded(
                              child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 3),
                                  child: Tooltip(
                                    message:
                                        '${point.label}\nVentas: ${Formatters.formatCurrency(point.total)}\nCobrado: ${Formatters.formatCurrency(point.collected)}',
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Expanded(
                                              child: Align(
                                                  alignment:
                                                      Alignment.bottomCenter,
                                                  child: SizedBox(
                                                    height:
                                                        (box.maxHeight - 32) *
                                                            ratio,
                                                    child: DecoratedBox(
                                                        decoration: BoxDecoration(
                                                            color: AppColors
                                                                .primaryLight,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        5)),
                                                        child: Align(
                                                          alignment: Alignment
                                                              .bottomCenter,
                                                          child: FractionallySizedBox(
                                                              heightFactor:
                                                                  collected,
                                                              child: DecoratedBox(
                                                                  decoration: BoxDecoration(
                                                                      color: AppColors
                                                                          .secondary,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              5)))),
                                                        )),
                                                  ))),
                                          const SizedBox(height: 6),
                                          Text(
                                              point.label.length > 7
                                                  ? point.label.substring(5)
                                                  : point.label,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 9,
                                                  color:
                                                      AppColors.textSecondary)),
                                        ]),
                                  )));
                        }).toList(),
                      ))),
        ]));
  }
}

class Legend extends StatelessWidget {
  final Color color;
  final String label;
  const Legend({super.key, required this.color, required this.label});
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 5),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary))
      ]);
}
