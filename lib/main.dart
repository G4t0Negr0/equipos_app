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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
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
    if (fechaProxima == null) return Colors.grey;
    final fecha = DateTime.tryParse(fechaProxima);
    if (fecha == null) return Colors.grey;
    final dias = fecha.difference(DateTime.now()).inDays;
    if (dias < 0) return Colors.red;
    if (dias <= 60) return Colors.amber;
    return Colors.green;
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

  void _irAFormulario() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FormularioEquipoScreen()),
    ).then((resultado) {
      if (resultado == true) {
        _cargarEquipos();
      }
    });
  }

  void _irADetalle(Equipo equipo) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetalleEquipoScreen(equipo: equipo)),
    ).then((resultado) {
      if (resultado == true) {
        _cargarEquipos();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipos de Laboratorio'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o código...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: _filtrarEquipos,
            ),
          ),
          // Leyenda de colores
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLeyenda(Colors.green, 'Vigente'),
                _buildLeyenda(Colors.amber, 'Por vencer'),
                _buildLeyenda(Colors.red, 'Vencido'),
                _buildLeyenda(Colors.grey, 'Sin fecha'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: $_error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _cargarEquipos,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
                : _equiposFiltrados.isEmpty
                ? const Center(child: Text('No se encontraron equipos'))
                : RefreshIndicator(
              onRefresh: _cargarEquipos,
              child: ListView.builder(
                itemCount: _equiposFiltrados.length,
                itemBuilder: (context, index) {
                  final equipo = _equiposFiltrados[index];
                  final color = _colorEstado(equipo.fechaProximaCalibracion);
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(
                        equipo.nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Código: ${equipo.codigo}\n'
                            '${_textoEstado(equipo.fechaProximaCalibracion)}',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _irADetalle(equipo),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _irAFormulario,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildLeyenda(Color color, String texto) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(texto, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

// ==================== PANTALLA DETALLE ====================

class DetalleEquipoScreen extends StatelessWidget {
  final Equipo equipo;

  const DetalleEquipoScreen({super.key, required this.equipo});

  void _confirmarEliminar(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar equipo'),
        content: Text('¿Estás seguro de eliminar "${equipo.nombre}" (${equipo.codigo})?\n\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _eliminarEquipo(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
            const SnackBar(
              content: Text('Equipo eliminado'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al eliminar'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(equipo.nombre),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
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
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmarEliminar(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCampo('Nombre', equipo.nombre),
            _buildCampo('Código', equipo.codigo),
            _buildCampo('Marca', equipo.marca),
            _buildCampo('Número de serie', equipo.numeroSerie),
            _buildCampo('Rango / Capacidad', equipo.rangoCapacidad),
            _buildCampo('Fecha de calibración', equipo.fechaCalibracion),
            _buildCampo('Próxima calibración', equipo.fechaProximaCalibracion),
            _buildCampo('Calibrado por', equipo.calibradoPor),
            _buildCampo('Responsable', equipo.responsable),
            _buildCampo('Estado', equipo.estado),
          ],
        ),
      ),
    );
  }

  Widget _buildCampo(String label, String? valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor ?? 'N/A',
            style: const TextStyle(fontSize: 16),
          ),
          const Divider(),
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
          const SnackBar(
            content: Text('Equipo registrado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al registrar el equipo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Equipo'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del equipo *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.build),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? 'El nombre es obligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codigoController,
                decoration: const InputDecoration(
                  labelText: 'Código *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? 'El código es obligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _marcaController,
                decoration: const InputDecoration(
                  labelText: 'Marca',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _serieController,
                decoration: const InputDecoration(
                  labelText: 'Número de serie',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rangoController,
                decoration: const InputDecoration(
                  labelText: 'Rango / Capacidad',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.straighten),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _responsableController,
                decoration: const InputDecoration(
                  labelText: 'Responsable',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _calibradorController,
                decoration: const InputDecoration(
                  labelText: 'Calibrado por',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.engineering),
                ),
              ),
              const SizedBox(height: 16),
              // Selector de fecha de calibración
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: const BorderSide(color: Colors.grey),
                ),
                leading: const Icon(Icons.calendar_today),
                title: const Text('Fecha de calibración'),
                subtitle: Text(_formatearFecha(_fechaCalibracion)),
                onTap: () => _seleccionarFecha(context, false),
              ),
              const SizedBox(height: 16),
              // Selector de próxima calibración
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: const BorderSide(color: Colors.grey),
                ),
                leading: const Icon(Icons.event),
                title: const Text('Próxima calibración'),
                subtitle: Text(_formatearFecha(_fechaProximaCalibracion)),
                onTap: () => _seleccionarFecha(context, true),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _guardando ? null : _guardarEquipo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _guardando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'REGISTRAR EQUIPO',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
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
      initialDate: esProxima
          ? (_fechaProximaCalibracion ?? DateTime.now())
          : (_fechaCalibracion ?? DateTime.now()),
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
          const SnackBar(
            content: Text('Equipo actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar ${widget.equipo.codigo}'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del equipo *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.build),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? 'El nombre es obligatorio' : null,
              ),
              const SizedBox(height: 16),
              // Código no editable
              TextFormField(
                initialValue: widget.equipo.codigo,
                decoration: const InputDecoration(
                  labelText: 'Código (no editable)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code),
                ),
                enabled: false,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _marcaController,
                decoration: const InputDecoration(
                  labelText: 'Marca',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _serieController,
                decoration: const InputDecoration(
                  labelText: 'Número de serie',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rangoController,
                decoration: const InputDecoration(
                  labelText: 'Rango / Capacidad',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.straighten),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _responsableController,
                decoration: const InputDecoration(
                  labelText: 'Responsable',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _calibradorController,
                decoration: const InputDecoration(
                  labelText: 'Calibrado por',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.engineering),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: const BorderSide(color: Colors.grey),
                ),
                leading: const Icon(Icons.calendar_today),
                title: const Text('Fecha de calibración'),
                subtitle: Text(_formatearFecha(_fechaCalibracion)),
                onTap: () => _seleccionarFecha(context, false),
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: const BorderSide(color: Colors.grey),
                ),
                leading: const Icon(Icons.event),
                title: const Text('Próxima calibración'),
                subtitle: Text(_formatearFecha(_fechaProximaCalibracion)),
                onTap: () => _seleccionarFecha(context, true),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _guardando ? null : _guardarCambios,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _guardando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'GUARDAR CAMBIOS',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}