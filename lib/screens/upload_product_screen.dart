import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class UploadProductScreen extends StatefulWidget {
  final dynamic productoEditar;

  const UploadProductScreen({super.key, this.productoEditar});

  @override
  State<UploadProductScreen> createState() => _UploadProductScreenState();
}

class _UploadProductScreenState extends State<UploadProductScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.productoEditar != null) {
      final p = widget.productoEditar;
      _nombreController.text = p['nombre'] ?? '';
      _precioController.text = p['precio']?.toString() ?? '';
      _descripcionController.text = p['descripcion'] ?? '';
      _marcaController.text = p['marca'] ?? '';
      _categoriaSeleccionada = p['categoria'];
      _estiloSeleccionado = p['estilo'];
      _generoSeleccionado = p['genero'];
      _stock = p['stock'] ?? 1;
      if (p['tallas'] != null) {
        _tallasSeleccionadas.addAll(List<String>.from(p['tallas']));
      }
    }
  }

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _marcaController = TextEditingController();

  int _stock = 1;
  final List<String> _tallasDisponibles = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  final List<String> _tallasSeleccionadas = [];

  // --- DROPDOWNS ---
  String? _categoriaSeleccionada;
  String? _estiloSeleccionado;
  String? _generoSeleccionado;

  final List<String> _categorias = [
    'Camiseta',
    'Camisa',
    'Pantalón',
    'Jeans',
    'Shorts',
    'Vestido',
    'Falda',
    'Chaqueta',
    'Hoodie',
    'Abrigo',
    'Zapatos',
    'Zapatillas',
    'Accesorios',
    'Otro',
  ];

  final List<String> _estilos = [
    'Urban',
    'Casual',
    'Streetwear',
    'Formal',
    'Deportivo',
    'Vintage',
    'Bohemio',
    'Minimalista',
    'Elegante',
    'Otro',
  ];

  final List<String> _generos = ['Hombre', 'Mujer', 'Niño', 'Niña', 'Unisex'];

  // --- MÚLTIPLES IMÁGENES (máx 4) ---
  final List<XFile> _imagenesSeleccionadas = [];
  final ImagePicker _picker = ImagePicker();
  bool _estaCargando = false;

  Future<void> _agregarImagen() async {
    if (_imagenesSeleccionadas.isEmpty && widget.productoEditar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bro, agrega al menos una foto 📸'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _imagenesSeleccionadas.add(pickedFile);
      });
    }
  }

  void _eliminarImagen(int index) {
    setState(() {
      _imagenesSeleccionadas.removeAt(index);
    });
  }

  Future<void> _subirProducto() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imagenesSeleccionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bro, agrega al menos una foto 📸'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_categoriaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una categoría 🛑'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_estiloSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un estilo 🛑'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_generoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona el género 🛑'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_tallasSeleccionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos una talla 🛑'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _estaCargando = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      final esEdicion = widget.productoEditar != null;
      final url = esEdicion
          ? 'http://localhost:4000/api/productos/${widget.productoEditar['_id']}'
          : 'http://localhost:4000/api/productos';

      var request = http.MultipartRequest(
        esEdicion ? 'PUT' : 'POST',
        Uri.parse(url),
      );

      request.headers.addAll({
        'x-auth-token': token ?? '',
        'x-app-source': 'hub_moda_app_2026',
      });

      request.fields['nombre'] = _nombreController.text.trim();
      request.fields['precio'] = _precioController.text.trim();
      request.fields['descripcion'] = _descripcionController.text.trim();
      request.fields['categoria'] = _categoriaSeleccionada!;
      request.fields['estilo'] = _estiloSeleccionado!;
      request.fields['genero'] = _generoSeleccionado!;
      request.fields['marca'] = _marcaController.text.trim();
      request.fields['stock'] = _stock.toString();
      // Mandamos las tallas como JSON array
      request.fields['tallas'] = _tallasSeleccionadas.join(',');

      // Subimos todas las imágenes
      for (final imagen in _imagenesSeleccionadas) {
        http.MultipartFile pic;
        if (kIsWeb) {
          final bytes = await imagen.readAsBytes();
          pic = http.MultipartFile.fromBytes(
            'imagenes',
            bytes,
            filename: imagen.name,
          );
        } else {
          pic = await http.MultipartFile.fromPath('imagenes', imagen.path);
        }
        request.files.add(pic);
      }

      var response = await request.send();

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Prenda subida con éxito al Hub! 🔥'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        final respBody = await response.stream.bytesToString();
        throw 'Error ${response.statusCode}: $respBody';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _estaCargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.productoEditar != null ? 'EDITAR PRENDA' : 'NUEVA PRENDA',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- SECCIÓN DE FOTOS ---
              const Text(
                'Fotos del producto (máx. 4)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 110,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Miniaturas de imágenes agregadas
                    ..._imagenesSeleccionadas.asMap().entries.map((entry) {
                      final index = entry.key;
                      final imagen = entry.value;
                      return Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.grey[200],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: kIsWeb
                                  ? Image.network(
                                      imagen.path,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(imagen.path),
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 14,
                            child: GestureDetector(
                              onTap: () => _eliminarImagen(index),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),

                    // Botón agregar foto
                    if (_imagenesSeleccionadas.length < 4)
                      GestureDetector(
                        onTap: _agregarImagen,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.black26,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 30,
                                color: Colors.black54,
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Agregar',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- NOMBRE ---
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Prenda',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Falta el nombre' : null,
              ),
              const SizedBox(height: 16),

              // --- PRECIO ---
              TextFormField(
                controller: _precioController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Precio (\$)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Falta el precio' : null,
              ),
              const SizedBox(height: 16),

              // --- DROPDOWN GÉNERO ---
              DropdownButtonFormField<String>(
                value: _generoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Género',
                  border: OutlineInputBorder(),
                ),
                items: _generos
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _generoSeleccionado = value),
                validator: (value) =>
                    value == null ? 'Selecciona el género' : null,
              ),
              const SizedBox(height: 16),

              // --- DROPDOWN CATEGORÍA ---
              DropdownButtonFormField<String>(
                value: _categoriaSeleccionada,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                ),
                items: _categorias
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _categoriaSeleccionada = value),
                validator: (value) =>
                    value == null ? 'Selecciona una categoría' : null,
              ),
              const SizedBox(height: 16),

              // --- DROPDOWN ESTILO ---
              DropdownButtonFormField<String>(
                value: _estiloSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Estilo',
                  border: OutlineInputBorder(),
                ),
                items: _estilos
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _estiloSeleccionado = value),
                validator: (value) =>
                    value == null ? 'Selecciona un estilo' : null,
              ),
              const SizedBox(height: 16),

              // --- MARCA ---
              TextFormField(
                controller: _marcaController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de tu Marca',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Falta la marca' : null,
              ),
              const SizedBox(height: 16),

              // --- DESCRIPCIÓN ---
              TextFormField(
                controller: _descripcionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción del producto',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Falta la descripción' : null,
              ),
              const SizedBox(height: 30),

              // --- TALLAS ---
              const Text(
                'Tallas disponibles',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _tallasDisponibles.map((talla) {
                  final seleccionada = _tallasSeleccionadas.contains(talla);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (seleccionada) {
                          _tallasSeleccionadas.remove(talla);
                        } else {
                          _tallasSeleccionadas.add(talla);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: seleccionada ? Colors.black : Colors.white,
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        talla,
                        style: TextStyle(
                          color: seleccionada ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // --- STOCK ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Stock disponible',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => setState(() {
                          if (_stock > 1) _stock--;
                        }),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '$_stock',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _stock++),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- BOTÓN PUBLICAR ---
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _estaCargando ? null : _subirProducto,
                  child: _estaCargando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.productoEditar != null
                              ? 'GUARDAR CAMBIOS'
                              : 'PUBLICAR PRENDA',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
