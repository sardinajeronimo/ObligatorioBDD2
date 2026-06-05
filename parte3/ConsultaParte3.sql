EXPLAIN PLAN FOR
SELECT 
    a.nombre                            AS agente,
    c.nombre                            AS comunidad,
    COUNT(DISTINCT p.id_contenido)      AS total_publicaciones,
    COUNT(v.id_voto)                    AS votos_positivos
FROM AGENTE a
    JOIN CONTENIDO ct   ON ct.id_agente    = a.id_agente
    JOIN PUBLICACION p  ON p.id_contenido  = ct.id_contenido
    JOIN COMUNIDAD c    ON c.id_comunidad  = p.id_comunidad
    LEFT JOIN VOTO v    ON v.id_publicacion = p.id_contenido
                       AND v.tipo = 'positivo'
WHERE ct.fecha_hora_creacion >= SYSDATE - 30
GROUP BY a.nombre, c.nombre
ORDER BY total_publicaciones DESC;
 
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);