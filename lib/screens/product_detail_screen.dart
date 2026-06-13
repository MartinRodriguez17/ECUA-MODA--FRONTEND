import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_provider.dart';
import '../services/resena_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final dynamic producto;
  const ProductDetailScreen({super.key, required this.producto});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? _tallaSeleccionada;
  int _imagenActual = 0;

  @override
  Widget build(BuildContext context) {
    // Imágenes
    List<String> imagenes = [];
    var campoImagen = widget.producto['imagenes'];
    if (campoImagen is List && campoImagen.isNotEmpty) {
      imagenes = campoImagen.map((e) => e.toString()).toList();
    } else if (campoImagen is String) {
      imagenes = [campoImagen];
    }
    final urlImagen = imagenes.isNotEmpty
        ? imagenes[0]
        : 'https://via.placeholder.com/400';

    // Tallas reales con stock
    List<Map<String, dynamic>> tallas = [];
    if (widget.producto['tallas'] != null) {
      tallas = List<Map<String, dynamic>>.from(widget.producto['tallas']);
    }

    // Stock de la talla seleccionada
    int stockTallaActual = 0;
    if (_tallaSeleccionada != null) {
      final tallaData = tallas.firstWhere(
        (t) => t['talla'] == _tallaSeleccionada,
        orElse: () => {'stock': 0},
      );
      stockTallaActual = tallaData['stock'] ?? 0;
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
            // --- CARRUSEL DE IMÁGENES ---
            Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 450,
                  child: PageView.builder(
                    itemCount: imagenes.isNotEmpty ? imagenes.length : 1,
                    onPageChanged: (index) =>
                        setState(() => _imagenActual = index),
                    itemBuilder: (context, index) {
                      return Image.network(
                        imagenes.isNotEmpty ? imagenes[index] : urlImagen,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 60,
                            color: Colors.black26,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Indicadores de página
                if (imagenes.length > 1)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: imagenes.asMap().entries.map((e) {
                        return Container(
                          width: _imagenActual == e.key ? 20 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: _imagenActual == e.key
                                ? Colors.black
                                : Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre
                  Text(
                    widget.producto['nombre'] ?? '',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Precio
                  Text(
                    '\$${widget.producto['precio']}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Vendido por
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
                  const SizedBox(height: 8),
                  const SizedBox(height: 6),
                  FutureBuilder<List<dynamic>>(
                    future: ResenaService().obtenerResenasMarca(
                      widget.producto['marcaId']?.toString() ?? '',
                    ),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text(
                          'Sin calificaciones aún',
                          style: TextStyle(fontSize: 12, color: Colors.black38),
                        );
                      }
                      final resenas = snapshot.data!;
                      final promedio =
                          resenas.fold<double>(
                            0,
                            (sum, r) => sum + (r['estrellas'] ?? 0),
                          ) /
                          resenas.length;
                      return Row(
                        children: [
                          ...List.generate(
                            5,
                            (index) => Icon(
                              index < promedio.round()
                                  ? Icons.star
                                  : Icons.star_outline,
                              color: Colors.amber,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${promedio.toStringAsFixed(1)} (${resenas.length})',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  // --- TALLAS REALES ---
                  const Text(
                    'SELECCIONA UNA TALLA',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: tallas.map((tallaData) {
                      final talla = tallaData['talla'] as String;
                      final stockTalla = tallaData['stock'] as int? ?? 0;
                      final estaSeleccionada = _tallaSeleccionada == talla;
                      final agotada = stockTalla == 0;

                      return GestureDetector(
                        onTap: agotada
                            ? null
                            : () => setState(() => _tallaSeleccionada = talla),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 60,
                          height: 60,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: agotada
                                ? Colors.grey[200]
                                : estaSeleccionada
                                ? Colors.black
                                : Colors.white,
                            border: Border.all(
                              color: agotada
                                  ? Colors.grey.shade300
                                  : estaSeleccionada
                                  ? Colors.black
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                talla,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: agotada
                                      ? Colors.grey
                                      : estaSeleccionada
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                              if (agotada)
                                const Text(
                                  'Out',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Stock de la talla seleccionada
                  if (_tallaSeleccionada != null)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Row(
                        key: ValueKey(_tallaSeleccionada),
                        children: [
                          Icon(
                            stockTallaActual > 5
                                ? Icons.check_circle_outline
                                : stockTallaActual > 0
                                ? Icons.warning_amber_outlined
                                : Icons.cancel_outlined,
                            size: 16,
                            color: stockTallaActual > 5
                                ? Colors.green
                                : stockTallaActual > 0
                                ? Colors.orange
                                : Colors.red,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            stockTallaActual > 5
                                ? 'Disponible en talla $_tallaSeleccionada ($stockTallaActual unidades)'
                                : stockTallaActual > 0
                                ? '¡Solo quedan $stockTallaActual en talla $_tallaSeleccionada!'
                                : 'Agotado en talla $_tallaSeleccionada',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: stockTallaActual > 5
                                  ? Colors.green
                                  : stockTallaActual > 0
                                  ? Colors.orange
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 35),

                  // --- BOTÓN AÑADIR AL CARRITO ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          stockTallaActual == 0 && _tallaSeleccionada != null
                          ? null
                          : () {
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

                              context.read<CartProvider>().agregarAlCarrito(
                                widget.producto,
                                _tallaSeleccionada!,
                                imagenes.isNotEmpty ? imagenes[0] : urlImagen,
                              );

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
                              Navigator.pop(context);
                            },
                      child: Text(
                        _tallaSeleccionada != null && stockTallaActual == 0
                            ? 'AGOTADO'
                            : 'AÑADIR AL CARRITO',
                      ),
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
