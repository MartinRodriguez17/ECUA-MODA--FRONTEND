// Archivo: lib/screens/home_screen.dart
// Esta es tu pantalla de inicio, donde se muestran los productos.
// Archivo: lib/screens/home_screen.dart
import 'product_detail_screen.dart';
import 'package:flutter/material.dart';
import '../services/product_service.dart'; 
import '../services/auth_service.dart'; // Importamos el servicio de Auth para leer el rol
import 'package:provider/provider.dart';
import '../services/cart_provider.dart';
import 'cart_screen.dart';
import 'upload_product_screen.dart'; // Esta será tu nueva pantalla

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();
  final AuthService _authService = AuthService(); // Instanciamos el servicio de Auth

  List<dynamic> productosReales = [];
  bool estaCargando = true;
  String? mensajeError;
  String? miRol; // Aquí guardaremos si es 'cliente' o 'marca'

  @override
  void initState() {
    super.initState();
    cargarDatos();
    cargarRolDelUsuario(); // Buscamos el rol apenas se abre la pantalla
  }

  // --- LA FUNCIÓN QUE PREGUNTA EL ROL ---
  Future<void> cargarRolDelUsuario() async {
    String? rolGuardado = await _authService.obtenerRolGuardado();
    if (mounted) {
      setState(() {
        miRol = rolGuardado;
      });
    }
  }

  Future<void> cargarDatos() async {
    try {
      final data = await _productService.obtenerRopa();
      if (!mounted) return;

      setState(() {
        productosReales = data;
        estaCargando = false;
      });
      print('Productos cargados desde el servicio: ${productosReales.length}');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        mensajeError = error.toString();
        estaCargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ECUA MODA',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -1.0),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        
      ),
      
      // --- LA MAGIA: EL BOTÓN CONDICIONAL ---
      // Solo aparece si miRol es exactamente 'marca' o 'admin'
      floatingActionButton: (miRol == 'marca' || miRol == 'admin') 
        ? FloatingActionButton(
            backgroundColor: Colors.black,
            child: const Icon(Icons.add_a_photo, color: Colors.white),
            onPressed: () {
              // Viajamos a la pantalla de subir producto (la crearemos después)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UploadProductScreen(),
                ),
              );
            },
          )
        : null, // Si es un cliente normal, el botón no existe.

      body: estaCargando
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : mensajeError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(mensajeError!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                )
              : productosReales.isEmpty
                  ? const Center(child: Text('No hay ropa en la tienda todavía bro 👕', style: TextStyle(fontSize: 18)))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16.0),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: productosReales.length,
                      itemBuilder: (context, index) {
                        final producto = productosReales[index];
                        
                        String urlImagen = 'https://via.placeholder.com/150';
                        var campoImagen = producto['imagenes']; 
                        if (campoImagen != null) {
                          if (campoImagen is List && campoImagen.isNotEmpty) {
                            urlImagen = campoImagen[0].toString();
                          } else if (campoImagen is String) {
                            urlImagen = campoImagen;
                          }
                        }

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailScreen(producto: producto),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    image: DecorationImage(
                                      image: NetworkImage(urlImagen),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                producto['nombre'] ?? 'Sin nombre',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${producto['precio']?.toString() ?? '0.00'}',
                                style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}