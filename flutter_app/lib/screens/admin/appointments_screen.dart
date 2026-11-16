import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/clinic_models.dart';
import '../../models/patient_model.dart';
import '../../services/admin_service.dart';
import '../../services/patient_service.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/loading_indicator.dart';

/// Contrato ISO-8601 con zona horaria exigido por FastAPI/PostgreSQL.
/// Se construye explícitamente porque DateTime local no añade el desplazamiento
/// al llamar a toIso8601String().
String appointmentDateTimeIso(DateTime date, TimeOfDay time) {
  final local =
      DateTime(date.year, date.month, date.day, time.hour, time.minute);
  final offset = local.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final absolute = offset.abs();
  final hours = absolute.inHours.toString().padLeft(2, '0');
  final minutes = (absolute.inMinutes % 60).toString().padLeft(2, '0');
  String two(int value) => value.toString().padLeft(2, '0');
  return '${local.year.toString().padLeft(4, '0')}-${two(local.month)}-${two(local.day)}'
      'T${two(local.hour)}:${two(local.minute)}:00$sign$hours:$minutes';
}

class AppointmentsScreen extends StatefulWidget {
  final AppState appState;

  const AppointmentsScreen({super.key, required this.appState});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final _adminService = AdminService();
  final _patientService = PatientService();

  List<AppointmentModel> _appointments = [];
  List<PatientModel> _patients = [];
  bool _loading = true;
  String? _error;
  String? _selectedEstado;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await _adminService.getAppointments(estado: _selectedEstado);
      final pts = await _patientService
          .getPatients()
          .catchError((_) => <PatientModel>[]);
      if (mounted) {
        setState(() {
          _appointments = list;
          _patients = pts;
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

  Future<void> _updateState(AppointmentModel app, String newState) async {
    try {
      await _adminService.updateAppointmentState(app.id, newState);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _openNewAppointmentDialog() async {
    PatientModel? selectedPatient;
    Map<String, String>? pendingNewClient;
    final formKey = GlobalKey<FormState>();
    var selectedDate = DateTime.now();
    var selectedTime = const TimeOfDay(hour: 10, minute: 0);
    final dateCtrl = TextEditingController(text: _formatDate(selectedDate));
    final timeCtrl = TextEditingController(text: _formatTime(selectedTime));
    final motivoCtrl =
        TextEditingController(text: 'Examen de la vista completo');
    final profesionalCtrl =
        TextEditingController(text: 'Dr. Alejandro Peña (Optometrista)');
    final observacionesCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Agendar Nueva Consulta'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.person_add_alt_1, size: 18),
                        label: const Text('Nuevo cliente y paciente'),
                        onPressed: () async {
                          final created = await _openQuickPatientDialog();
                          if (created != null) {
                            setDlgState(() {
                              pendingNewClient = created;
                              selectedPatient = null;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (pendingNewClient != null)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.person_add_alt_1,
                            color: AppColors.primary),
                        title: Text(
                            '${pendingNewClient!['nombres']} ${pendingNewClient!['apellidos'] ?? ''}'
                                .trim()),
                        subtitle: const Text(
                            'Cliente nuevo: se guardará al confirmar la cita.'),
                      ),
                    if (_patients.isNotEmpty)
                      DropdownButtonFormField<PatientModel>(
                        initialValue: selectedPatient,
                        decoration:
                            const InputDecoration(labelText: 'Paciente *'),
                        items: _patients
                            .map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(p.nombreCompleto,
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (val) => setDlgState(() {
                          selectedPatient = val;
                          pendingNewClient = null;
                        }),
                        validator: (value) => value == null &&
                                pendingNewClient == null
                            ? 'Selecciona un paciente o crea uno para esta cita.'
                            : null,
                      )
                    else
                      const Text(
                        'No hay pacientes registrados. Crea un paciente primero.',
                        style: TextStyle(color: AppColors.danger),
                      ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final dateField = TextFormField(
                          controller: dateCtrl,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Fecha *',
                            suffixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now()
                                  .subtract(const Duration(days: 1)),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 730)),
                            );
                            if (picked != null) {
                              setDlgState(() {
                                selectedDate = picked;
                                dateCtrl.text = _formatDate(picked);
                              });
                            }
                          },
                          validator: (value) => value == null || value.isEmpty
                              ? 'Indica la fecha.'
                              : null,
                        );
                        final timeField = TextFormField(
                          controller: timeCtrl,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Hora *',
                            suffixIcon: Icon(Icons.access_time_outlined),
                          ),
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (picked != null) {
                              setDlgState(() {
                                selectedTime = picked;
                                timeCtrl.text = _formatTime(picked);
                              });
                            }
                          },
                          validator: (value) => value == null || value.isEmpty
                              ? 'Indica la hora.'
                              : null,
                        );
                        if (constraints.maxWidth < 390) {
                          return Column(children: [
                            dateField,
                            const SizedBox(height: 12),
                            timeField
                          ]);
                        }
                        return Row(
                          children: [
                            Expanded(child: dateField),
                            const SizedBox(width: 12),
                            Expanded(child: timeField),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: motivoCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Motivo de Consulta *'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Indica el motivo de la consulta.'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: profesionalCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Profesional Asignado'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: observacionesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                          labelText: 'Observaciones (opcional)'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: selectedPatient == null && pendingNewClient == null
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      final fechaHoraIso =
                          appointmentDateTimeIso(selectedDate, selectedTime);
                      final repeated = selectedPatient != null &&
                          _appointments.any(
                            (appointment) =>
                                appointment.pacienteId == selectedPatient!.id &&
                                appointment.fechaHora
                                    .startsWith(fechaHoraIso.substring(0, 16)),
                          );
                      if (repeated) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Ese paciente ya tiene una cita en la fecha y hora seleccionadas.'),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                        return;
                      }
                      try {
                        if (pendingNewClient != null) {
                          await _adminService.createAppointmentWithNewClient(
                            nombres: pendingNewClient!['nombres']!,
                            apellidos: pendingNewClient!['apellidos'],
                            telefono: pendingNewClient!['telefono'],
                            correo: pendingNewClient!['correo'],
                            fechaHora: fechaHoraIso,
                            motivo: motivoCtrl.text.trim(),
                            profesional: profesionalCtrl.text.trim(),
                            observaciones: observacionesCtrl.text.trim(),
                          );
                        } else {
                          await _adminService.createAppointment(
                              pacienteId: selectedPatient!.id,
                              fechaHora: fechaHoraIso,
                              motivo: motivoCtrl.text.trim(),
                              profesional: profesionalCtrl.text.trim(),
                              observaciones: observacionesCtrl.text.trim());
                        }
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        _loadData();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppColors.danger),
                          );
                        }
                      }
                    },
              child: const Text('Agendar Cita'),
            ),
          ],
        ),
      ),
    );
    dateCtrl.dispose();
    timeCtrl.dispose();
    motivoCtrl.dispose();
    profesionalCtrl.dispose();
    observacionesCtrl.dispose();
  }

  /// Alta breve desde la agenda: el cliente y su ficha de paciente se crean
  /// juntos para que la primera cita no requiera navegar a otra pantalla.
  Future<Map<String, String>?> _openQuickPatientDialog() async {
    final formKey = GlobalKey<FormState>();
    final nombres = TextEditingController();
    final apellidos = TextEditingController();
    final telefono = TextEditingController();
    final correo = TextEditingController();
    final patient = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nuevo cliente y paciente'),
          content: SizedBox(
            width: 430,
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(
                  controller: nombres,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Nombres *'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Indica el nombre del cliente.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextField(
                    controller: apellidos,
                    decoration: const InputDecoration(labelText: 'Apellidos')),
                const SizedBox(height: 12),
                TextField(
                    controller: telefono,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                        labelText: 'Teléfono / WhatsApp')),
                const SizedBox(height: 12),
                TextField(
                    controller: correo,
                    keyboardType: TextInputType.emailAddress,
                    decoration:
                        const InputDecoration(labelText: 'Correo electrónico')),
              ]),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx, {
                  'nombres': nombres.text.trim(),
                  'apellidos': apellidos.text.trim(),
                  'telefono': telefono.text.trim(),
                  'correo': correo.text.trim()
                });
              },
              child: const Text('Usar en esta cita'),
            ),
          ],
        ),
      ),
    );
    nombres.dispose();
    apellidos.dispose();
    telefono.dispose();
    correo.dispose();
    return patient;
  }

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  static String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clientes y Citas',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Agenda de citas y registro de clientes durante el agendamiento',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  OutlinedButton.icon(
                      onPressed: () =>
                          widget.appState.setActiveSection(AppSection.patients),
                      icon: const Icon(Icons.description_outlined, size: 18),
                      label: const Text('Expedientes y recetas')),
                  ElevatedButton.icon(
                      onPressed: _openNewAppointmentDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Agendar cita')),
                ]),
              ],
            ),
            const SizedBox(height: 16),

            // Filtros de Estado
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilterChip(
                  selected: _selectedEstado == null,
                  label: const Text('Todas'),
                  onSelected: (_) {
                    setState(() => _selectedEstado = null);
                    _loadData();
                  },
                ),
                FilterChip(
                  selected: _selectedEstado == 'pendiente',
                  label: const Text('Pendientes'),
                  selectedColor: AppColors.warningLight,
                  onSelected: (_) {
                    setState(() => _selectedEstado = 'pendiente');
                    _loadData();
                  },
                ),
                FilterChip(
                  selected: _selectedEstado == 'confirmada',
                  label: const Text('Confirmadas'),
                  selectedColor: AppColors.infoLight,
                  onSelected: (_) {
                    setState(() => _selectedEstado = 'confirmada');
                    _loadData();
                  },
                ),
                FilterChip(
                  selected: _selectedEstado == 'completada',
                  label: const Text('Completadas'),
                  selectedColor: AppColors.successLight,
                  onSelected: (_) {
                    setState(() => _selectedEstado = 'completada');
                    _loadData();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadData,
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_error != null)
              ErrorBanner(message: _error!, onRetry: _loadData),

            Expanded(
              child: _loading
                  ? const LoadingIndicator(
                      message: 'Cargando agenda optométrica...')
                  : _appointments.isEmpty
                      ? EmptyState(
                          icon: Icons.calendar_month_outlined,
                          title: 'Sin citas programadas',
                          message: 'Agenda consultas para tus pacientes.',
                          buttonText: 'Crear Primera Cita',
                          onAction: _openNewAppointmentDialog,
                        )
                      : Card(
                          child: ListView.separated(
                            itemCount: _appointments.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (ctx, index) {
                              final app = _appointments[index];
                              final isCompleted = app.estado == 'completada';
                              final isCancelled = app.estado == 'cancelada';

                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? AppColors.successLight
                                        : (isCancelled
                                            ? AppColors.dangerLight
                                            : AppColors.primaryLight),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.access_time_rounded,
                                    color: isCompleted
                                        ? AppColors.success
                                        : (isCancelled
                                            ? AppColors.danger
                                            : AppColors.primary),
                                  ),
                                ),
                                title: Text(
                                  '${app.pacienteNombre ?? "Paciente #${app.pacienteId}"} — ${app.fechaHora.replaceAll("T", " ")}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                                subtitle: Text(
                                  'Motivo: ${app.motivo}\nAtiende: ${app.profesional ?? "Optometrista de turno"} • Tel: ${app.telefono ?? "N/A"}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Chip(
                                      label: Text(app.estado.toUpperCase()),
                                      backgroundColor: isCompleted
                                          ? AppColors.successLight
                                          : (isCancelled
                                              ? AppColors.dangerLight
                                              : AppColors.infoLight),
                                      labelStyle: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isCompleted
                                            ? const Color(0xFF065F46)
                                            : (isCancelled
                                                ? const Color(0xFF991B1B)
                                                : const Color(0xFF1E40AF)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    PopupMenuButton<String>(
                                      icon:
                                          const Icon(Icons.more_vert, size: 20),
                                      onSelected: (val) =>
                                          _updateState(app, val),
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                            value: 'confirmada',
                                            child: Text('Confirmar')),
                                        const PopupMenuItem(
                                            value: 'completada',
                                            child: Text('Marcar Completada')),
                                        const PopupMenuItem(
                                            value: 'no_asistio',
                                            child: Text('No Asistió')),
                                        const PopupMenuItem(
                                            value: 'cancelada',
                                            child: Text('Cancelar Cita')),
                                      ],
                                    ),
                                  ],
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
