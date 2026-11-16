import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/patient_model.dart';
import '../../services/patient_service.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/search_input.dart';
import 'patient_detail_screen.dart';

class PatientListScreen extends StatefulWidget {
  final AppState appState;

  const PatientListScreen({super.key, required this.appState});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final _patientService = PatientService();
  final _searchController = TextEditingController();

  List<PatientModel> _allPatients = [];
  List<PatientModel> _filteredPatients = [];
  PatientModel? _selectedPatient;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await _patientService.getPatients();
      if (mounted) {
        setState(() {
          _allPatients = list;
          _filteredPatients = list;
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

  void _onSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() => _filteredPatients = _allPatients);
      return;
    }

    final q = query.toLowerCase();
    setState(() {
      _filteredPatients = _allPatients.where((p) {
        final name = (p.nombreCompleto).toLowerCase();
        final tel = (p.telefono ?? '').toLowerCase();
        return name.contains(q) || tel.contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedPatient != null) {
      return PatientDetailScreen(
        patient: _selectedPatient!,
        onBack: () {
          setState(() => _selectedPatient = null);
          _loadPatients();
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Expedientes y recetas',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_allPatients.length} pacientes con expediente clínico',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () =>
                      widget.appState.setActiveSection(AppSection.appointments),
                  icon: const Icon(Icons.calendar_month_outlined, size: 18),
                  label: const Text('Volver a agenda'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Buscador
            Row(
              children: [
                Expanded(
                  child: SearchInput(
                    controller: _searchController,
                    hintText: 'Filtrar por nombre o teléfono de paciente...',
                    onChanged: _onSearch,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualizar lista',
                  onPressed: _loadPatients,
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_error != null)
              ErrorBanner(message: _error!, onRetry: _loadPatients),

            // Lista de Pacientes
            Expanded(
              child: _loading
                  ? const LoadingIndicator(message: 'Cargando pacientes...')
                  : _filteredPatients.isEmpty
                      ? EmptyState(
                          icon: Icons.medical_information_outlined,
                          title: 'Sin pacientes registrados',
                          message:
                              'Crea una cita y registra al cliente desde el mismo formulario para abrir el primer expediente.',
                          buttonText: 'Nueva cita y paciente',
                          onAction: () => widget.appState
                              .setActiveSection(AppSection.appointments),
                        )
                      : Card(
                          child: ListView.separated(
                            itemCount: _filteredPatients.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (ctx, index) {
                              final patient = _filteredPatients[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.secondary
                                      .withValues(alpha: 0.15),
                                  child: const Icon(
                                    Icons.remove_red_eye,
                                    color: AppColors.secondary,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  patient.nombreCompleto,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Text(
                                  'Tel: ${patient.telefono ?? "No registrado"} • Ficha #${patient.id}\n'
                                  'Alergias: ${patient.alergias ?? "Ninguna reportada"} • Registrado: ${Formatters.formatDate(patient.fechaRegistro)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                isThreeLine: true,
                                trailing: ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() => _selectedPatient = patient);
                                  },
                                  icon: const Icon(Icons.visibility_outlined,
                                      size: 16),
                                  label: const Text('Ver Recetas'),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
