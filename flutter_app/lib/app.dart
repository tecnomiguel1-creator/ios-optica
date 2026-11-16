import 'package:flutter/material.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'screens/admin/appointments_screen.dart';
import 'screens/admin/cash_register_screen.dart';
import 'screens/admin/lab_orders_screen.dart';
import 'screens/admin/settings_screen.dart';
import 'screens/admin/reports_dashboard_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/inventory/product_list_screen.dart';
import 'screens/patients/patient_list_screen.dart';
import 'screens/purchases/purchase_list_screen.dart';
import 'screens/purchases/accounts_payable_screen.dart';
import 'screens/sales/pos_screen.dart';
import 'screens/shell/adaptive_navigation_shell.dart';
import 'state/app_state.dart';
import 'widgets/loading_indicator.dart';

class OnlyEyesApp extends StatefulWidget {
  const OnlyEyesApp({super.key});

  @override
  State<OnlyEyesApp> createState() => _OnlyEyesAppState();
}

class _OnlyEyesAppState extends State<OnlyEyesApp> {
  late final AppState _appState;

  @override
  void initState() {
    super.initState();
    _appState = AppState();
    _appState.initialize();
  }

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  Widget _buildActiveScreen() {
    switch (_appState.activeSection) {
      case AppSection.dashboard:
        return DashboardScreen(appState: _appState);
      case AppSection.patients:
        return PatientListScreen(appState: _appState);
      case AppSection.inventory:
        return ProductListScreen(appState: _appState);
      case AppSection.purchases:
        return PurchaseListScreen(appState: _appState);
      case AppSection.sales:
        return PosScreen(appState: _appState);
      case AppSection.appointments:
        return AppointmentsScreen(appState: _appState);
      case AppSection.labOrders:
        return LabOrdersScreen(appState: _appState);
      case AppSection.cashRegister:
        return CashRegisterScreen(appState: _appState);
      case AppSection.settings:
        return SettingsScreen(appState: _appState, initialTab: 0);
      case AppSection.businessData:
        return SettingsScreen(appState: _appState, initialTab: 1);
      case AppSection.insurance:
        return SettingsScreen(appState: _appState, initialTab: 2);
      case AppSection.accountsPayable:
        return AccountsPayableScreen(appState: _appState);
      case AppSection.reports:
        return ReportsDashboardScreen(appState: _appState);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: AnimatedBuilder(
        animation: _appState,
        builder: (context, _) {
          if (_appState.isLoading) {
            return const Scaffold(
              body: LoadingIndicator(message: 'Iniciando ONLY EYES 360...'),
            );
          }

          if (!_appState.isAuthenticated) {
            return LoginScreen(appState: _appState);
          }

          return AdaptiveNavigationShell(
            appState: _appState,
            child: _buildActiveScreen(),
          );
        },
      ),
    );
  }
}
