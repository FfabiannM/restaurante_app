import { ICalendarioRepository } from '../../domain/repositories/ICalendarioRepository';
import { ExcepcionCalendarioModel } from '../models/ExcepcionCalendarioModel';
import { supabase as defaultSupabase } from '../../../../core/config/supabaseClient';
import { AppError } from '../../../../core/errors/AppError';

/**
 * Repositorio Concreto: SupabaseCalendarioRepository
 * 
 * Implementa ICalendarioRepository comunicándose con la tabla 'excepcion_calendario' de Supabase.
 */
export class SupabaseCalendarioRepository extends ICalendarioRepository {
  /**
   * @param {import('@supabase/supabase-js').SupabaseClient} client
   */
  constructor(client = defaultSupabase) {
    super();
    this.client = client;
  }

  async getExcepciones() {
    const { data, error } = await this.client
      .from('excepcion_calendario')
      .select('*')
      .order('fecha', { ascending: true });

    if (error) {
      throw new AppError(error.message, 'FETCH_EXCEPCIONES_ERROR', error);
    }

    return (data || []).map((row) => ExcepcionCalendarioModel.fromSupabase(row));
  }

  async checkExcepcionExists(fecha) {
    const { data, error } = await this.client
      .from('excepcion_calendario')
      .select('fecha')
      .eq('fecha', fecha)
      .maybeSingle();

    if (error) {
      throw new AppError(error.message, 'CHECK_EXCEPCION_ERROR', error);
    }

    return Boolean(data);
  }

  async createExcepcion({ fecha, motivo, id_encargado }) {
    const { data, error } = await this.client
      .from('excepcion_calendario')
      .insert([
        {
          fecha,
          motivo,
          id_encargado,
        },
      ])
      .select()
      .single();

    if (error) {
      throw new AppError(error.message, 'CREATE_EXCEPCION_ERROR', error);
    }

    return ExcepcionCalendarioModel.fromSupabase(data);
  }

  async deleteExcepcion(excepcion) {
    let query = this.client.from('excepcion_calendario').delete();

    if (excepcion.id_excepcion) {
      query = query.eq('id_excepcion', excepcion.id_excepcion);
    } else if (excepcion.id) {
      query = query.eq('id', excepcion.id);
    } else if (excepcion.fecha) {
      query = query.eq('fecha', excepcion.fecha);
    } else {
      throw new AppError('Identificador de excepción no válido.', 'VALIDATION_ERROR');
    }

    const { error } = await query;
    if (error) {
      throw new AppError(error.message, 'DELETE_EXCEPCION_ERROR', error);
    }
  }
}
