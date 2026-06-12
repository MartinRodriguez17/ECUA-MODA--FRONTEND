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
import 'admin_login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();
  final AuthService _authService =
      AuthService(); // Instanciamos el servicio de Auth

  List<dynamic> productosReales = [];
  bool _buscandoActivo = false;
  bool estaCargando = true;
  String? mensajeError;
  String? miRol; // Aquí guardaremos si es 'cliente' o 'marca'

  List<dynamic> productosFiltrados = [];
  final TextEditingController _searchController = TextEditingController();

  int _tapsLogo = 0;
  DateTime? _ultimoTap;

  @override
  void initState() {
    super.initState();
    cargarDatos();
    cargarRolDelUsuario(); // Buscamos el rol apenas se abre la pantalla
  }

  void _filtrarProductos(String query) {
    setState(() {
      if (query.isEmpty) {
        productosFiltrados = productosReales;
      } else {
        productosFiltrados = productosReales.where((producto) {
          final nombre = producto['nombre']?.toString().toLowerCase() ?? '';
          final marca = producto['marca']?.toString().toLowerCase() ?? '';
          final categoria =
              producto['categoria']?.toString().toLowerCase() ?? '';
          final busqueda = query.toLowerCase();
          return nombre.contains(busqueda) ||
              marca.contains(busqueda) ||
              categoria.contains(busqueda);
        }).toList();
      }
    });
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
        productosFiltrados = data; // 👈 inicializamos los dos
        estaCargando = false;
      });
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
        backgroundColor: Colors.white,
        elevation: 0.5,
        leadingWidth: 56,
        leading: GestureDetector(
          onTap: () {
            final ahora = DateTime.now();
            if (_ultimoTap == null ||
                ahora.difference(_ultimoTap!) > const Duration(seconds: 2)) {
              _tapsLogo = 0;
            }
            _ultimoTap = ahora;
            _tapsLogo++;

            if (_tapsLogo >= 3) {
              _tapsLogo = 0;
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ClipOval(
              child: Image.asset('../asset/img/logo.png', fit: BoxFit.cover),
            ),
          ),
        ),
        title: _buscandoActivo
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _filtrarProductos,
                decoration: InputDecoration(
                  hintText: 'Buscar ropa, marca...',
                  hintStyle: const TextStyle(
                    color: Colors.black38,
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0,
                  ),
                ),
              )
            : const Text(
                'ECUA MODA',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                ),
              ),
        centerTitle: true,
        foregroundColor: Colors.black,
        actions: [
          _buscandoActivo
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _buscandoActivo = false;
                      _searchController.clear();
                      _filtrarProductos('');
                    });
                  },
                )
              : IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _buscandoActivo = true;
                    });
                  },
                ),
        ],
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
                child: Text(
                  mensajeError!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : productosFiltrados.isEmpty
          ? Center(
              child: Text(
                productosReales.isEmpty
                    ? 'No hay ropa en la tienda todavía bro 👕'
                    : 'No encontramos nada con "${_searchController.text}" 🔍',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: productosFiltrados.length,
              itemBuilder: (context, index) {
                final producto = productosFiltrados[index]; // 👈 este cambio

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
                        builder: (context) =>
                            ProductDetailScreen(producto: producto),
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
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${producto['precio']?.toString() ?? '0.00'}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
