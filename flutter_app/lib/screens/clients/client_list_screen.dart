import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/client_model.dart';
import '../../services/client_service.dart';
import '../../services/patient_service.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/search_input.dart';
import 'client_form_dialog.dart';

class ClientListScreen extends StatefulWidget {
  final AppState appState;

  const ClientListScreen({super.key, required this.appState});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  final _clientService = ClientService();
  final _patientService = PatientService();
  final _searchController = TextEditingController();

  List<ClientModel> _clients = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await _clientService.getClients();
      if (mounted) {
        setState(() {
          _clients = list;
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

  Future<void> _onSearch(String query) async {
    if (query.trim().isEmpty) {
      _loadClients();
      return;
    }

    setState(() => _loading = true);
    try {
      final results = await _clientService.searchClients(query.trim());
      if (mounted) {
        setState(() {
          _clients = results;
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

  void _openClientForm([ClientModel? client]) {
    showDialog(
      context: context,
      builder: (ctx) => ClientFormDialog(
        client: client,
        onSaved: _loadClients,
      ),
    );
  }

  Future<void> _createPatientFromClient(ClientModel client) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abrir Ficha de Paciente'),
        content: Text(
          '¿Deseas crear la ficha clínica para "${client.nombreCompleto}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Crear Paciente'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _patientService.createPatient(clienteId: client.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ficha de paciente creada para ${client.nombreCompleto}'),
              backgroundColor: AppColors.success,
            ),
          );
          widget.appState.setActiveSection(AppSection.patients);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      'Directorio de Clientes',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_clients.length} clientes registrados en el sistema',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _openClientForm(),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Nuevo Cliente'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Barra de Búsqueda
            Row(
              children: [
                Expanded(
                  child: SearchInput(
                    controller: _searchController,
                    hintText: 'Buscar por nombre, apellido o teléfono...',
                    onChanged: (val) {
                      if (val.isEmpty) _loadClients();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _onSearch(_searchController.text),
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Buscar'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Recargar lista',
                  onPressed: _loadClients,
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_error != null)
              ErrorBanner(message: _error!, onRetry: _loadClients),

            // Listado de Clientes
            Expanded(
              child: _loading
                  ? const LoadingIndicator(message: 'Cargando directorio de clientes...')
                  : _clients.isEmpty
                      ? EmptyState(
                          icon: Icons.people_outline,
                          title: 'No hay clientes registrados',
                          message:
                              'Agrega clientes para comenzar a emitir recetas y ventas.',
                          buttonText: 'Crear Primer Cliente',
                          onAction: () => _openClientForm(),
                        )
                      : Card(
                          child: ListView.separated(
                            itemCount: _clients.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (ctx, index) {
                              final client = _clients[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primaryLight,
                                  child: Text(
                                    client.nombres.isNotEmpty
                                        ? client.nombres.substring(0, 1).toUpperCase()
                                        : 'C',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  client.nombreCompleto,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Text(
                                  'Tel: ${client.telefono ?? "No registrado"} • Correo: ${client.correo ?? "Sin correo"}\nRegistro: ${Formatters.formatDate(client.fechaRegistro)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => _createPatientFromClient(client),
                                      icon: const Icon(Icons.medical_information_outlined, size: 16),
                                      label: const Text('Ficha Clínica', style: TextStyle(fontSize: 12)),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18),
                                      tooltip: 'Editar cliente',
                                      onPressed: () => _openClientForm(client),
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
