// Archivo: lib/screens/upload_product_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // <-- ¡NUEVO! Para saber si estamos en Web

class UploadProductScreen extends StatefulWidget {
  const UploadProductScreen({super.key});

  @override
  State<UploadProductScreen> createState() => _UploadProductScreenState();
}

class _UploadProductScreenState extends State<UploadProductScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _categoriaController = TextEditingController();
  final TextEditingController _estiloController = TextEditingController();
  final TextEditingController _marcaController = TextEditingController();

  XFile? _imagenSeleccionada; // Usamos XFile en lugar de File para que aguante Web
  bool _estaCargando = false;

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imagenSeleccionada = pickedFile;
      });
    }
  }

  Future<void> _subirProducto() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imagenSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bro, te olvidaste de elegir la foto 📸'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _estaCargando = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:4000/api/productos'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'x-app-source': 'hub_moda_app_2026',
      });

      request.fields['nombre'] = _nombreController.text;
      request.fields['precio'] = _precioController.text;
      request.fields['descripcion'] = _descripcionController.text;
      request.fields['categoria'] = _categoriaController.text;
      request.fields['estilo'] = _estiloController.text;
      request.fields['marca'] = _marcaController.text;

      // --- LA MAGIA MULTIPLATAFORMA PARA SUBIR FOTOS ---
      http.MultipartFile pic;
      if (kIsWeb) {
        // Si estamos en Chrome/Edge, leemos los bytes puros
        final bytes = await _imagenSeleccionada!.readAsBytes();
        pic = http.MultipartFile.fromBytes('imagen', bytes, filename: _imagenSeleccionada!.name);
      } else {
        // Si estamos en Android/iOS, leemos la ruta normal
        pic = await http.MultipartFile.fromPath('imagen', _imagenSeleccionada!.path);
      }
      request.files.add(pic);

      var response = await request.send();

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Prenda subida con éxito al Hub! 🔥'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        throw 'Error al subir la prenda. Código: ${response.statusCode}';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _estaCargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NUEVA PRENDA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -1.0)),
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
              GestureDetector(
                onTap: _seleccionarImagen,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: _imagenSeleccionada != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          // --- LA MAGIA MULTIPLATAFORMA PARA MOSTRAR FOTOS ---
                          child: kIsWeb 
                              ? Image.network(_imagenSeleccionada!.path, fit: BoxFit.cover)
                              : Image.file(File(_imagenSeleccionada!.path), fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 50, color: Colors.black54),
                            SizedBox(height: 10),
                            Text('Toca para elegir la foto', style: TextStyle(color: Colors.black54)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre de la Prenda', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Falta el nombre' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _precioController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Precio (\$)', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Falta el precio' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _categoriaController,
                decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _estiloController,
                decoration: const InputDecoration(labelText: 'Estilo', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _marcaController,
                decoration: const InputDecoration(labelText: 'Nombre de tu Marca', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descripcionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Descripción del producto', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 30),

              SizedBox(
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                  onPressed: _estaCargando ? null : _subirProducto,
                  child: _estaCargando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('PUBLICAR PRENDA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}