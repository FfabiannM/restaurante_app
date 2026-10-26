import React, { useState, useMemo } from 'react';
import { useUsuarios } from '../hooks/useUsuarios';
import { Users, UserPlus, RefreshCw, CheckCircle2 } from 'lucide-react';

import UsuariosStats from '../components/UsuariosStats';
import UsuariosFilter from '../components/UsuariosFilter';
import UsuariosTable from '../components/UsuariosTable';
import UsuarioCreateModal from '../components/UsuarioCreateModal';
import UsuarioDetailsModal from '../components/UsuarioDetailsModal';
import UsuarioDeleteModal from '../components/UsuarioDeleteModal';
import UsuarioFamiliarModal from '../components/UsuarioFamiliarModal';

/**
 * Página Principal: UsuariosPage
 * 
 * Capa de Presentación:
 * - Orquesta la vista completa de administración de usuarios e integrantes.
 * - Conectada al hook useUsuarios (que consume Casos de Uso del Dominio).
 */
export default function UsuariosPage() {
  const {
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
  } = useUsuarios();

  // Estados locales de modales
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [selectedUser, setSelectedUser] = useState(null);
  const [userToDelete, setUserToDelete] = useState(null);
  const [isDeleting, setIsDeleting] = useState(false);
  const [familiarUserModal, setFamiliarUserModal] = useState(null);
  const [showGeneralFamiliarModal, setShowGeneralFamiliarModal] = useState(false);
  const [successToast, setSuccessToast] = useState(null);

  const showToast = (message) => {
    setSuccessToast(message);
    setTimeout(() => {
      setSuccessToast(null);
    }, 4000);
  };

  const handleToggleStatus = async (user) => {
    const displayName = user.nombreCompleto || `${user.nombres || ''} ${user.apellidos || ''}`.trim();
    try {
      const nextState = await toggleStatus(user);
      showToast(`Acceso ${nextState ? 'activado' : 'anulado'} para ${displayName}.`);
    } catch (err) {
      console.error('[UsuariosPage] Error toggling user status:', err);
      alert('Error al modificar el estado del usuario.');
    }
  };

  const handleDeleteUser = async (userId) => {
    try {
      setIsDeleting(true);
      await deleteUser(userId);
      showToast('Usuario eliminado permanentemente.');
      setUserToDelete(null);
    } catch (err) {
      console.error('[UsuariosPage] Error deleting user:', err);
      alert('Error al eliminar usuario.');
    } finally {
      setIsDeleting(false);
    }
  };

  // Cálculo de estadísticas memoizadas a partir de las entidades
  const stats = useMemo(() => {
    const total = usuarios.length;
    const adminCount = usuarios.filter((u) => u.isAdmin ? u.isAdmin() : u.rol === 'Administrador').length;
    const empleadoCount = usuarios.filter((u) => u.isEmpleado ? u.isEmpleado() : u.rol === 'Empleado').length;
    const institucionCount = usuarios.filter((u) => u.isInstitucion ? u.isInstitucion() : u.rol === 'Institucion').length;
    const activos = usuarios.filter((u) => u.isActivo ? u.isActivo() : u.activo !== false).length;

    return { total, adminCount, empleadoCount, institucionCount, activos };
  }, [usuarios]);

  const empleados = useMemo(() => {
    return usuarios.filter((u) => u.isEmpleado ? u.isEmpleado() : u.rol === 'Empleado');
  }, [usuarios]);

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-6 animate-fade-in">
      {/* Toast Notificación */}
      {successToast && (
        <div className="fixed bottom-5 right-5 z-50 bg-emerald-700 text-white px-5 py-3 rounded-2xl shadow-xl flex items-center space-x-2 text-sm font-semibold animate-slide-up">
          <CheckCircle2 className="w-5 h-5 text-emerald-300" />
          <span>{successToast}</span>
        </div>
      )}

      {/* Header Bar */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 pb-2 border-b border-slate-200">
        <div>
          <div className="flex items-center space-x-2 text-blue-600 mb-1">
            <Users className="w-6 h-6" />
            <h1 className="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight">
              Gestión de Usuarios e Integrantes
            </h1>
          </div>
          <p className="text-slate-500 text-sm">
            Administración institucional de credenciales, roles y dependientes familiares.
          </p>
        </div>

        {/* Action Buttons */}
        <div className="flex flex-wrap items-center gap-2.5">
          <button
            type="button"
            onClick={loadUsuarios}
            disabled={loading}
            className="p-2.5 bg-white border border-slate-200 text-slate-600 rounded-xl hover:bg-slate-50 transition shadow-2xs hover:text-slate-900 cursor-pointer"
            title="Recargar datos"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin text-blue-600' : ''}`} />
          </button>

          {empleados.length > 0 && (
            <button
              type="button"
              onClick={() => setShowGeneralFamiliarModal(true)}
              className="flex items-center space-x-2 px-3.5 py-2.5 bg-indigo-50 hover:bg-indigo-100 text-indigo-700 border border-indigo-200 rounded-xl text-sm font-semibold transition cursor-pointer"
            >
              <Users className="w-4 h-4" />
              <span>Familiares</span>
            </button>
          )}

          <button
            type="button"
            onClick={() => setShowCreateModal(true)}
            className="flex items-center space-x-2 px-4 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-sm font-semibold shadow-md shadow-blue-500/20 transition cursor-pointer"
          >
            <UserPlus className="w-4 h-4" />
            <span>Registrar Integrante</span>
          </button>
        </div>
      </div>

      {/* Stats Cards */}
      <UsuariosStats stats={stats} />

      {/* Filters Bar */}
      <UsuariosFilter
        searchTerm={searchTerm}
        onSearchChange={setSearchTerm}
        roleFilter={roleFilter}
        onRoleChange={setRoleFilter}
        statusFilter={statusFilter}
        onStatusChange={setStatusFilter}
      />

      {/* Main Table */}
      <UsuariosTable
        usuarios={filteredUsuarios}
        totalCount={usuarios.length}
        loading={loading}
        error={error}
        onRetry={loadUsuarios}
        actionLoadingId={actionLoadingId}
        onSelectDetails={(u) => setSelectedUser(u)}
        onToggleStatus={handleToggleStatus}
        onDeleteClick={(u) => setUserToDelete(u)}
        onManageFamiliares={(u) => setFamiliarUserModal(u)}
      />

      {/* Modals */}
      <UsuarioCreateModal
        isOpen={showCreateModal}
        onClose={() => setShowCreateModal(false)}
        onCreateUser={registerUser}
        showToast={showToast}
      />

      <UsuarioDetailsModal
        isOpen={Boolean(selectedUser)}
        user={selectedUser}
        onClose={() => setSelectedUser(null)}
        onOpenFamiliares={(u) => setFamiliarUserModal(u)}
      />

      <UsuarioDeleteModal
        isOpen={Boolean(userToDelete)}
        user={userToDelete}
        onClose={() => setUserToDelete(null)}
        onConfirm={handleDeleteUser}
        isDeleting={isDeleting}
      />

      {/* Modal de Familiares específico para un empleado */}
      <UsuarioFamiliarModal
        isOpen={Boolean(familiarUserModal)}
        onClose={() => setFamiliarUserModal(null)}
        employee={familiarUserModal}
        showToast={showToast}
      />

      {/* Modal de Familiares general con selector de empleados */}
      <UsuarioFamiliarModal
        isOpen={showGeneralFamiliarModal}
        onClose={() => setShowGeneralFamiliarModal(false)}
        employees={empleados}
        showToast={showToast}
      />
    </div>
  );
}
