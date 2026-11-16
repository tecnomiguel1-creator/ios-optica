import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../state/app_state.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/error_banner.dart';

class LoginScreen extends StatefulWidget {
  final AppState appState;

  const LoginScreen({super.key, required this.appState});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.appState.login(
        _userController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // Disponible para una futura sección autenticada de soporte; no se expone
  // en el login de personal para evitar cambiar el servidor por accidente.
  // ignore: unused_element
  void _showServerSettingsDialog() {
    final urlController = TextEditingController(text: AppConfig.baseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configuración del Servidor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dirección IP o URL del backend FastAPI:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'URL del Backend',
                hintText: 'http://127.0.0.1:8000',
                prefixIcon: Icon(Icons.dns_outlined),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Windows local: http://127.0.0.1:8000\n• Emulador Android: http://10.0.2.2:8000\n• Red Local Wi-Fi: http://IP_DEL_SERVIDOR:8000',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.appState.updateBackendUrl(urlController.text.trim());
              Navigator.of(ctx).pop();
            },
            child: const Text('Guardar y Probar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A192F), Color(0xFF0F4C81)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: BoxConstraints(maxWidth: isDesktop ? 460 : 380),
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo y Branding Ejecutivo Oficial
                        const Center(
                          child: BrandLogo(width: 240, height: 130),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          AppColors.companyName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          AppColors.companySlogan,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                            color: AppColors.secondaryDark,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Estado de conexión con el Backend
                        InkWell(
                          onTap: () => widget.appState.checkBackendConnection(),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: widget.appState.isBackendConnected
                                  ? AppColors.successLight
                                  : AppColors.warningLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: widget.appState.isBackendConnected
                                    ? AppColors.success.withValues(alpha: 0.3)
                                    : AppColors.warning.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  widget.appState.isBackendConnected
                                      ? Icons.check_circle_rounded
                                      : Icons.cloud_off_rounded,
                                  size: 16,
                                  color: widget.appState.isBackendConnected
                                      ? AppColors.success
                                      : AppColors.warning,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.appState.isBackendConnected
                                        ? 'Listo para entrar'
                                        : (widget.appState.connectionError ??
                                            'Iniciando servidor local...'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: widget.appState.isBackendConnected
                                          ? const Color(0xFF065F46)
                                          : const Color(0xFF92400E),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.refresh,
                                    size: 14, color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (_errorMessage != null)
                          ErrorBanner(
                            message: _errorMessage!,
                            onRetry: _handleLogin,
                          ),

                        // Campo Usuario
                        TextFormField(
                          controller: _userController,
                          decoration: const InputDecoration(
                            labelText: 'Usuario',
                            hintText: 'Ingresa tu usuario',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor ingresa tu usuario.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Campo Contraseña
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa tu contraseña.';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _handleLogin(),
                        ),
                        const SizedBox(height: 24),

                        // Botón Ingresar
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Iniciar Sesión',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
