// Archivo: lib/services/cart_provider.dart
//Este archivo va a tener la lista de compras y la lógica para añadir ropa,
//sumar los precios, y avisarle a la app cuando algo cambie.

import 'package:flutter/material.dart';

// 1. Definimos la estructura de lo que va a entrar al carrito
class CartItem {
  final String id; // ID único (ej: hoodie123_M)
  final String nombre;
  final double precio;
  final String imagen;
  final String talla;
  int cantidad;

  CartItem({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.imagen,
    required this.talla,
    this.cantidad = 1,
  });
}

// 2. El Servicio Global (ChangeNotifier nos permite avisar a la pantalla cuando hay cambios)
class CartProvider extends ChangeNotifier {
  // La lista privada del carrito
  final List<CartItem> _items = [];

  // Función pública para que las pantallas puedan leer la lista
  List<CartItem> get items => _items;

  // 3. Lógica para añadir un producto
  void agregarAlCarrito(dynamic producto, String talla, String urlImagen) {
    // Creamos un ID compuesto (producto + talla)
    // Así, si el usuario compra el mismo Hoodie en 'S' y en 'M', cuentan como items separados.
    // Ojo: asumo que tu BD devuelve el id como '_id'. Si es 'id', cámbialo.
    final String productoId =
        producto['_id']?.toString() ?? DateTime.now().toString();
    final String idUnico = '${productoId}_$talla';

    // Buscamos si ya existe exactamente ese producto con esa talla en el carrito
    final index = _items.indexWhere((item) => item.id == idUnico);

    if (index >= 0) {
      // Si ya existe, solo le sumamos 1 a la cantidad para no repetir la foto en la lista
      _items[index].cantidad++;
    } else {
      // Si es nuevo, limpiamos el precio por si Node.js lo mandó como String
      double precioFinal = 0.0;
      if (producto['precio'] != null) {
        precioFinal = double.tryParse(producto['precio'].toString()) ?? 0.0;
      }

      // Lo agregamos a la lista
      _items.add(
        CartItem(
          id: idUnico,
          nombre: producto['nombre'] ?? 'Sin nombre',
          precio: precioFinal,
          imagen: urlImagen,
          talla: talla,
        ),
      );
    }

    // ¡ESTO ES CLAVE! Grita a los 4 vientos que el carrito cambió para que la UI se actualice
    notifyListeners();
  }

  // 4. Utilidad: Calcular cuántos artículos hay en total (para ponerle un numerito al icono de la bolsa)
  int get cantidadTotal {
    return _items.fold(0, (total, item) => total + item.cantidad);
  }

  // Utilidad: Calcular el precio total a pagar
  double get precioTotal {
    return _items.fold(
      0.0,
      (total, item) => total + (item.precio * item.cantidad),
    );
  }

  // --- NUEVA FUNCIÓN: Sumar Cantidad Manualmente ---
  void sumarCantidad(String idUnico) {
    final index = _items.indexWhere((item) => item.id == idUnico);
    if (index >= 0) {
      _items[index].cantidad++;
      notifyListeners();
    }
  }

  // --- NUEVA FUNCIÓN: Restar Cantidad Manualmente ---
  void restarCantidad(String idUnico) {
    final index = _items.indexWhere((item) => item.id == idUnico);
    if (index >= 0) {
      if (_items[index].cantidad > 1) {
        _items[index].cantidad--;
        notifyListeners();
      } else {
        // Si tiene 1 y le da al menos, lo eliminamos de la bolsa
        eliminarDelCarrito(idUnico);
      }
    }
  }

  // --- FUNCIÓN PARA ELIMINAR ---
  void eliminarDelCarrito(String idUnico) {
    _items.removeWhere((item) => item.id == idUnico);
    notifyListeners();
  }

  // --- FUNCIÓN PARA VACIAR TODO ---
  void vaciarCarrito() {
    _items.clear();
    notifyListeners();
  }

  // ==========================================
  //      LÓGICA FINANCIERA (SRI / IVA)
  // ==========================================

  // 1. El Subtotal (Lo que cuesta la ropa sin impuestos)
  double get subtotal {
    return _items.fold(
      0.0,
      (total, item) => total + (item.precio * item.cantidad),
    );
  }

  // 2. El IVA (15% en Ecuador)
  double get impuestosIva {
    return subtotal * 0.15;
  }

  // 3. El Total Final a Pagar
  // Ojo: Cambié el nombre de 'precioTotal' a 'totalFinal' para ser más precisos.
  double get totalFinal {
    return subtotal + impuestosIva;
  }
}
