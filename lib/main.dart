import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
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
      title: 'LabGuard',
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
      home: const SplashScreen(),
    );
  }
}

// ==================== SPLASH / CHECK SESIÓN ====================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _verificarSesion();
  }

  Future<void> _verificarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final labId = prefs.getString('laboratorio_id');

    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      if (labId != null && labId.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ListaEquiposScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1E88E5)],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.precision_manufacturing, color: Colors.white, size: 64),
              SizedBox(height: 16),
              Text('LabGuard', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2)),
              SizedBox(height: 8),
              Text('Gestión de Equipos', style: TextStyle(color: Colors.white70, fontSize: 14)),
              SizedBox(height: 32),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== LOGIN ====================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final EquipoService _service = EquipoService();
  bool _cargando = false;
  bool _verPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);

    try {
      final resultado = await _service.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('usuario_id', resultado['usuario_id']);
      await prefs.setString('nombre', resultado['nombre']);
      await prefs.setString('email', resultado['email']);
      await prefs.setString('rol', resultado['rol']);
      await prefs.setString('laboratorio_id', resultado['laboratorio_id']);
      await prefs.setString('laboratorio_nombre', resultado['laboratorio_nombre']);
      await prefs.setString('codigo_laboratorio', resultado['codigo_laboratorio']);
      await prefs.setInt('dias_restantes', resultado['dias_restantes'] ?? 0);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ListaEquiposScreen()),
        );
      }
    } catch (e) {
      String mensaje = e.toString().replaceAll('Exception: ', '');
      if (mensaje.contains('TRIAL_VENCIDO')) {
        _mostrarTrialVencido();
      } else if (mensaje.contains('CUENTA_INACTIVA')) {
        _mostrarCuentaInactiva();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(mensaje),
              backgroundColor: const Color(0xFFE53935),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarTrialVencido() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.timer_off, color: Color(0xFFFFA726)),
            SizedBox(width: 8),
            Text('Prueba finalizada'),
          ],
        ),
        content: const Text(
          'Tu período de prueba gratuita ha terminado.\n\n'
              'Contáctanos para activar tu cuenta y seguir usando LabGuard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
          FilledButton.icon(
            onPressed: () {
              final uri = Uri(scheme: 'mailto', path: 'websmarthousecl@gmail.com',
                  query: 'subject=Activar cuenta LabGuard');
              launchUrl(uri);
            },
            icon: const Icon(Icons.email),
            label: const Text('Contactar'),
          ),
        ],
      ),
    );
  }

  void _mostrarCuentaInactiva() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.block, color: Color(0xFFE53935)),
            SizedBox(width: 8),
            Text('Cuenta inactiva'),
          ],
        ),
        content: const Text(
          'Tu cuenta ha sido desactivada.\n\n'
              'Contáctanos para más información.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
          FilledButton.icon(
            onPressed: () {
              final uri = Uri(scheme: 'mailto', path: 'websmarthousecl@gmail.com',
                  query: 'subject=Cuenta inactiva LabGuard');
              launchUrl(uri);
            },
            icon: const Icon(Icons.email),
            label: const Text('Contactar'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icono) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icono, color: const Color(0xFF0D47A1)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2)),
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D47A1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.precision_manufacturing, color: Color(0xFF0D47A1), size: 48),
                ),
                const SizedBox(height: 20),
                const Text('LabGuard', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1), letterSpacing: 2)),
                const SizedBox(height: 4),
                Text('Gestión de Equipos', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  decoration: _inputDeco('Email', Icons.email_outlined),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || v.isEmpty ? 'Ingresa tu email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: _inputDeco('Contraseña', Icons.lock_outline).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_verPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: () => setState(() => _verPassword = !_verPassword),
                    ),
                  ),
                  obscureText: !_verPassword,
                  validator: (v) => v == null || v.isEmpty ? 'Ingresa tu contraseña' : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _cargando ? null : _login,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _cargando
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Iniciar sesión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const RegistroScreen()));
                  },
                  child: const Text('¿No tienes cuenta? Regístrate'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== REGISTRO ====================

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final EquipoService _service = EquipoService();
  bool _cargando = false;
  bool _crearNuevoLab = false;

  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codigoLabController = TextEditingController();
  final _nombreLabController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _codigoLabController.dispose();
    _nombreLabController.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);

    try {
      final datos = {
        'nombre': _nombreController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      };

      if (_crearNuevoLab) {
        datos['nombre_laboratorio'] = _nombreLabController.text.trim();
      } else {
        datos['codigo_laboratorio'] = _codigoLabController.text.trim();
      }

      final resultado = await _service.registro(datos);

      if (mounted) {
        String mensaje = _crearNuevoLab
            ? 'Laboratorio creado. Tu código de acceso es: ${resultado['codigo_laboratorio']}'
            : 'Registro exitoso';
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF43A047)),
                SizedBox(width: 8),
                Text('Registro exitoso'),
              ],
            ),
            content: Text('$mensaje\n\nAhora puedes iniciar sesión con tu email y contraseña.'),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('Ir a login'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: const Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: _inputDeco('Nombre completo', Icons.person_outline, requerido: true),
                validator: (v) => v == null || v.isEmpty ? 'Ingresa tu nombre' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailController,
                decoration: _inputDeco('Email', Icons.email_outlined, requerido: true),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || v.isEmpty ? 'Ingresa tu email' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                decoration: _inputDeco('Contraseña (mín. 6 caracteres)', Icons.lock_outline, requerido: true),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa una contraseña';
                  if (v.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text('¿Cómo quieres unirte?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Tengo un código'),
                            selected: !_crearNuevoLab,
                            onSelected: (v) => setState(() => _crearNuevoLab = false),
                            selectedColor: const Color(0xFF0D47A1).withOpacity(0.15),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Crear laboratorio'),
                            selected: _crearNuevoLab,
                            onSelected: (v) => setState(() => _crearNuevoLab = true),
                            selectedColor: const Color(0xFF0D47A1).withOpacity(0.15),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (!_crearNuevoLab)
                      TextFormField(
                        controller: _codigoLabController,
                        decoration: _inputDeco('Código del laboratorio', Icons.vpn_key_outlined, requerido: true),
                        validator: (v) => !_crearNuevoLab && (v == null || v.isEmpty) ? 'Ingresa el código' : null,
                      ),
                    if (_crearNuevoLab)
                      TextFormField(
                        controller: _nombreLabController,
                        decoration: _inputDeco('Nombre del laboratorio', Icons.business_outlined, requerido: true),
                        validator: (v) => _crearNuevoLab && (v == null || v.isEmpty) ? 'Ingresa el nombre' : null,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _cargando ? null : _registrar,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _cargando
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Registrarse', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
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
String _labId = '';
String _labNombre = '';
String _userName = '';
int _diasRestantes = 0;

@override
void initState() {
super.initState();
_cargarSesion();
}

Future<void> _cargarSesion() async {
final prefs = await SharedPreferences.getInstance();
_labId = prefs.getString('laboratorio_id') ?? '';
_labNombre = prefs.getString('laboratorio_nombre') ?? '';
_userName = prefs.getString('nombre') ?? '';
_diasRestantes = prefs.getInt('dias_restantes') ?? 0;
_cargarEquipos();
}

Future<void> _cargarEquipos() async {
setState(() { _cargando = true; _error = null; });
try {
final equipos = await _service.obtenerEquipos(_labId);
setState(() { _todosEquipos = equipos; _equiposFiltrados = equipos; _cargando = false; });
} catch (e) {
setState(() { _error = e.toString(); _cargando = false; });
}
}

void _filtrarEquipos(String texto) {
setState(() {
if (texto.isEmpty) {
_equiposFiltrados = _todosEquipos;
} else {
_equiposFiltrados = _todosEquipos.where((equipo) {
return equipo.nombre.toLowerCase().contains(texto.toLowerCase()) ||
equipo.codigo.toLowerCase().contains(texto.toLowerCase());
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
Navigator.push(context, MaterialPageRoute(builder: (context) => FormularioEquipoScreen(labId: _labId)))
.then((r) { if (r == true) _cargarEquipos(); });
}

void _irADetalle(Equipo equipo) {
Navigator.push(context, MaterialPageRoute(builder: (context) => DetalleEquipoScreen(equipo: equipo)))
.then((r) { if (r == true) _cargarEquipos(); });
}

Future<void> _descargarExcel() async {
try {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: const Text('Descargando...'), backgroundColor: const Color(0xFF0D47A1),
behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
);
final response = await _service.exportarExcel(_labId);
if (response.statusCode == 200) {
final directory = Directory('/storage/emulated/0/Download');
final file = File('${directory.path}/equipos_$_labNombre.xlsx');
await file.writeAsBytes(response.bodyBytes);
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Guardado en Descargas: ${file.path}'), backgroundColor: const Color(0xFF43A047),
behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
);
}
}
} catch (e) {
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFE53935),
behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
);
}
}
}

void _contactar() {
final uri = Uri(scheme: 'mailto', path: 'websmarthousecl@gmail.com',
query: 'subject=Consulta LabGuard - $_labNombre');
launchUrl(uri);
}

Future<void> _cerrarSesion() async {
final confirmar = await showDialog<bool>(
context: context,
builder: (ctx) => AlertDialog(
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
title: const Text('Cerrar sesión'),
content: const Text('¿Deseas cerrar sesión?'),
actions: [
TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cerrar sesión')),
],
),
);
if (confirmar == true) {
final prefs = await SharedPreferences.getInstance();
await prefs.clear();
if (mounted) {
Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
}
}
}

@override
Widget build(BuildContext context) {
return Scaffold(
body: CustomScrollView(
slivers: [
SliverAppBar(
expandedHeight: 140,
floating: false,
pinned: true,
automaticallyImplyLeading: false,
backgroundColor: const Color(0xFF0D47A1),
flexibleSpace: FlexibleSpaceBar(
background: Container(
decoration: const BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topLeft, end: Alignment.bottomRight,
colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1E88E5)],
),
),
child: SafeArea(
child: Padding(
padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Container(
padding: const EdgeInsets.all(8),
decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
child: const Icon(Icons.precision_manufacturing, color: Colors.white, size: 24),
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(_labNombre.isNotEmpty ? _labNombre : 'LabGuard',
style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
Text('Hola, $_userName', style: const TextStyle(color: Colors.white70, fontSize: 13)),
],
),
),
],
),
const SizedBox(height: 8),
if (_diasRestantes <= 15)
Container(
padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
decoration: BoxDecoration(color: const Color(0xFFFFA726).withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
child: Text(
_diasRestantes > 0 ? 'Prueba: $_diasRestantes días restantes' : 'Prueba vencida',
style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
),
),
],
),
),
),
),
),
actions: [
PopupMenuButton<String>(
icon: const Icon(Icons.more_vert, color: Colors.white),
onSelected: (value) {
if (value == 'excel') _descargarExcel();
if (value == 'contacto') _contactar();
if (value == 'cerrar') _cerrarSesion();
},
itemBuilder: (context) => [
const PopupMenuItem(value: 'excel', child: Row(children: [Icon(Icons.download, size: 20), SizedBox(width: 8), Text('Descargar Excel')])),
const PopupMenuItem(value: 'contacto', child: Row(children: [Icon(Icons.email, size: 20), SizedBox(width: 8), Text('Contactar')])),
const PopupMenuItem(value: 'cerrar', child: Row(children: [Icon(Icons.logout, size: 20), SizedBox(width: 8), Text('Cerrar sesión')])),
],
),
],
),
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
border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
filled: true, fillColor: const Color(0xFFF5F5F5),
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
Padding(
padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
child: Row(children: [Text('${_equiposFiltrados.length} equipos', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500))]),
),
],
),
),
_cargando
? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
: _error != null
? SliverFillRemaining(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
Icon(Icons.cloud_off, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16),
Text('No se pudo conectar', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
const SizedBox(height: 8), FilledButton.tonal(onPressed: _cargarEquipos, child: const Text('Reintentar'))])))
: _equiposFiltrados.isEmpty
? SliverFillRemaining(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
Icon(Icons.search_off, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16),
Text('No se encontraron equipos', style: TextStyle(color: Colors.grey.shade600))])))
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
                    child: Icon(Icons.precision_manufacturing, color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(equipo.nombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(equipo.codigo, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
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
onPressed: _irAFormulario, backgroundColor: const Color(0xFF0D47A1),
icon: const Icon(Icons.add, color: Colors.white),
label: const Text('Nuevo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
),
);
}

Widget _buildLeyenda(Color color, String texto) {
return Row(children: [
Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
const SizedBox(width: 4), Text(texto, style: TextStyle(fontSize: 11, color: Colors.grey.shade600))]);
}
}

// ==================== PANTALLA DETALLE ====================

class DetalleEquipoScreen extends StatelessWidget {
final Equipo equipo;
const DetalleEquipoScreen({super.key, required this.equipo});

Color _colorEstado(String? fp) {
if (fp == null) return const Color(0xFFBDBDBD);
final f = DateTime.tryParse(fp); if (f == null) return const Color(0xFFBDBDBD);
final d = f.difference(DateTime.now()).inDays;
if (d < 0) return const Color(0xFFE53935); if (d <= 60) return const Color(0xFFFFA726); return const Color(0xFF43A047);
}

String _textoEstado(String? fp) {
if (fp == null) return 'Sin fecha'; final f = DateTime.tryParse(fp); if (f == null) return 'Sin fecha';
final d = f.difference(DateTime.now()).inDays;
if (d < 0) return 'VENCIDO'; if (d <= 60) return 'Vence en $d días'; return 'Vigente ($d días)';
}

void _confirmarEliminar(BuildContext context) {
showDialog(context: context, builder: (ctx) => AlertDialog(
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935)), SizedBox(width: 8), Text('Eliminar equipo')]),
content: Text('¿Eliminar "${equipo.nombre}" (${equipo.codigo})?\n\nEsta acción no se puede deshacer.'),
actions: [
TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
FilledButton(onPressed: () { Navigator.pop(ctx); _eliminarEquipo(context); },
style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE53935)), child: const Text('Eliminar'))],
));
}

void _eliminarEquipo(BuildContext context) async {
try {
final exito = await EquipoService().eliminarEquipo(equipo.codigo);
if (context.mounted) {
ScaffoldMessenger.of(context).showSnackBar(SnackBar(
content: Text(exito ? 'Equipo eliminado' : 'Error al eliminar'),
backgroundColor: exito ? const Color(0xFF43A047) : const Color(0xFFE53935),
behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
if (exito) Navigator.pop(context, true);
}
} catch (e) {
if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFE53935)));
}
}

@override
Widget build(BuildContext context) {
final color = _colorEstado(equipo.fechaProximaCalibracion);
return Scaffold(
body: CustomScrollView(slivers: [
SliverAppBar(expandedHeight: 180, pinned: true, backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white,
flexibleSpace: FlexibleSpaceBar(background: Container(
decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1E88E5)])),
child: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
Text(equipo.nombre, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
const SizedBox(height: 4),
Row(children: [
Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
child: Text(equipo.codigo, style: const TextStyle(color: Colors.white, fontSize: 13))),
const SizedBox(width: 8),
Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
decoration: BoxDecoration(color: color.withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
child: Text(_textoEstado(equipo.fechaProximaCalibracion), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)))])]))))),
actions: [
IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () async {
final r = await Navigator.push(context, MaterialPageRoute(builder: (c) => EditarEquipoScreen(equipo: equipo)));
if (r == true && context.mounted) Navigator.pop(context, true);
}),
IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _confirmarEliminar(context))]),
SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
_buildSeccion('Información general', [
_buildCampo(Icons.build_outlined, 'Nombre', equipo.nombre), _buildCampo(Icons.qr_code, 'Código', equipo.codigo),
_buildCampo(Icons.business_outlined, 'Marca', equipo.marca), _buildCampo(Icons.numbers, 'N° serie', equipo.numeroSerie),
_buildCampo(Icons.straighten, 'Rango / Capacidad', equipo.rangoCapacidad)]),
const SizedBox(height: 16),
_buildSeccion('Calibración', [
_buildCampo(Icons.calendar_today_outlined, 'Última calibración', equipo.fechaCalibracion),
_buildCampo(Icons.event_outlined, 'Próxima calibración', equipo.fechaProximaCalibracion),
_buildCampo(Icons.engineering_outlined, 'Calibrado por', equipo.calibradoPor)]),
const SizedBox(height: 16),
_buildSeccion('Responsabilidad', [
_buildCampo(Icons.person_outline, 'Responsable', equipo.responsable),
_buildCampo(Icons.info_outline, 'Estado', equipo.estado)])])))]),
);
}

Widget _buildSeccion(String titulo, List<Widget> campos) {
return Container(width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
child: Text(titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0D47A1), letterSpacing: 0.5))),
const Divider(height: 1), ...campos]));
}

Widget _buildCampo(IconData icono, String label, String? valor) {
return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
child: Row(children: [Icon(icono, size: 20, color: Colors.grey.shade400), const SizedBox(width: 12),
Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)), const SizedBox(height: 2),
Text(valor ?? 'N/A', style: TextStyle(fontSize: 15, color: valor != null ? Colors.black87 : Colors.grey.shade400))]))]));
}
}

// ==================== PANTALLA FORMULARIO ====================

class FormularioEquipoScreen extends StatefulWidget {
final String labId;
const FormularioEquipoScreen({super.key, required this.labId});
@override
State<FormularioEquipoScreen> createState() => _FormularioEquipoScreenState();
}

class _FormularioEquipoScreenState extends State<FormularioEquipoScreen> {
final _formKey = GlobalKey<FormState>();
final EquipoService _service = EquipoService();
bool _guardando = false;
final _nombreC = TextEditingController(); final _codigoC = TextEditingController();
final _marcaC = TextEditingController(); final _serieC = TextEditingController();
final _rangoC = TextEditingController(); final _responsableC = TextEditingController();
final _calibradorC = TextEditingController();
DateTime? _fechaCal; DateTime? _fechaProxCal;

@override
void dispose() { _nombreC.dispose(); _codigoC.dispose(); _marcaC.dispose(); _serieC.dispose(); _rangoC.dispose(); _responsableC.dispose(); _calibradorC.dispose(); super.dispose(); }

Future<void> _selFecha(bool esProx) async {
final f = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
if (f != null) setState(() { if (esProx) _fechaProxCal = f; else _fechaCal = f; });
}

String _fmtFecha(DateTime? f) => f == null ? 'Seleccionar fecha' : '${f.year}-${f.month.toString().padLeft(2, '0')}-${f.day.toString().padLeft(2, '0')}';

Future<void> _guardar() async {
if (!_formKey.currentState!.validate()) return;
setState(() => _guardando = true);
try {
final datos = {'nombre': _nombreC.text, 'codigo': _codigoC.text, 'laboratorio_id': widget.labId,
'marca': _marcaC.text.isEmpty ? null : _marcaC.text, 'numero_serie': _serieC.text.isEmpty ? null : _serieC.text,
'rango_capacidad': _rangoC.text.isEmpty ? null : _rangoC.text, 'responsable': _responsableC.text.isEmpty ? null : _responsableC.text,
'calibrado_por': _calibradorC.text.isEmpty ? null : _calibradorC.text,
'fecha_calibracion': _fechaCal != null ? _fmtFecha(_fechaCal) : null,
'fecha_proxima_calibracion': _fechaProxCal != null ? _fmtFecha(_fechaProxCal) : null};
final ok = await _service.crearEquipo(datos);
if (ok && mounted) {
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Equipo registrado'), backgroundColor: const Color(0xFF43A047),
behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
Navigator.pop(context, true);
}
} catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFE53935))); }
finally { if (mounted) setState(() => _guardando = false); }
}

InputDecoration _d(String l, IconData i, {bool r = false}) => InputDecoration(
labelText: r ? '$l *' : l, prefixIcon: Icon(i, color: const Color(0xFF0D47A1)),
border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2)),
filled: true, fillColor: const Color(0xFFFAFAFA));

Widget _fechaTile(IconData i, String t, DateTime? f, VoidCallback onTap) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14),
child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
decoration: BoxDecoration(color: const Color(0xFFFAFAFA), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade300)),
child: Row(children: [Icon(i, color: const Color(0xFF0D47A1)), const SizedBox(width: 14),
Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
Text(t, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)), const SizedBox(height: 2),
Text(_fmtFecha(f), style: TextStyle(fontSize: 15, color: f != null ? Colors.black87 : Colors.grey.shade400))])),
Icon(Icons.arrow_drop_down, color: Colors.grey.shade400)])));

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: const Text('Nuevo Equipo'), backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white),
backgroundColor: Colors.white,
body: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
TextFormField(controller: _nombreC, decoration: _d('Nombre del equipo', Icons.build_outlined, r: true),
validator: (v) => v == null || v.isEmpty ? 'Obligatorio' : null),
const SizedBox(height: 14),
TextFormField(controller: _codigoC, decoration: _d('Código', Icons.qr_code, r: true),
validator: (v) => v == null || v.isEmpty ? 'Obligatorio' : null),
const SizedBox(height: 14),
TextFormField(controller: _marcaC, decoration: _d('Marca', Icons.business_outlined)),
const SizedBox(height: 14),
TextFormField(controller: _serieC, decoration: _d('Número de serie', Icons.numbers)),
const SizedBox(height: 14),
TextFormField(controller: _rangoC, decoration: _d('Rango / Capacidad', Icons.straighten)),
const SizedBox(height: 14),
TextFormField(controller: _responsableC, decoration: _d('Responsable', Icons.person_outline)),
const SizedBox(height: 14),
TextFormField(controller: _calibradorC, decoration: _d('Calibrado por', Icons.engineering_outlined)),
const SizedBox(height: 14),
_fechaTile(Icons.calendar_today_outlined, 'Fecha de calibración', _fechaCal, () => _selFecha(false)),
const SizedBox(height: 14),
_fechaTile(Icons.event_outlined, 'Próxima calibración', _fechaProxCal, () => _selFecha(true))]))),
floatingActionButton: FloatingActionButton.extended(onPressed: _guardando ? null : _guardar, backgroundColor: const Color(0xFF0D47A1),
icon: _guardando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
: const Icon(Icons.save, color: Colors.white),
label: Text(_guardando ? 'Guardando...' : 'Registrar', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))));
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
late TextEditingController _nombreC, _marcaC, _serieC, _rangoC, _responsableC, _calibradorC;
DateTime? _fechaCal, _fechaProxCal;

@override
void initState() {
super.initState();
_nombreC = TextEditingController(text: widget.equipo.nombre);
_marcaC = TextEditingController(text: widget.equipo.marca ?? '');
_serieC = TextEditingController(text: widget.equipo.numeroSerie ?? '');
_rangoC = TextEditingController(text: widget.equipo.rangoCapacidad ?? '');
_responsableC = TextEditingController(text: widget.equipo.responsable ?? '');
_calibradorC = TextEditingController(text: widget.equipo.calibradoPor ?? '');
_fechaCal = DateTime.tryParse(widget.equipo.fechaCalibracion ?? '');
_fechaProxCal = DateTime.tryParse(widget.equipo.fechaProximaCalibracion ?? '');
}

@override
void dispose() { _nombreC.dispose(); _marcaC.dispose(); _serieC.dispose(); _rangoC.dispose(); _responsableC.dispose(); _calibradorC.dispose(); super.dispose(); }

Future<void> _selFecha(bool esProx) async {
final f = await showDatePicker(context: context, initialDate: esProx ? (_fechaProxCal ?? DateTime.now()) : (_fechaCal ?? DateTime.now()),
firstDate: DateTime(2020), lastDate: DateTime(2030));
if (f != null) setState(() { if (esProx) _fechaProxCal = f; else _fechaCal = f; });
}

String _fmtFecha(DateTime? f) => f == null ? 'Seleccionar fecha' : '${f.year}-${f.month.toString().padLeft(2, '0')}-${f.day.toString().padLeft(2, '0')}';

Future<void> _guardar() async {
if (!_formKey.currentState!.validate()) return;
setState(() => _guardando = true);
try {
final datos = {'nombre': _nombreC.text, 'marca': _marcaC.text.isEmpty ? null : _marcaC.text,
'numero_serie': _serieC.text.isEmpty ? null : _serieC.text, 'rango_capacidad': _rangoC.text.isEmpty ? null : _rangoC.text,
'responsable': _responsableC.text.isEmpty ? null : _responsableC.text, 'calibrado_por': _calibradorC.text.isEmpty ? null : _calibradorC.text,
'fecha_calibracion': _fechaCal != null ? _fmtFecha(_fechaCal) : null,
'fecha_proxima_calibracion': _fechaProxCal != null ? _fmtFecha(_fechaProxCal) : null};
final ok = await _service.actualizarEquipo(widget.equipo.codigo, datos);
if (ok && mounted) {
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Equipo actualizado'), backgroundColor: const Color(0xFF43A047),
behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
Navigator.pop(context, true);
}
} catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFE53935))); }
finally { if (mounted) setState(() => _guardando = false); }
}

InputDecoration _d(String l, IconData i, {bool r = false}) => InputDecoration(
labelText: r ? '$l *' : l, prefixIcon: Icon(i, color: const Color(0xFF0D47A1)),
border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2)),
filled: true, fillColor: const Color(0xFFFAFAFA));

Widget _fechaTile(IconData i, String t, DateTime? f, VoidCallback onTap) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14),
child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
decoration: BoxDecoration(color: const Color(0xFFFAFAFA), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade300)),
child: Row(children: [Icon(i, color: const Color(0xFF0D47A1)), const SizedBox(width: 14),
Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
Text(t, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)), const SizedBox(height: 2),
Text(_fmtFecha(f), style: TextStyle(fontSize: 15, color: f != null ? Colors.black87 : Colors.grey.shade400))])),
Icon(Icons.arrow_drop_down, color: Colors.grey.shade400)])));

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: Text('Editar ${widget.equipo.codigo}'), backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white),
backgroundColor: Colors.white,
body: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
TextFormField(controller: _nombreC, decoration: _d('Nombre del equipo', Icons.build_outlined, r: true),
validator: (v) => v == null || v.isEmpty ? 'Obligatorio' : null),
const SizedBox(height: 14),
TextFormField(initialValue: widget.equipo.codigo, decoration: _d('Código (no editable)', Icons.qr_code).copyWith(fillColor: Colors.grey.shade200), enabled: false),
const SizedBox(height: 14),
TextFormField(controller: _marcaC, decoration: _d('Marca', Icons.business_outlined)),
const SizedBox(height: 14),
TextFormField(controller: _serieC, decoration: _d('Número de serie', Icons.numbers)),
const SizedBox(height: 14),
TextFormField(controller: _rangoC, decoration: _d('Rango / Capacidad', Icons.straighten)),
const SizedBox(height: 14),
TextFormField(controller: _responsableC, decoration: _d('Responsable', Icons.person_outline)),
const SizedBox(height: 14),
TextFormField(controller: _calibradorC, decoration: _d('Calibrado por', Icons.engineering_outlined)),
const SizedBox(height: 14),
_fechaTile(Icons.calendar_today_outlined, 'Fecha de calibración', _fechaCal, () => _selFecha(false)),
const SizedBox(height: 14),
_fechaTile(Icons.event_outlined, 'Próxima calibración', _fechaProxCal, () => _selFecha(true))]))),
floatingActionButton: FloatingActionButton.extended(onPressed: _guardando ? null : _guardar, backgroundColor: const Color(0xFF0D47A1),
icon: _guardando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
: const Icon(Icons.save, color: Colors.white),
label: Text(_guardando ? 'Guardando...' : 'Guardar', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))));
}
}