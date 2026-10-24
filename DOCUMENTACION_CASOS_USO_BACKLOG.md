# Restaurante App: casos de uso y backlog

## 1. Propósito del documento

Este documento describe la funcionalidad actual de **Restaurante App** y sirve como
base para:

- documentar el producto;
- elaborar diagramas de casos de uso;
- redactar historias de usuario;
- organizar un backlog de desarrollo y pruebas;
- identificar funcionalidades pendientes.

La aplicación está desarrollada con Flutter para Android y Web. Utiliza Supabase
para autenticación, base de datos, reglas de acceso (RLS), almacenamiento de
imágenes y funciones del backend.

> **Importante:** la sección de funcionalidades implementadas refleja el código
> existente. Los elementos marcados como `Pendiente` son propuestas de backlog y
> deben validarse con el responsable del negocio antes de implementarse.

---

## 2. Objetivo del sistema

Centralizar la operación de un restaurante institucional:

1. publicar el menú diario y semanal;
2. permitir que los empleados consulten el menú;
3. registrar y administrar reservas de almuerzos;
4. administrar familiares y beneficiarios;
5. controlar pensiones o suscripciones mensuales;
6. permitir al personal de cocina consultar y atender las reservas;
7. permitir a administradores gestionar empleados, platos, feriados y datos
   operativos.

---

## 3. Actores

| Actor | Descripción | Responsabilidades principales |
|---|---|---|
| Visitante | Usuario que aún no inició sesión | Consultar las pantallas públicas habilitadas, principalmente el menú |
| Empleado | Usuario autenticado que consume el servicio | Consultar menú, gestionar reservas, gestionar familiares, consultar pensión y actualizar su perfil |
| Administrador | Usuario con permisos de administración | Gestionar empleados, platos, menú, feriados, pensiones y operaciones |
| Cocina | Usuario responsable de la preparación y atención | Consultar reservas y marcar pedidos como atendidos |
| Supabase | Sistema externo de backend | Autenticación, persistencia, autorización, almacenamiento y funciones |

### Roles reconocidos por la aplicación

- `empleado`
- `admin`
- `cocina`

---

## 4. Módulos funcionales

### 4.1. Autenticación y perfil

- Inicio de sesión con correo y contraseña.
- Persistencia de la sesión mediante Supabase Auth.
- Recuperación y cambio de contraseña según el flujo disponible.
- Carga del perfil del usuario y su rol.
- Cierre de sesión.
- Visualización y actualización de datos del perfil.
- Modo local/demo cuando Supabase no está disponible o no está configurado.

### 4.2. Menú

- Consulta del menú por día y por semana.
- Visualización de platos, categorías e imágenes.
- Soporte para platos bolivianos y categorías de alimentos.
- Menú diario con reglas de publicación y disponibilidad.
- Gestión de imágenes mediante el bucket de Supabase Storage `platos`.
- Gestión administrativa del menú semanal.
- Publicación del menú para que esté visible a los usuarios.

### 4.3. Reservas

- Consulta de fechas disponibles mediante calendario.
- Consulta de feriados y fechas bloqueadas.
- Creación de una reserva para el usuario.
- Reserva de almuerzo completo o de una opción del menú, según disponibilidad.
- Consulta de reservas propias.
- Cancelación o modificación cuando las reglas del negocio lo permiten.
- Priorización o tratamiento diferenciado de personas adultas mayores, según las
  reglas implementadas.
- Visualización operativa de reservas para empleados autorizados y cocina.

### 4.4. Familiares

- Registro de familiares asociados a un empleado.
- Consulta de familiares.
- Edición y eliminación según permisos.
- Validación de parentesco y límites de acuerdo con las políticas de familia.
- Uso de familiares como beneficiarios de una reserva cuando corresponde.

### 4.5. Pensiones

- Consulta de la pensión o suscripción mensual del empleado.
- Visualización del estado y del gasto mensual configurado.
- Integración con el calendario y la operación de reservas.

### 4.6. Administración

- Gestión de empleados.
- Asignación y consulta de roles.
- Consulta de información institucional.
- Gestión de platos y categorías.
- Gestión del menú semanal.
- Gestión de feriados.
- Consulta y control de operaciones relacionadas con reservas.
- Funciones administrativas protegidas por autenticación y RLS.

### 4.7. Cocina

- Consulta de las reservas y pedidos del día.
- Visualización de la información necesaria para preparar los pedidos.
- Marcado de pedidos como atendidos.
- Manejo de estados de carga, errores y ausencia de datos.

---

## 5. Reglas de negocio identificadas

Estas reglas deben conservarse al modificar la aplicación:

1. Un usuario no autenticado no debe acceder a funciones privadas.
2. El rol determina la pantalla inicial y las opciones disponibles.
3. Un empleado solo puede consultar o modificar sus propios datos y reservas,
   salvo las operaciones explícitamente permitidas.
4. El administrador puede gestionar información operativa y empleados.
5. Cocina debe tener acceso a la información necesaria para preparar y atender
   pedidos, sin obtener permisos administrativos innecesarios.
6. No se deben crear reservas en fechas feriadas o bloqueadas.
7. La disponibilidad del menú depende de su publicación y de la fecha
   seleccionada.
8. Las reglas de familiares y parentesco se validan antes de guardar cambios.
9. Las operaciones sensibles deben estar protegidas tanto en la interfaz como en
   las políticas RLS de Supabase.
10. La aplicación puede iniciar en modo demo/local si el backend remoto no está
    disponible; este modo no debe confundirse con una reserva persistida.

---

## 6. Casos de uso

### CU-01. Iniciar sesión

**Actor principal:** Empleado, Administrador o Cocina  
**Objetivo:** acceder a las funciones correspondientes al rol del usuario.

**Precondiciones**

- El usuario tiene una cuenta registrada.
- Existe conexión con Supabase, o la aplicación está operando en modo demo.

**Flujo principal**

1. El usuario introduce correo y contraseña.
2. El sistema valida los campos.
3. Supabase Auth valida las credenciales.
4. El sistema carga el perfil y el rol.
5. El sistema muestra la pantalla inicial correspondiente.

**Flujos alternativos**

- Credenciales inválidas: se muestra un mensaje de error.
- Usuario sin perfil válido: se informa el problema y no se habilitan funciones
  que requieran autorización.
- Sin conexión: se mantiene el modo local/demo cuando corresponda.

**Criterios de aceptación**

- Una credencial válida permite entrar.
- Una credencial inválida no permite entrar.
- La pantalla inicial depende del rol.
- El mensaje de error no expone información sensible.

### CU-02. Consultar el menú

**Actor principal:** Visitante o Empleado  
**Objetivo:** conocer los platos disponibles para una fecha.

**Flujo principal**

1. El actor abre el módulo de menú.
2. Selecciona una fecha o semana.
3. El sistema consulta el menú publicado.
4. El sistema muestra los platos, categorías e imágenes disponibles.

**Criterios de aceptación**

- El usuario puede cambiar de fecha.
- Los platos sin imagen mantienen una presentación válida.
- Un menú no publicado no aparece como menú público.
- Se muestra un estado comprensible cuando no hay menú.

### CU-03. Crear una reserva

**Actor principal:** Empleado  
**Objetivo:** reservar un almuerzo para una fecha permitida.

**Precondiciones**

- El empleado inició sesión.
- Existe menú o modalidad de almuerzo disponible.
- La fecha no está bloqueada.

**Flujo principal**

1. El empleado abre el calendario.
2. Selecciona una fecha disponible.
3. Selecciona la opción de menú o almuerzo completo.
4. El sistema valida disponibilidad, reglas de fecha y límites del usuario.
5. El sistema guarda la reserva.
6. El sistema confirma la operación y actualiza el calendario.

**Flujos alternativos**

- Fecha feriada: la reserva se rechaza con una explicación.
- Ya existe una reserva: el sistema evita duplicarla.
- Se alcanzó el límite permitido: el sistema informa la regla aplicable.
- Error de red: la reserva no se muestra como exitosa si no fue persistida.

### CU-04. Consultar y administrar mis reservas

**Actor principal:** Empleado  
**Objetivo:** revisar el historial y el estado de sus reservas.

**Flujo principal**

1. El empleado abre “Mis reservas”.
2. El sistema carga sus reservas.
3. El empleado filtra o revisa las fechas.
4. El empleado cancela o modifica una reserva si la política lo permite.

**Criterios de aceptación**

- Solo se muestran reservas pertenecientes al usuario.
- El estado de la reserva es visible.
- Las acciones no permitidas se deshabilitan o explican claramente.

### CU-05. Gestionar familiares

**Actor principal:** Empleado  
**Objetivo:** administrar beneficiarios familiares.

**Flujo principal**

1. El empleado abre el módulo de familiares.
2. Crea o edita los datos del familiar.
3. Selecciona el parentesco.
4. El sistema valida los datos y las políticas de familia.
5. El sistema guarda y muestra el familiar actualizado.

### CU-06. Consultar pensión

**Actor principal:** Empleado  
**Objetivo:** consultar el estado de su pensión o suscripción mensual.

**Flujo principal**

1. El empleado abre el módulo de pensión.
2. El sistema carga su información mensual.
3. El sistema muestra estado, importe y datos relevantes.

### CU-07. Gestionar empleados

**Actor principal:** Administrador  
**Objetivo:** crear, editar, consultar o desactivar empleados.

**Flujo principal**

1. El administrador abre el módulo de empleados.
2. Consulta la lista.
3. Crea o edita un empleado.
4. Asigna los datos institucionales y el rol.
5. El sistema valida la información.
6. El backend crea o actualiza el usuario y su perfil.

**Criterios de aceptación**

- Solo un administrador puede ejecutar estas acciones.
- Los datos inválidos se rechazan antes de guardar.
- Un error del backend se informa explícitamente.
- El cambio de rol se refleja en el siguiente inicio de sesión.

### CU-08. Gestionar menú y platos

**Actor principal:** Administrador  
**Objetivo:** mantener el catálogo y publicar el menú.

**Flujo principal**

1. El administrador selecciona la semana.
2. Agrega, edita o retira platos.
3. Configura categorías, disponibilidad e imágenes.
4. Revisa la semana.
5. Publica el menú.

### CU-09. Gestionar feriados

**Actor principal:** Administrador  
**Objetivo:** bloquear fechas en las que no se atiende el restaurante.

1. El administrador registra o edita un feriado.
2. El sistema valida la fecha.
3. El calendario de reservas utiliza esa información.
4. Las reservas no permitidas se rechazan.

### CU-10. Atender pedidos en cocina

**Actor principal:** Cocina  
**Objetivo:** preparar y marcar como atendidos los pedidos del día.

1. Cocina abre la pantalla operativa.
2. El sistema carga las reservas correspondientes.
3. El usuario identifica el pedido.
4. Marca el pedido como atendido.
5. El sistema actualiza el estado para los usuarios autorizados.

---

## 7. Backlog inicial

### 7.1. Historias implementadas o parcialmente implementadas

| ID | Prioridad | Historia de usuario | Estado |
|---|---|---|---|
| US-001 | Alta | Como usuario registrado, quiero iniciar sesión para acceder a la aplicación | Implementado |
| US-002 | Alta | Como usuario, quiero cerrar sesión para proteger mi cuenta | Implementado |
| US-003 | Alta | Como empleado, quiero consultar el menú por fecha | Implementado |
| US-004 | Alta | Como empleado, quiero crear una reserva de almuerzo | Implementado |
| US-005 | Alta | Como empleado, quiero consultar mis reservas | Implementado |
| US-006 | Alta | Como empleado, quiero cancelar o modificar reservas permitidas | Parcial; validar reglas finales |
| US-007 | Media | Como empleado, quiero administrar mis familiares | Implementado |
| US-008 | Media | Como empleado, quiero consultar mi pensión mensual | Implementado |
| US-009 | Alta | Como administrador, quiero gestionar empleados y roles | Implementado |
| US-010 | Alta | Como administrador, quiero administrar el menú semanal | Implementado |
| US-011 | Media | Como administrador, quiero gestionar platos e imágenes | Implementado |
| US-012 | Media | Como administrador, quiero registrar feriados | Implementado |
| US-013 | Alta | Como cocina, quiero ver las reservas del día | Implementado |
| US-014 | Alta | Como cocina, quiero marcar pedidos como atendidos | Implementado |
| US-015 | Alta | Como sistema, quiero aplicar permisos RLS por usuario y rol | Implementado; requiere pruebas de seguridad |
| US-016 | Media | Como usuario, quiero ver un mensaje claro cuando Supabase no está disponible | Implementado en modo demo/híbrido |

### 7.2. Backlog recomendado

| ID | Prioridad | Historia de usuario | Criterio de aceptación principal |
|---|---|---|---|
| BL-001 | Alta | Como administrador, quiero un tablero con indicadores diarios para conocer reservas, atendidos y pendientes | Los indicadores coinciden con las reservas persistidas |
| BL-002 | Alta | Como administrador, quiero exportar reservas a CSV o Excel para preparar reportes | El archivo contiene filtros, fecha, usuario, menú y estado |
| BL-003 | Alta | Como empleado, quiero recibir confirmación de reserva por correo o notificación | La notificación se envía solo después de guardar correctamente |
| BL-004 | Alta | Como cocina, quiero filtrar pedidos por estado para priorizar la atención | Se pueden ver pendientes, atendidos y cancelados |
| BL-005 | Alta | Como administrador, quiero configurar horarios límite para reservar y cancelar | El sistema rechaza operaciones fuera del horario configurado |
| BL-006 | Alta | Como administrador, quiero auditar cambios sensibles | Se registra usuario, fecha, acción y valores modificados |
| BL-007 | Media | Como empleado, quiero ver el detalle de cada reserva | El detalle muestra fecha, platos, beneficiario, importe y estado |
| BL-008 | Media | Como administrador, quiero cargar imágenes desde la interfaz | La imagen se valida, almacena y vincula al plato |
| BL-009 | Media | Como empleado, quiero consultar el saldo o pagos de mi pensión | El saldo y los movimientos tienen fecha y estado |
| BL-010 | Media | Como usuario, quiero buscar platos por nombre o categoría | La búsqueda devuelve resultados sin recargar toda la pantalla |
| BL-011 | Media | Como administrador, quiero configurar precios y subsidios | El cálculo queda centralizado y es visible antes de confirmar |
| BL-012 | Media | Como empleado, quiero recibir advertencias antes de cancelar una reserva | La cancelación requiere confirmación y explica sus consecuencias |
| BL-013 | Baja | Como usuario, quiero cambiar el tema visual entre claro y oscuro | La preferencia persiste en el dispositivo |
| BL-014 | Baja | Como usuario, quiero utilizar la aplicación con accesibilidad mejorada | Textos, contraste y navegación cumplen criterios de accesibilidad |
| BL-015 | Baja | Como equipo, quiero pruebas automatizadas de integración con Supabase | Las operaciones críticas se prueban contra un entorno controlado |

---

## 8. Requisitos no funcionales

### Seguridad

- Aplicar autenticación a todas las operaciones privadas.
- Mantener políticas RLS alineadas con los permisos de la interfaz.
- No incluir claves secretas de Supabase en el cliente.
- Validar entradas tanto en Flutter como en el backend.
- Registrar errores sin exponer contraseñas, tokens ni datos sensibles.

### Disponibilidad y resiliencia

- Mostrar estados de carga, vacío y error.
- No confirmar operaciones que no fueron persistidas.
- Mantener un comportamiento claro cuando no exista conexión.
- Diferenciar datos demo de datos reales.

### Usabilidad

- Mostrar mensajes de éxito y error accionables.
- Evitar duplicidad de reservas.
- Confirmar acciones destructivas.
- Mantener navegación coherente por rol.

### Compatibilidad

- Validar la aplicación en Android.
- Validar la aplicación Web.
- Probar tamaños de pantalla pequeños y grandes.
- Verificar carga de imágenes desde Supabase Storage y desde assets locales.

---

## 9. Entidades principales

| Entidad | Propósito |
|---|---|
| `profiles` | Datos del usuario, rol, departamento y configuración relacionada |
| `dishes` / `platos` | Catálogo de platos, categorías e imágenes |
| `reservations` | Reservas de empleados y beneficiarios |
| `holidays` | Fechas en las que no se permite reservar |
| `monthly_subscriptions` | Información de pensión o suscripción mensual |
| `auth.users` | Identidad y credenciales administradas por Supabase Auth |
| Storage `platos` | Imágenes públicas o controladas de los platos |

---

## 10. Matriz de permisos resumida

| Funcionalidad | Visitante | Empleado | Cocina | Administrador |
|---|---:|---:|---:|---:|
| Ver menú público | Sí | Sí | Sí | Sí |
| Iniciar/cerrar sesión | Sí | Sí | Sí | Sí |
| Crear reserva | No | Sí | Según política | Según política |
| Ver mis reservas | No | Sí | No | No |
| Ver reservas operativas | No | No | Sí | Sí |
| Marcar pedido atendido | No | No | Sí | Sí |
| Gestionar familiares propios | No | Sí | No | No |
| Consultar pensión propia | No | Sí | No | Sí |
| Gestionar empleados | No | No | No | Sí |
| Gestionar menú y platos | No | No | No | Sí |
| Gestionar feriados | No | No | No | Sí |

> La matriz es una guía funcional. La autorización efectiva debe quedar
> garantizada por las políticas RLS y no solamente por ocultar botones.

---

## 11. Plan sugerido de entregas

### Iteración 1: operación básica

- Validar autenticación y recuperación de contraseña.
- Validar menú publicado.
- Validar creación, consulta y cancelación de reservas.
- Ejecutar pruebas de permisos por rol.

### Iteración 2: operación del restaurante

- Validar pantalla de cocina.
- Incorporar filtros por estado.
- Validar feriados, horarios límite y duplicidad.
- Crear reporte diario básico.

### Iteración 3: administración y control

- Completar catálogo de platos e imágenes.
- Incorporar auditoría.
- Incorporar exportación de reservas.
- Validar pensiones, precios y subsidios.

### Iteración 4: calidad y experiencia

- Pruebas de integración y pruebas de aceptación.
- Accesibilidad.
- Notificaciones.
- Rendimiento y uso con conectividad limitada.

---

## 12. Riesgos y decisiones pendientes

Antes de cerrar los requisitos, conviene definir:

1. ¿La reserva se puede cancelar hasta qué hora?
2. ¿Una reserva puede incluir más de un familiar?
3. ¿La pensión representa un pago real, un subsidio o solo información?
4. ¿Quién puede modificar una reserva: el empleado, cocina o administración?
5. ¿Qué estados oficiales tendrá una reserva?
6. ¿El menú se publica automáticamente o requiere aprobación?
7. ¿Qué datos deben incluir los reportes?
8. ¿Se necesitan notificaciones por correo, WhatsApp o push?
9. ¿El modo demo se mantendrá para producción o solo para desarrollo?
10. ¿Qué políticas de retención y privacidad aplican a los datos personales?

---

## 13. Definición de terminado

Una historia se considera terminada cuando:

- cumple sus criterios de aceptación;
- tiene validaciones de entrada;
- contempla estados de carga, vacío y error;
- respeta los permisos del rol;
- tiene pruebas unitarias o de widget cuando corresponde;
- fue probada con Supabase conectado;
- no rompe el modo demo si ese comportamiento forma parte del alcance;
- está verificada en Android y Web cuando aplica;
- la documentación relacionada está actualizada.

