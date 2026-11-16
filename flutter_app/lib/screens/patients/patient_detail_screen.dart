import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/patient_model.dart';
import '../../models/prescription_model.dart';
import '../../services/prescription_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/optical_prescription_card.dart';
import 'prescription_form_dialog.dart';

class PatientDetailScreen extends StatefulWidget {
  final PatientModel patient;
  final VoidCallback onBack;

  const PatientDetailScreen({
    super.key,
    required this.patient,
    required this.onBack,
  });

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  final _prescriptionService = PrescriptionService();
  List<PrescriptionModel> _prescriptions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list =
          await _prescriptionService.getPrescriptionsByPatient(widget.patient.id);
      if (mounted) {
        setState(() {
          _prescriptions = list;
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

  void _openPrescriptionForm() {
    showDialog(
      context: context,
      builder: (ctx) => PrescriptionFormDialog(
        pacienteId: widget.patient.id,
        pacienteNombre: widget.patient.nombreCompleto,
        onSaved: _loadPrescriptions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: Text('Ficha Clínica: ${widget.patient.nombreCompleto}'),
        actions: [
          ElevatedButton.icon(
            onPressed: _openPrescriptionForm,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nueva Receta'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen de Datos Médicos del Paciente
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primaryLight,
                          child: Icon(Icons.person, color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.patient.nombreCompleto,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Tel: ${widget.patient.telefono ?? "No registrado"} • Ficha #${widget.patient.id}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Wrap(
                      spacing: 24,
                      runSpacing: 12,
                      children: [
                        if (widget.patient.antecedentes != null &&
                            widget.patient.antecedentes!.isNotEmpty)
                          _InfoPill(
                            icon: Icons.history,
                            label: 'Antecedentes',
                            value: widget.patient.antecedentes!,
                          ),
                        if (widget.patient.alergias != null &&
                            widget.patient.alergias!.isNotEmpty)
                          _InfoPill(
                            icon: Icons.warning_amber_rounded,
                            label: 'Alergias',
                            value: widget.patient.alergias!,
                            color: AppColors.danger,
                          ),
                        if (widget.patient.observaciones != null &&
                            widget.patient.observaciones!.isNotEmpty)
                          _InfoPill(
                            icon: Icons.notes_outlined,
                            label: 'Observaciones',
                            value: widget.patient.observaciones!,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Historial de Recetas Oftalmológicas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Historial de Graduaciones y Recetas',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${_prescriptions.length} recetas emitidas',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_error != null)
              ErrorBanner(message: _error!, onRetry: _loadPrescriptions),

            if (_loading)
              const LoadingIndicator(message: 'Cargando recetas oftalmológicas...')
            else if (_prescriptions.isEmpty)
              EmptyState(
                icon: Icons.remove_red_eye_outlined,
                title: 'Sin recetas registradas',
                message:
                    'Este paciente aún no tiene ninguna graduación oftalmológica guardada.',
                buttonText: 'Emitir Primera Receta',
                onAction: _openPrescriptionForm,
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _prescriptions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (ctx, index) {
                  return OpticalPrescriptionCard(
                    prescription: _prescriptions[index],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (color ?? AppColors.primary).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color ?? AppColors.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color ?? AppColors.primary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
