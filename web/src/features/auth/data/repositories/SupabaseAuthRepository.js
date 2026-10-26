import { IAuthRepository } from '../../domain/repositories/IAuthRepository';
import { UserModel } from '../models/UserModel';
import { supabase as defaultSupabase } from '../../../../core/config/supabaseClient';
import { AuthenticationError, AppError } from '../../../../core/errors/AppError';

/**
 * Repositorio Concreto: SupabaseAuthRepository
 * 
 * Implementa el contrato IAuthRepository usando Supabase y la vista 'vista_usuarios'.
 * Convierte cualquier respuesta cruda de Supabase en Entidades de Dominio (User).
 */
export class SupabaseAuthRepository extends IAuthRepository {
  /**
   * @param {import('@supabase/supabase-js').SupabaseClient} client
   */
  constructor(client = defaultSupabase) {
    super();
    this.client = client;
  }

  async login(email, password) {
    const { data, error } = await this.client.auth.signInWithPassword({
      email,
      password,
    });

    if (error) {
      if (error.message?.includes('Invalid login credentials')) {
        throw new AuthenticationError('Credenciales inválidas. Revise su correo y contraseña.');
      }
      throw new AuthenticationError(error.message, error);
    }

    const profile = await this.getProfile(data.user.id);
    const domainUser = UserModel.fromSupabase(data.user, profile);

    return {
      user: domainUser,
      session: data.session,
    };
  }

  async logout() {
    const { error } = await this.client.auth.signOut();
    if (error) {
      throw new AppError(error.message, 'LOGOUT_ERROR', error);
    }
  }

  async getCurrentSession() {
    const { data: { session }, error } = await this.client.auth.getSession();
    if (error || !session?.user) {
      return { user: null, session: null };
    }

    const profile = await this.getProfile(session.user.id);
    const domainUser = UserModel.fromSupabase(session.user, profile);

    return {
      user: domainUser,
      session,
    };
  }

  async getProfile(userId) {
    try {
      const { data, error } = await this.client
        .from('vista_usuarios')
        .select('*')
        .eq('id_usuario', userId)
        .maybeSingle();

      if (error) {
        console.warn('[SupabaseAuthRepository] Error al obtener vista_usuarios:', error.message);
        return null;
      }

      return data;
    } catch (err) {
      console.warn('[SupabaseAuthRepository] Excepción al obtener perfil:', err);
      return null;
    }
  }

  onAuthStateChange(callback) {
    const { data: { subscription } } = this.client.auth.onAuthStateChange(async (event, session) => {
      if (session?.user) {
        const profile = await this.getProfile(session.user.id);
        const domainUser = UserModel.fromSupabase(session.user, profile);
        callback({ user: domainUser, session });
      } else {
        callback({ user: null, session: null });
      }
    });

    return {
      unsubscribe: () => subscription?.unsubscribe(),
    };
  }
}
