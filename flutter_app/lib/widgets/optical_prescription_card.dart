import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/prescription_model.dart';

class OpticalPrescriptionCard extends StatelessWidget {
  final PrescriptionModel prescription;
  final VoidCallback? onPrint;

  const OpticalPrescriptionCard({
    super.key,
    required this.prescription,
    this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.primary, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera Clínica
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.remove_red_eye_outlined,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Receta #${prescription.id}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Fecha: ${Formatters.formatDate(prescription.fechaReceta)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (prescription.profesional != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      prescription.profesional!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryDark,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Tabla Oftalmológica OD / OI
            Table(
              border: TableBorder.all(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(8),
              ),
              columnWidths: const {
                0: FlexColumnWidth(1.2), // Ojo
                1: FlexColumnWidth(1.5), // Esfera
                2: FlexColumnWidth(1.5), // Cilindro
                3: FlexColumnWidth(1.2), // Eje
              },
              children: [
                const TableRow(
                  decoration: BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  children: [
                    _TableHeaderCell('OJO'),
                    _TableHeaderCell('ESFERA'),
                    _TableHeaderCell('CILINDRO'),
                    _TableHeaderCell('EJE'),
                  ],
                ),
                TableRow(
                  children: [
                    const _TableCell('OD (Derecho)', isBold: true),
                    _TableCell(Formatters.formatDiopter(prescription.odEsfera)),
                    _TableCell(Formatters.formatDiopter(prescription.odCilindro)),
                    _TableCell(Formatters.formatAxis(prescription.odEje)),
                  ],
                ),
                TableRow(
                  children: [
                    const _TableCell('OI (Izquierdo)', isBold: true),
                    _TableCell(Formatters.formatDiopter(prescription.oiEsfera)),
                    _TableCell(Formatters.formatDiopter(prescription.oiCilindro)),
                    _TableCell(Formatters.formatAxis(prescription.oiEje)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Adición y Distancia Pupilar
            Row(
              children: [
                Expanded(
                  child: _MetricBadge(
                    label: 'Adición (ADD)',
                    value: Formatters.formatDiopter(prescription.adicion),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricBadge(
                    label: 'Distancia Pupilar (DP)',
                    value: Formatters.formatPd(prescription.distanciaPupilar),
                  ),
                ),
              ],
            ),

            if (prescription.diagnostico != null &&
                prescription.diagnostico!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Diagnóstico: ${prescription.diagnostico}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],

            if (prescription.observaciones != null &&
                prescription.observaciones!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Observaciones: ${prescription.observaciones}',
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String text;
  const _TableHeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final bool isBold;
  const _TableCell(this.text, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  final String label;
  final String value;

  const _MetricBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
