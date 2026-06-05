-- ============================================
-- drop_all.sql — Borra todas las tablas del esquema (reset).
-- ============================================
-- Útil para reejecutar run_all.sql desde cero sin errores de
-- "ORA-00955: nombre ya utilizado".
--
-- CASCADE CONSTRAINTS permite borrar sin importar el orden de las FKs.
-- El bloque ignora las tablas que no existan, así que es idempotente.
-- ============================================
SET SERVEROUTPUT ON
BEGIN
    FOR t IN (
        SELECT table_name
          FROM user_tables
         WHERE table_name IN (
            'MODERACION', 'VOTO', 'COMENTARIO', 'PUBLICACION', 'CONTENIDO',
            'AGENTE_COMUNIDAD', 'COMUNIDAD', 'TRANSFERENCIA_AGENTE',
            'CONFIGURACION_HISTORICA', 'AGENTE', 'TELEFONO_USUARIO', 'USUARIO'
         )
    ) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS PURGE';
        DBMS_OUTPUT.PUT_LINE('Borrada: ' || t.table_name);
    END LOOP;
END;
/
