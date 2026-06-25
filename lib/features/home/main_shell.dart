import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'home_screen.dart';
import '../orders/orders_screen.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';
import '../auth/auth_provider.dart';
import '../auth/login_screen.dart';
import '../cart/cart_provider.dart';
import '../../widgets/widgets.dart';

/// Ana uygulama iskeleti — bottom navigation ile sekmeleri yönetir.
///
/// IndexedStack kullanılır; böylece sekmeler arası geçişte her sekmenin
/// kaydırma konumu ve state'i korunur. Sepette ürün varken Home ve Ara
/// sekmelerinde floating cart button belirir.
///
/// Profil sekmesi: misafir kullanıcı için ayrı bir sayfaya YÖNLENDİRMEZ,
/// doğrudan o sekmenin içinde LoginScreen'i gösterir — böylece bottom nav
/// login formunda da görünür kalır ve kullanıcı diğer sekmelere serbestçe
/// geçebilir.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final isLoggedIn = ref.watch(authProvider).isLoggedIn;
    // Sepet butonu yalnızca alışveriş sekmelerinde (Ana Sayfa, Ara) görünür.
    final showCart = _index == 0 || _index == 1;

    final tabs = [
      const HomeScreen(),
      const SearchScreen(),
      const OrdersScreen(),
      isLoggedIn ? const ProfileScreen() : const LoginScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      floatingActionButton: showCart
          ? Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding),
              child: FloatingCartButton(
                itemCount: cart.itemCount,
                total: cart.total,
                onTap: () => context.push('/cart'),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          AppNavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Ana Sayfa'),
          AppNavItem(
              icon: Icons.search_outlined,
              activeIcon: Icons.search_rounded,
              label: 'Ara'),
          AppNavItem(
              icon: Icons.receipt_long_outlined,
              activeIcon: Icons.receipt_long_rounded,
              label: 'Siparişler'),
          AppNavItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Profil'),
        ],
      ),
    );
  }
}

