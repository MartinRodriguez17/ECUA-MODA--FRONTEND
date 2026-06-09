// Archivo: lib/screens/payment_screen.dart
// Esta pantalla es el paso final del proceso de compra, donde el usuario sube la foto 
//de su transferencia bancaria.
// Aquí es donde se integra la lógica de subir la imagen al backend junto con los datos del pedido.
// Archivo: lib/screens/payment_screen.dart
import 'dart:typed_data'; // <-- Reemplazamos dart:io por esto
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/cart_provider.dart';
import '../services/order_service.dart';

class PaymentScreen extends StatefulWidget {
  final String correo;
  final String direccion;
  final String telefono;

  const PaymentScreen({
    super.key,
    required this.correo,
    required this.direccion,
    required this.telefono,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Uint8List? _imagenBytes; // <-- Aquí guardamos la foto en memoria (apto para Web)
  String? _nombreArchivo;  // <-- Guardamos el nombre ("foto.jpg")
  
  final ImagePicker _picker = ImagePicker();
  final OrderService _orderService = OrderService();
  bool _estaProcesando = false;

  Future<void> _seleccionarComprobante() async {
    try {
      final XFile? imagenSeleccionada = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, 
      );

      if (imagenSeleccionada != null) {
        // Leemos la imagen como bytes de memoria (Funciona en Web, Android y iOS)
        final bytes = await imagenSeleccionada.readAsBytes();
        
        setState(() {
          _imagenBytes = bytes;
          _nombreArchivo = imagenSeleccionada.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bro, hubo un error al abrir la galería 🛑'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _confirmarPago(CartProvider carrito) async {
    if (_imagenBytes == null || _nombreArchivo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bro, tienes que subir la foto de la transferencia 📸'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _estaProcesando = true);

    try {
      // Mandamos los bytes y el nombre al servicio
      await _orderService.crearOrden(
        items: carrito.items,
        subtotal: carrito.subtotal,
        iva: carrito.impuestosIva,
        total: carrito.totalFinal,
        correo: widget.correo,
        direccion: widget.direccion,
        telefono: widget.telefono,
        comprobanteBytes: _imagenBytes!,
        nombreArchivo: _nombreArchivo!,
      );

      if (!mounted) return;

      carrito.vaciarCarrito();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Pago recibido! El admin verificará tu depósito en breve 🏦🔥'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );

      Navigator.of(context).popUntil((route) => route.isFirst);

    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error ❌'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _estaProcesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('PAGO SEGURO 🔒', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -1.0)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.account_balance, color: Colors.white, size: 50),
                    const SizedBox(height: 10),
                    const Text('BANCO PICHINCHA', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(height: 15),
                    const Text('Cuenta de Ahorros', style: TextStyle(color: Colors.white70)),
                    const Text('2200001234', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 4)),
                    const SizedBox(height: 15),
                    const Text('Titular: Hub Moda Urbana S.A.', style: TextStyle(color: Colors.white70)),
                    const Divider(color: Colors.white30, height: 30),
                    Text('Total a transferir: \$${carrito.totalFinal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.greenAccent, fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              const Text('Adjunta tu comprobante', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),

              GestureDetector(
                onTap: _estaProcesando ? null : _seleccionarComprobante,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: _imagenBytes == null ? Colors.grey.shade400 : Colors.black, width: 2, style: BorderStyle.solid),
                  ),
                  child: _imagenBytes == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 60, color: Colors.black54),
                            SizedBox(height: 10),
                            Text('Toca para abrir tus archivos', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          // --- EL PARCHE MULTIPLATAFORMA ---
                          // Muestra la imagen directamente de la memoria, sin que la web se ponga a llorar
                          child: Image.memory(_imagenBytes!, fit: BoxFit.cover, width: double.infinity),
                        ),
                ),
              ),
              const SizedBox(height: 40),

              SizedBox(
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                  onPressed: _estaProcesando ? null : () => _confirmarPago(carrito),
                  child: _estaProcesando
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('CONFIRMAR DEPÓSITO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}