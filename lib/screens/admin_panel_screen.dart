import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/admin_service.dart';
import '../main_wrapper.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  late TabController _tabController;

  double _totalVendido = 0;
  double _gananciaHub = 0;
  double _pagarMarcas = 0;
  List<dynamic> _pedidos = [];
  bool _estaCargando = true;
  String? _mensajeError;
  List<dynamic> _clientes = [];
  List<dynamic> _marcas = [];
  bool _cargandoUsuarios = true;
  String _filtroUsuarios = 'clientes';
  List<dynamic> _todosProductos = [];
  bool _cargandoProductos = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _cargarTodosLosPedidos();
    _cargarUsuarios();
    _cargarTodosProductos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarTodosLosPedidos() async {
    try {
      final pedidos = await _adminService.obtenerTodosPedidosAdmin();
      double sumTotalVendido = 0;
      for (var p in pedidos) {
        String est = p['estado']?.toString().toLowerCase() ?? '';
        double total = (p['total'] ?? 0).toDouble();
        if (est.contains('aprobado') || est.contains('completado')) {
          sumTotalVendido += total;
        }
      }
      if (mounted) {
        setState(() {
          _pedidos = pedidos;
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

  Future<void> _cargarUsuarios() async {
    try {
      final data = await _adminService.obtenerTodosUsuarios();
      if (mounted) {
        setState(() {
          _clientes = data['clientes'] ?? [];
          _marcas = data['marcas'] ?? [];
          _cargandoUsuarios = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cargandoUsuarios = false);
    }
  }

  Future<void> _cerrarSesion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainWrapper()),
      (route) => false,
    );
  }

  Future<void> _cambiarEstado(String id, String nuevoEstado) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
    try {
      await _adminService.actualizarEstadoPedido(id, nuevoEstado);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pedido $nuevoEstado 🚀'),
          backgroundColor: Colors.black,
        ),
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

  Future<void> _aceptarMarca(String id, String nombre) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('¿Aceptar a $nombre?'),
        content: const Text(
          'Se le enviará un correo de bienvenida y podrá iniciar sesión.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ACEPTAR', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _adminService.aceptarMarca(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡$nombre aceptada! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
      _cargarUsuarios();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _cargarTodosProductos() async {
    try {
      final productos = await _adminService.obtenerTodosProductosAdmin();
      if (mounted) {
        setState(() {
          _todosProductos = productos;
          _cargandoProductos = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cargandoProductos = false);
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
    if (estado.toLowerCase().contains('aprobado') ||
        estado.toLowerCase().contains('completado')) return Colors.green;
    if (estado.toLowerCase().contains('rechazado')) return Colors.red;
    return Colors.grey;
  }

  Widget _crearTarjetaPlata(String titulo, double monto, Color color) {
    return Column(
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${monto.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  // ==========================================
  //         TAB 1 — CONTROL
  // ==========================================
  Widget _buildTabControl() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: const Border(bottom: BorderSide(color: Colors.black12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _crearTarjetaPlata('Vendido (100%)', _totalVendido, Colors.black),
              _crearTarjetaPlata('Tu Ganancia (5%)', _gananciaHub, Colors.green),
              _crearTarjetaPlata('Pagar Marcas', _pagarMarcas, Colors.red.shade700),
            ],
          ),
        ),
        Expanded(
          child: _pedidos.isEmpty
              ? const Center(
                  child: Text(
                    'No hay ventas todavía Jefe 💨',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pedidos.length,
                  itemBuilder: (context, index) {
                    final pedido = _pedidos[index];
                    final estado = pedido['estado'] ?? 'Pendiente Verificación';
                    final fechaRaw = pedido['fechaCreacion'];
                    final fecha = fechaRaw != null
                        ? DateTime.parse(fechaRaw.toString()).toLocal().toString().split('.')[0]
                        : 'Sin fecha';

                    List productosDelPedido = pedido['productos'] ?? [];
                    Set<String> infoMarcas = {};
                    for (var item in productosDelPedido) {
                      var prod = item['producto'];
                      if (prod != null) {
                        String nombreM = prod['marcaNombre'] ?? 'Desconocida';
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
                                Text(
                                  'Orden #${pedido['_id'].toString().substring(18)}',
                                  style: const TextStyle(fontWeight: FontWeight.w900),
                                ),
                                Text(
                                  '\$${pedido['total']}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
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
                              decoration: BoxDecoration(
                                color: _obtenerColorEstado(estado).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                estado.toUpperCase(),
                                style: TextStyle(
                                  color: _obtenerColorEstado(estado),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
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
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ==========================================
  //         TAB 2 — USUARIOS
  // ==========================================
  Widget _buildTabUsuarios() {
    final lista = _filtroUsuarios == 'clientes' ? _clientes : _marcas;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _filtroUsuarios = 'clientes'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _filtroUsuarios == 'clientes' ? Colors.black : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'CLIENTES (${_clientes.length})',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _filtroUsuarios == 'clientes' ? Colors.white : Colors.black,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _filtroUsuarios = 'vendedores'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _filtroUsuarios == 'vendedores' ? Colors.black : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'VENDEDORES (${_marcas.length})',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _filtroUsuarios == 'vendedores' ? Colors.white : Colors.black,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _cargandoUsuarios
              ? const Center(child: CircularProgressIndicator(color: Colors.black))
              : lista.isEmpty
                  ? const Center(child: Text('No hay usuarios aquí bro 💨'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: lista.length,
                      itemBuilder: (context, index) {
                        final usuario = lista[index];
                        final esVendedor = _filtroUsuarios == 'vendedores';
                        final nombre = esVendedor
                            ? (usuario['nombreMarca'] ?? 'Sin nombre')
                            : (usuario['nombre'] ?? 'Sin nombre');
                        final email = esVendedor
                            ? (usuario['correo'] ?? '')
                            : (usuario['email'] ?? '');
                        final estado = esVendedor
                            ? (usuario['estadoAprobacion'] ?? 'Pendiente')
                            : (usuario['estadoCuenta'] ?? 'activo');
                        final foto = usuario['fotoUrl'] ?? '';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: foto.isNotEmpty ? NetworkImage(foto) : null,
                              child: foto.isEmpty ? const Icon(Icons.person, color: Colors.black54) : null,
                            ),
                            title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(email, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _colorEstadoCuenta(estado).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _colorEstadoCuenta(estado)),
                              ),
                              child: Text(
                                estado.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _colorEstadoCuenta(estado),
                                ),
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Divider(),
                                    if (esVendedor) ...[
                                      _infoRow(Icons.badge_outlined, 'RUC: ${usuario['ruc'] ?? 'N/A'}'),
                                      _infoRow(Icons.alternate_email, 'Instagram: ${usuario['instagram'] ?? 'N/A'}'),
                                      _infoRow(
                                        Icons.calendar_today_outlined,
                                        'Solicitud: ${usuario['fechaSolicitud'] != null ? DateTime.parse(usuario['fechaSolicitud']).toLocal().toString().split(' ')[0] : 'N/A'}',
                                      ),
                                    ],
                                    if (!esVendedor) ...[
                                      _infoRow(Icons.person_outline, 'Usuario: ${usuario['nombre'] ?? 'N/A'}'),
                                      _infoRow(Icons.verified_user_outlined, 'Rol: ${usuario['rol'] ?? 'cliente'}'),
                                    ],
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        // BLOQUEAR
                                        if (estado != 'bloqueado' && estado != 'suspendido' &&
                                            estado != 'baneado' && estado != 'Suspendida')
                                          Expanded(
                                            child: OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.orange,
                                                side: const BorderSide(color: Colors.orange),
                                              ),
                                              onPressed: () => _confirmarAccionUsuario(
                                                usuario['_id'],
                                                esVendedor ? 'marca' : 'usuario',
                                                'bloqueado',
                                                nombre,
                                              ),
                                              child: const Text('BLOQUEAR', style: TextStyle(fontSize: 11)),
                                            ),
                                          ),
                                        const SizedBox(width: 6),
                                        // SUSPENDER
                                        if (estado != 'suspendido' && estado != 'baneado' && estado != 'Suspendida')
                                          Expanded(
                                            child: OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.purple,
                                                side: const BorderSide(color: Colors.purple),
                                              ),
                                              onPressed: () => _confirmarAccionUsuario(
                                                usuario['_id'],
                                                esVendedor ? 'marca' : 'usuario',
                                                'suspendido',
                                                nombre,
                                              ),
                                              child: const Text('SUSPENDER', style: TextStyle(fontSize: 11)),
                                            ),
                                          ),
                                        const SizedBox(width: 6),
                                        // BANEAR
                                        if (estado != 'baneado' && estado != 'Rechazada')
                                          Expanded(
                                            child: OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.red,
                                                side: const BorderSide(color: Colors.red),
                                              ),
                                              onPressed: () => _confirmarAccionUsuario(
                                                usuario['_id'],
                                                esVendedor ? 'marca' : 'usuario',
                                                'baneado',
                                                nombre,
                                              ),
                                              child: const Text('BANEAR', style: TextStyle(fontSize: 11)),
                                            ),
                                          ),
                                        // REACTIVAR
                                        if (estado == 'bloqueado' || estado == 'suspendido' ||
                                            estado == 'baneado' || estado == 'Suspendida' || estado == 'Rechazada')
                                          Expanded(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: () => _confirmarAccionUsuario(
                                                usuario['_id'],
                                                esVendedor ? 'marca' : 'usuario',
                                                'activo',
                                                nombre,
                                              ),
                                              child: const Text('REACTIVAR', style: TextStyle(fontSize: 11)),
                                            ),
                                          ),
                                        // ACEPTAR MARCA
                                        if (esVendedor && estado == 'Pendiente')
                                          Expanded(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: () => _aceptarMarca(usuario['_id'], nombre),
                                              child: const Text('ACEPTAR', style: TextStyle(fontSize: 11)),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Color _colorEstadoCuenta(String estado) {
    switch (estado.toLowerCase()) {
      case 'activo':
      case 'aceptada':
        return Colors.green;
      case 'bloqueado':
        return Colors.orange;
      case 'suspendido':
      case 'suspendida':
        return Colors.purple;
      case 'baneado':
      case 'rechazada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _infoRow(IconData icono, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icono, size: 14, color: Colors.black54),
          const SizedBox(width: 6),
          Expanded(child: Text(texto, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Future<void> _confirmarAccionUsuario(
    String id,
    String tipo,
    String accionTipo,
    String nombre,
  ) async {
    final motivoController = TextEditingController();
    final diasController = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_tituloAccion(accionTipo)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Usuario: $nombre'),
            const SizedBox(height: 12),
            if (accionTipo != 'activo') ...[
              TextField(
                controller: motivoController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Motivo *',
                  border: OutlineInputBorder(),
                ),
              ),
              if (accionTipo == 'suspendido') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: diasController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Días de suspensión (1-30) *',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              _tituloAccion(accionTipo),
              style: TextStyle(color: _colorAccion(accionTipo)),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    if (accionTipo != 'activo' && motivoController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes ingresar un motivo 🛑'), backgroundColor: Colors.red),
      );
      return;
    }

    if (accionTipo == 'suspendido') {
      final dias = int.tryParse(diasController.text.trim()) ?? 0;
      if (dias < 1 || dias > 30) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Los días deben ser entre 1 y 30 🛑'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    try {
      await _adminService.cambiarEstadoUsuario(
        tipo,
        id,
        accionTipo,
        motivo: motivoController.text.trim(),
        dias: accionTipo == 'suspendido' ? int.tryParse(diasController.text.trim()) : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$nombre: $accionTipo ✅'), backgroundColor: Colors.black),
      );
      _cargarUsuarios();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _tituloAccion(String accion) {
    switch (accion) {
      case 'bloqueado': return 'Bloquear';
      case 'suspendido': return 'Suspender';
      case 'baneado': return 'Banear';
      case 'activo': return 'Reactivar';
      default: return accion;
    }
  }

  Color _colorAccion(String accion) {
    switch (accion) {
      case 'bloqueado': return Colors.orange;
      case 'suspendido': return Colors.purple;
      case 'baneado': return Colors.red;
      case 'activo': return Colors.green;
      default: return Colors.black;
    }
  }

  // ==========================================
  //         TAB 3 — PRODUCTOS
  // ==========================================
  Widget _buildTabProductos() {
    return _cargandoProductos
        ? const Center(child: CircularProgressIndicator(color: Colors.black))
        : _todosProductos.isEmpty
            ? const Center(child: Text('No hay productos bro 💨'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _todosProductos.length,
                itemBuilder: (context, index) {
                  final producto = _todosProductos[index];
                  final imagenes = producto['imagenes'] as List?;
                  final urlImagen = (imagenes != null && imagenes.isNotEmpty)
                      ? imagenes[0].toString()
                      : '';
                  final oculto = producto['oculto'] ?? false;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: oculto ? Colors.grey.shade100 : Colors.white,
                      border: Border.all(color: oculto ? Colors.grey.shade300 : Colors.black12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                producto['nombre'] ?? '',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: oculto ? Colors.grey : Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                producto['marcaNombre'] ?? 'Sin marca',
                                style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '\$${producto['precio']}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              if (oculto)
                                const Text(
                                  'OCULTO',
                                  style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            IconButton(
                              icon: Icon(
                                oculto ? Icons.visibility : Icons.visibility_off,
                                color: oculto ? Colors.green : Colors.orange,
                                size: 20,
                              ),
                              tooltip: oculto ? 'Mostrar' : 'Ocultar',
                              onPressed: () async {
                                try {
                                  await _adminService.ocultarProducto(producto['_id'], !oculto);
                                  _cargarTodosProductos();
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              tooltip: 'Eliminar',
                              onPressed: () async {
                                final confirmar = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('¿Eliminar producto?'),
                                    content: const Text('Esta acción no se puede deshacer 🗑️'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmar != true) return;
                                try {
                                  await _adminService.eliminarProductoAdmin(producto['_id']);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Producto eliminado ✅'), backgroundColor: Colors.black),
                                  );
                                  _cargarTodosProductos();
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
  }

  // ==========================================
  //         TAB 4 — ESTADÍSTICAS
  // ==========================================
  Widget _buildTabEstadisticas() {
    final total = _pedidos.length;
    final aprobados = _pedidos
        .where((p) => p['estado']?.toString().toLowerCase().contains('aprobado') ?? false)
        .length;
    final rechazados = _pedidos
        .where((p) => p['estado']?.toString().toLowerCase().contains('rechazado') ?? false)
        .length;
    final pendientes = _pedidos
        .where((p) => p['estado']?.toString().toLowerCase().contains('pendiente') ?? false)
        .length;
    final entregados = _pedidos
        .where((p) => p['estado']?.toString().toLowerCase().contains('entregado') ?? false)
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RESUMEN FINANCIERO 💰',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _tarjetaEstadistica('Total Vendido', '\$${_totalVendido.toStringAsFixed(2)}', Icons.attach_money, Colors.black)),
              const SizedBox(width: 12),
              Expanded(child: _tarjetaEstadistica('Ganancia Hub', '\$${_gananciaHub.toStringAsFixed(2)}', Icons.trending_up, Colors.green)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _tarjetaEstadistica('Por Pagar', '\$${_pagarMarcas.toStringAsFixed(2)}', Icons.payment, Colors.red)),
              const SizedBox(width: 12),
              Expanded(child: _tarjetaEstadistica('Total Pedidos', '$total', Icons.shopping_bag_outlined, Colors.blue)),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'ESTADO DE PEDIDOS 📦',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 16),
          _barraEstado('Pendientes', pendientes, total, Colors.orange),
          const SizedBox(height: 10),
          _barraEstado('Aprobados', aprobados, total, Colors.amber),
          const SizedBox(height: 10),
          _barraEstado('Entregados', entregados, total, Colors.green),
          const SizedBox(height: 10),
          _barraEstado('Rechazados', rechazados, total, Colors.red),
          const SizedBox(height: 28),
          const Text(
            'TICKET PROMEDIO 🎯',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Promedio por pedido', style: TextStyle(color: Colors.white, fontSize: 14)),
                Text(
                  total > 0 ? '\$${(_totalVendido / total).toStringAsFixed(2)}' : '\$0.00',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaEstadistica(String titulo, String valor, IconData icono, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color, size: 24),
          const SizedBox(height: 8),
          Text(valor, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(titulo, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _barraEstado(String label, int cantidad, int total, Color color) {
    final porcentaje = total > 0 ? cantidad / total : 0.0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text('$cantidad pedidos', style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: porcentaje,
            minHeight: 10,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${(porcentaje * 100).toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PANEL ADMIN ⚙️',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -1.0),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              final confirmar = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('¿Cerrar sesión?'),
                  content: const Text('Volverás a la pantalla principal.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Salir', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirmar == true) _cerrarSesion();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.tune), text: 'CONTROL'),
            Tab(icon: Icon(Icons.people), text: 'USUARIOS'),
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'PRODUCTOS'),
            Tab(icon: Icon(Icons.bar_chart), text: 'ESTADÍSTICAS'),
          ],
        ),
      ),
      body: _estaCargando
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _mensajeError != null
              ? Center(
                  child: Text(
                    _mensajeError!,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTabControl(),
                    _buildTabUsuarios(),
                    _buildTabProductos(),
                    _buildTabEstadisticas(),
                  ],
                ),
    );
  }
}