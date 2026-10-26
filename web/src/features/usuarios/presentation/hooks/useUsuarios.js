import { useState, useEffect, useCallback, useMemo } from 'react';
import { 
  getUsuariosUseCase, 
  toggleUsuarioEstadoUseCase, 
  deleteUsuarioUseCase,
  registerUsuarioUseCase 
} from '../../di';

/**
 * Hook de Presentación: useUsuarios
 * 
 * Regla de Clean Architecture:
 * - NO importa Supabase.
 * - Solo consume los Casos de Uso del Dominio (GetUsuariosUseCase, ToggleUsuarioEstadoUseCase, etc.).
 */
export function useUsuarios() {
  const [usuarios, setUsuarios] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [roleFilter, setRoleFilter] = useState('ALL');
  const [statusFilter, setStatusFilter] = useState('ALL');
  const [actionLoadingId, setActionLoadingId] = useState(null);

  const loadUsuarios = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await getUsuariosUseCase.execute();
      setUsuarios(data);
    } catch (err) {
      console.error('[useUsuarios] Error al cargar usuarios:', err);
      setError(err.message || 'No se pudieron cargar los usuarios.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadUsuarios();
  }, [loadUsuarios]);

  const toggleStatus = async (user) => {
    const nextState = !user.activo;
    try {
      setActionLoadingId(user.id_usuario);
      await toggleUsuarioEstadoUseCase.execute(user.id_usuario, nextState);
      setUsuarios((prev) =>
        prev.map((u) => {
          if (u.id_usuario === user.id_usuario) {
            u.activo = nextState;
          }
          return u;
        })
      );
      return nextState;
    } finally {
      setActionLoadingId(null);
    }
  };

  const deleteUser = async (id_usuario) => {
    await deleteUsuarioUseCase.execute(id_usuario);
    setUsuarios((prev) => prev.filter((u) => u.id_usuario !== id_usuario));
  };

  const registerUser = async (userData) => {
    const newUser = await registerUsuarioUseCase.execute(userData);
    await loadUsuarios(); // Refrescar lista completa
    return newUser;
  };

  const filteredUsuarios = useMemo(() => {
    return usuarios.filter((u) => {
      // Filtro de búsqueda
      const search = searchTerm.toLowerCase().trim();
      const matchSearch =
        !search ||
        u.nombreCompleto.toLowerCase().includes(search) ||
        u.email.toLowerCase().includes(search) ||
        u.ci_codigo.toLowerCase().includes(search) ||
        u.telefono.toLowerCase().includes(search);

      // Filtro de rol
      const matchRole =
        roleFilter === 'ALL' || u.rol?.toUpperCase() === roleFilter.toUpperCase();

      // Filtro de estado
      const matchStatus =
        statusFilter === 'ALL' ||
        (statusFilter === 'ACTIVO' && u.activo) ||
        (statusFilter === 'INACTIVO' && !u.activo);

      return matchSearch && matchRole && matchStatus;
    });
  }, [usuarios, searchTerm, roleFilter, statusFilter]);

  return {
    usuarios,
    filteredUsuarios,
    loading,
    error,
    searchTerm,
    setSearchTerm,
    roleFilter,
    setRoleFilter,
    statusFilter,
    setStatusFilter,
    actionLoadingId,
    loadUsuarios,
    toggleStatus,
    deleteUser,
    registerUser,
  };
}
