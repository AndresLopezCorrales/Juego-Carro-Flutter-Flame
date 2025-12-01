import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario.dart';
import '../models/puntaje.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // USUARIOS

  Future<Usuario?> crearObtenerUsuario(String nombre) async {
    try {
      final usuarioExistente = await obtenerUsuarioPorNombre(nombre);
      if (usuarioExistente != null) {
        return usuarioExistente;
      }

      final response = await _supabase
          .from('usuarios')
          .insert({'nombre': nombre.trim()})
          .select()
          .single();

      return Usuario.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        return await obtenerUsuarioPorNombre(nombre);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Usuario?> obtenerUsuarioPorNombre(String nombre) async {
    try {
      final response = await _supabase
          .from('usuarios')
          .select()
          .eq('nombre', nombre.trim())
          .maybeSingle();

      if (response == null) return null;
      return Usuario.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<Usuario?> obtenerUsuarioPorId(String id) async {
    try {
      final response = await _supabase
          .from('usuarios')
          .select()
          .eq('id', id)
          .single();

      return Usuario.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // PUNTOS

  Future<Puntaje?> guardarPuntaje({
    required String usuarioId,
    required int puntos,
  }) async {
    try {
      final usuario = await obtenerUsuarioPorId(usuarioId);
      if (usuario == null) return null;

      final response = await _supabase
          .from('puntos')
          .insert({'usuario_id': usuarioId, 'puntos': puntos})
          .select()
          .single();

      return Puntaje.fromJson({...response, 'nombre_usuario': usuario.nombre});
    } catch (e) {
      return null;
    }
  }

  // MÉTODO CLAVE: Obtener top 10 puntajes (solo el mejor por usuario)
  Future<List<Puntaje>> obtenerTopPuntajes({int limite = 10}) async {
    try {
      final response = await _supabase
          .from('puntos')
          .select('''
            id, usuario_id, puntos, fecha,
            usuarios!inner(nombre)
          ''')
          .order('puntos', ascending: false);

      // Filtrar para mantener solo el mejor puntaje por usuario
      final Map<String, Puntaje> mejoresPorUsuario = {};

      for (final json in response) {
        final usuarioId = json['usuario_id'] as String;
        final puntos = json['puntos'] as int;

        // Si es la primera vez que vemos este usuario o tiene un puntaje mayor
        if (!mejoresPorUsuario.containsKey(usuarioId) ||
            puntos > mejoresPorUsuario[usuarioId]!.puntos) {
          mejoresPorUsuario[usuarioId] = Puntaje.fromJson({
            ...json,
            'nombre_usuario':
                (json['usuarios'] as Map<String, dynamic>)['nombre'],
          });
        }
      }

      // Convertir a lista, ordenar por puntos y limitar
      final listaOrdenada = mejoresPorUsuario.values.toList();
      listaOrdenada.sort((a, b) => b.puntos.compareTo(a.puntos));

      return listaOrdenada.take(limite).toList();
    } catch (e) {
      return [];
    }
  }

  // Método alternativo - DISTINCT ON
  Future<List<Puntaje>> obtenerTopPuntajesEficiente({int limite = 10}) async {
    try {
      final response = await _supabase
          .from('puntos')
          .select('''
            DISTINCT ON (usuario_id) 
            id, usuario_id, puntos, fecha,
            usuarios!inner(nombre)
          ''')
          .order('usuario_id')
          .order('puntos', ascending: false)
          .limit(limite);

      return (response as List)
          .map(
            (json) => Puntaje.fromJson({
              ...json,
              'nombre_usuario':
                  (json['usuarios'] as Map<String, dynamic>)['nombre'],
            }),
          )
          .toList();
    } catch (e) {
      // Si falla DISTINCT ON, usar el método manual
      return await obtenerTopPuntajes(limite: limite);
    }
  }

  Future<List<Puntaje>> obtenerPuntajesUsuario(
    String usuarioId, {
    int limite = 20,
  }) async {
    try {
      final response = await _supabase
          .from('puntos')
          .select()
          .eq('usuario_id', usuarioId)
          .order('fecha', ascending: false)
          .limit(limite);

      final usuario = await obtenerUsuarioPorId(usuarioId);
      final nombreUsuario = usuario?.nombre ?? 'Desconocido';

      return (response as List)
          .map(
            (json) =>
                Puntaje.fromJson({...json, 'nombre_usuario': nombreUsuario}),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<Puntaje?> obtenerMejorPuntajeUsuario(String usuarioId) async {
    try {
      final response = await _supabase
          .from('puntos')
          .select()
          .eq('usuario_id', usuarioId)
          .order('puntos', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      final usuario = await obtenerUsuarioPorId(usuarioId);
      final nombreUsuario = usuario?.nombre ?? 'Desconocido';

      return Puntaje.fromJson({...response, 'nombre_usuario': nombreUsuario});
    } catch (e) {
      return null;
    }
  }
}
