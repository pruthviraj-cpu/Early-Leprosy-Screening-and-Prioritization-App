import 'package:flutter/material.dart';
import 'package:frontend/screens/home.dart';
import '../profile/screen/profile_screen.dart';
import 'package:frontend/screens/doctor_home.dart';

class DoctorBottomNavScreen extends StatefulWidget {
  const DoctorBottomNavScreen({super.key});

  @override
  State<DoctorBottomNavScreen> createState() => _DoctorBottomNavScreenState();
}

class _DoctorBottomNavScreenState extends State<DoctorBottomNavScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [const DoctorHomePage(), const ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xff0F172A).withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
          border: const Border(
            top: BorderSide(color: Color(0xffE2E8F0), width: 1),
          ),
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundColor: Colors.white,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedItemColor: const Color(0xff0EA5A4),
            unselectedItemColor: const Color(0xff94A3B8),
            selectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
            items: [
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _currentIndex == 0
                        ? const Color(0xffF0FDFA)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.home_outlined,
                    size: 24,
                    color: _currentIndex == 0
                        ? const Color(0xff0EA5A4)
                        : const Color(0xff94A3B8),
                  ),
                ),
                activeIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xffF0FDFA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.home_filled,
                    size: 24,
                    color: Color(0xff0EA5A4),
                  ),
                ),
                label: 'Home',
              ),
              // BottomNavigationBarItem(
              //   icon: Container(
              //     padding: const EdgeInsets.all(8),
              //     decoration: BoxDecoration(
              //       color: _currentIndex == 1
              //           ? const Color(0xffF0FDFA)
              //           : Colors.transparent,
              //       borderRadius: BorderRadius.circular(12),
              //     ),
              //     child: Icon(
              //       Icons.chat_bubble_outline_outlined,
              //       size: 24,
              //       color: _currentIndex == 1
              //           ? const Color(0xff0EA5A4)
              //           : const Color(0xff94A3B8),
              //     ),
              //   ),
              //   activeIcon: Container(
              //     padding: const EdgeInsets.all(8),
              //     decoration: BoxDecoration(
              //       color: const Color(0xffF0FDFA),
              //       borderRadius: BorderRadius.circular(12),
              //     ),
              //     child: const Icon(
              //       Icons.chat_bubble_rounded,
              //       size: 24,
              //       color: Color(0xff0EA5A4),
              //     ),
              //   ),
              //   label: 'Chat',
              // ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _currentIndex == 2
                        ? const Color(0xffF0FDFA)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person_outline_outlined,
                    size: 24,
                    color: _currentIndex == 2
                        ? const Color(0xff0EA5A4)
                        : const Color(0xff94A3B8),
                  ),
                ),
                activeIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xffF0FDFA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 24,
                    color: Color(0xff0EA5A4),
                  ),
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
