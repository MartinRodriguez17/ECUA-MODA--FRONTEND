import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'dart:typed_data';

class MisVentasScreen extends StatefulWidget {
  const MisVentasScreen({super.key});

  @override
  State<MisVentasScreen> createState() => _MisVentasScreenState();
}

class _MisVentasScreenState extends State<MisVentasScreen> {
  List<dynamic> _ventas = [];
  bool _estaCargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarVentas();
  }

  Future<void> _cargarVentas() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      final response = await http.get(
        Uri.parse('http://localhost:4000/api/pedidos/mis-ventas'),
        headers: {'x-auth-token': token ?? ''},
      );

      if (response.statusCode == 200) {
        setState(() {
          _ventas = jsonDecode(response.body);
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

  Color _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'aprobado': return Colors.amber;
      case 'rechazado': return Colors.red;
      case 'entregado': return Colors.green;
      default: return Colors.blue;
    }
  }

  void _mostrarAccionesEstado(dynamic venta) {
    final estado = venta['estado'] ?? 'Pendiente Verificación';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ModalAcciones(
        venta: venta,
        estadoActual: estado,
        onActualizado: () {
          Navigator.pop(context);
          _cargarVentas();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MIS VENTAS 💰', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -1.0)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _estaCargando
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _ventas.isEmpty
                  ? const Center(
                      child: Text('Aún no tienes ventas bro 💨',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _ventas.length,
                      itemBuilder: (context, index) {
                        final venta = _ventas[index];
                        final estado = venta['estado'] ?? 'Pendiente Verificación';
                        final fecha = venta['fechaCreacion'] != null
                            ? DateTime.parse(venta['fechaCreacion']).toLocal().toString().split('.')[0]
                            : 'Fecha desconocida';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.black12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              // Header
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _colorEstado(estado).withOpacity(0.1),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Orden #${venta['_id'].toString().substring(18)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        Text(fecha, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _colorEstado(estado),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        estado.toUpperCase(),
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Info del comprador
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.person_outline, size: 16, color: Colors.black54),
                                        const SizedBox(width: 6),
                                        Text(venta['correoComprador'] ?? '', style: const TextStyle(fontSize: 13)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined, size: 16, color: Colors.black54),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(venta['direccionEnvio'] ?? '',
                                              style: const TextStyle(fontSize: 13), maxLines: 2),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.phone_outlined, size: 16, color: Colors.black54),
                                        const SizedBox(width: 6),
                                        Text(venta['telefonoComprador'] ?? '', style: const TextStyle(fontSize: 13)),
                                      ],
                                    ),
                                    const Divider(height: 20),

                                    // Productos
                                    ...((venta['productos'] as List? ?? []).map((item) {
                                      final prod = item['producto'];
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '${prod?['nombre'] ?? 'Producto'} - Talla ${item['talla']} x${item['cantidad']}',
                                                style: const TextStyle(fontSize: 13),
                                              ),
                                            ),
                                            Text('\$${item['precio']}',
                                                style: const TextStyle(fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      );
                                    })),

                                    const Divider(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text('\$${venta['total']?.toStringAsFixed(2)}',
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Botones de acción
                                    if (estado == 'Pendiente Verificación')
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.amber,
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: () => _mostrarAccionesEstado(venta),
                                              child: const Text('GESTIONAR', style: TextStyle(fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (estado == 'Aprobado')
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () => _mostrarAccionesEstado(venta),
                                          child: const Text('MARCAR ENTREGADO', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                  ],
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

// --- MODAL DE ACCIONES ---
class _ModalAcciones extends StatefulWidget {
  final dynamic venta;
  final String estadoActual;
  final VoidCallback onActualizado;

  const _ModalAcciones({
    required this.venta,
    required this.estadoActual,
    required this.onActualizado,
  });

  @override
  State<_ModalAcciones> createState() => _ModalAccionesState();
}

class _ModalAccionesState extends State<_ModalAcciones> {
  final TextEditingController _motivoController = TextEditingController();
  final TextEditingController _rastreoController = TextEditingController();
  XFile? _fotoEnvio;
  Uint8List? _fotoBytes;
  bool _cargando = false;

  Future<void> _seleccionarFoto() async {
    final picker = ImagePicker();
    final foto = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (foto != null) {
      final bytes = await foto.readAsBytes();
      setState(() {
        _fotoEnvio = foto;
        _fotoBytes = bytes;
      });
    }
  }

  Future<void> _actualizarEstado(String nuevoEstado) async {
    setState(() => _cargando = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('http://localhost:4000/api/pedidos/${widget.venta['_id']}/estado'),
      );

      request.headers['x-auth-token'] = token ?? '';
      request.fields['estado'] = nuevoEstado;

      if (_motivoController.text.isNotEmpty) {
        request.fields['motivoRechazo'] = _motivoController.text.trim();
      }
      if (_rastreoController.text.isNotEmpty) {
        request.fields['numeroRastreo'] = _rastreoController.text.trim();
      }
      if (_fotoEnvio != null && _fotoBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'fotoEnvio', _fotoBytes!, filename: _fotoEnvio!.name,
        ));
      }

      final response = await request.send();
      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pedido $nuevoEstado ✅'), backgroundColor: Colors.green),
        );
        widget.onActualizado();
      } else {
        throw 'Error al actualizar';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esPendiente = widget.estadoActual == 'Pendiente Verificación';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24, right: 24, top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              esPendiente ? 'GESTIONAR PEDIDO 📦' : 'MARCAR COMO ENTREGADO 🎉',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 20),

            if (esPendiente) ...[
              // APROBADO
              const Text('Número de rastreo', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _rastreoController,
                decoration: const InputDecoration(
                  hintText: 'Ej: EC123456789',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Foto de envío
              const Text('Foto del comprobante de envío (opcional)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _seleccionarFoto,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black26),
                  ),
                  child: _fotoBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(_fotoBytes!, fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, color: Colors.black54),
                            Text('Agregar foto', style: TextStyle(color: Colors.black54)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.white),
                onPressed: _cargando ? null : () => _actualizarEstado('Aprobado'),
                child: _cargando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('✅ APROBAR PEDIDO', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),

              // RECHAZADO
              const Text('Motivo de rechazo', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _motivoController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Ej: Comprobante no válido, monto incorrecto...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                onPressed: _cargando ? null : () {
                  if (_motivoController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Escribe el motivo del rechazo 🛑'), backgroundColor: Colors.orange),
                    );
                    return;
                  }
                  _actualizarEstado('Rechazado');
                },
                child: const Text('❌ RECHAZAR PEDIDO', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],

            if (!esPendiente) ...[
              const Text(
                '¿Confirmas que el pedido fue entregado al cliente?',
                style: TextStyle(fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                onPressed: _cargando ? null : () => _actualizarEstado('Entregado'),
                child: _cargando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('📦 CONFIRMAR ENTREGA', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}