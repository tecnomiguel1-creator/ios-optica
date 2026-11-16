import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/prescription_model.dart';
import '../../services/prescription_service.dart';
import '../../widgets/error_banner.dart';

class PrescriptionFormDialog extends StatefulWidget {
  final int pacienteId;
  final String pacienteNombre;
  final VoidCallback onSaved;

  const PrescriptionFormDialog({
    super.key,
    required this.pacienteId,
    required this.pacienteNombre,
    required this.onSaved,
  });

  @override
  State<PrescriptionFormDialog> createState() => _PrescriptionFormDialogState();
}

class _PrescriptionFormDialogState extends State<PrescriptionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _prescriptionService = PrescriptionService();

  // OD
  final _odEsferaController = TextEditingController();
  final _odCilindroController = TextEditingController();
  final _odEjeController = TextEditingController();

  // OI
  final _oiEsferaController = TextEditingController();
  final _oiCilindroController = TextEditingController();
  final _oiEjeController = TextEditingController();

  // Adición, DP, Diagnóstico, Médico
  final _adicionController = TextEditingController();
  final _dpController = TextEditingController();
  final _diagnosticoController = TextEditingController();
  final _observacionesController = TextEditingController();
  final _profesionalController = TextEditingController(text: 'Dr. Alejandro Peña (Optometrista)');

  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _odEsferaController.dispose();
    _odCilindroController.dispose();
    _odEjeController.dispose();
    _oiEsferaController.dispose();
    _oiCilindroController.dispose();
    _oiEjeController.dispose();
    _adicionController.dispose();
    _dpController.dispose();
    _diagnosticoController.dispose();
    _observacionesController.dispose();
    _profesionalController.dispose();
    super.dispose();
  }

  double? _parseDouble(String text) {
    if (text.trim().isEmpty) return null;
    return double.tryParse(text.trim().replaceAll(',', '.'));
  }

  int? _parseInt(String text) {
    if (text.trim().isEmpty) return null;
    return int.tryParse(text.trim());
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final model = PrescriptionModel(
        id: 0,
        pacienteId: widget.pacienteId,
        fechaReceta: DateTime.now().toIso8601String().substring(0, 10),
        odEsfera: _parseDouble(_odEsferaController.text),
        odCilindro: _parseDouble(_odCilindroController.text),
        odEje: _parseInt(_odEjeController.text),
        oiEsfera: _parseDouble(_oiEsferaController.text),
        oiCilindro: _parseDouble(_oiCilindroController.text),
        oiEje: _parseInt(_oiEjeController.text),
        adicion: _parseDouble(_adicionController.text),
        distanciaPupilar: _parseDouble(_dpController.text),
        diagnostico: _diagnosticoController.text.trim().isNotEmpty
            ? _diagnosticoController.text.trim()
            : null,
        observaciones: _observacionesController.text.trim().isNotEmpty
            ? _observacionesController.text.trim()
            : null,
        profesional: _profesionalController.text.trim().isNotEmpty
            ? _profesionalController.text.trim()
            : null,
      );

      await _prescriptionService.createPrescription(model);
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.remove_red_eye_outlined, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Emitir Receta: ${widget.pacienteNombre}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null) ErrorBanner(message: _error!),

                // Profesional
                TextFormField(
                  controller: _profesionalController,
                  decoration: const InputDecoration(
                    labelText: 'Profesional Optometrista / Oftalmólogo',
                    prefixIcon: Icon(Icons.badge_outlined, size: 18),
                  ),
                ),
                const SizedBox(height: 16),

                // Graduación OD
                const Text(
                  'OJO DERECHO (OD)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _odEsferaController,
                        decoration: const InputDecoration(
                          labelText: 'Esfera (OD)',
                          hintText: '+1.50 / -2.00',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            signed: true, decimal: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _odCilindroController,
                        decoration: const InputDecoration(
                          labelText: 'Cilindro (OD)',
                          hintText: '-0.75',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            signed: true, decimal: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _odEjeController,
                        decoration: const InputDecoration(
                          labelText: 'Eje (0°-180°)',
                          hintText: '90',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Graduación OI
                const Text(
                  'OJO IZQUIERDO (OI)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _oiEsferaController,
                        decoration: const InputDecoration(
                          labelText: 'Esfera (OI)',
                          hintText: '+1.25 / -1.75',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            signed: true, decimal: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _oiCilindroController,
                        decoration: const InputDecoration(
                          labelText: 'Cilindro (OI)',
                          hintText: '-0.50',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            signed: true, decimal: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _oiEjeController,
                        decoration: const InputDecoration(
                          labelText: 'Eje (0°-180°)',
                          hintText: '180',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Adición y DP
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _adicionController,
                        decoration: const InputDecoration(
                          labelText: 'Adición (ADD)',
                          hintText: '+2.00',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            signed: true, decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _dpController,
                        decoration: const InputDecoration(
                          labelText: 'Distancia Pupilar (mm)',
                          hintText: '62',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Diagnóstico y Observaciones
                TextFormField(
                  controller: _diagnosticoController,
                  decoration: const InputDecoration(
                    labelText: 'Diagnóstico Clínico',
                    hintText: 'Miopía simple, astigmatismo miópico, presbicia...',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _observacionesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Recomendaciones y Observaciones',
                    hintText: 'Uso de filtro BlueBlock para pantallas, lentes progresivos...',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Guardar Receta'),
        ),
      ],
    );
  }
}
