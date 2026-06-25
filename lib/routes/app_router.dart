import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/splash/splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/home/main_shell.dart';
import '../features/category_select/category_select_screen.dart';
import '../features/restaurant/restaurant_detail_screen.dart';
import '../features/restaurant/product_detail_screen.dart';
import '../features/orders/order_tracking_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/address/address_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/courier/courier_orders_screen.dart';
import '../features/courier/courier_shell.dart';
import '../features/courier/courier_login_screen.dart';
import '../features/courier/courier_delivery_screen.dart';
import '../theme/app_dimensions.dart';

/// Uygulama rota isimleri — tek doğruluk kaynağı (typo riskini önler).
abstract final class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String categorySelect = '/category-select';
  static const String cart = '/cart';
  static const String addresses = '/addresses';
  static const String notifications = '/notifications';
  static const String courierOrders = '/courier/orders';
  static const String courierLogin  = '/courier/login';
}

/// Yumuşak fade + hafif yukarı kayma geçişi (premium his).
CustomTransitionPage<void> _fadeUp(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: AppDurations.page,
    child: child,
    transitionsBuilder: (context, animation, secondary, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
              .animate(curved),
          child: child,
        ),
      );
    },
  );
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      pageBuilder: (context, state) => _fadeUp(const OnboardingScreen(), state),
    ),
    GoRoute(
      path: AppRoutes.login,
      pageBuilder: (context, state) => _fadeUp(const LoginScreen(), state),
    ),
    GoRoute(
      path: AppRoutes.register,
      pageBuilder: (context, state) => _fadeUp(const RegisterScreen(), state),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      pageBuilder: (context, state) => _fadeUp(const ForgotPasswordScreen(), state),
    ),
    GoRoute(
      path: AppRoutes.categorySelect,
      pageBuilder: (context, state) => _fadeUp(const CategorySelectScreen(), state),
    ),
    GoRoute(
      path: AppRoutes.home,
      pageBuilder: (context, state) => _fadeUp(const MainShell(), state),
    ),
    GoRoute(
      path: AppRoutes.cart,
      pageBuilder: (context, state) => _fadeUp(const CartScreen(), state),
    ),
    GoRoute(
      path: '/restaurant/:id',
      pageBuilder: (context, state) => _fadeUp(
        RestaurantDetailScreen(id: state.pathParameters['id']!),
        state,
      ),
    ),
    GoRoute(
      path: '/product/:id',
      pageBuilder: (context, state) => _fadeUp(
        ProductDetailScreen(id: state.pathParameters['id']!),
        state,
      ),
    ),
    GoRoute(
      path: '/order/:id/track',
      pageBuilder: (context, state) => _fadeUp(
        OrderTrackingScreen(id: state.pathParameters['id']!),
        state,
      ),
    ),
    GoRoute(
      path: AppRoutes.addresses,
      pageBuilder: (context, state) => _fadeUp(const AddressScreen(), state),
    ),
    GoRoute(
      path: AppRoutes.notifications,
      pageBuilder: (context, state) => _fadeUp(const NotificationsScreen(), state),
    ),
    GoRoute(
      path: AppRoutes.courierOrders,
      pageBuilder: (context, state) => _fadeUp(const CourierShell(), state),
    ),
    GoRoute(
      path: AppRoutes.courierLogin,
      pageBuilder: (context, state) => _fadeUp(const CourierLoginScreen(), state),
    ),
    GoRoute(
      path: '/courier/order/:id',
      pageBuilder: (context, state) => _fadeUp(
        CourierDeliveryScreen(orderId: state.pathParameters['id']!),
        state,
      ),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Sayfa bulunamadı: ${state.uri}')),
  ),
);
