// Archivo: lib/screens/cart_screen.dart
// Esta pantalla muestra el contenido del carrito, permite modificar cantidades, eliminar productos y proceder al pago.
// Aquí es donde el usuario hace clic en "Proceder al Pago" y se le pide la dirección y teléfono antes de ir a la pantalla de pago.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../services/cart_provider.dart';
import '../services/auth_service.dart'; // <-- IMPORTAMOS EL SERVICIO
import 'payment_screen.dart';
import 'login_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  
  final AuthService _authService = AuthService(); // <-- INSTANCIAMOS EL SERVICIO

  // --- CANDADO MEJORADO: AHORA SACA EL CORREO REAL ---
  Future<void> _verificarSesionYProceder(CartProvider carrito) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bro, inicia sesión o regístrate para comprar 🛑'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    } else {
      // 1. Ponemos un mini circulito de carga mientras Node.js nos da el correo
      showDialog(
        context: context, 
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)),
      );

      try {
        // 2. Pedimos tus datos reales a la base de datos
        final datosPerfil = await _authService.obtenerDatosPerfil();
        final String correoReal = datosPerfil['email']; 

        if (!mounted) return;
        Navigator.pop(context); // Quitamos el circulito de carga

        // 3. Abrimos el formulario de envío, pero ahora le pasamos tu correo real
        _mostrarFormularioEnvio(carrito, correoReal);
      } catch (error) {
        if (!mounted) return;
        Navigator.pop(context); // Quitamos el circulito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al leer tu perfil: $error'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Fíjate que ahora la función recibe el correo real como parámetro
  void _mostrarFormularioEnvio(CartProvider carrito, String correoReal) {
  _direccionController.clear();
  _telefonoController.clear();

  // Controladores nuevos
  final callePrimariaController = TextEditingController();
  final calleSecundariaController = TextEditingController();
  final numeroViviendaController = TextEditingController();
  final referenciaController = TextEditingController();
  String? tipoVivienda;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      String? errorCallePrimaria;
      String? errorCalleSecundaria;
      String? errorNumero;
      String? errorTelefono;
      String? errorTipoVivienda;

      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24, right: 24, top: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '¿A DÓNDE LO ENVIAMOS? 📦',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 20),

                  // CALLE PRIMARIA
                  TextField(
                    controller: callePrimariaController,
                    maxLength: 60,
                    decoration: InputDecoration(
                      labelText: 'Calle Principal',
                      hintText: 'Ej: Av. 6 de Diciembre',
                      border: const OutlineInputBorder(),
                      errorText: errorCallePrimaria,
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CALLE SECUNDARIA
                  TextField(
                    controller: calleSecundariaController,
                    maxLength: 60,
                    decoration: InputDecoration(
                      labelText: 'Calle Secundaria / Intersección',
                      hintText: 'Ej: y Patria',
                      border: const OutlineInputBorder(),
                      errorText: errorCalleSecundaria,
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // TIPO DE VIVIENDA
                  DropdownButtonFormField<String>(
                    value: tipoVivienda,
                    decoration: InputDecoration(
                      labelText: 'Tipo de Vivienda',
                      border: const OutlineInputBorder(),
                      errorText: errorTipoVivienda,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Casa', child: Text('🏠 Casa')),
                      DropdownMenuItem(value: 'Departamento', child: Text('🏢 Departamento')),
                      DropdownMenuItem(value: 'Oficina', child: Text('💼 Oficina')),
                    ],
                    onChanged: (value) {
                      setModalState(() => tipoVivienda = value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // NÚMERO / PISO
                  TextField(
                    controller: numeroViviendaController,
                    maxLength: 10,
                    decoration: InputDecoration(
                      labelText: 'Número / Piso',
                      hintText: 'Ej: 304 o Piso 3',
                      border: const OutlineInputBorder(),
                      errorText: errorNumero,
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // REFERENCIA
                  TextField(
                    controller: referenciaController,
                    maxLength: 80,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Referencia (opcional)',
                      hintText: 'Ej: Frente al parque, casa azul',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // TELÉFONO
                  TextField(
                    controller: _telefonoController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 10,
                    decoration: InputDecoration(
                      labelText: 'Número de Teléfono',
                      hintText: 'Ej: 0991234567',
                      border: const OutlineInputBorder(),
                      errorText: errorTelefono,
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // BOTÓN CONTINUAR
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        setModalState(() {
                          // Validaciones
                          final callePrimaria = callePrimariaController.text.trim();
                          errorCallePrimaria = callePrimaria.isEmpty
                              ? 'Ingresa la calle principal'
                              : callePrimaria.length < 3
                                  ? 'Sé más específico'
                                  : null;

                          final calleSecundaria = calleSecundariaController.text.trim();
                          errorCalleSecundaria = calleSecundaria.isEmpty
                              ? 'Ingresa la calle secundaria'
                              : null;

                          errorTipoVivienda = tipoVivienda == null
                              ? 'Selecciona el tipo de vivienda'
                              : null;

                          final numero = numeroViviendaController.text.trim();
                          errorNumero = numero.isEmpty
                              ? 'Ingresa el número o piso'
                              : null;

                          final telefono = _telefonoController.text.trim();
                          errorTelefono = telefono.isEmpty
                              ? 'Ingresa tu teléfono'
                              : telefono.length != 10
                                  ? 'Debe tener 10 dígitos'
                                  : !telefono.startsWith('0')
                                      ? 'Debe empezar con 0'
                                      : null;
                        });

                        if (errorCallePrimaria != null ||
                            errorCalleSecundaria != null ||
                            errorTipoVivienda != null ||
                            errorNumero != null ||
                            errorTelefono != null) return;

                        // Armamos la dirección completa para enviar
                        final direccionCompleta =
                            '${callePrimariaController.text.trim()} y '
                            '${calleSecundariaController.text.trim()}, '
                            '$tipoVivienda ${numeroViviendaController.text.trim()}'
                            '${referenciaController.text.trim().isNotEmpty ? ' - Ref: ${referenciaController.text.trim()}' : ''}';

                        Navigator.pop(context);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentScreen(
                              correo: correoReal,
                              direccion: direccionCompleta, // 👈 dirección completa armada
                              telefono: _telefonoController.text.trim(),
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'CONTINUAR AL PAGO',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('TU BOLSITA 🛍️', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -1.0)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: carrito.items.isEmpty
          ? const Center(
              child: Text('Tu carrito está más vacío que mi billetera bro 💨', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: carrito.items.length,
                    itemBuilder: (context, index) {
                      final item = carrito.items[index];
                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red.shade800,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                        ),
                        onDismissed: (direction) {
                          Provider.of<CartProvider>(context, listen: false).eliminarDelCarrito(item.id);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.black12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(image: NetworkImage(item.imagen), fit: BoxFit.cover),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text('Talla: ${item.talla}', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text('\$${item.precio}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(20)),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 16),
                                      onPressed: () => Provider.of<CartProvider>(context, listen: false).restarCantidad(item.id),
                                    ),
                                    Text('${item.cantidad}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 16),
                                      onPressed: () => Provider.of<CartProvider>(context, listen: false).sumarCantidad(item.id),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black12))),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
                            Text('\$${carrito.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('IVA (15%)', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
                            Text('\$${carrito.impuestosIva.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(height: 24, thickness: 1),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('TOTAL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                            Text('\$${carrito.totalFinal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                            onPressed: () => _verificarSesionYProceder(carrito),
                            child: const Text('PROCEDER AL PAGO', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}