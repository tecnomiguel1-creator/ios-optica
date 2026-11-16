import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';

/// Componente ejecutivo de presentación para Cobertura de Seguro Médico (ARS).
///
/// Diseñado para ópticas de República Dominicana.
/// Desacoplado de la lógica de persistencia: no simula pagos ficticios ni altera
/// las transacciones hasta que Codex active los endpoints en FastAPI.
class InsuranceCoverageCard extends StatefulWidget {
  final double totalVenta;
  final double pagosRealizados;
  final ValueChanged<double> onMontoAutorizadoChanged;
  final ValueChanged<String?> onArsChanged;
  final ValueChanged<String?> onNumeroAutorizacionChanged;

  const InsuranceCoverageCard({
    super.key,
    required this.totalVenta,
    this.pagosRealizados = 0.0,
    required this.onMontoAutorizadoChanged,
    required this.onArsChanged,
    required this.onNumeroAutorizacionChanged,
  });

  @override
  State<InsuranceCoverageCard> createState() => _InsuranceCoverageCardState();
}

class _InsuranceCoverageCardState extends State<InsuranceCoverageCard> {
  bool _activo = false;
  String? _selectedArs;
  final _autorizacionController = TextEditingController();
  final _montoAutorizadoController = TextEditingController();

  // Catálogo privado dominicano de referencia configurable (excluye SeNaSa y regímenes subsidiados)
  List<String> get _arsDominicanas => AppConfig.arsList;

  @override
  void dispose() {
    _autorizacionController.dispose();
    _montoAutorizadoController.dispose();
    super.dispose();
  }

  double get _montoAutorizado {
    if (!_activo) return 0.0;
    return double.tryParse(
          _montoAutorizadoController.text.trim().replaceAll(',', '.'),
        ) ??
        0.0;
  }

  double get _diferenciaCliente {
    final diff = widget.totalVenta - _montoAutorizado;
    return diff > 0 ? diff : 0.0;
  }

  double get _balancePendiente {
    final bal = _diferenciaCliente - widget.pagosRealizados;
    return bal > 0 ? bal : 0.0;
  }

  void _onToggleActivo(bool value) {
    setState(() {
      _activo = value;
      if (!_activo) {
        _selectedArs = null;
        _autorizacionController.clear();
        _montoAutorizadoController.clear();
        widget.onMontoAutorizadoChanged(0.0);
        widget.onArsChanged(null);
        widget.onNumeroAutorizacionChanged(null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: _activo ? AppColors.secondary : AppColors.border,
          width: _activo ? 1.4 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera con switch de activación adaptable
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _activo ? AppColors.secondaryLight : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.health_and_safety_outlined,
                          color: _activo ? AppColors.secondaryDark : AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cobertura de seguro médico',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _activo
                                  ? 'Seguro privado dominicano aplicado'
                                  : 'Toca para aplicar autorización de ARS',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _activo,
                  activeThumbColor: AppColors.secondary,
                  onChanged: _onToggleActivo,
                ),
              ],
            ),

            if (_activo) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Banner de Aclaración de Cobertura y Dependencia de Backend
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_outlined, size: 16, color: AppColors.warningDark),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pre-visualización de cobertura: Las aseguradoras mostradas son configurables y de referencia, no representan coberturas garantizadas. Este monto no se descuenta de la venta real hasta que Codex implemente y valide el módulo formal de ARS en FastAPI/PostgreSQL.',
                        style: TextStyle(fontSize: 11, color: AppColors.warningDark, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Selector Desplegable de ARS / Aseguradora
              DropdownButtonFormField<String>(
                initialValue: _selectedArs,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Aseguradora / ARS privada *',
                  hintText: 'Selecciona la ARS del paciente',
                  prefixIcon: Icon(Icons.business_outlined, size: 18),
                ),
                items: [
                  ..._arsDominicanas.map((ars) {
                    return DropdownMenuItem<String>(
                      value: ars,
                      child: Text(ars, style: const TextStyle(fontSize: 13)),
                    );
                  }),
                  const DropdownMenuItem<String>(
                    value: 'Otra Aseguradora / ARS',
                    child: Text('Otra Aseguradora / ARS privada...', style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                  ),
                ],
                onChanged: (val) {
                  setState(() => _selectedArs = val);
                  widget.onArsChanged(val);
                },
              ),
              const SizedBox(height: 12),

              // Fila con Número de Autorización y Monto Autorizado
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 420;
                  final authField = TextFormField(
                    controller: _autorizacionController,
                    decoration: const InputDecoration(
                      labelText: 'Número de autorización',
                      hintText: 'Ej. AUT-984210',
                      prefixIcon: Icon(Icons.verified_outlined, size: 18),
                    ),
                    onChanged: (val) => widget.onNumeroAutorizacionChanged(val.trim()),
                  );

                  final amountField = TextFormField(
                    controller: _montoAutorizadoController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Monto autorizado por la ARS *',
                      hintText: '0.00',
                      prefixText: 'RD\$ ',
                      prefixIcon: Icon(Icons.payments_outlined, size: 18),
                    ),
                    onChanged: (val) {
                      setState(() {});
                      final parsed = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
                      widget.onMontoAutorizadoChanged(parsed);
                    },
                  );

                  if (isCompact) {
                    return Column(
                      children: [
                        authField,
                        const SizedBox(height: 12),
                        amountField,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: authField),
                      const SizedBox(width: 12),
                      Expanded(child: amountField),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // Resumen Financiero de Cobertura
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _financialRow('Total de la venta:', Formatters.formatCurrency(widget.totalVenta)),
                    const SizedBox(height: 6),
                    _financialRow(
                      'Cobertura autorizada (ARS):',
                      Formatters.formatCurrency(_montoAutorizado),
                      valueColor: AppColors.secondaryDark,
                      isBold: true,
                    ),
                    const Divider(height: 16),
                    _financialRow(
                      'Diferencia a pagar por el cliente:',
                      Formatters.formatCurrency(_diferenciaCliente),
                      valueColor: AppColors.primary,
                      isBold: true,
                    ),
                    if (widget.pagosRealizados > 0) ...[
                      const SizedBox(height: 6),
                      _financialRow('Pagos realizados por el cliente:', Formatters.formatCurrency(widget.pagosRealizados)),
                      const SizedBox(height: 6),
                      _financialRow(
                        'Balance pendiente:',
                        Formatters.formatCurrency(_balancePendiente),
                        valueColor: _balancePendiente > 0 ? AppColors.danger : AppColors.success,
                        isBold: true,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'El monto autorizado genera una cuenta por cobrar a la ARS y reduce la obligación directa del cliente.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _financialRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          textAlign: TextAlign.end,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
