import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/clinic_models.dart';
import '../../services/admin_service.dart';
import '../../state/app_state.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/stat_card.dart';

class AccountsPayableScreen extends StatefulWidget {
  final AppState appState;
  const AccountsPayableScreen({super.key, required this.appState});

  @override
  State<AccountsPayableScreen> createState() => _AccountsPayableScreenState();
}

class _AccountsPayableScreenState extends State<AccountsPayableScreen> {
  final _admin = AdminService();
  List<AccountPayableModel> _accounts = [];
  bool _loading = true;
  String? _error;

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
      final accounts = await _admin.getAccountsPayable();
      if (mounted) {
        setState(() {
          _accounts = accounts;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'No se pudieron cargar las cuentas por pagar.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _recordPayment(AccountPayableModel account) async {
    final amount =
        TextEditingController(text: account.saldo.toStringAsFixed(2));
    final reference = TextEditingController();
    var method = 'transferencia';
    final accepted = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (context, setDialog) => AlertDialog(
                  title: Text('Pago a ${account.proveedor}'),
                  content: SizedBox(
                      width: 390,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(
                            'Saldo pendiente: ${Formatters.formatCurrency(account.saldo)}'),
                        const SizedBox(height: 14),
                        TextField(
                            controller: amount,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                                labelText: 'Monto a pagar')),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                            initialValue: method,
                            decoration: const InputDecoration(
                                labelText: 'Método de pago'),
                            items: const [
                              DropdownMenuItem(
                                  value: 'efectivo', child: Text('Efectivo')),
                              DropdownMenuItem(
                                  value: 'transferencia',
                                  child: Text('Transferencia')),
                              DropdownMenuItem(
                                  value: 'tarjeta', child: Text('Tarjeta')),
                              DropdownMenuItem(
                                  value: 'otro', child: Text('Otro')),
                            ],
                            onChanged: (value) => setDialog(
                                () => method = value ?? 'transferencia')),
                        const SizedBox(height: 12),
                        TextField(
                            controller: reference,
                            decoration: const InputDecoration(
                                labelText: 'Referencia (opcional)')),
                      ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar')),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Registrar pago'))
                  ],
                )));
    if (accepted != true) return;
    final value = double.tryParse(amount.text.replaceAll(',', '.'));
    if (value == null || value <= 0 || value > account.saldo) {
      if (mounted) {
        _notice('Indica un monto válido que no supere el saldo.', error: true);
      }
      return;
    }
    try {
      await _admin.paySupplier(
          compraId: account.compraId,
          monto: value,
          metodoPago: method,
          referencia: reference.text.trim());
      if (mounted) {
        _notice('Pago registrado correctamente.');
        _load();
      }
    } catch (_) {
      if (mounted) _notice('No se pudo registrar el pago.', error: true);
    }
  }

  void _notice(String text, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(text),
          backgroundColor: error ? AppColors.danger : AppColors.success));

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          backgroundColor: AppColors.background,
          body: LoadingIndicator(message: 'Cargando cuentas por pagar...'));
    }
    final due = _accounts.fold<double>(0, (total, item) => total + item.saldo);
    final paid =
        _accounts.fold<double>(0, (total, item) => total + item.montoPagado);
    final suppliers = _accounts.map((e) => e.proveedorId).toSet().length;
    return Scaffold(
        backgroundColor: AppColors.background,
        body: RefreshIndicator(
            onRefresh: _load,
            child: ListView(padding: const EdgeInsets.all(24), children: [
              const Text('Cuentas por pagar',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              const Text(
                  'Compras pendientes con proveedores y pagos parciales registrados.',
                  style:
                      TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              if (_error != null) ErrorBanner(message: _error!, onRetry: _load),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      widget.appState.setActiveSection(AppSection.purchases),
                  icon: const Icon(Icons.add_shopping_cart_outlined, size: 18),
                  label: const Text('Registrar compra o cuenta por pagar'),
                ),
              ),
              const SizedBox(height: 18),
              LayoutBuilder(builder: (_, box) {
                final w =
                    box.maxWidth < 620 ? box.maxWidth : (box.maxWidth - 24) / 3;
                return Wrap(spacing: 12, runSpacing: 12, children: [
                  SizedBox(
                      width: w,
                      child: StatCard(
                          title: 'Total pendiente',
                          value: Formatters.formatCurrency(due),
                          icon: Icons.request_quote_outlined,
                          iconColor: AppColors.danger)),
                  SizedBox(
                      width: w,
                      child: StatCard(
                          title: 'Pagado en estas compras',
                          value: Formatters.formatCurrency(paid),
                          icon: Icons.paid_outlined,
                          iconColor: AppColors.success)),
                  SizedBox(
                      width: w,
                      child: StatCard(
                          title: 'Proveedores con saldo',
                          value: suppliers.toString(),
                          icon: Icons.local_shipping_outlined,
                          iconColor: AppColors.primary)),
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
                              Icon(Icons.business_center_outlined,
                                  color: AppColors.primary),
                              SizedBox(width: 10),
                              Text('Deudas con proveedores',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold))
                            ]),
                            const SizedBox(height: 8),
                            const Text(
                                'Cada registro muestra la compra, lo pagado y su saldo pendiente.',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: 10),
                            if (_accounts.isEmpty)
                              Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                            'No hay pagos pendientes a proveedores.',
                                            style: TextStyle(
                                                color:
                                                    AppColors.textSecondary)),
                                        const SizedBox(height: 10),
                                        OutlinedButton.icon(
                                            onPressed: () => widget.appState
                                                .setActiveSection(
                                                    AppSection.purchases),
                                            icon:
                                                const Icon(Icons.add, size: 17),
                                            label: const Text(
                                                'Registrar primera compra'))
                                      ]))
                            else
                              ..._accounts.map((a) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const CircleAvatar(
                                      backgroundColor: AppColors.primaryLight,
                                      child: Icon(Icons.local_shipping_outlined,
                                          color: AppColors.primary)),
                                  title: Text(a.proveedor),
                                  subtitle: Text(
                                      'Compra #${a.compraId} · ${Formatters.formatDate(a.fechaCompra)}\nTotal: ${Formatters.formatCurrency(a.total)} · Pagado: ${Formatters.formatCurrency(a.montoPagado)}'),
                                  isThreeLine: true,
                                  trailing: Wrap(
                                      spacing: 8,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(Formatters.formatCurrency(a.saldo),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.danger)),
                                        OutlinedButton(
                                            onPressed: () => _recordPayment(a),
                                            child: const Text('Pagar'))
                                      ])))
                          ]))),
            ])));
  }
}
