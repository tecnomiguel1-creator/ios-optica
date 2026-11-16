import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/user_management_service.dart';
import '../../services/business_profile_service.dart';
import '../../state/app_state.dart';

/// Ajustes organizados para el personal; la conexión local es automática.
class SettingsScreen extends StatefulWidget {
  final AppState appState;
  final int initialTab;

  const SettingsScreen(
      {super.key, required this.appState, this.initialTab = 0});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nombreOptica = TextEditingController(text: AppColors.companyName);
  final _eslogan = TextEditingController(text: AppColors.companySlogan);
  late final TextEditingController _rnc;
  late final TextEditingController _direccion;
  late final TextEditingController _telefono;
  late final TextEditingController _itbis;
  final _userService = UserManagementService();
  final _businessProfileService = BusinessProfileService();
  List<UserModel> _users = [];
  bool _loadingUsers = true;

  @override
  void initState() {
    super.initState();
    _rnc = TextEditingController(text: AppConfig.companyRnc);
    _direccion = TextEditingController(text: AppConfig.companyAddress);
    _telefono = TextEditingController(text: AppConfig.companyPhone);
    _itbis = TextEditingController(
        text: (AppConfig.itbisRate * 100).toStringAsFixed(2));
    _loadUsers();
  }

  @override
  void dispose() {
    _nombreOptica.dispose();
    _eslogan.dispose();
    _rnc.dispose();
    _direccion.dispose();
    _telefono.dispose();
    _itbis.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _userService.getUsers();
      if (mounted) setState(() => _users = users);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  void _message(String text, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(text),
          backgroundColor: error ? AppColors.danger : AppColors.success));

  Future<void> _saveItbis() async {
    final value = double.tryParse(_itbis.text.replaceAll(',', '.'));
    if (value == null || value < 0 || value > 100) {
      _message('Indica una tasa entre 0% y 100%.', error: true);
      return;
    }
    await AppConfig.saveItbisRate(value / 100);
    if (mounted) {
      _message('La tasa de ITBIS se aplicará a las próximas ventas.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: Padding(
            padding: const EdgeInsets.all(24),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_pageTitle,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(_pageSubtitle,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 18),
              Expanded(child: _currentPage()),
            ])),
      );

  Widget _scroll(Widget child) => SingleChildScrollView(
      padding: const EdgeInsets.only(top: 12, bottom: 24), child: child);

  String get _pageTitle => switch (widget.initialTab) {
        1 => 'Datos del negocio',
        2 => 'Seguros',
        _ => 'Administración',
      };

  String get _pageSubtitle => switch (widget.initialTab) {
        1 => 'Información comercial para recetas y facturas.',
        2 => 'Catálogo de aseguradoras disponibles en mostrador.',
        _ => 'Impuestos, usuarios y permisos del sistema.',
      };

  Widget _currentPage() => switch (widget.initialTab) {
        1 => _businessTab(),
        2 => _insuranceTab(),
        _ => _adminTab(),
      };

  Widget _adminTab() => _scroll(
      Column(children: [_taxCard(), const SizedBox(height: 20), _usersCard()]));

  Widget _taxCard() => Card(
      child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.percent_outlined, color: AppColors.primary),
              SizedBox(width: 10),
              Text('Impuestos de venta',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
            ]),
            const SizedBox(height: 12),
            const Text(
                'Esta tasa se calcula antes de cobrar y queda guardada para las próximas ventas.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                      width: 180,
                      child: TextField(
                          controller: _itbis,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                              labelText: 'ITBIS (%)', suffixText: '%'))),
                  ElevatedButton(
                      onPressed: _saveItbis, child: const Text('Guardar tasa')),
                ]),
          ])));

  Widget _usersCard() => Card(
      child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.people_outline, color: AppColors.primary),
              const SizedBox(width: 10),
              const Expanded(
                  child: Text('Usuarios y roles',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold))),
              OutlinedButton.icon(
                  onPressed: _showCreateUser,
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  label: const Text('Crear usuario')),
            ]),
            const SizedBox(height: 8),
            const Text(
                'Cada venta se registra automáticamente con el nombre de la cajera o vendedor que inició sesión.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 14),
            if (_loadingUsers)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator()))
            else if (_users.isEmpty)
              const Text(
                  'No se pudieron cargar los usuarios. Verifica tu sesión de administrador.',
                  style: TextStyle(color: AppColors.textSecondary))
            else
              ..._users.map((u) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                      backgroundColor: u.activo
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      child: Text(
                          u.nombre.isEmpty
                              ? '?'
                              : u.nombre.substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Colors.white))),
                  title: Text(u.nombre),
                  subtitle: Text(
                      '@${u.usuario} · ${_roleLabel(u.rol)}${u.activo ? '' : ' · Inactivo'}'))),
          ])));

  Widget _businessTab() => _scroll(Card(
      child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.storefront_outlined, color: AppColors.secondary),
              SizedBox(width: 10),
              Text('Datos Comerciales para Recetas y Facturas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
            ]),
            const SizedBox(height: 16),
            _two(
              TextField(
                  controller: _nombreOptica,
                  decoration: const InputDecoration(
                      labelText: 'Razón Social / Nombre Comercial')),
              TextField(
                  controller: _eslogan,
                  decoration:
                      const InputDecoration(labelText: 'Eslogan Corporativo')),
            ),
            const SizedBox(height: 12),
            _two(
              TextField(
                  controller: _rnc,
                  decoration: const InputDecoration(
                      labelText: 'RNC (Registro Nacional del Contribuyente)')),
              TextField(
                  controller: _telefono,
                  decoration:
                      const InputDecoration(labelText: 'Teléfono Principal')),
            ),
            const SizedBox(height: 12),
            TextField(
                controller: _direccion,
                decoration: const InputDecoration(
                    labelText: 'Dirección Comercial (República Dominicana)')),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: () async {
                  await AppConfig.saveBusinessProfile(
                      rnc: _rnc.text,
                      address: _direccion.text,
                      phone: _telefono.text);
                  await _businessProfileService.save(
                    nombreComercial: _nombreOptica.text,
                    eslogan: _eslogan.text,
                    rnc: _rnc.text,
                    direccion: _direccion.text,
                    telefono: _telefono.text,
                  );
                  if (mounted) {
                    _message(
                        'Datos comerciales configurados y guardados correctamente.');
                  }
                },
                child: const Text('Guardar Datos del Negocio')),
          ]))));

  Widget _two(Widget first, Widget second) => LayoutBuilder(
      builder: (_, box) => box.maxWidth < 650
          ? Column(children: [first, const SizedBox(height: 12), second])
          : Row(children: [
              Expanded(child: first),
              const SizedBox(width: 12),
              Expanded(child: second)
            ]));

  Widget _insuranceTab() => _scroll(Card(
      child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.health_and_safety_outlined, color: AppColors.primary),
              SizedBox(width: 10),
              Text('Catálogo de Aseguradoras (ARS Dominicanas)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
            ]),
            const SizedBox(height: 8),
            const Text(
                'Aseguradoras disponibles en mostrador. El catálogo se sincronizará con el backend cuando se active el módulo ARS.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConfig.arsList
                    .map((ars) => Chip(
                        label: Text(ars, style: const TextStyle(fontSize: 12)),
                        backgroundColor: AppColors.background,
                        side: const BorderSide(color: AppColors.border),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () async {
                          final updated = List<String>.from(AppConfig.arsList)
                            ..remove(ars);
                          await AppConfig.saveArsList(updated);
                          if (mounted) setState(() {});
                        }))
                    .toList()),
            const SizedBox(height: 16),
            OutlinedButton.icon(
                onPressed: _showAddInsurance,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Agregar Aseguradora al Catálogo')),
          ]))));

  String _roleLabel(String role) => switch (role) {
        'administrador' || 'admin' => 'Administrador',
        'cajero' => 'Cajero/a',
        'gerente' => 'Gerente',
        'supervisor' => 'Supervisor',
        _ => role
      };

  void _showAddInsurance() {
    final controller = TextEditingController();
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Nueva Aseguradora ARS'),
                content: TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                        labelText: 'Nombre de la ARS',
                        hintText: 'Ej. ARS Futuro')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar')),
                  ElevatedButton(
                      onPressed: () async {
                        final value = controller.text.trim();
                        if (value.isNotEmpty &&
                            !AppConfig.arsList.contains(value)) {
                          await AppConfig.saveArsList(
                              List<String>.from(AppConfig.arsList)..add(value));
                          if (mounted) setState(() {});
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Agregar')),
                ]));
  }

  void _showCreateUser() {
    final key = GlobalKey<FormState>();
    final name = TextEditingController();
    final username = TextEditingController();
    final password = TextEditingController();
    var role = 'cajero';
    var saving = false;
    showDialog(
        context: context,
        builder: (dialog) => StatefulBuilder(
            builder: (ctx, dialogSet) => AlertDialog(
                    title: const Text('Crear usuario'),
                    content: SizedBox(
                        width: 420,
                        child: Form(
                            key: key,
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextFormField(
                                      controller: name,
                                      autofocus: true,
                                      decoration: const InputDecoration(
                                          labelText: 'Nombre completo'),
                                      validator: (v) => (v ?? '')
                                                  .trim()
                                                  .length <
                                              2
                                          ? 'Indica el nombre de la persona.'
                                          : null),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                      controller: username,
                                      decoration: const InputDecoration(
                                          labelText: 'Usuario'),
                                      validator: (v) => RegExp(
                                                  r'^[A-Za-z0-9._-]{3,}$')
                                              .hasMatch((v ?? '').trim())
                                          ? null
                                          : 'Usa al menos 3 letras, números, punto, guion o guion bajo.'),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                      controller: password,
                                      obscureText: true,
                                      decoration: const InputDecoration(
                                          labelText: 'Contraseña'),
                                      validator: (v) => (v ?? '').length < 4
                                          ? 'Usa al menos 4 caracteres.'
                                          : null),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                      initialValue: role,
                                      decoration: const InputDecoration(
                                          labelText: 'Rol'),
                                      items: const [
                                        DropdownMenuItem(
                                            value: 'cajero',
                                            child: Text('Cajero/a')),
                                        DropdownMenuItem(
                                            value: 'administrador',
                                            child: Text('Administrador')),
                                        DropdownMenuItem(
                                            value: 'gerente',
                                            child: Text('Gerente')),
                                        DropdownMenuItem(
                                            value: 'supervisor',
                                            child: Text('Supervisor'))
                                      ],
                                      onChanged: (v) => dialogSet(
                                          () => role = v ?? 'cajero')),
                                ]))),
                    actions: [
                      TextButton(
                          onPressed:
                              saving ? null : () => Navigator.pop(dialog),
                          child: const Text('Cancelar')),
                      ElevatedButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  if (!key.currentState!.validate()) return;
                                  dialogSet(() => saving = true);
                                  try {
                                    await _userService.createUser(
                                        nombre: name.text.trim(),
                                        usuario: username.text.trim(),
                                        contrasena: password.text,
                                        rol: role);
                                    if (dialog.mounted) Navigator.pop(dialog);
                                    if (mounted) {
                                      _message('Usuario creado correctamente.');
                                      setState(() => _loadingUsers = true);
                                      await _loadUsers();
                                    }
                                  } catch (_) {
                                    if (mounted) {
                                      _message(
                                          'No se pudo crear el usuario. Revisa que el usuario no esté repetido.',
                                          error: true);
                                    }
                                    dialogSet(() => saving = false);
                                  }
                                },
                          child: saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Crear usuario')),
                    ])));
  }
}
