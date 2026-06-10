import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'upload_product_screen.dart';

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  List<dynamic> _misProductos = [];
  bool _estaCargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarMisProductos();
  }

  Future<void> _cargarMisProductos() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      final response = await http.get(
        Uri.parse('http://localhost:4000/api/productos/mis-productos'),
        headers: {'x-auth-token': token ?? ''},
      );

      if (response.statusCode == 200) {
        setState(() {
          _misProductos = jsonDecode(response.body);
          _estaCargando = false;
        });
      } else {
        throw 'Error ${response.statusCode}';
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _estaCargando = false;
      });
    }
  }

  Future<void> _eliminarProducto(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar prenda?'),
        content: const Text('Esta acción no se puede deshacer bro 🗑️'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      final response = await http.delete(
        Uri.parse('http://localhost:4000/api/productos/$id'),
        headers: {'x-auth-token': token ?? ''},
      );

      if (response.statusCode == 200) {
        setState(() => _misProductos.removeWhere((p) => p['_id'] == id));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prenda eliminada ✅'), backgroundColor: Colors.black),
        );
      } else {
        throw 'Error al eliminar';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _editarProducto(dynamic producto) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UploadProductScreen(productoEditar: producto),
      ),
    ).then((_) => _cargarMisProductos());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MIS PRODUCTOS 👕', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -1.0)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UploadProductScreen()),
        ).then((_) => _cargarMisProductos()),
      ),
      body: _estaCargando
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _misProductos.isEmpty
                  ? const Center(
                      child: Text('Aún no tienes prendas publicadas bro 👕',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _misProductos.length,
                      itemBuilder: (context, index) {
                        final producto = _misProductos[index];
                        final imagenes = producto['imagenes'] as List?;
                        final urlImagen = (imagenes != null && imagenes.isNotEmpty)
                            ? imagenes[0].toString()
                            : '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.black12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              // Imagen
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  image: urlImagen.isNotEmpty
                                      ? DecorationImage(image: NetworkImage(urlImagen), fit: BoxFit.cover)
                                      : null,
                                ),
                                child: urlImagen.isEmpty
                                    ? const Icon(Icons.image_not_supported, color: Colors.black26)
                                    : null,
                              ),
                              const SizedBox(width: 12),

                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(producto['nombre'] ?? '',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text('\$${producto['precio']}',
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text('Stock: ${producto['stock'] ?? 0}',
                                        style: const TextStyle(color: Colors.black54, fontSize: 13)),
                                  ],
                                ),
                              ),

                              // Botones editar/eliminar
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.black),
                                    onPressed: () => _editarProducto(producto),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _eliminarProducto(producto['_id']),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}