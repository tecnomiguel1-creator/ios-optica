import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../state/app_state.dart';
import '../../widgets/brand_logo.dart';

class AdaptiveNavigationShell extends StatelessWidget {
  final AppState appState;
  final Widget child;

  const AdaptiveNavigationShell({
    super.key,
    required this.appState,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            _DesktopSidebar(appState: appState),
            const VerticalDivider(
                width: 1, thickness: 1, color: AppColors.border),
            Expanded(child: child),
          ],
        ),
      );
    }

    // Layout para Android y pantallas móviles/tablets
    return Scaffold(
      appBar: AppBar(
        title: Text(_getSectionTitle(appState.activeSection)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
            onPressed: () => appState.logout(),
          ),
        ],
      ),
      drawer: _MobileDrawer(appState: appState),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _getBottomNavIndex(appState.activeSection),
        onTap: (index) {
          switch (index) {
            case 0:
              appState.setActiveSection(AppSection.dashboard);
              break;
            case 1:
              appState.setActiveSection(AppSection.patients);
              break;
            case 2:
              appState.setActiveSection(AppSection.inventory);
              break;
            case 3:
              appState.setActiveSection(AppSection.sales);
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.badge_outlined),
            activeIcon: Icon(Icons.badge),
            label: 'Pacientes',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.inventory_2_outlined),
                if (appState.lowStockCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${appState.lowStockCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            activeIcon: const Icon(Icons.inventory_2),
            label: 'Inventario',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale_outlined),
            activeIcon: Icon(Icons.point_of_sale),
            label: 'POS',
          ),
        ],
      ),
    );
  }

  static int _getBottomNavIndex(AppSection section) {
    switch (section) {
      case AppSection.dashboard:
        return 0;
      case AppSection.patients:
        return 1;
      case AppSection.inventory:
      case AppSection.purchases:
        return 2;
      case AppSection.sales:
      default:
        return 3;
    }
  }

  static String _getSectionTitle(AppSection section) {
    switch (section) {
      case AppSection.dashboard:
        return 'Panel Principal';
      case AppSection.patients:
        return 'Pacientes y Recetas';
      case AppSection.inventory:
        return 'Inventario y Catálogo';
      case AppSection.purchases:
        return 'Compras y Proveedores';
      case AppSection.sales:
        return 'Punto de Venta (POS)';
      case AppSection.appointments:
        return 'Clientes y Citas';
      case AppSection.labOrders:
        return 'Taller Óptico y Laboratorio';
      case AppSection.cashRegister:
        return 'Caja Diaria y Cuadre';
      case AppSection.settings:
        return 'Administración';
      case AppSection.businessData:
        return 'Datos del negocio';
      case AppSection.insurance:
        return 'Seguros';
      case AppSection.accountsPayable:
        return 'Cuentas por pagar';
      case AppSection.reports:
        return 'Reportes y Estadísticas';
    }
  }
}

class _DesktopSidebar extends StatelessWidget {
  final AppState appState;

  const _DesktopSidebar({required this.appState});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: AppColors.sidebarBg,
      child: Column(
        children: [
          // Cabecera de la Marca Oficial
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 18, 16, 14),
            child: Column(
              children: [
                BrandLogo(width: 210, height: 105),
                SizedBox(height: 10),
                Text(
                  AppColors.companyName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  AppColors.companySlogan,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.sidebarActive,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1E293B), height: 1),

          // Lista de Módulos de Navegación
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              children: [
                _SidebarItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  title: 'Dashboard',
                  isSelected: appState.activeSection == AppSection.dashboard,
                  onTap: () => appState.setActiveSection(AppSection.dashboard),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    'CLIENTES Y ATENCIÓN',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                _SidebarItem(
                  icon: Icons.medical_services_outlined,
                  activeIcon: Icons.medical_services,
                  title: 'Pacientes y Recetas',
                  isSelected: appState.activeSection == AppSection.patients,
                  onTap: () => appState.setActiveSection(AppSection.patients),
                ),
                _SidebarItem(
                  icon: Icons.calendar_month_outlined,
                  activeIcon: Icons.calendar_month,
                  title: 'Clientes y Citas',
                  isSelected: appState.activeSection == AppSection.appointments,
                  onTap: () =>
                      appState.setActiveSection(AppSection.appointments),
                ),
                _SidebarItem(
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2,
                  title: 'Inventario y Catálogo',
                  badgeCount: appState.lowStockCount,
                  isSelected: appState.activeSection == AppSection.inventory,
                  onTap: () => appState.setActiveSection(AppSection.inventory),
                ),
                _SidebarItem(
                  icon: Icons.local_shipping_outlined,
                  activeIcon: Icons.local_shipping,
                  title: 'Compras y Proveedores',
                  isSelected: appState.activeSection == AppSection.purchases,
                  onTap: () => appState.setActiveSection(AppSection.purchases),
                ),
                _SidebarItem(
                  icon: Icons.request_quote_outlined,
                  activeIcon: Icons.request_quote,
                  title: 'Cuentas por pagar',
                  isSelected:
                      appState.activeSection == AppSection.accountsPayable,
                  onTap: () =>
                      appState.setActiveSection(AppSection.accountsPayable),
                ),
                _SidebarItem(
                  icon: Icons.point_of_sale_outlined,
                  activeIcon: Icons.point_of_sale,
                  title: 'Punto de Venta (POS)',
                  isSelected: appState.activeSection == AppSection.sales,
                  onTap: () => appState.setActiveSection(AppSection.sales),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    'GESTIÓN Y ADMINISTRACIÓN',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                _SidebarItem(
                  icon: Icons.build_outlined,
                  activeIcon: Icons.build,
                  title: 'Taller y Laboratorio',
                  isSelected: appState.activeSection == AppSection.labOrders,
                  onTap: () => appState.setActiveSection(AppSection.labOrders),
                ),
                _SidebarItem(
                  icon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet,
                  title: 'Caja Diaria y Cuadre',
                  isSelected: appState.activeSection == AppSection.cashRegister,
                  onTap: () =>
                      appState.setActiveSection(AppSection.cashRegister),
                ),
                _SidebarItem(
                  icon: Icons.bar_chart_outlined,
                  activeIcon: Icons.bar_chart,
                  title: 'Reportes y Estadísticas',
                  isSelected: appState.activeSection == AppSection.reports,
                  onTap: () => appState.setActiveSection(AppSection.reports),
                ),
                _SidebarItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  title: 'Administración',
                  isSelected: appState.activeSection == AppSection.settings,
                  onTap: () => appState.setActiveSection(AppSection.settings),
                ),
                _SidebarItem(
                  icon: Icons.storefront_outlined,
                  activeIcon: Icons.storefront,
                  title: 'Datos del negocio',
                  isSelected: appState.activeSection == AppSection.businessData,
                  onTap: () =>
                      appState.setActiveSection(AppSection.businessData),
                ),
                _SidebarItem(
                  icon: Icons.health_and_safety_outlined,
                  activeIcon: Icons.health_and_safety,
                  title: 'Seguros',
                  isSelected: appState.activeSection == AppSection.insurance,
                  onTap: () => appState.setActiveSection(AppSection.insurance),
                ),
              ],
            ),
          ),

          // Perfil y Salida
          const Divider(color: Color(0xFF1E293B), height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  radius: 18,
                  child: Text(
                    (appState.currentUser?.nombre.isNotEmpty ?? false)
                        ? appState.currentUser!.nombre
                            .substring(0, 1)
                            .toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appState.currentUser?.nombre ?? 'Usuario',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        appState.currentUser?.rol.toUpperCase() ?? 'STAFF',
                        style: const TextStyle(
                          color: AppColors.sidebarActive,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout,
                      size: 18, color: AppColors.sidebarText),
                  tooltip: 'Cerrar Sesión',
                  onPressed: () => appState.logout(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String title;
  final bool isSelected;
  final int badgeCount;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.activeIcon,
    required this.title,
    required this.isSelected,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1E293B) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? const Border(
                left: BorderSide(color: AppColors.sidebarActive, width: 3.5))
            : null,
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? AppColors.sidebarActive : AppColors.sidebarText,
          size: 19,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.sidebarText,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: -0.1,
          ),
        ),
        trailing: badgeCount > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}

class _MobileDrawer extends StatelessWidget {
  final AppState appState;

  const _MobileDrawer({required this.appState});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A192F), Color(0xFF0F4C81)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const BrandLogo(width: 188, height: 92),
                const SizedBox(height: 8),
                Text(
                  appState.currentUser?.nombre ?? 'Usuario Activo',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            onTap: () {
              appState.setActiveSection(AppSection.dashboard);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.medical_services_outlined),
            title: const Text('Pacientes y Recetas'),
            onTap: () {
              appState.setActiveSection(AppSection.patients);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: const Text('Clientes y Citas'),
            onTap: () {
              appState.setActiveSection(AppSection.appointments);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('Inventario'),
            trailing: appState.lowStockCount > 0
                ? Text('${appState.lowStockCount}',
                    style: const TextStyle(
                        color: AppColors.danger, fontWeight: FontWeight.bold))
                : null,
            onTap: () {
              appState.setActiveSection(AppSection.inventory);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_shipping_outlined),
            title: const Text('Compras y Proveedores'),
            onTap: () {
              appState.setActiveSection(AppSection.purchases);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.request_quote_outlined),
            title: const Text('Cuentas por pagar'),
            onTap: () {
              appState.setActiveSection(AppSection.accountsPayable);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.point_of_sale_outlined),
            title: const Text('Punto de Venta (POS)'),
            onTap: () {
              appState.setActiveSection(AppSection.sales);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.build_outlined),
            title: const Text('Laboratorio óptico'),
            onTap: () {
              appState.setActiveSection(AppSection.labOrders);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Caja Diaria'),
            onTap: () {
              appState.setActiveSection(AppSection.cashRegister);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart_outlined),
            title: const Text('Reportes y Estadísticas'),
            onTap: () {
              appState.setActiveSection(AppSection.reports);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Administración'),
            onTap: () {
              appState.setActiveSection(AppSection.settings);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: const Text('Datos del negocio'),
            onTap: () {
              appState.setActiveSection(AppSection.businessData);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.health_and_safety_outlined),
            title: const Text('Seguros'),
            onTap: () {
              appState.setActiveSection(AppSection.insurance);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.danger),
            title: const Text('Cerrar Sesión',
                style: TextStyle(color: AppColors.danger)),
            onTap: () {
              Navigator.pop(context);
              appState.logout();
            },
          ),
        ],
      ),
    );
  }
}
