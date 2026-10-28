import { createClient } from '@supabase/supabase-js';
import { IUsuarioRepository } from '../../domain/repositories/IUsuarioRepository';
import { UsuarioModel } from '../models/UsuarioModel';
import { supabase as defaultSupabase } from '../../../../core/config/supabaseClient';
import { AppError } from '../../../../core/errors/AppError';

/**
 * Repositorio Concreto: SupabaseUsuarioRepository
 * 
 * Implementa IUsuarioRepository comunicándose con Supabase y la vista 'vista_usuarios'.
 */
export class SupabaseUsuarioRepository extends IUsuarioRepository {
  /**
   * @param {import('@supabase/supabase-js').SupabaseClient} client
   */
  constructor(client = defaultSupabase) {
    super();
    this.client = client;
  }

  async getUsuarios() {
    const { data, error } = await this.client
      .from('vista_usuarios')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) {
      throw new AppError(error.message, 'FETCH_USERS_ERROR', error);
    }

    return (data || []).map((row) => UsuarioModel.fromSupabase(row));
  }

  async checkUniqueness({ ci_codigo, email, telefono }) {
    let isCiAvailable = true;
    let isEmailAvailable = true;
    let isPhoneAvailable = true;

    if (ci_codigo) {
      const { data: ciRow } = await this.client
        .from('vista_usuarios')
        .select('id_usuario')
        .eq('ci_codigo', ci_codigo.trim())
        .maybeSingle();
      if (ciRow) isCiAvailable = false;
    }

    if (email) {
      const { data: emailRow } = await this.client
        .from('vista_usuarios')
        .select('id_usuario')
        .eq('email', email.trim().toLowerCase())
        .maybeSingle();
      if (emailRow) isEmailAvailable = false;
    }

    if (telefono) {
      const { data: phoneRow } = await this.client
        .from('vista_usuarios')
        .select('id_usuario')
        .eq('telefono', telefono.trim())
        .maybeSingle();
      if (phoneRow) isPhoneAvailable = false;
    }

    return { isCiAvailable, isEmailAvailable, isPhoneAvailable };
  }

  async registerUsuario(userData) {
    const { email, password, nombre, apellidos, ci_codigo, telefono, rol } = userData;

    // Cliente aislado sin persistencia de sesión para no desloguear al Administrador actual
    const supabaseUrl = (import.meta.env.VITE_SUPABASE_URL || '').trim();
    const supabaseAnonKey = (import.meta.env.VITE_SUPABASE_ANON_KEY || '').trim();

    const tempAuthClient = createClient(
      supabaseUrl || 'https://placeholder.supabase.co',
      supabaseAnonKey || 'placeholder-anon-key',
      {
        auth: {
          persistSession: false,
          autoRefreshToken: false,
          detectSessionInUrl: false,
        },
      }
    );

    const { data, error } = await tempAuthClient.auth.signUp({
      email: email.trim().toLowerCase(),
      password,
      options: {
        data: {
          nombre: nombre.trim(),
          nombres: nombre.trim(),
          apellidos: apellidos.trim(),
          ci_codigo: ci_codigo.trim(),
          telefono: telefono.trim(),
          rol,
        },
      },
    });

    if (error) {
      throw new AppError(error.message || 'Error al registrar el usuario en Supabase', 'SIGNUP_ERROR', error);
    }

    return UsuarioModel.fromSupabase({
      id_usuario: data.user?.id,
      email,
      nombre,
      apellidos,
      ci_codigo,
      telefono,
      rol,
      activo: true,
      created_at: new Date().toISOString(),
    });
  }

  async toggleEstado(id_usuario, nuevoEstado) {
    const { error } = await this.client
      .from('usuario')
      .update({ activo: nuevoEstado })
      .eq('id_usuario', id_usuario);

    if (error) {
      throw new AppError(error.message, 'UPDATE_STATUS_ERROR', error);
    }
  }

  async deleteUsuario(id_usuario) {
    const { error } = await this.client
      .from('usuario')
      .delete()
      .eq('id_usuario', id_usuario);

    if (error) {
      throw new AppError(error.message, 'DELETE_USER_ERROR', error);
    }
  }

  async getSolicitudesRecuperacion() {
    const { data, error } = await this.client.rpc('obtener_solicitudes_recuperacion');
    if (error) {
      // Fallback tabla directa
      const { data: directData, error: dirErr } = await this.client
        .from('solicitud_recuperacion')
        .select('*')
        .order('fecha_solicitud', { ascending: false });
      if (dirErr) {
        throw new AppError(dirErr.message, 'FETCH_SOLICITUDES_ERROR', dirErr);
      }
      return directData || [];
    }
    return data || [];
  }

  async cambiarPasswordUsuario(id_usuario, nuevo_password) {
    const { data, error } = await this.client.rpc('admin_cambiar_password_usuario', {
      p_id_usuario: id_usuario,
      p_nuevo_password: nuevo_password,
    });

    if (error) {
      throw new AppError(error.message, 'CHANGE_PASSWORD_ERROR', error);
    }

    if (data && data.success === false) {
      throw new AppError(data.message || 'Error al cambiar contraseña', 'CHANGE_PASSWORD_ERROR');
    }

    return data || { success: true, message: 'Contraseña actualizada con éxito.' };
  }
}

