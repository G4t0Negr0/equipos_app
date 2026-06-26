import 'package:flutter/material.dart';
import 'models/equipo.dart';
import 'services/equipo_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Equipos LAMYG',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ),
      home: const ListaEquiposScreen(),
    );
  }
}

// ==================== PANTALLA LISTA ====================

class ListaEquiposScreen extends StatefulWidget {
  const ListaEquiposScreen({super.key});

  @override
  State<ListaEquiposScreen> createState() => _ListaEquiposScreenState();
}

class _ListaEquiposScreenState extends State<ListaEquiposScreen> {
  final EquipoService _service = EquipoService();
  List<Equipo> _todosEquipos = [];
  List<Equipo> _equiposFiltrados = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarEquipos();
  }

  Future<void> _cargarEquipos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final equipos = await _service.obtenerEquipos();
      setState(() {
        _todosEquipos = equipos;
        _equiposFiltrados = equipos;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  void _filtrarEquipos(String texto) {
    setState(() {
      if (texto.isEmpty) {
        _equiposFiltrados = _todosEquipos;
      } else {
        _equiposFiltrados = _todosEquipos.where((equipo) {
          final nombre = equipo.nombre.toLowerCase();
          final codigo = equipo.codigo.toLowerCase();
          final buscar = texto.toLowerCase();
          return nombre.contains(buscar) || codigo.contains(buscar);
        }).toList();
      }
    });
  }

  Color _colorEstado(String? fechaProxima) {
    if (fechaProxima == null) return const Color(0xFFBDBDBD);
    final fecha = DateTime.tryParse(fechaProxima);
    if (fecha == null) return const Color(0xFFBDBDBD);
    final dias = fecha.difference(DateTime.now()).inDays;
    if (dias < 0) return const Color(0xFFE53935);
    if (dias <= 60) return const Color(0xFFFFA726);
    return const Color(0xFF43A047);
  }

  String _textoEstado(String? fechaProxima) {
    if (fechaProxima == null) return 'Sin fecha';
    final fecha = DateTime.tryParse(fechaProxima);
    if (fecha == null) return 'Sin fecha';
    final dias = fecha.difference(DateTime.now()).inDays;
    if (dias < 0) return 'VENCIDO';
    if (dias <= 60) return 'Vence en $dias días';
    return 'Vigente ($dias días)';
  }

  Color _colorTextoEstado(String? fechaProxima) {
    if (fechaProxima == null) return const Color(0xFF757575);
    final fecha = DateTime.tryParse(fechaProxima);
    if (fecha == null) return const Color(0xFF757575);
    final dias = fecha.difference(DateTime.now()).inDays;
    if (dias < 0) return const Color(0xFFE53935);
    if (dias <= 60) return const Color(0xFFE65100);
    return const Color(0xFF2E7D32);
  }

  void _irAFormulario() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FormularioEquipoScreen()),
    ).then((resultado) {
      if (resultado == true) _cargarEquipos();
    });
  }

  void _irADetalle(Equipo equipo) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetalleEquipoScreen(equipo: equipo)),
    ).then((resultado) {
      if (resultado == true) _cargarEquipos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header con gradiente
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF0D47A1),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0D47A1),
                      Color(0xFF1565C0),
                      Color(0xFF1E88E5),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.precision_manufacturing,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'LAMYG',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                                Text(
                                  'Gestión de Equipos',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Barra de búsqueda y leyenda
          SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o código...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onChanged: _filtrarEquipos,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildLeyenda(const Color(0xFF43A047), 'Vigente'),
                      _buildLeyenda(const Color(0xFFFFA726), 'Por vencer'),
                      _buildLeyenda(const Color(0xFFE53935), 'Vencido'),
                      _buildLeyenda(const Color(0xFFBDBDBD), 'Sin fecha'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        '${_equiposFiltrados.length} equipos',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          // Lista de equipos
          _cargando
              ? const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
              : _error != null
              ? SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No se pudo conectar',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: _cargarEquipos,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          )
              : _equiposFiltrados.isEmpty
              ? SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No se encontraron equipos',
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
          )
              : SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final equipo = _equiposFiltrados[index];
                final color = _colorEstado(equipo.fechaProximaCalibracion);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _irADetalle(equipo),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.precision_manufacturing,
                                color: color,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    equipo.nombre,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    equipo.codigo,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _textoEstado(equipo.fechaProximaCalibracion),
                                    style: TextStyle(
                                      color: _colorTextoEstado(equipo.fechaProximaCalibracion),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Icon(Icons.chevron_right, color: Colors.grey.shade300, size: 20),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              childCount: _equiposFiltrados.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _irAFormulario,
        backgroundColor: const Color(0xFF0D47A1),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nuevo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildLeyenda(Color color, String texto) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(texto, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}

// ==================== PANTALLA DETALLE ====================

class DetalleEquipoScreen extends StatelessWidget {
  final Equipo equipo;

  const DetalleEquipoScreen({super.key, required this.equipo});

  Color _colorEstado(String? fechaProxima) {
    if (fechaProxima == null) return const Color(0xFFBDBDBD);
    final fecha = DateTime.tryParse(fechaProxima);
    if (fecha == null) return const Color(0xFFBDBDBD);
    final dias = fecha.difference(DateTime.now()).inDays;
    if (dias < 0) return const Color(0xFFE53935);
    if (dias <= 60) return const Color(0xFFFFA726);
    return const Color(0xFF43A047);
  }

  String _textoEstado(String? fechaProxima) {
    if (fechaProxima == null) return 'Sin fecha';
    final fecha = DateTime.tryParse(fechaProxima);
    if (fecha == null) return 'Sin fecha';
    final dias = fecha.difference(DateTime.now()).inDays;
    if (dias < 0) return 'VENCIDO';
    if (dias <= 60) return 'Vence en $dias días';
    return 'Vigente ($dias días)';
  }

  void _confirmarEliminar(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935)),
            SizedBox(width: 8),
            Text('Eliminar equipo'),
          ],
        ),
        content: Text('¿Estás seguro de eliminar "${equipo.nombre}" (${equipo.codigo})?\n\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _eliminarEquipo(context);
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _eliminarEquipo(BuildContext context) async {
    final service = EquipoService();
    try {
      final exito = await service.eliminarEquipo(equipo.codigo);
      if (context.mounted) {
        if (exito) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Equipo eliminado'),
              backgroundColor: const Color(0xFF43A047),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Error al eliminar'),
              backgroundColor: const Color(0xFFE53935),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorEstado(equipo.fechaProximaCalibracion);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: const Color(0xFF0D47A1),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1E88E5)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          equipo.nombre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                equipo.codigo,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _textoEstado(equipo.fechaProximaCalibracion),
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  final resultado = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditarEquipoScreen(equipo: equipo),
                    ),
                  );
                  if (resultado == true && context.mounted) {
                    Navigator.pop(context, true);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmarEliminar(context),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSeccion('Información General', [
                    _buildCampo(Icons.build_outlined, 'Nombre', equipo.nombre),
                    _buildCampo(Icons.qr_code, 'Código', equipo.codigo),
                    _buildCampo(Icons.business_outlined, 'Marca', equipo.marca),
                    _buildCampo(Icons.numbers, 'Número de serie', equipo.numeroSerie),
                    _buildCampo(Icons.straighten, 'Rango / Capacidad', equipo.rangoCapacidad),
                  ]),
                  const SizedBox(height: 16),
                  _buildSeccion('Calibración', [
                    _buildCampo(Icons.calendar_today_outlined, 'Última calibración', equipo.fechaCalibracion),
                    _buildCampo(Icons.event_outlined, 'Próxima calibración', equipo.fechaProximaCalibracion),
                    _buildCampo(Icons.engineering_outlined, 'Calibrado por', equipo.calibradoPor),
                  ]),
                  const SizedBox(height: 16),
                  _buildSeccion('Responsabilidad', [
                    _buildCampo(Icons.person_outline, 'Responsable', equipo.responsable),
                    _buildCampo(Icons.info_outline, 'Estado', equipo.estado),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccion(String titulo, List<Widget> campos) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              titulo,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D47A1),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Divider(height: 1),
          ...campos,
        ],
      ),
    );
  }

  Widget _buildCampo(IconData icono, String label, String? valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icono, size: 20, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                const SizedBox(height: 2),
                Text(
                  valor ?? 'N/A',
                  style: TextStyle(
                    fontSize: 15,
                    color: valor != null ? Colors.black87 : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== PANTALLA FORMULARIO ====================

class FormularioEquipoScreen extends StatefulWidget {
  const FormularioEquipoScreen({super.key});

  @override
  State<FormularioEquipoScreen> createState() => _FormularioEquipoScreenState();
}

class _FormularioEquipoScreenState extends State<FormularioEquipoScreen> {
  final _formKey = GlobalKey<FormState>();
  final EquipoService _service = EquipoService();
  bool _guardando = false;

  final _nombreController = TextEditingController();
  final _codigoController = TextEditingController();
  final _marcaController = TextEditingController();
  final _serieController = TextEditingController();
  final _rangoController = TextEditingController();
  final _responsableController = TextEditingController();
  final _calibradorController = TextEditingController();

  DateTime? _fechaCalibracion;
  DateTime? _fechaProximaCalibracion;

  @override
  void dispose() {
    _nombreController.dispose();
    _codigoController.dispose();
    _marcaController.dispose();
    _serieController.dispose();
    _rangoController.dispose();
    _responsableController.dispose();
    _calibradorController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha(BuildContext context, bool esProxima) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: esProxima ? 'Próxima calibración' : 'Fecha de calibración',
    );
    if (fecha != null) {
      setState(() {
        if (esProxima) {
          _fechaProximaCalibracion = fecha;
        } else {
          _fechaCalibracion = fecha;
        }
      });
    }
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'Seleccionar fecha';
    return '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
  }

  Future<void> _guardarEquipo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final datos = {
        'nombre': _nombreController.text,
        'codigo': _codigoController.text,
        'marca': _marcaController.text.isEmpty ? null : _marcaController.text,
        'numero_serie': _serieController.text.isEmpty ? null : _serieController.text,
        'rango_capacidad': _rangoController.text.isEmpty ? null : _rangoController.text,
        'responsable': _responsableController.text.isEmpty ? null : _responsableController.text,
        'calibrado_por': _calibradorController.text.isEmpty ? null : _calibradorController.text,
        'fecha_calibracion': _fechaCalibracion != null ? _formatearFecha(_fechaCalibracion) : null,
        'fecha_proxima_calibracion': _fechaProximaCalibracion != null ? _formatearFecha(_fechaProximaCalibracion) : null,
      };
      final exito = await _service.crearEquipo(datos);
      if (exito && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Equipo registrado exitosamente'),
            backgroundColor: const Color(0xFF43A047),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al registrar el equipo'),
            backgroundColor: const Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFE53935)),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  InputDecoration _inputDeco(String label, IconData icono, {bool requerido = false}) {
    return InputDecoration(
      labelText: requerido ? '$label *' : label,
      prefixIcon: Icon(icono, color: const Color(0xFF0D47A1)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2)),
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Equipo'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: _inputDeco('Nombre del equipo', Icons.build_outlined, requerido: true),
                validator: (v) => v == null || v.isEmpty ? 'El nombre es obligatorio' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _codigoController,
                decoration: _inputDeco('Código', Icons.qr_code, requerido: true),
                validator: (v) => v == null || v.isEmpty ? 'El código es obligatorio' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(controller: _marcaController, decoration: _inputDeco('Marca', Icons.business_outlined)),
              const SizedBox(height: 14),
              TextFormField(controller: _serieController, decoration: _inputDeco('Número de serie', Icons.numbers)),
              const SizedBox(height: 14),
              TextFormField(controller: _rangoController, decoration: _inputDeco('Rango / Capacidad', Icons.straighten)),
              const SizedBox(height: 14),
              TextFormField(controller: _responsableController, decoration: _inputDeco('Responsable', Icons.person_outline)),
              const SizedBox(height: 14),
              TextFormField(controller: _calibradorController, decoration: _inputDeco('Calibrado por', Icons.engineering_outlined)),
              const SizedBox(height: 14),
              _buildFechaTile(Icons.calendar_today_outlined, 'Fecha de calibración', _fechaCalibracion, () => _seleccionarFecha(context, false)),
              const SizedBox(height: 14),
              _buildFechaTile(Icons.event_outlined, 'Próxima calibración', _fechaProximaCalibracion, () => _seleccionarFecha(context, true)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _guardando ? null : _guardarEquipo,
        backgroundColor: const Color(0xFF0D47A1),
        icon: _guardando
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.save, color: Colors.white),
        label: Text(
          _guardando ? 'Guardando...' : 'Registrar',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildFechaTile(IconData icono, String titulo, DateTime? fecha, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icono, color: const Color(0xFF0D47A1)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 2),
                  Text(
                    _formatearFecha(fecha),
                    style: TextStyle(
                      fontSize: 15,
                      color: fecha != null ? Colors.black87 : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// ==================== PANTALLA EDITAR ====================

class EditarEquipoScreen extends StatefulWidget {
  final Equipo equipo;

  const EditarEquipoScreen({super.key, required this.equipo});

  @override
  State<EditarEquipoScreen> createState() => _EditarEquipoScreenState();
}

class _EditarEquipoScreenState extends State<EditarEquipoScreen> {
  final _formKey = GlobalKey<FormState>();
  final EquipoService _service = EquipoService();
  bool _guardando = false;

  late TextEditingController _nombreController;
  late TextEditingController _marcaController;
  late TextEditingController _serieController;
  late TextEditingController _rangoController;
  late TextEditingController _responsableController;
  late TextEditingController _calibradorController;

  DateTime? _fechaCalibracion;
  DateTime? _fechaProximaCalibracion;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.equipo.nombre);
    _marcaController = TextEditingController(text: widget.equipo.marca ?? '');
    _serieController = TextEditingController(text: widget.equipo.numeroSerie ?? '');
    _rangoController = TextEditingController(text: widget.equipo.rangoCapacidad ?? '');
    _responsableController = TextEditingController(text: widget.equipo.responsable ?? '');
    _calibradorController = TextEditingController(text: widget.equipo.calibradoPor ?? '');
    _fechaCalibracion = DateTime.tryParse(widget.equipo.fechaCalibracion ?? '');
    _fechaProximaCalibracion = DateTime.tryParse(widget.equipo.fechaProximaCalibracion ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _marcaController.dispose();
    _serieController.dispose();
    _rangoController.dispose();
    _responsableController.dispose();
    _calibradorController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha(BuildContext context, bool esProxima) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: esProxima ? (_fechaProximaCalibracion ?? DateTime.now()) : (_fechaCalibracion ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (fecha != null) {
      setState(() {
        if (esProxima) {
          _fechaProximaCalibracion = fecha;
        } else {
          _fechaCalibracion = fecha;
        }
      });
    }
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'Seleccionar fecha';
    return '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final datos = {
        'nombre': _nombreController.text,
        'marca': _marcaController.text.isEmpty ? null : _marcaController.text,
        'numero_serie': _serieController.text.isEmpty ? null : _serieController.text,
        'rango_capacidad': _rangoController.text.isEmpty ? null : _rangoController.text,
        'responsable': _responsableController.text.isEmpty ? null : _responsableController.text,
        'calibrado_por': _calibradorController.text.isEmpty ? null : _calibradorController.text,
        'fecha_calibracion': _fechaCalibracion != null ? _formatearFecha(_fechaCalibracion) : null,
        'fecha_proxima_calibracion': _fechaProximaCalibracion != null ? _formatearFecha(_fechaProximaCalibracion) : null,
      };
      final exito = await _service.actualizarEquipo(widget.equipo.codigo, datos);
      if (exito && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Equipo actualizado exitosamente'),
            backgroundColor: const Color(0xFF43A047),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al actualizar'),
            backgroundColor: const Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFE53935)),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  InputDecoration _inputDeco(String label, IconData icono, {bool requerido = false}) {
    return InputDecoration(
      labelText: requerido ? '$label *' : label,
      prefixIcon: Icon(icono, color: const Color(0xFF0D47A1)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2)),
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildFechaTile(IconData icono, String titulo, DateTime? fecha, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icono, color: const Color(0xFF0D47A1)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 2),
                  Text(
                    _formatearFecha(fecha),
                    style: TextStyle(fontSize: 15, color: fecha != null ? Colors.black87 : Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar ${widget.equipo.codigo}'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: _inputDeco('Nombre del equipo', Icons.build_outlined, requerido: true),
                validator: (v) => v == null || v.isEmpty ? 'El nombre es obligatorio' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: widget.equipo.codigo,
                decoration: _inputDeco('Código (no editable)', Icons.qr_code).copyWith(
                  fillColor: Colors.grey.shade200,
                ),
                enabled: false,
              ),
              const SizedBox(height: 14),
              TextFormField(controller: _marcaController, decoration: _inputDeco('Marca', Icons.business_outlined)),
              const SizedBox(height: 14),
              TextFormField(controller: _serieController, decoration: _inputDeco('Número de serie', Icons.numbers)),
              const SizedBox(height: 14),
              TextFormField(controller: _rangoController, decoration: _inputDeco('Rango / Capacidad', Icons.straighten)),
              const SizedBox(height: 14),
              TextFormField(controller: _responsableController, decoration: _inputDeco('Responsable', Icons.person_outline)),
              const SizedBox(height: 14),
              TextFormField(controller: _calibradorController, decoration: _inputDeco('Calibrado por', Icons.engineering_outlined)),
              const SizedBox(height: 14),
              _buildFechaTile(Icons.calendar_today_outlined, 'Fecha de calibración', _fechaCalibracion, () => _seleccionarFecha(context, false)),
              const SizedBox(height: 14),
              _buildFechaTile(Icons.event_outlined, 'Próxima calibración', _fechaProximaCalibracion, () => _seleccionarFecha(context, true)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _guardando ? null : _guardarCambios,
        backgroundColor: const Color(0xFF0D47A1),
        icon: _guardando
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.save, color: Colors.white),
        label: Text(
          _guardando ? 'Guardando...' : 'Guardar',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}