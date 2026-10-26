import React, { useState } from 'react';
import { useAuth } from '../hooks/useAuth';
import { LoginForm } from '../components/LoginForm';
import { UtensilsCrossed } from 'lucide-react';

/**
 * Página Principal: LoginPage
 * 
 * Capa de Presentación:
 * - Orquesta la vista completa de autenticación.
 * - Conecta el hook useAuth (que consume los casos de uso) con los componentes visuales.
 */
export default function LoginPage() {
  const { login } = useAuth();
  const [loading, setLoading] = useState(false);
  const [loginError, setLoginError] = useState('');

  const handleLogin = async (email, password) => {
    setLoginError('');
    setLoading(true);
    try {
      await login(email, password);
    } catch (err) {
      setLoginError(err.message || 'Error al iniciar sesión.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div 
      className="relative min-h-screen w-full flex items-center justify-center p-4 bg-cover bg-center bg-no-repeat selection:bg-blue-500 selection:text-white"
      style={{
        backgroundImage: "url('/bg-restaurante.jpg'), url('https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1920&q=80')"
      }}
    >
      {/* Overlay con desenfoque elegante */}
      <div className="absolute inset-0 bg-gradient-to-tr from-black/80 via-black/60 to-black/75 backdrop-blur-[2px]" />

      {/* Tarjeta de Login */}
      <div className="relative z-10 w-full max-w-md bg-white/95 backdrop-blur-xl rounded-2xl shadow-2xl overflow-hidden border border-white/40">
        <div className="bg-gradient-to-r from-blue-600 to-indigo-600 text-white p-6 sm:p-8 text-center relative">
          <div className="mx-auto w-16 h-16 rounded-2xl bg-white/15 backdrop-blur-md flex items-center justify-center mb-3 shadow-inner border border-white/20 transform transition hover:scale-105">
            <UtensilsCrossed className="w-8 h-8 text-white" />
          </div>
          <h2 className="text-2xl sm:text-3xl font-extrabold tracking-tight">Rumbo al Cielo</h2>
          <p className="text-blue-100 text-sm mt-1 font-medium">Sistema de Gestión & Administración</p>

          <div className="absolute -bottom-3 left-1/2 transform -translate-x-1/2 bg-blue-50 text-blue-800 text-[11px] font-bold uppercase tracking-wider px-3 py-0.5 rounded-full shadow-sm border border-blue-200">
            Acceso al Sistema
          </div>
        </div>

        <div className="p-6 sm:p-8 pt-7 bg-slate-50/80">
          <LoginForm 
            onLogin={handleLogin} 
            isLoading={loading} 
            externalError={loginError} 
          />

          <div className="mt-6 text-center text-xs text-slate-500">
            ¿Problemas para acceder? Contacte a soporte o administración institucional.
          </div>
        </div>
      </div>
    </div>
  );
}
