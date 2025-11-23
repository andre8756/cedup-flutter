import 'package:flutter/material.dart';

class AppFooter extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppFooter({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.black54,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.sync_alt), label: "Transação"),
        BottomNavigationBarItem(
          icon: Icon(Icons.trending_up),
          label: "Extrato",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.grid_view_rounded),
          label: "Todos",
        ),
      ],
    );
  }
}
