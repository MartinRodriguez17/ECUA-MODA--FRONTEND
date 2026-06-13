// Archivo: lib/screens/profile_screen.dart
// Esta pantalla es el perfil del usuario. Por ahora es un placeholder,
//pero aquí es donde el usuario podrá ver y editar sus datos personales.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart'; // <-- PARA ABRIR LA GALERÍA
import 'dart:typed_data'; // <-- PARA LEER LA FOTO EN LA WEB/CELULAR
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../main_wrapper.dart';
import 'admin_panel_screen.dart'; // <-- IMPORTAMOS LA PANTALLA DEL PANEL DE CONTROL, aunque no se vea en el menú normal
import 'upload_product_screen.dart';
import 'my_products_screen.dart';
import 'mis_ventas_screen.dart';
import '../services/resena_service.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final OrderService _orderService = OrderService();
  final ImagePicker _picker =
      ImagePicker(); // <-- INSTANCIAMOS EL SELECTOR DE FOTOS

  Map<String, dynamic>? _datosUsuario;
  List<dynamic> _misPedidos = [];

  bool _estaCargando = true;
  String? _mensajeError;

  @override
  void initState() {
    super.initState();
    _cargarDatosCompletos();
  }

  Future<void> _cargarDatosCompletos() async {
    try {
      final datos = await _authService.obtenerDatosPerfil();
      List<dynamic> pedidos = [];

      // Solo cargamos pedidos si es cliente normal
      if (datos['rol'] == 'cliente') {
        pedidos = await _orderService.obtenerHistorialPedidos();
        print('PEDIDOS: ${jsonEncode(pedidos)}');
      }

      if (mounted) {
        setState(() {
          _datosUsuario = datos;
          _misPedidos = pedidos;
          _estaCargando = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _mensajeError = error.toString();
          _estaCargando = false;
        });
      }
    }
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sesión cerrada correctamente bro 👋'),
        backgroundColor: Colors.black,
      ),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainWrapper()),
      (Route<dynamic> route) => false,
    );
  }

  // --- LA VENTANITA MÁGICA PARA EDITAR PERFIL ---
  void _mostrarModalEdicion() {
    final TextEditingController nombreController = TextEditingController(
      text: _datosUsuario?['nombre'],
    );
    Uint8List? nuevaFotoBytes;
    String? nuevoNombreArchivo;
    bool guardando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'EDITAR PERFIL ✏️',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 20),

                  // BOTÓN PARA CAMBIAR FOTO
                  GestureDetector(
                    onTap: () async {
                      final XFile? imagen = await _picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 80,
                      );
                      if (imagen != null) {
                        final bytes = await imagen.readAsBytes();
                        setModalState(() {
                          nuevaFotoBytes = bytes;
                          nuevoNombreArchivo = imagen.name;
                        });
                      }
                    },
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: nuevaFotoBytes != null
                          ? MemoryImage(nuevaFotoBytes!)
                          : null,
                      child: nuevaFotoBytes == null
                          ? const Icon(
                              Icons.add_a_photo,
                              size: 40,
                              color: Colors.black54,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // CAJA PARA EL NOMBRE
                  TextField(
                    controller: nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nuevo Nombre de Usuario',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // BOTÓN GUARDAR
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: guardando
                          ? null
                          : () async {
                              setModalState(() => guardando = true);
                              try {
                                await _authService.actualizarPerfil(
                                  // 👇 Solo manda el nombre si realmente cambió
                                  nombre:
                                      nombreController.text.trim() !=
                                          _datosUsuario?['nombre']
                                      ? nombreController.text.trim()
                                      : null,
                                  fotoBytes: nuevaFotoBytes,
                                  nombreArchivo: nuevoNombreArchivo,
                                );
                                if (!mounted) return;

                                Navigator.pop(context); // Cierra el modal

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      '¡Perfil actualizado con éxito! 🔥',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );

                                // Recargamos los datos para que se vea el cambio al instante
                                setState(() => _estaCargando = true);
                                _cargarDatosCompletos();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString()),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } finally {
                                setModalState(() => guardando = false);
                              }
                            },
                      child: guardando
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'GUARDAR CAMBIOS',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarModalCalificacion(dynamic pedido) {
    int _estrellasSeleccionadas = 0;
    final comentarioController = TextEditingController();
    bool _enviando = false;

    // Sacamos la marca del primer producto del pedido
    final productos = pedido['productos'] as List? ?? [];
    String marcaId = '';
    for (var item in productos) {
      final prod = item['producto'];
      if (prod != null && prod is Map && prod['marcaId'] != null) {
        marcaId = prod['marcaId'].toString();
        break;
      }
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '¿Cómo fue tu experiencia? ⭐',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tu opinión ayuda a otros compradores',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  // Estrellas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () => setModalState(
                          () => _estrellasSeleccionadas = index + 1,
                        ),
                        child: Icon(
                          index < _estrellasSeleccionadas
                              ? Icons.star
                              : Icons.star_outline,
                          color: Colors.amber,
                          size: 40,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _estrellasSeleccionadas == 0
                        ? 'Toca para calificar'
                        : _estrellasSeleccionadas == 1
                        ? 'Muy malo 😞'
                        : _estrellasSeleccionadas == 2
                        ? 'Malo 😕'
                        : _estrellasSeleccionadas == 3
                        ? 'Regular 😐'
                        : _estrellasSeleccionadas == 4
                        ? 'Bueno 😊'
                        : 'Excelente 🔥',
                    style: TextStyle(
                      fontSize: 14,
                      color: _estrellasSeleccionadas == 0
                          ? Colors.black38
                          : Colors.amber.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Comentario
                  TextField(
                    controller: comentarioController,
                    maxLines: 3,
                    maxLength: 300,
                    decoration: const InputDecoration(
                      labelText: 'Comentario (opcional)',
                      hintText: 'Cuéntanos tu experiencia...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _enviando || _estrellasSeleccionadas == 0
                          ? null
                          : () async {
                              setModalState(() => _enviando = true);
                              try {
                                await ResenaService().crearResena(
                                  marcaId: marcaId,
                                  pedidoId: pedido['_id'],
                                  estrellas: _estrellasSeleccionadas,
                                  comentario: comentarioController.text,
                                );
                                if (!mounted) return;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      '¡Gracias por tu calificación! ⭐',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                setState(() => _estaCargando = true);
                                _cargarDatosCompletos();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString()),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } finally {
                                setModalState(() => _enviando = false);
                              }
                            },
                      child: _enviando
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'ENVIAR CALIFICACIÓN',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _obtenerColorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'aprobado':
        return Colors.amber;
      case 'rechazado':
        return Colors.red;
      case 'entregado':
        return Colors.green;
      default:
        return Colors.blue; // Pendiente Verificación
    }
  }

  Widget _buildHistorialPedidos() {
    return _misPedidos.isEmpty
        ? const Center(
            child: Text(
              'Aún no has comprado nada bro 💨',
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            itemCount: _misPedidos.length,
            itemBuilder: (context, index) {
              final pedido = _misPedidos[index];
              final estado = pedido['estado'] ?? 'Desconocido';
              final fechaRaw = pedido['fechaCreacion'];
              final fecha = fechaRaw != null
                  ? DateTime.parse(
                      fechaRaw.toString(),
                    ).toLocal().toString().split('.')[0]
                  : 'Fecha desconocida';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Orden #${pedido['_id'].toString().substring(18)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            '\$${pedido['total']}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fecha: $fecha',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _obtenerColorEstado(estado).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _obtenerColorEstado(estado),
                          ),
                        ),
                        child: Text(
                          estado.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _obtenerColorEstado(estado),
                          ),
                        ),
                      ),
                      // Después del Container del estado agrega:
                      if (estado.toLowerCase() == 'entregado')
                        FutureBuilder<bool>(
                          future: ResenaService().verificarResena(
                            pedido['_id'],
                          ),
                          builder: (context, snapshot) {
                            final yaCalifico = snapshot.data ?? false;
                            if (yaCalifico) {
                              return const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Ya calificaste este pedido',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.amber.shade800,
                                  side: BorderSide(
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                                icon: const Icon(Icons.star_outline, size: 16),
                                label: const Text(
                                  'CALIFICAR VENDEDOR',
                                  style: TextStyle(fontSize: 12),
                                ),
                                onPressed: () =>
                                    _mostrarModalCalificacion(pedido),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  //Distiguir Vendedor de Comprador
  Widget _buildPanelVendedor() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Botón subir producto
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_a_photo),
              label: const Text(
                'SUBIR NUEVO PRODUCTO',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UploadProductScreen(),
                  ),
                ).then((_) => _cargarDatosCompletos());
              },
            ),
          ),
          const SizedBox(height: 16),
          // Botón ver mis productos
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text(
                'VER MIS PRODUCTOS',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyProductsScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Botón ver ventas
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.bar_chart_outlined),
              label: const Text(
                'MIS VENTAS',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MisVentasScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Variable para saber si el usuario ya tiene foto en la base de datos
    String fotoUrl = _datosUsuario?['fotoUrl'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MI PERFIL 👤',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -1.0),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => _cerrarSesion(context),
          ),
        ],
      ),
      body: SafeArea(
        child: _estaCargando
            ? const Center(
                child: CircularProgressIndicator(color: Colors.black),
              )
            : _mensajeError != null
            ? Center(
                child: Text(
                  _mensajeError!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // EL AVATAR CON LA FOTO REAL DE CLOUDINARY
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.black12,
                          backgroundImage: fotoUrl.isNotEmpty
                              ? NetworkImage(fotoUrl)
                              : null,
                          child: fotoUrl.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.black,
                                )
                              : null,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          '¡Hola, ${_datosUsuario?['nombre'] ?? 'Crack'}!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _datosUsuario?['email'] ?? 'correo@ejemplo.com',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 15),
                        //CALIFICACIÓN DEL VENDEDOR (solo visible si es marca)
                        if (_datosUsuario?['rol'] == 'marca') ...[
                          const SizedBox(height: 8),
                          FutureBuilder<List<dynamic>>(
                            future: ResenaService().obtenerResenasMarca(
                              _datosUsuario?['_id'] ?? '',
                            ),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return const Text(
                                  'Sin calificaciones aún ⭐',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 13,
                                  ),
                                );
                              }
                              final resenas = snapshot.data!;
                              final promedio =
                                  resenas.fold<double>(
                                    0,
                                    (sum, r) => sum + (r['estrellas'] ?? 0),
                                  ) /
                                  resenas.length;
                              return Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(5, (index) {
                                      return Icon(
                                        index < promedio.round()
                                            ? Icons.star
                                            : Icons.star_outline,
                                        color: Colors.amber,
                                        size: 20,
                                      );
                                    }),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${promedio.toStringAsFixed(1)} / 5.0  (${resenas.length} reseña${resenas.length == 1 ? '' : 's'})',
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
                        ],

                        // BOTÓN PARA ABRIR LA EDICIÓN
                        OutlinedButton.icon(
                          onPressed: _mostrarModalEdicion,
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Editar Perfil'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black,
                            side: const BorderSide(color: Colors.black),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // --- EL BOTÓN FANTASMA DEL ADMIN ---
                        // Solo se dibuja si el rol es 'admin' o 'marca'
                        if (_datosUsuario?['rol'] == 'admin')
                          ElevatedButton.icon(
                            onPressed: () {
                              // ¡EL VIAJE AL CUARTEL GENERAL!
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AdminPanelScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.admin_panel_settings),
                            label: const Text('PANEL DE CONTROL'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade800,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),

                        const SizedBox(height: 20),
                        const Divider(thickness: 1, color: Colors.black12),
                        const SizedBox(height: 10),
                        // Contenido según el rol
                        if (_datosUsuario?['rol'] == 'cliente') ...[
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24.0),
                              child: Text(
                                'Mis Compras 📦',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ] else if (_datosUsuario?['rol'] == 'marca') ...[
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24.0),
                              child: Text(
                                'Mi Tienda 🏪',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: _datosUsuario?['rol'] == 'marca'
                        ? _buildPanelVendedor()
                        : _buildHistorialPedidos(),
                  ),
                ],
              ),
      ),
    );
  }
}
