import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:aplikasi_warung_supabase/providers/auth_provider.dart';
import 'package:aplikasi_warung_supabase/views/cashiers/cashier_screen.dart';
import 'package:aplikasi_warung_supabase/views/customers/customer_screen.dart';
import 'package:aplikasi_warung_supabase/views/profile/profile_screen.dart';
import 'package:aplikasi_warung_supabase/views/stock/stock_screen.dart';
import 'package:aplikasi_warung_supabase/views/dashboard_menu/dashoard_screen.dart';
import 'package:aplikasi_warung_supabase/widgets/navbar_bottom.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});
 
  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  NotchBottomBarController? _controller;
  PageController? _pageController;
  bool _isLoadingRole = true;

  @override
  void initState() {
    super.initState();
    // Panggil setelah frame selesai di-render untuk menghindari error setState/markNeedsBuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initRoleAndControllers();
    });
  }

  Future<void> _initRoleAndControllers() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.fetchUserProfile();

    if (!mounted) return;

    final isOwner = authProvider.isOwner;
    // Set index awal Home: Index 2 jika Owner, Index 1 jika Kasir
    final initialIndex = isOwner ? 2 : 1;

    setState(() {
      _controller = NotchBottomBarController(index: initialIndex);
      _pageController = PageController(initialPage: initialIndex);
      _isLoadingRole = false;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  List<Widget> _getPages(bool isOwner) {
    if (isOwner) {
      return const [
        StokPage(),
        CashierScreen(),
        DashboardScreen(),
        PelangganPage(),
        ProfilePage(),
      ];
    } else {
      return const [
        CashierScreen(),
        DashboardScreen(),
        PelangganPage(),
        ProfilePage(),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingRole || _controller == null || _pageController == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isOwner = context.watch<AuthProvider>().isOwner;

    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: _getPages(isOwner),
        ),
      ),
      bottomNavigationBar: CustomBottomNavbar(
        controller: _controller!,
        isOwner: isOwner,
        onTap: (index) {
          _pageController?.jumpToPage(index);
        },
      ),
    );
  }
}
