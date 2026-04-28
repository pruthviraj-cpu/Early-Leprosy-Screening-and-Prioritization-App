import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../profile/screen/profile_screen.dart';
import '../../screens/doctor_home_list.dart';

class DoctorBottomNavScreen extends StatefulWidget {
  final int initialIndex;
  const DoctorBottomNavScreen({super.key, this.initialIndex = 0});

  @override
  State<DoctorBottomNavScreen> createState() => _DoctorBottomNavScreenState();
}

class _DoctorBottomNavScreenState extends State<DoctorBottomNavScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _pages = [
    const DoctorHomeListPage(),
    const ProfileScreen(),
  ];

  void _onTap(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: _GoogleNavBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
      ),
    );
  }
}

class _GoogleNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _GoogleNavBar({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavItem(label: 'Home',    icon: Icons.home_outlined,          activeIcon: Icons.home_rounded),
    _NavItem(label: 'Profile', icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8EAED), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_items.length, (i) {
              return Expanded(
                child: _NavTile(
                  item: _items[i],
                  selected: i == currentIndex,
                  onTap: () => onTap(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─── Individual tile with animated pill ──────────────────────────────────────
class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavTile({required this.item, required this.selected, required this.onTap});

  static const _blue        = Color(0xFF1A73E8);
  static const _inactiveClr = Color(0xFF5F6368);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            width: selected ? 64 : 36,
            height: 32,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFE8F0FE) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Icon(
                selected ? item.activeIcon : item.icon,
                size: 22,
                color: selected ? _blue : _inactiveClr,
              ),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? _blue : _inactiveClr,
              letterSpacing: 0.1,
            ),
            child: Text(item.label),
          ),
        ],
      ),
    );
  }
}

// ─── Data class ───────────────────────────────────────────────────────────────
class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _NavItem({required this.label, required this.icon, required this.activeIcon});
}