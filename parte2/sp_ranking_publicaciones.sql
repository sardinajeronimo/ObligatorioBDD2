
CREATE OR REPLACE PROCEDURE sp_ranking_publicaciones(
    p_id_comunidad IN NUMBER,
    p_alias_admin  IN VARCHAR2 DEFAULT NULL,
    p_cursor       OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
        SELECT
            p.puntaje_total,
            p.titulo,
            c.fecha_hora_creacion,
            a.nombre          AS nombre_agente,
            u.alias           AS alias_admin
        FROM PUBLICACION     p
        JOIN CONTENIDO       c ON c.id_contenido = p.id_contenido
        JOIN AGENTE          a ON a.id_agente     = c.id_agente
        JOIN USUARIO         u ON u.id_usuario    = a.id_usuario_admin
        WHERE p.id_comunidad         = p_id_comunidad
          AND p.estado               = 'Activa'
          AND c.fecha_hora_creacion >= SYSDATE - 30
          AND (p_alias_admin IS NULL OR u.alias = p_alias_admin)
        ORDER BY p.puntaje_total DESC
        FETCH FIRST 10 ROWS ONLY;
END;
/
