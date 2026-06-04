---
name: testear-procedures
description: Corre una batería de pruebas de los procedimientos de Parte 2 contra la base Oracle (contenedor oracle-moltbook), validando el happy path Y que cada validación de negocio rechace lo que debe, con el ORA-xxxxx esperado. Devuelve OK/FALLA por caso. Úsala cuando el usuario pida "testear", "probar los procedures", "validar que anda", "correr los tests" o variantes.
---

# Testear procedures (Parte 2)

Valida **comportamiento**, no solo compilación: un SP que nunca rechaza nada igual
"corre". Por eso cada validación obligatoria se prueba con un caso que la dispare,
y un caso que **debe fallar** que pasa sin excepción se cuenta como **FALLA**, no OK.

## Procedimiento

### 1. Base limpia
- Verificar que el contenedor esté arriba: `docker ps | grep oracle-moltbook`.
  Si no está, **abortar** avisando "el contenedor oracle-moltbook no está corriendo".
- Recrear el esquema desde cero (los `@@` son relativos; usar `cd` al dir y
  `SET SQLBLANKLINES ON` para que SQL*Plus no corte los CREATE TABLE):
  ```
  docker exec -u root oracle-moltbook rm -rf /tmp/scripts
  docker cp scripts oracle-moltbook:/tmp/scripts
  docker exec -i oracle-moltbook bash -lc "cd /tmp/scripts && sqlplus -S moltbook/moltbook@//localhost:1521/FREEPDB1 <<'EOF'
  SET SQLBLANKLINES ON
  @drop_all.sql
  @run_all.sql
  EOF"
  ```
- Confirmar 0 inválidos: `SELECT COUNT(*) FROM user_objects WHERE status='INVALID';`
  Si hay inválidos, reportar cuáles y abortar (los tests no tienen sentido).

### 2. Sembrar datos mínimos
En un único bloque PL/SQL, crear y guardar los ids de: usuario, agente GENERADOR
(+ miembro de la comunidad), agente OBSERVADOR, agente MODERADOR (+ miembro),
una comunidad Activa, una publicación y un comentario. Sembrar vía los propios
SPs cuando se pueda (ejercita más camino).

### 3. Batería de casos
Cada caso "que debe fallar" se envuelve en `BEGIN ... EXCEPTION WHEN OTHERS THEN
(verificar SQLCODE) END;`. Si NO levanta el ORA esperado → **FALLA**.

**Happy path (deben pasar sin error):**
| SP | Verificación |
|----|----|
| sp_registrar_agente | crea AGENTE + CONFIGURACION_HISTORICA versión 1 |
| sp_publicar | GENERADOR miembro en comunidad Activa → crea CONTENIDO + PUBLICACION |
| sp_comentar | publicación Activa → crea CONTENIDO + COMENTARIO (y respuesta a comentario) |
| sp_emitir_voto | OBSERVADOR → inserta VOTO y `puntaje_total` +1 |
| sp_moderar_contenido | MODERADOR miembro sobre contenido de su comunidad |
| sp_transferir_administracion | cambia `id_usuario_admin` + fila en TRANSFERENCIA_AGENTE |
| sp_actualizar_config_agente | nueva versión en CONFIGURACION_HISTORICA |
| sp_ranking_publicaciones | abre el cursor y devuelve filas |

**Casos que deben rechazar (ORA esperado):**
| Caso | SP | ORA |
|------|----|-----|
| tipo de agente inválido | sp_registrar_agente | -20003 |
| usuario admin suspendido/inexistente | sp_registrar_agente | -20001 |
| identificador de agente duplicado | sp_registrar_agente | -20002 |
| agente no GENERADOR publica | sp_publicar | -20022 |
| comunidad archivada | sp_publicar | -20024 |
| agente no miembro publica | sp_publicar | -20025 |
| agente no GENERADOR comenta | sp_comentar | -20032 |
| publicación Cerrada/Eliminada | sp_comentar | -20034 |
| comentario padre de otra publicación | sp_comentar | -20036 |
| agente no OBSERVADOR vota | sp_emitir_voto | -20015 |
| voto duplicado mismo agente/publicación | sp_emitir_voto | -20014 |
| tipo de voto inválido | sp_emitir_voto | -20013 |
| agente no MODERADOR modera | sp_moderar_contenido | -20003 |
| moderador no miembro de la comunidad | sp_moderar_contenido | -20004 |
| contenido de otra comunidad | sp_moderar_contenido | -20006 |
| transferir al mismo admin actual | sp_transferir_administracion | -20012 |

> Los códigos ORA viven en el header de cada archivo en `scripts/procedures/`.
> Si cambian, actualizar esta tabla (es la fuente de verdad del test).

### 4. Aislar
Cerrar el bloque con `ROLLBACK` para no ensuciar la base. Los tests deben poder
correrse N veces seguidas con el mismo resultado.

### 5. Reporte
Por cada caso imprimir `OK` o `FALLA: <esperaba ORA-xxxxx, obtuve ...>`, citando
el archivo del SP. Cerrar con un resumen `X / Y OK`. Si falla algún caso de un
requerimiento **obligatorio** (2.1, 2.2, 2.3, 2.6, 2.8), marcarlo como **crítico**.

## Reglas
- Un caso "que debe fallar" que pasa sin excepción = **FALLA** (no OK).
- Verificar el **SQLCODE exacto**, no solo "hubo error" (un error distinto al
  esperado también es FALLA: significa que falló por la razón equivocada).
- Citar `scripts/procedures/<sp>.sql` en cada hallazgo.
- No tocar datos persistentes: todo dentro de una transacción con ROLLBACK final.
