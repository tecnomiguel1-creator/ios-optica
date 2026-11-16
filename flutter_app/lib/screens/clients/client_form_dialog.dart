import 'package:flutter/material.dart';
import '../../models/client_model.dart';
import '../../services/client_service.dart';
import '../../widgets/error_banner.dart';

class ClientFormDialog extends StatefulWidget {
  final ClientModel? client;
  final VoidCallback onSaved;

  const ClientFormDialog({super.key, this.client, required this.onSaved});

  @override
  State<ClientFormDialog> createState() => _ClientFormDialogState();
}

class _ClientFormDialogState extends State<ClientFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _clientService = ClientService();

  late TextEditingController _nombresController;
  late TextEditingController _apellidosController;
  late TextEditingController _telefonoController;
  late TextEditingController _correoController;
  late TextEditingController _direccionController;

  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nombresController = TextEditingController(text: widget.client?.nombres ?? '');
    _apellidosController = TextEditingController(text: widget.client?.apellidos ?? '');
    _telefonoController = TextEditingController(text: widget.client?.telefono ?? '');
    _correoController = TextEditingController(text: widget.client?.correo ?? '');
    _direccionController = TextEditingController(text: widget.client?.direccion ?? '');
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      if (widget.client == null) {
        // Crear cliente en /api/clientes
        await _clientService.createClient(
          nombres: _nombresController.text.trim(),
          apellidos: _apellidosController.text.trim(),
          telefono: _telefonoController.text.trim(),
          correo: _correoController.text.trim(),
          direccion: _direccionController.text.trim(),
        );
      } else {
        // Actualizar cliente en /api/clientes/{id}
        await _clientService.updateClient(
          widget.client!.id,
          nombres: _nombresController.text.trim(),
          apellidos: _apellidosController.text.trim(),
          telefono: _telefonoController.text.trim(),
          correo: _correoController.text.trim(),
          direccion: _direccionController.text.trim(),
        );
      }
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
    final isEditing = widget.client != null;

    return AlertDialog(
      title: Row(
        children: [
          Icon(isEditing ? Icons.edit_outlined : Icons.person_add_outlined),
          const SizedBox(width: 10),
          Text(isEditing ? 'Editar Cliente' : 'Nuevo Cliente'),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error != null) ErrorBanner(message: _error!),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nombresController,
                        decoration: const InputDecoration(labelText: 'Nombres *'),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _apellidosController,
                        decoration: const InputDecoration(labelText: 'Apellidos'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _telefonoController,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono / WhatsApp',
                          prefixIcon: Icon(Icons.phone_outlined, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _correoController,
                        decoration: const InputDecoration(
                          labelText: 'Correo Electrónico',
                          prefixIcon: Icon(Icons.email_outlined, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _direccionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Dirección física',
                    prefixIcon: Icon(Icons.location_on_outlined, size: 18),
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
              : Text(isEditing ? 'Actualizar' : 'Registrar'),
        ),
      ],
    );
  }
}
