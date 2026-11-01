import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';

class CustomBottomNavbar extends StatefulWidget {
  final NotchBottomBarController controller;
  final Function(int) onTap;
  final bool isOwner;

  const CustomBottomNavbar({
    super.key,
    required this.controller,
    required this.onTap,
    required this.isOwner,
  });
 
  @override
  State<CustomBottomNavbar> createState() => _CustomBottomNavbarState();
}

class _CustomBottomNavbarState extends State<CustomBottomNavbar> {
  // 💡 Buat list item dinamis berdasarkan role
  List<BottomBarItem> _buildBottomBarItems() {
    return [
      // 👑 KHUSUS OWNER: Tampilkan Tab Stok
      if (widget.isOwner)
        const BottomBarItem(
          inActiveItem: Icon(Icons.inventory_2_outlined, color: Colors.grey),
          activeItem: Icon(Icons.inventory_2_outlined, color: Colors.white),
          itemLabel: 'Stok',
        ),

      // 🧑‍💼 KASIR & OWNER: Tab Publik
      const BottomBarItem(
        inActiveItem: Icon(Icons.point_of_sale_rounded, color: Colors.grey),
        activeItem: Icon(Icons.point_of_sale_rounded, color: Colors.white),
        itemLabel: 'Kasir',
      ),
      const BottomBarItem(
        inActiveItem: Icon(Icons.home_rounded, color: Colors.grey),
        activeItem: Icon(Icons.home_rounded, color: Colors.white),
        itemLabel: 'Home',
      ),
      const BottomBarItem(
        inActiveItem: Icon(Icons.people_alt_outlined, color: Colors.grey),
        activeItem: Icon(Icons.people_alt_outlined, color: Colors.white),
        itemLabel: 'Pelang...',
      ),
      const BottomBarItem(
        inActiveItem: Icon(Icons.person_outline_rounded, color: Colors.grey),
        activeItem: Icon(Icons.person_outline_rounded, color: Colors.white),
        itemLabel: 'Profile',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedNotchBottomBar(
      notchBottomBarController: widget.controller,
      color: Colors.white,
      showLabel: true,
      notchColor: const Color(0xFF1E88E5),
      removeMargins: false,
      bottomBarWidth: 500,
      durationInMilliSeconds: 300,
      bottomBarItems:
          _buildBottomBarItems(), // 👈 Gunakan fungsi dinamis di sini
      onTap: widget.onTap,
      kIconSize: 24.0,
      kBottomRadius: 28.0,
    );
  }
}
