// Archivo: lib/screens/product_detail_screen.dart
//Esta pantalla va a recibir la información del producto que el usuario tocó y la va a dibujar en grande.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_provider.dart';

// 1. Evolucionamos a StatefulWidget para poder guardar la talla seleccionada
class ProductDetailScreen extends StatefulWidget {
  final dynamic producto;

  const ProductDetailScreen({super.key, required this.producto});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  // 2. Aquí guardamos la memoria de la pantalla
  String? _tallaSeleccionada;
  final List<String> _tallasDisponibles = ['S', 'M', 'L', 'XL'];

  @override
  Widget build(BuildContext context) {
    // 3. OJO AQUÍ: Como ahora es StatefulWidget, para leer la info usamos "widget.producto"
    String urlImagen = 'https://via.placeholder.com/400';

    // RECUERDA PONER AQUÍ EL NOMBRE REAL DE TU CAMPO EN LA BASE DE DATOS
    var campoImagen = widget.producto['imagenes'];

    if (campoImagen != null) {
      if (campoImagen is List && campoImagen.isNotEmpty) {
        urlImagen = campoImagen[0].toString();
      } else if (campoImagen is String) {
        urlImagen = campoImagen;
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 450,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                image: DecorationImage(
                  image: NetworkImage(urlImagen),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget
                        .producto['nombre'], // (O como tengas tu variable del título)
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),

                  // --- EL PARCHE MULTIMARCA ---
                  Row(
                    children: [
                      const Icon(
                        Icons.storefront,
                        size: 16,
                        color: Colors.blueGrey,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Vendido por: ${widget.producto['marcaNombre'] ?? 'Hub Moda'}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // --- NUEVA SECCIÓN: SELECTOR DE TALLAS ---
                  const Text(
                    'SELECCIONA UNA TALLA',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Wrap nos permite poner los botones uno al lado del otro
                  Wrap(
                    spacing: 12, // Espacio horizontal entre botones
                    children: _tallasDisponibles.map((talla) {
                      final bool estaSeleccionada = _tallaSeleccionada == talla;

                      return GestureDetector(
                        onTap: () {
                          // setState actualiza la pantalla al tocar
                          setState(() {
                            _tallaSeleccionada = talla;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 50,
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            // Estética brutalista: fondo negro si está seleccionado, blanco si no
                            color: estaSeleccionada
                                ? Colors.black
                                : Colors.white,
                            border: Border.all(
                              color: estaSeleccionada
                                  ? Colors.black
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                            // Bordes completamente cuadrados
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Text(
                            talla,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: estaSeleccionada
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // -----------------------------------------
                  const SizedBox(height: 35),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_tallaSeleccionada == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '⚠️ Bro, selecciona una talla primero',
                              ),
                              backgroundColor: Colors.orange,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        // --- LA MAGIA DE PROVIDER ---
                        // Leemos el servicio global y guardamos la prenda
                        context.read<CartProvider>().agregarAlCarrito(
                          widget.producto,
                          _tallaSeleccionada!,
                          urlImagen,
                        );
                        // ----------------------------

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '¡Añadido talla $_tallaSeleccionada al carrito! 🛍️',
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );

                        // Opcional: Regresamos a la tienda automáticamente después de añadir
                        Navigator.pop(context);
                      },
                      child: const Text('AÑADIR AL CARRITO'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
