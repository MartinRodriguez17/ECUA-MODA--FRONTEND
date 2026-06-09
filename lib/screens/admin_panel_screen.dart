// Archivo: lib/screens/admin_panel_screen.dart
import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final AdminService _adminService = AdminService();
  
  // VARIABLES FINANCIERAS REALISTAS
  double _totalVendido = 0;
  double _gananciaHub = 0;
  double _pagarMarcas = 0;
  
  List<dynamic> _pedidos = [];
  bool _estaCargando = true;
  String? _mensajeError;

  @override
  void initState() {
    super.initState();
    _cargarTodosLosPedidos();
  }

  Future<void> _cargarTodosLosPedidos() async {
    try {
      final pedidos = await _adminService.obtenerTodosPedidosAdmin();
      
      double sumTotalVendido = 0;
      
      for (var p in pedidos) {
        String est = p['estado']?.toString().toLowerCase() ?? '';
        double total = (p['total'] ?? 0).toDouble();
        
        // Solo sumamos la plata de los pedidos que ya aprobaste
        if (est.contains('aprobado') || est.contains('completado')) {
          sumTotalVendido += total;
        } 
      }

      if (mounted) {
        setState(() {
          _pedidos = pedidos;
          // CÁLCULOS DEL CEO (5% para ti, 95% para las marcas)
          _totalVendido = sumTotalVendido;
          _gananciaHub = sumTotalVendido * 0.05; 
          _pagarMarcas = sumTotalVendido * 0.95;
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

  Future<void> _cambiarEstado(String id, String nuevoEstado) async {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      await _adminService.actualizarEstadoPedido(id, nuevoEstado);
      if (!mounted) return;
      
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pedido $nuevoEstado 🚀'), backgroundColor: Colors.black),
      );
      
      setState(() => _estaCargando = true);
      _cargarTodosLosPedidos();

    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  void _verComprobante(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Color _obtenerColorEstado(String estado) {
    if (estado.toLowerCase().contains('pendiente')) return Colors.orange;
    if (estado.toLowerCase().contains('aprobado') || estado.toLowerCase().contains('completado')) return Colors.green;
    if (estado.toLowerCase().contains('rechazado')) return Colors.red;
    return Colors.grey;
  }

  Widget _crearTarjetaPlata(String titulo, double monto, Color color) {
    return Column(
      children: [
        Text(titulo, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 4),
        Text('\$${monto.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PANEL DE CONTROL ⚙️', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _estaCargando
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _mensajeError != null
              ? Center(child: Text(_mensajeError!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))
              : Column(
                  children: [
                    // --- TARJETAS FINANCIERAS REALISTAS ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: const Border(bottom: BorderSide(color: Colors.black12))
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _crearTarjetaPlata('Vendido (100%)', _totalVendido, Colors.black),
                          _crearTarjetaPlata('Tu Ganancia (5%)', _gananciaHub, Colors.green),
                          _crearTarjetaPlata('Pagar a Marcas', _pagarMarcas, Colors.red.shade700),
                        ],
                      ),
                    ),
                    
                    // --- LA LISTA DE PEDIDOS ---
                    Expanded(
                      child: _pedidos.isEmpty
                          ? const Center(child: Text('No hay ventas todavía Jefe 💨', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _pedidos.length,
                              itemBuilder: (context, index) {
                                final pedido = _pedidos[index];
                                final estado = pedido['estado'] ?? 'Pendiente Verificación';
                                final fechaRaw = pedido['fechaCreacion'];
                                final fecha = fechaRaw != null ? DateTime.parse(fechaRaw.toString()).toLocal().toString().split('.')[0] : 'Sin fecha';

                                // --- EXTRACCIÓN DE DATOS DE LA MARCA PARA PAGARLES ---
                                List productosDelPedido = pedido['productos'] ?? [];
                                Set<String> infoMarcas = {};
                                
                                for (var item in productosDelPedido) {
                                  var prod = item['producto'];
                                  if (prod != null) {
                                    String nombreM = prod['marcaNombre'] ?? 'Desconocida';
                                    // Sacamos el correo del usuario dueño de la ropa
                                    String contactoM = prod['marcaId']?['email'] ?? 'Sin contacto'; 
                                    infoMarcas.add('$nombreM ($contactoM)');
                                  }
                                }
                                String marcasTexto = infoMarcas.isNotEmpty ? infoMarcas.join('\n') : 'Desconocida';

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Orden #${pedido['_id'].toString().substring(18)}', style: const TextStyle(fontWeight: FontWeight.w900)),
                                            Text('\$${pedido['total']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.green)),
                                          ],
                                        ),
                                        const Divider(),
                                        // AQUÍ MOSTRAMOS LA MARCA Y SU CORREO
                                        const Text('Debe pagarse a:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                        Text(marcasTexto, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey)),
                                        
                                        const SizedBox(height: 10),
                                        Text('Comprador: ${pedido['correoComprador']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text('Telf: ${pedido['telefonoComprador']}'),
                                        Text('Envío: ${pedido['direccionEnvio']}'),
                                        Text('Fecha: $fecha', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                        const SizedBox(height: 10),
                                        
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(color: _obtenerColorEstado(estado).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                          child: Text(estado.toUpperCase(), style: TextStyle(color: _obtenerColorEstado(estado), fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                        const SizedBox(height: 15),

                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.receipt_long, color: Colors.blue),
                                              tooltip: 'Ver Comprobante',
                                              onPressed: () => _verComprobante(pedido['comprobantePagoUrl']),
                                            ),
                                            if (estado.toLowerCase() == 'pendiente verificación')
                                              ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                                onPressed: () => _cambiarEstado(pedido['_id'], 'Aprobado'),
                                                icon: const Icon(Icons.check, size: 16),
                                                label: const Text('Aprobar'),
                                              ),
                                            if (estado.toLowerCase() == 'pendiente verificación')
                                              ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                                onPressed: () => _cambiarEstado(pedido['_id'], 'Rechazado'),
                                                icon: const Icon(Icons.close, size: 16),
                                                label: const Text('Rechazar'),
                                              ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}