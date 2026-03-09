import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/auth_switcher_screen.dart';
import '../../features/auth/presentation/screens/merchant_registration_screen.dart';
import '../../features/auth/presentation/screens/courier_registration_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';

import '../../features/merchant/presentation/screens/merchant_dashboard_screen.dart';
import '../../features/shipments/presentation/screens/create_shipment_screen.dart';
import '../../features/courier/presentation/screens/courier_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/wallet/presentation/screens/wallet_screen.dart';

// Provides the GoRouter instance
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const AuthSwitcherScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      GoRoute(
        path: '/register/merchant',
        builder: (context, state) => const MerchantRegistrationScreen(),
      ),
      GoRoute(
        path: '/register/courier',
        builder: (context, state) => const CourierRegistrationScreen(),
      ),
      GoRoute(
        path: '/merchant/dashboard',
        builder: (context, state) => const MerchantDashboardScreen(),
      ),
      GoRoute(
        path: '/merchant/shipment/create',
        builder: (context, state) => const CreateShipmentScreen(),
      ),
      GoRoute(
        path: '/courier/dashboard',
        builder: (context, state) => const CourierDashboardScreen(),
      ),
      GoRoute(
        path: '/courier/wallet',
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
  );
});
