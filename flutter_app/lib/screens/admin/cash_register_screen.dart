import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/cash_models.dart';
import '../../services/cash_service.dart';
import '../../state/app_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/stat_card.dart';

/// Turn-based cash control backed by FastAPI. Commercial documents are non-fiscal.
class CashRegisterScreen extends StatefulWidget {
  final AppState appState;
  const CashRegisterScreen({super.key, required this.appState});
  @override
  State<CashRegisterScreen> createState() => _CashRegisterScreenState();
}

class _CashRegisterScreenState extends State<CashRegisterScreen> {
  final _cash = CashService();
  CashShiftModel? _shift;
  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  String? _openingIdempotencyKey;
  List<Map<String, dynamic>> _history = const [];

  bool get _isManager => const {
        'admin',
        'administrador',
        'gerente',
        'supervisor'
      }.contains(widget.appState.currentUser?.rol);

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      final shift = await _cash.getCurrent();
      final history = _isManager
          ? await _cash.getHistory()
          : const <Map<String, dynamic>>[];
      if (mounted) {
        setState(() {
          _shift = shift;
          _history = history;
          _loadError = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _shift = null;
          _loadError = 'No se pudo consultar el estado de caja. $error';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _message(String text, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(text),
          backgroundColor: error ? AppColors.danger : AppColors.success));

  Future<void> _openCashDialog() async {
    final amount = TextEditingController();
    final notes = TextEditingController();
    final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Abrir caja'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: amount,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'Fondo inicial', prefixText: 'RD\$ ')),
                  TextField(
                      controller: notes,
                      maxLines: 2,
                      decoration: const InputDecoration(
                          labelText: 'Observaciones (opcional)')),
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Abrir'))
                ]));
    if (accepted != true) {
      return;
    }
    final value = double.tryParse(amount.text.replaceAll(',', '.'));
    if (value == null || value < 0) {
      return _message('Indica un fondo inicial válido.', error: true);
    }
    final openingKey = _openingIdempotencyKey ??=
        'cash-open-${DateTime.now().microsecondsSinceEpoch}';
    await _run(() async {
      await _cash.open(
          openingFloat: value, notes: notes.text, idempotencyKey: openingKey);
      _openingIdempotencyKey = null;
      return 'Caja abierta correctamente.';
    }, null);
  }

  Future<void> _movementDialog(String type) async {
    final amount = TextEditingController();
    final concept = TextEditingController();
    final reference = TextEditingController();
    final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text(type == 'ingreso'
                    ? 'Registrar ingreso'
                    : 'Registrar egreso'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: amount,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'Monto', prefixText: 'RD\$ ')),
                  TextField(
                      controller: concept,
                      decoration: const InputDecoration(labelText: 'Concepto')),
                  TextField(
                      controller: reference,
                      decoration: const InputDecoration(
                          labelText: 'Referencia (opcional)')),
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Guardar'))
                ]));
    if (accepted != true) {
      return;
    }
    final value = double.tryParse(amount.text.replaceAll(',', '.'));
    if (value == null || value <= 0 || concept.text.trim().isEmpty) {
      return _message('Completa monto y concepto.', error: true);
    }
    await _run(
        () => _cash.addMovement(
            type: type,
            amount: value,
            concept: concept.text,
            reference: reference.text),
        'Movimiento registrado.');
  }

  Future<void> _closeDialog() async {
    // Conteo ciego: no se rellena el esperado, para que el arqueo sea real.
    final counted = TextEditingController();
    final notes = TextEditingController();
    final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Cerrar y arquear caja'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text(
                      'Cuenta el efectivo físico de la gaveta y registra el total.'),
                  const SizedBox(height: 8),
                  Text(
                      'Fondo de apertura: ${Formatters.formatCurrency(_shift?.openingFloat ?? 0)}',
                      style: const TextStyle(color: AppColors.textSecondary)),
                  Text(
                      'Efectivo esperado: ${Formatters.formatCurrency(_shift?.expectedBalance ?? 0)}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  TextField(
                      controller: counted,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'Efectivo contado', prefixText: 'RD\$ ')),
                  TextField(
                      controller: notes,
                      maxLines: 2,
                      decoration: const InputDecoration(
                          labelText: 'Observaciones (opcional)')),
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Cerrar turno'))
                ]));
    if (accepted != true) {
      return;
    }
    final value = double.tryParse(counted.text.replaceAll(',', '.'));
    if (value == null || value < 0) {
      return _message('Indica el efectivo contado.', error: true);
    }
    if (value != (_shift?.expectedBalance ?? 0) && notes.text.trim().isEmpty) {
      return _message(
          'Indica una observación para registrar la diferencia de caja.',
          error: true);
    }
    int? closedShiftId;
    await _run(() async {
      final result = await _cash.close(countedAmount: value, notes: notes.text);
      closedShiftId = result['turno_id'] as int?;
      final difference = (result['diferencia'] as num?)?.toDouble() ?? 0;
      return 'Turno cerrado. Diferencia de arqueo: ${Formatters.formatCurrency(difference)}';
    }, null);
    if (closedShiftId != null && mounted) {
      _offerCloseReceipt(closedShiftId!);
    }
  }

  void _offerCloseReceipt(int shiftId) {
    showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
                title: const Text('Turno cerrado'),
                content: const Text(
                    'El cierre quedó en el historial. Puedes abrir su comprobante PDF para imprimirlo o guardarlo.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Después')),
                  FilledButton.icon(
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        try {
                          final file = await _cash.saveCloseReceipt(shiftId);
                          await _cash.openSavedReceipt(file);
                        } catch (error) {
                          if (mounted) {
                            _message('No se pudo abrir el comprobante: $error',
                                error: true);
                          }
                        }
                      },
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Comprobante PDF')),
                ]));
  }

  Future<void> _run(Future<dynamic> Function() task, String? success) async {
    setState(() => _saving = true);
    try {
      final dynamic result = await task();
      if (mounted) {
        _message(
            result is String ? result : success ?? 'Operación completada.');
      }
      await _reload();
    } catch (error) {
      if (mounted) {
        _message('No se pudo completar la operación: $error', error: true);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: LoadingIndicator(message: 'Consultando estado de caja...'));
    }
    if (_loadError != null) {
      return Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
              child: Card(
                  child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.cloud_off_outlined,
                            size: 52, color: AppColors.danger),
                        const SizedBox(height: 12),
                        const Text('No se pudo consultar la caja',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(_loadError!, textAlign: TextAlign.center),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                            onPressed: _reload,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar')),
                      ])))));
    }
    if (_shift == null) {
      return Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
              child: Card(
                  child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.point_of_sale_outlined,
                            size: 52, color: AppColors.primary),
                        const SizedBox(height: 12),
                        const Text('Caja cerrada',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text(
                            'Abre caja con el efectivo inicial de la gaveta para iniciar tu turno.'),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                            onPressed: _saving ? null : _openCashDialog,
                            icon: const Icon(Icons.lock_open),
                            label: const Text('Abrir caja')),
                      ])))));
    }
    final shift = _shift!;
    final incomes = shift.movements
        .where((m) => m.type == 'ingreso')
        .fold<double>(0, (total, m) => total + m.amount);
    final expenses = shift.movements
        .where((m) => m.type == 'egreso')
        .fold<double>(0, (total, m) => total + m.amount);
    return Scaffold(
        backgroundColor: AppColors.background,
        body: RefreshIndicator(
            onRefresh: _reload,
            child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('Caja Diaria y Cuadre de Caja',
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary)),
                              SizedBox(height: 4),
                              Text(
                                  'Gestión de turno operativo, ingresos, egresos y cuadre de efectivo comercial',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13))
                            ])),
                        IconButton(
                            onPressed: _saving ? null : _reload,
                            icon: const Icon(Icons.refresh))
                      ]),
                      const SizedBox(height: 16),
                      Card(
                          color: AppColors.primaryLight,
                          child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(children: [
                                const Icon(Icons.play_circle_outline,
                                    color: AppColors.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Text(
                                        'Continuar turno • abierto ${shift.openedAt} • fondo inicial ${Formatters.formatCurrency(shift.openingFloat)}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary)))
                              ]))),
                      const SizedBox(height: 16),
                      LayoutBuilder(builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 900 ? 4 : 2;
                        return GridView.count(
                            crossAxisCount: columns,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: columns == 4 ? 1.7 : 1.45,
                            children: [
                              StatCard(
                                  title: 'Fondo Inicial',
                                  value: Formatters.formatCurrency(
                                      shift.openingFloat),
                                  subtitle: 'Apertura de turno',
                                  icon: Icons.account_balance_wallet_outlined,
                                  iconColor: AppColors.info),
                              StatCard(
                                  title: 'Ingresos de Caja',
                                  value: Formatters.formatCurrency(incomes),
                                  subtitle: 'Entradas de efectivo',
                                  icon: Icons.arrow_downward_rounded,
                                  iconColor: AppColors.success),
                              StatCard(
                                  title: 'Retiros / Egresos',
                                  value: Formatters.formatCurrency(expenses),
                                  subtitle: 'Salidas de efectivo',
                                  icon: Icons.arrow_upward_rounded,
                                  iconColor: AppColors.danger),
                              StatCard(
                                  title: 'Efectivo Esperado',
                                  value: Formatters.formatCurrency(
                                      shift.expectedBalance),
                                  subtitle: 'Cuadre en gaveta',
                                  icon: Icons.calculate_outlined,
                                  iconColor: AppColors.primary),
                              StatCard(
                                  title: 'Tarjeta',
                                  value: Formatters.formatCurrency(
                                      shift.paymentTotals['tarjeta'] ?? 0),
                                  subtitle: 'Cobros del turno',
                                  icon: Icons.credit_card_outlined,
                                  iconColor: AppColors.secondaryDark),
                              StatCard(
                                  title: 'Transferencia',
                                  value: Formatters.formatCurrency(
                                      shift.paymentTotals['transferencia'] ??
                                          0),
                                  subtitle: 'Cobros del turno',
                                  icon: Icons.account_balance_outlined,
                                  iconColor: AppColors.info),
                            ]);
                      }),
                      const SizedBox(height: 18),
                      Wrap(spacing: 12, runSpacing: 10, children: [
                        ElevatedButton.icon(
                            onPressed: _saving
                                ? null
                                : () => _movementDialog('ingreso'),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Registrar Ingreso')),
                        OutlinedButton.icon(
                            onPressed: _saving
                                ? null
                                : () => _movementDialog('egreso'),
                            icon: const Icon(Icons.remove, size: 18),
                            label: const Text('Registrar Retiro / Egreso')),
                        ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryDark),
                            onPressed: _saving ? null : _closeDialog,
                            icon: const Icon(Icons.lock_outline, size: 18),
                            label: const Text('Cuadre y Cierre de Turno'))
                      ]),
                      const SizedBox(height: 22),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Movimientos y Auditoría del Turno',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary)),
                              const Divider(),
                              if (shift.movements.isEmpty)
                                const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text('Aún no hay movimientos.')),
                              ...shift.movements.map((m) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                        backgroundColor: m.type == 'ingreso'
                                            ? AppColors.successLight
                                            : AppColors.dangerLight,
                                        child: Icon(
                                            m.type == 'ingreso'
                                                ? Icons.add
                                                : Icons.remove,
                                            color: m.type == 'ingreso'
                                                ? AppColors.success
                                                : AppColors.danger)),
                                    title: Text(m.concept),
                                    subtitle:
                                        Text('${m.origin} • ${m.createdAt}'),
                                    trailing: Text(
                                        '${m.type == 'ingreso' ? '+' : '-'} ${Formatters.formatCurrency(m.amount)}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: m.type == 'ingreso'
                                                ? AppColors.success
                                                : AppColors.danger)),
                                  )),
                            ],
                          ),
                        ),
                      ),
                      if (_isManager) ...[
                        const SizedBox(height: 22),
                        Card(
                            child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Historial de cierres',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary)),
                                      const Divider(),
                                      if (_history.isEmpty)
                                        const Padding(
                                            padding: EdgeInsets.all(12),
                                            child: Text(
                                                'No hay cierres registrados.')),
                                      ..._history.take(20).map((row) {
                                        final difference =
                                            (row['diferencia'] as num?)
                                                    ?.toDouble() ??
                                                0;
                                        return ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: Text(
                                                '${row['usuario_nombre'] ?? 'Cajero'} • ${row['abierto_en'] ?? ''}'),
                                            subtitle: Text(
                                                'Esperado ${Formatters.formatCurrency((row['monto_esperado'] as num?)?.toDouble() ?? 0)} • contado ${Formatters.formatCurrency((row['monto_contado'] as num?)?.toDouble() ?? 0)}'),
                                            trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                      difference == 0
                                                          ? 'Cuadrada'
                                                          : '${difference < 0 ? 'Faltante' : 'Sobrante'} ${Formatters.formatCurrency(difference.abs())}',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: difference == 0
                                                              ? AppColors
                                                                  .success
                                                              : AppColors
                                                                  .danger)),
                                                  if (row['estado'] ==
                                                      'cerrada')
                                                    IconButton(
                                                        tooltip:
                                                            'Comprobante PDF',
                                                        onPressed: () =>
                                                            _offerCloseReceipt(
                                                                row['id']
                                                                    as int),
                                                        icon: const Icon(
                                                            Icons
                                                                .picture_as_pdf_outlined,
                                                            size: 19))
                                                ]));
                                      })
                                    ])))
                      ],
                    ]))));
  }
}
