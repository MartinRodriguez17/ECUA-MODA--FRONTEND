// Archivo: lib/main_wrapper.dart
// Este widget se encarga de manejar la navegación entre las pantallas principales (Home y Login

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart'; // <-- IMPORTAMOS PROVIDER
import 'services/cart_provider.dart';  // <-- IMPORTAMOS EL CARRITO

import 'screens/home_screen.dart';
import 'screens/login_screen.dart'; 
import 'screens/cart_screen.dart';    
import 'screens/profile_screen.dart'; 

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _indiceActual = 0;
  bool _estaLogueado = false; 

  @override
  void initState() {
    super.initState();
    _verificarSesion(); 
  }

  Future<void> _verificarSesion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');
    
    setState(() {
      _estaLogueado = (token != null && token.isNotEmpty);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos al carrito para saber cuántos items hay en total
    final carrito = context.watch<CartProvider>();

    final List<Widget> pantallas = [
      const HomeScreen(),  
      const CartScreen(),  
      _estaLogueado ? const ProfileScreen() : const LoginScreen(), 
    ];

    return Scaffold(
      body: pantallas[_indiceActual],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceActual,
        onTap: (index) {
          setState(() {
            _indiceActual = index;
          });
        },
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,   
        showUnselectedLabels: false, 
        type: BottomNavigationBarType.fixed, 
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Inicio'),
          
          // --- ¡EL NUEVO ICONO DEL CARRITO CON NOTIFICACIÓN! ---
          BottomNavigationBarItem(
            icon: Badge(
              // Solo se muestra la bolita roja si hay más de 0 cosas en el carrito
              isLabelVisible: carrito.cantidadTotal > 0, 
              label: Text(
                carrito.cantidadTotal.toString(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            // Cuando está seleccionado (activo), le ponemos el icono rellenito
            activeIcon: Badge(
              isLabelVisible: carrito.cantidadTotal > 0,
              label: Text(
                carrito.cantidadTotal.toString(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              child: const Icon(Icons.shopping_bag),
            ),
            label: 'Bolsita',
          ),
          
          BottomNavigationBarItem(
            icon: Icon(_estaLogueado ? Icons.person : Icons.person_outline), 
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}