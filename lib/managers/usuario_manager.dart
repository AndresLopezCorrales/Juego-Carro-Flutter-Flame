import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';
import '../models/usuario.dart';

class UsuarioManager {
  static final UsuarioManager _instancia = UsuarioManager._interno();
  factory UsuarioManager() => _instancia;
  UsuarioManager._interno();

  final SupabaseService _supabaseService = SupabaseService();
  Usuario? _usuarioActual;

  Usuario? get usuarioActual => _usuarioActual;
  bool get hayUsuario => _usuarioActual != null;
  String get nombreUsuario => _usuarioActual?.nombre ?? 'Invitado';

  Future<void> cargarUsuarioGuardado() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getString('usuario_actual_id');

      if (usuarioId != null) {
        final usuario = await _supabaseService.obtenerUsuarioPorId(usuarioId);

        if (usuario != null) {
          _usuarioActual = usuario;
        }
      }
    } catch (e) {
      _usuarioActual = null;
    }
  }

  Future<bool> iniciarSesionOCrear(String nombre) async {
    try {
      if (nombre.trim().isEmpty) return false;

      final usuario = await _supabaseService.crearObtenerUsuario(nombre.trim());

      if (usuario != null) {
        _usuarioActual = usuario;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('usuario_actual_id', usuario.id);

        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('usuario_actual_id');
    _usuarioActual = null;
  }

  Future<void> guardarPuntajeActual(int puntos) async {
    if (_usuarioActual == null) return;

    try {
      await _supabaseService.guardarPuntaje(
        usuarioId: _usuarioActual!.id,
        puntos: puntos,
      );
    } catch (e) {
      // Silenciar error
    }
  }

  Future<bool> cambiarUsuario(String nombre) async {
    await cerrarSesion();
    return await iniciarSesionOCrear(nombre);
  }
}
