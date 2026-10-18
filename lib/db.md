# Documentación del Esquema de Base de Datos - Supabase

Este documento describe la arquitectura de base de datos en Supabase para el sistema de gestión del comedor institucional y reservas.

## Conexión con Supabase
- **URL**: `https://qnieqczrdyxyhpepjduj.supabase.co`
- **Anon Key**: `sb_publishable_s7ww56WzXyW76KlH-cqvfQ_SgdpLsX7`

---

## Tarifas Fijas del Sistema
1. **15 Bs** para comensales bajo **Plan Mensual** (empleado o familiar asociado).
2. **18 Bs** para comensales particulares / sin plan mensual registrado.

---

## Esquema DDL de Tablas Principales

```sql
-- 1. Usuarios y Empleados
CREATE TABLE public.usuarios (  
  id uuid NOT NULL,  
  ci text NOT NULL UNIQUE,  
  nombres text NOT NULL CHECK (btrim(nombres) <> ''::text),  
  apellidos text NOT NULL CHECK (btrim(apellidos) <> ''::text),  
  email text NOT NULL UNIQUE CHECK (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'::text),  
  telefono text,  
  rol USER-DEFINED NOT NULL DEFAULT 'EMPLEADO'::rol_usuario,  
  activo boolean NOT NULL DEFAULT true,  
  creado_en timestamp with time zone NOT NULL DEFAULT now(),  
  CONSTRAINT usuarios_pkey PRIMARY KEY (id),  
  -- El padrón puede contener empleados sin cuenta de acceso en auth.users.
);  

-- 2. Familiares asociados a un Empleado (Hasta 3 familiares por empleado)
CREATE TABLE public.familiares (  
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,  
  empleado_id uuid NOT NULL,  
  ci text NOT NULL,  
  nombres text NOT NULL CHECK (btrim(nombres) <> ''::text),  
  apellidos text NOT NULL CHECK (btrim(apellidos) <> ''::text),  
  parentesco USER-DEFINED NOT NULL,  
  activo boolean NOT NULL DEFAULT true,  
  creado_en timestamp with time zone NOT NULL DEFAULT now(),  
  CONSTRAINT familiares_pkey PRIMARY KEY (id),  
  CONSTRAINT familiares_empleado_id_fkey FOREIGN KEY (empleado_id) REFERENCES public.usuarios(id)  
);  

-- 3. Catálogo de Gastronomía Boliviana
CREATE TABLE public.platos_catalogo (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  nombre text NOT NULL UNIQUE CHECK (btrim(nombre) <> ''),
  descripcion text,
  categoria text NOT NULL DEFAULT 'Segundo', -- Entrada, Sopa, Segundo, Vegetariano, Especial, Postre
  region text,                               -- Cochabamba, Santa Cruz, La Paz, Tarija, Chuquisaca, etc.
  precio numeric NOT NULL DEFAULT 18.00 CHECK (precio >= 0),
  imagen_url text,
  activo boolean NOT NULL DEFAULT true,
  creado_en timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT platos_catalogo_pkey PRIMARY KEY (id)
);

-- 4. Menú Semanal (Planificado por Cocina)
CREATE TABLE public.menu_semanal (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  fecha date NOT NULL,
  dia_semana text NOT NULL, -- 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'
  plato_catalogo_id bigint NOT NULL,
  tipo_plato text NOT NULL DEFAULT 'Segundo',
  estado text NOT NULL DEFAULT 'borrador' CHECK (estado IN ('borrador', 'publicado')),
  creado_por uuid,
  creado_en timestamp with time zone NOT NULL DEFAULT now(),
  actualizado_en timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT menu_semanal_pkey PRIMARY KEY (id),
  CONSTRAINT menu_semanal_plato_catalogo_id_fkey FOREIGN KEY (plato_catalogo_id) REFERENCES public.platos_catalogo(id) ON DELETE CASCADE,
  CONSTRAINT menu_semanal_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES public.usuarios(id)
);

-- 5. Suscripciones / Membresías a Plan Mensual
CREATE TABLE public.suscripciones (  
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,  
  empleado_id uuid NOT NULL,  
  mes date NOT NULL CHECK (mes = date_trunc('month'::text, mes::timestamp with time zone)::date),  
  modalidad USER-DEFINED NOT NULL,  
  vegetariano boolean NOT NULL DEFAULT false,  
  activo boolean NOT NULL DEFAULT true,
  creado_en timestamp with time zone NOT NULL DEFAULT now(),  
  CONSTRAINT suscripciones_pkey PRIMARY KEY (id),  
  CONSTRAINT suscripciones_empleado_id_fkey FOREIGN KEY (empleado_id) REFERENCES public.usuarios(id)  
);  

-- 6. Reservas de Almuerzo (Empleado o Familiar)
CREATE TABLE public.reservas (  
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,  
  empleado_id uuid NOT NULL,  
  familiar_id bigint,  
  fecha date NOT NULL,  
  estado USER-DEFINED NOT NULL DEFAULT 'ACTIVA'::estado_reserva,  
  tipo_tarifa text NOT NULL DEFAULT 'PARTICULAR' CHECK (tipo_tarifa IN ('PLAN_MENSUAL', 'PARTICULAR')),  
  precio numeric NOT NULL DEFAULT 18.00 CHECK (precio >= 0),  
  vegetariano boolean NOT NULL DEFAULT false,  
  notas text,  
  creado_en timestamp with time zone NOT NULL DEFAULT now(),  
  cancelado_en timestamp with time zone,  
  CONSTRAINT reservas_pkey PRIMARY KEY (id),  
  CONSTRAINT reservas_empleado_id_fkey FOREIGN KEY (empleado_id) REFERENCES public.usuarios(id),  
  CONSTRAINT reservas_familiar_id_fkey FOREIGN KEY (familiar_id) REFERENCES public.familiares(id)  
);  

-- 7. Tarifas y Acuerdos
CREATE TABLE public.tarifas (  
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,  
  tipo USER-DEFINED NOT NULL,  
  consumidor USER-DEFINED NOT NULL,  
  precio numeric NOT NULL CHECK (precio >= 0::numeric),  
  vigente_desde date NOT NULL,  
  vigente_hasta date,  
  CONSTRAINT tarifas_pkey PRIMARY KEY (id)  
);  

-- 8. Calendario institucional y feriados
CREATE TABLE public.calendario (  
  fecha date NOT NULL,  
  habilitado boolean NOT NULL,  
  motivo text,  
  CONSTRAINT calendario_pkey PRIMARY KEY (fecha)  
);  
```

---

## Políticas de Seguridad (RLS)

Para permitir que el administrador registre empleados desde la aplicación,
ejecuta la migración
`supabase/migrations/20261018_admin_employee_rls.sql` en el SQL Editor de
Supabase. Esta migración habilita las operaciones administrativas sobre
`usuarios` y `familiares` y elimina la dependencia de `usuarios.id` respecto
de `auth.users(id)`.

1. **`platos_catalogo`**:
   - Lectura pública para cualquier usuario institucional autenticado.
   - Creación, actualización y desactivación restringida a roles `ADMIN` y `COCINA`.
2. **`menu_semanal`**:
   - Los empleados solo tienen acceso de lectura si el estado es `'publicado'`.
   - El personal de `COCINA` y `ADMIN` pueden consultar y modificar en estado `'borrador'` y publicar el menú.
3. **`reservas`**:
   - Cada empleado puede ver, registrar y cancelar sus propias reservas y las de sus familiares vinculados.
   - La cocina y los administradores tienen acceso global para auditar y marcar entregas.

---

## Platos Preestablecidos de Gastronomía Boliviana
- Silpancho Cochabambino
- Pique Macho Especial
- Majadito Cruceño con Huevo y Plátano
- Sopa de Maní Tradicional
- Falso Conejo
- Saice Tarijeño
- Chairo Paceño
- Picante Mixto
- Mondongo Chuquisaqueño
- Trucha del Titicaca al Limón
- Ají de Papalisa
- Pastel de Fideo Tradicional