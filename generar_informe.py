#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Generador del informe final PDF - Obligatorio BD2 Moltbook
Universidad ORT Uruguay - 2026
"""

import os
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import cm
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_JUSTIFY
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, PageBreak, Table, TableStyle,
    KeepTogether, HRFlowable, Image, Preformatted
)
from reportlab.platypus.tableofcontents import TableOfContents
from reportlab.pdfgen import canvas
from reportlab.platypus import BaseDocTemplate, Frame, PageTemplate
from reportlab.lib.colors import HexColor

# ---------------------------------------------------------------------------
# Constantes de color
# ---------------------------------------------------------------------------
COLOR_HEADER      = HexColor('#1A237E')   # azul oscuro
COLOR_H1          = HexColor('#283593')
COLOR_H2          = HexColor('#1565C0')
COLOR_H3          = HexColor('#1976D2')
COLOR_CODE_BG     = HexColor('#F5F5F5')
COLOR_ROW_ALT     = HexColor('#F0F0F0')
COLOR_ROW_HEADER  = HexColor('#3F51B5')
COLOR_ACCENT      = HexColor('#E3F2FD')
COLOR_LINE        = HexColor('#90CAF9')

PAGE_W, PAGE_H = A4
MARGIN = 2.5 * cm

# ---------------------------------------------------------------------------
# Estilos
# ---------------------------------------------------------------------------
base_styles = getSampleStyleSheet()

def make_styles():
    s = {}

    s['portada_titulo'] = ParagraphStyle(
        'portada_titulo', fontName='Helvetica-Bold', fontSize=32,
        textColor=COLOR_HEADER, alignment=TA_CENTER, spaceAfter=12, leading=38
    )
    s['portada_subtitulo'] = ParagraphStyle(
        'portada_subtitulo', fontName='Helvetica', fontSize=16,
        textColor=HexColor('#455A64'), alignment=TA_CENTER, spaceAfter=8, leading=22
    )
    s['portada_meta'] = ParagraphStyle(
        'portada_meta', fontName='Helvetica', fontSize=12,
        textColor=HexColor('#546E7A'), alignment=TA_CENTER, spaceAfter=6, leading=18
    )
    s['portada_bold'] = ParagraphStyle(
        'portada_bold', fontName='Helvetica-Bold', fontSize=13,
        textColor=COLOR_HEADER, alignment=TA_CENTER, spaceAfter=6, leading=20
    )

    s['h1'] = ParagraphStyle(
        'h1', fontName='Helvetica-Bold', fontSize=18,
        textColor=COLOR_H1, spaceBefore=24, spaceAfter=10, leading=24,
        borderPad=4
    )
    s['h2'] = ParagraphStyle(
        'h2', fontName='Helvetica-Bold', fontSize=14,
        textColor=COLOR_H2, spaceBefore=16, spaceAfter=6, leading=18
    )
    s['h3'] = ParagraphStyle(
        'h3', fontName='Helvetica-Bold', fontSize=11,
        textColor=COLOR_H3, spaceBefore=10, spaceAfter=4, leading=16
    )

    s['body'] = ParagraphStyle(
        'body', fontName='Helvetica', fontSize=10,
        textColor=HexColor('#212121'), alignment=TA_JUSTIFY,
        spaceBefore=4, spaceAfter=4, leading=15
    )
    s['body_small'] = ParagraphStyle(
        'body_small', fontName='Helvetica', fontSize=9,
        textColor=HexColor('#424242'), alignment=TA_JUSTIFY,
        spaceBefore=2, spaceAfter=2, leading=13
    )
    s['bullet'] = ParagraphStyle(
        'bullet', fontName='Helvetica', fontSize=10,
        textColor=HexColor('#212121'), leftIndent=18, bulletIndent=6,
        spaceBefore=2, spaceAfter=2, leading=15
    )
    s['caption'] = ParagraphStyle(
        'caption', fontName='Helvetica-Oblique', fontSize=9,
        textColor=HexColor('#616161'), alignment=TA_CENTER,
        spaceBefore=4, spaceAfter=10
    )
    s['toc_h1'] = ParagraphStyle(
        'toc_h1', fontName='Helvetica-Bold', fontSize=11,
        textColor=COLOR_H1, spaceBefore=6, spaceAfter=2, leading=16
    )
    s['toc_h2'] = ParagraphStyle(
        'toc_h2', fontName='Helvetica', fontSize=10,
        textColor=HexColor('#424242'), leftIndent=16, spaceBefore=1, spaceAfter=1, leading=14
    )
    s['label'] = ParagraphStyle(
        'label', fontName='Helvetica-Bold', fontSize=9,
        textColor=HexColor('#FFFFFF')
    )
    s['table_body'] = ParagraphStyle(
        'table_body', fontName='Helvetica', fontSize=8,
        textColor=HexColor('#212121'), leading=12, wordWrap='LTR'
    )
    s['table_header'] = ParagraphStyle(
        'table_header', fontName='Helvetica-Bold', fontSize=8,
        textColor=HexColor('#FFFFFF'), leading=12
    )
    return s

ST = make_styles()

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def P(text, style='body'):
    """Crea un Paragraph con el estilo dado."""
    return Paragraph(text, ST[style])

def H1(text):
    return Paragraph(text, ST['h1'])

def H2(text):
    return Paragraph(text, ST['h2'])

def H3(text):
    return Paragraph(text, ST['h3'])

def SP(n=6):
    return Spacer(1, n)

def HR():
    return HRFlowable(width='100%', thickness=1, color=COLOR_LINE,
                      spaceAfter=6, spaceBefore=6)

def code_block(text, font_size=7):
    """Bloque de código con fondo gris. Retorna lista de flowables para que se divida entre páginas."""
    # Truncar líneas muy largas de forma segura
    lines = text.split('\n')
    wrapped = []
    max_chars = int((PAGE_W - 2*MARGIN - 16) / (font_size * 0.6))
    for line in lines:
        if len(line) > max_chars:
            while len(line) > max_chars:
                wrapped.append(line[:max_chars])
                line = '    ' + line[max_chars:]
            wrapped.append(line)
        else:
            wrapped.append(line)
    clean = '\n'.join(wrapped)

    style = ParagraphStyle(
        'code', fontName='Courier', fontSize=font_size,
        textColor=HexColor('#212121'), leading=font_size * 1.45,
        backColor=COLOR_CODE_BG, borderPad=6,
        leftIndent=6, rightIndent=6,
        spaceBefore=2, spaceAfter=2,
    )
    return Preformatted(clean, style)

def restricciones_table(rows, col_widths=None):
    """Tabla de restricciones con alternancia de filas."""
    if col_widths is None:
        avail = PAGE_W - 2 * MARGIN
        col_widths = [avail * w for w in [0.20, 0.22, 0.13, 0.16, 0.29]]

    header = ['Restricción', 'Tabla', 'Tipo', 'Implementación', 'Comentarios']
    header_row = [Paragraph(h, ST['table_header']) for h in header]
    table_data = [header_row]
    for row in rows:
        table_data.append([Paragraph(str(c), ST['table_body']) for c in row])

    style = [
        ('BACKGROUND',    (0,0), (-1,0),  COLOR_ROW_HEADER),
        ('TEXTCOLOR',     (0,0), (-1,0),  colors.white),
        ('FONTNAME',      (0,0), (-1,0),  'Helvetica-Bold'),
        ('FONTSIZE',      (0,0), (-1,-1), 8),
        ('GRID',          (0,0), (-1,-1), 0.4, HexColor('#BDBDBD')),
        ('ROWBACKGROUNDS',(0,1), (-1,-1), [colors.white, COLOR_ROW_ALT]),
        ('TOPPADDING',    (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ('LEFTPADDING',   (0,0), (-1,-1), 5),
        ('RIGHTPADDING',  (0,0), (-1,-1), 5),
        ('VALIGN',        (0,0), (-1,-1), 'TOP'),
    ]
    t = Table(table_data, colWidths=col_widths, repeatRows=1)
    t.setStyle(TableStyle(style))
    return t

def simple_table(headers, rows, col_widths=None, font_size=9):
    """Tabla genérica."""
    avail = PAGE_W - 2 * MARGIN
    if col_widths is None:
        w = avail / len(headers)
        col_widths = [w] * len(headers)

    hstyle = ParagraphStyle('th', fontName='Helvetica-Bold', fontSize=font_size,
                             textColor=colors.white, leading=13)
    bstyle = ParagraphStyle('td', fontName='Helvetica', fontSize=font_size - 1,
                             textColor=HexColor('#212121'), leading=12)
    header_row = [Paragraph(h, hstyle) for h in headers]
    data = [header_row]
    for row in rows:
        data.append([Paragraph(str(c), bstyle) for c in row])

    style = [
        ('BACKGROUND',     (0,0), (-1,0),  COLOR_ROW_HEADER),
        ('GRID',           (0,0), (-1,-1), 0.4, HexColor('#BDBDBD')),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, COLOR_ROW_ALT]),
        ('TOPPADDING',     (0,0), (-1,-1), 4),
        ('BOTTOMPADDING',  (0,0), (-1,-1), 4),
        ('LEFTPADDING',    (0,0), (-1,-1), 5),
        ('RIGHTPADDING',   (0,0), (-1,-1), 5),
        ('VALIGN',         (0,0), (-1,-1), 'TOP'),
    ]
    t = Table(data, colWidths=col_widths, repeatRows=1)
    t.setStyle(TableStyle(style))
    return t

def img_if_exists(path, width=13*cm, caption_text=None):
    """Incluye imagen si existe, con caption opcional."""
    items = []
    if os.path.exists(path):
        try:
            from PIL import Image as PILImage
            pil = PILImage.open(path)
            orig_w, orig_h = pil.size
            aspect = orig_h / orig_w
            # Limit height to 60% of page
            max_h = (PAGE_H - 2*MARGIN - 2.2*cm) * 0.60
            if width * aspect > max_h:
                width = max_h / aspect
            img = Image(path, width=width, height=width * aspect)
            img.hAlign = 'CENTER'
            items.append(SP(8))
            items.append(img)
            if caption_text:
                items.append(P(f'<i>{caption_text}</i>', 'caption'))
            items.append(SP(4))
        except Exception as e:
            items.append(P(f'[No se pudo cargar imagen: {os.path.basename(path)}]', 'body_small'))
    return items

# ---------------------------------------------------------------------------
# Header / Footer
# ---------------------------------------------------------------------------
class MoltbookDocTemplate(BaseDocTemplate):
    def __init__(self, filename, **kwargs):
        super().__init__(filename, **kwargs)
        frame = Frame(MARGIN, MARGIN, PAGE_W - 2*MARGIN,
                      PAGE_H - 2*MARGIN, id='normal')
        template = PageTemplate(id='main', frames=frame,
                                onPage=self._noop)
        self.addPageTemplates([template])
        self.toc = None

    def _noop(self, c, doc):
        pass

    def afterFlowable(self, flowable):
        if hasattr(flowable, 'toc_entry'):
            level, text = flowable.toc_entry
            key = f'toc_{id(flowable)}'
            self.canv.bookmarkPage(key)
            self.notify('TOCEntry', (level, text, self.page, key))

class TocEntry(Paragraph):
    def __init__(self, text, style, level=0):
        super().__init__(text, style)
        self.toc_entry = (level, text)

def toc_h1(text):
    return TocEntry(text, ST['h1'], level=0)

def toc_h2(text):
    return TocEntry(text, ST['h2'], level=1)

# ---------------------------------------------------------------------------
# Secciones del informe
# ---------------------------------------------------------------------------

def seccion_portada():
    items = []

    # Estilo caratula ORT: borde exterior
    ORT_DARK = HexColor('#7B1230')   # bordó ORT

    portada_center = ParagraphStyle(
        'pc', fontName='Times-BoldItalic', fontSize=16,
        textColor=colors.black, alignment=TA_CENTER,
        spaceAfter=0, spaceBefore=0, leading=22,
        underlineProportion=0.05,
    )
    portada_center_plain = ParagraphStyle(
        'pcp', fontName='Times-Roman', fontSize=16,
        textColor=colors.black, alignment=TA_CENTER,
        spaceAfter=0, spaceBefore=0, leading=22,
    )
    portada_label = ParagraphStyle(
        'pl', fontName='Times-BoldItalic', fontSize=16,
        textColor=colors.black, alignment=TA_CENTER,
        spaceBefore=0, spaceAfter=0, leading=22,
    )

    # Borde de página: lo hacemos con una tabla que ocupa toda la hoja
    inner_w = PAGE_W - 2*MARGIN
    inner_h = PAGE_H - 2*MARGIN

    # Construir contenido interno de la caratula como lista de flowables
    # empaquetados dentro de una tabla única con borde exterior

    contenido = []

    # Espacio superior
    contenido.append(Spacer(1, 1.5*cm))

    # Logo ORT — buscamos si existe, si no dibujamos el texto
    logo_path = '/Users/jeronimo/Desktop/ObligatorioBDD2/docs/ort_logo.png'
    logo_drawn = False
    if os.path.exists(logo_path):
        try:
            from PIL import Image as PILImage
            pil = PILImage.open(logo_path)
            ow, oh = pil.size
            lw = 7*cm
            lh = lw * oh / ow
            logo_img = Image(logo_path, width=lw, height=lh)
            logo_img.hAlign = 'CENTER'
            contenido.append(logo_img)
            logo_drawn = True
        except Exception:
            pass

    if not logo_drawn:
        # Dibujar el logo ORT como texto estilizado
        ort_style = ParagraphStyle(
            'ort', fontName='Helvetica-Bold', fontSize=52,
            textColor=ORT_DARK, alignment=TA_CENTER,
            spaceAfter=0, spaceBefore=0, leading=60,
        )
        ort_sub = ParagraphStyle(
            'ortsub', fontName='Helvetica-Bold', fontSize=13,
            textColor=ORT_DARK, alignment=TA_CENTER,
            spaceAfter=0, spaceBefore=0, leading=18, letterSpacing=4,
        )
        ort_sub2 = ParagraphStyle(
            'ortsub2', fontName='Helvetica', fontSize=13,
            textColor=ORT_DARK, alignment=TA_CENTER,
            spaceAfter=0, spaceBefore=0, leading=18,
        )
        contenido.append(Paragraph('ORT', ort_style))
        contenido.append(Spacer(1, 4))
        contenido.append(Paragraph('UNIVERSIDAD ORT', ort_sub))
        contenido.append(Paragraph('Uruguay', ort_sub2))

    contenido.append(Spacer(1, 3*cm))

    # Materia
    contenido.append(Paragraph('<u>Bases de Datos 2</u>', portada_center))
    contenido.append(Spacer(1, 0.8*cm))

    # Obligatorio
    contenido.append(Paragraph('<u>Obligatorio</u>', portada_center))
    contenido.append(Spacer(1, 0.8*cm))

    # Fecha
    contenido.append(Paragraph('<u>22 de junio de 2026</u>', portada_center))
    contenido.append(Spacer(1, 1.2*cm))

    # Integrantes
    contenido.append(Paragraph('<u>Integrantes:</u>', portada_label))
    contenido.append(Spacer(1, 0.5*cm))
    contenido.append(Paragraph(
        '<u>Felipe Baz (328217),</u><br/>'
        '<u>Renzo De Marco (267922),</u><br/>'
        '<u>Jer&#243;nimo Sardina (323769)</u>',
        portada_center
    ))
    contenido.append(Spacer(1, 1.5*cm))

    # Empaquetar todo en una tabla con borde exterior bordó
    t = Table(
        [[contenido]],
        colWidths=[inner_w],
    )
    t.setStyle(TableStyle([
        ('BOX',            (0,0), (-1,-1), 2, ORT_DARK),
        ('TOPPADDING',     (0,0), (-1,-1), 0),
        ('BOTTOMPADDING',  (0,0), (-1,-1), 0),
        ('LEFTPADDING',    (0,0), (-1,-1), 0),
        ('RIGHTPADDING',   (0,0), (-1,-1), 0),
    ]))

    items.append(t)
    items.append(PageBreak())
    return items


def seccion_toc():
    items = []
    items.append(H1('Tabla de Contenidos'))
    items.append(HR())

    toc = TableOfContents()
    toc.levelStyles = [
        ParagraphStyle('toc1', fontName='Helvetica-Bold', fontSize=11,
                       textColor=COLOR_H1, spaceBefore=6, spaceAfter=2,
                       leftIndent=0, leading=16),
        ParagraphStyle('toc2', fontName='Helvetica', fontSize=10,
                       textColor=HexColor('#424242'), spaceBefore=1, spaceAfter=1,
                       leftIndent=18, leading=14),
        ParagraphStyle('toc3', fontName='Helvetica-Oblique', fontSize=9,
                       textColor=HexColor('#616161'), spaceBefore=0, spaceAfter=0,
                       leftIndent=36, leading=13),
    ]
    items.append(toc)
    items.append(PageBreak())
    return items, toc


def seccion_parte1():
    items = []
    items.append(toc_h1('Parte 1 — Modelo Relacional'))
    items.append(HR())

    # 1.1 Análisis y supuestos
    items.append(toc_h2('1.1 Análisis y Supuestos del Modelo'))
    items.append(SP(4))

    items.append(P(
        'Moltbook es una red social operada por <b>agentes de IA</b> que pertenecen a usuarios humanos. '
        'Los agentes participan en comunidades temáticas donde generan contenido (publicaciones y comentarios), '
        'lo votan y lo moderan. El modelo relacional captura tres ejes principales:',
        'body'
    ))
    items.append(SP(4))
    items.append(P('1. <b>Identidad y administración:</b> quién es dueño de qué agente y cómo evoluciona su '
                   'configuración (USUARIO, TELEFONO_USUARIO, AGENTE, CONFIGURACION_HISTORICA, TRANSFERENCIA_AGENTE).', 'bullet'))
    items.append(P('2. <b>Pertenencia:</b> qué agente participa en qué comunidad y en qué rol '
                   '(COMUNIDAD, AGENTE_COMUNIDAD).', 'bullet'))
    items.append(P('3. <b>Contenido e interacción:</b> la generalización CONTENIDO y sus subtipos, '
                   'más los votos y las acciones de moderación (CONTENIDO, PUBLICACION, COMENTARIO, VOTO, MODERACION).', 'bullet'))

    items.append(SP(10))
    items.append(H3('Decisiones de modelado'))

    items.append(H3('Generalización CONTENIDO → PUBLICACION / COMENTARIO'))
    items.append(P(
        'La consigna define <i>contenido</i> como "toda unidad de información generada por los agentes", '
        'clasificada en publicaciones y comentarios que comparten características comunes. '
        'Modelamos esto como <b>supertipo/subtipo</b>: CONTENIDO concentra lo común '
        '(identificador único, autor, fecha de creación) y PUBLICACION y COMENTARIO comparten la PK '
        'con el supertipo (id_contenido es a la vez PK y FK hacia CONTENIDO).',
        'body'
    ))
    items.append(P(
        'Descartamos "tabla única con discriminador" porque publicación y comentario tienen atributos '
        'disjuntos — muchos NULL y CHECKs condicionales frágiles. Descartamos también "dos tablas '
        'independientes sin supertipo" porque VOTO y MODERACION necesitan referenciar "contenido" '
        'de forma uniforme; con el supertipo, MODERACION apunta a CONTENIDO y modera indistintamente '
        'publicaciones o comentarios con una sola FK.',
        'body'
    ))

    items.append(H3('Versionado de configuración (CONFIGURACION_HISTORICA)'))
    items.append(P(
        'La configuración del agente cambia en el tiempo y el negocio exige conservar el historial. '
        'Separamos la config activa (campos prompt, configuracion en AGENTE) del historial '
        '(CONFIGURACION_HISTORICA, una fila por versión). La unicidad (id_agente, version) impide '
        'versiones duplicadas y version > 0 evita numeraciones inválidas. Esto soporta directamente '
        'los servicios 2.1 (primer registro de versión) y 2.7 (alta de nueva versión).',
        'body'
    ))

    items.append(H3('Transferencia de administración como bitácora inmutable'))
    items.append(P(
        'TRANSFERENCIA_AGENTE registra (agente, usuario_anterior, usuario_nuevo, fecha) y nunca se '
        'actualiza ni se borra: es una tabla de auditoría. El "dueño actual" vive en '
        'AGENTE.id_usuario_admin; el historial vive aquí. Las FKs a USUARIO sin ON DELETE garantizan '
        'que no se pueda borrar un usuario que figure en el historial, preservando la trazabilidad.',
        'body'
    ))

    items.append(H3('Puntaje desnormalizado en PUBLICACION'))
    items.append(P(
        'PUBLICACION.puntaje_total es una desnormalización deliberada: en vez de recalcular SUM sobre '
        'VOTO en cada lectura, el servicio de voto (2.4) lo mantiene atómicamente. El ranking top-10 '
        '(2.8) se consulta mucho más de lo que se vota, y mantener el agregado evita un GROUP BY costoso '
        'en cada ranking. El trade-off (riesgo de divergencia) se acota concentrando toda escritura del '
        'puntaje en el SP de voto.',
        'body'
    ))

    items.append(H3('Borrado lógico de publicaciones'))
    items.append(P(
        'Las publicaciones eliminadas no se borran físicamente: pasan a estado = "Eliminada". Permite '
        'que comentarios y moderaciones asociadas conserven su contexto y que el ranking las filtre '
        'por estado.',
        'body'
    ))

    items.append(SP(10))
    items.append(H3('Supuestos sobre cardinalidades'))

    card_rows = [
        ['USUARIO – TELEFONO_USUARIO', '1 : N', 'Un usuario tiene 0..N teléfonos; cada teléfono es de un solo usuario.'],
        ['USUARIO – AGENTE (admin)',   '1 : N', 'Un usuario administra 0..N agentes; un agente tiene exactamente un administrador a la vez.'],
        ['AGENTE – CONFIGURACION_HISTORICA', '1 : N', 'Un agente tiene 1..N versiones (al menos la inicial creada en 2.1).'],
        ['AGENTE – TRANSFERENCIA_AGENTE',    '1 : N', 'Un agente puede transferirse 0..N veces.'],
        ['AGENTE – COMUNIDAD',  'N : M', 'Resuelta con AGENTE_COMUNIDAD; un agente participa una sola vez por comunidad (UNIQUE), como seguidor o miembro.'],
        ['AGENTE – CONTENIDO',  '1 : N', 'Un agente autor genera 0..N contenidos; cada contenido tiene un único autor.'],
        ['COMUNIDAD – PUBLICACION', '1 : N', 'Cada publicación pertenece a exactamente una comunidad.'],
        ['PUBLICACION – COMENTARIO', '1 : N', 'Cada comentario pertenece a exactamente una publicación.'],
        ['COMENTARIO – COMENTARIO (padre)', '1 : N', 'Jerarquía de hilos: un comentario responde a 0..1 comentario padre.'],
        ['PUBLICACION – PUBLICACION (cita)', '1 : N', 'Una publicación cita opcionalmente a 0..1 publicación.'],
        ['AGENTE – PUBLICACION (voto)', 'N : M', 'Resuelta con VOTO; un agente vota a lo sumo una vez la misma publicación.'],
        ['AGENTE – CONTENIDO (moderación)', 'N : M', 'Resuelta con MODERACION; incluye la comunidad donde ocurre.'],
    ]
    avail = PAGE_W - 2 * MARGIN
    items.append(simple_table(
        ['Relación', 'Cardinalidad', 'Supuesto'],
        card_rows,
        col_widths=[avail*0.30, avail*0.13, avail*0.57]
    ))

    items.append(SP(10))
    items.append(H3('Reglas de negocio y su implementación'))
    items.append(P(
        'Las restricciones de dominio/estructura (tipos, unicidad, referencias) se resuelven en el DDL. '
        'Las reglas que dependen del estado en el momento de la operación (pertenencia activa, comunidad '
        'no archivada, publicación no cerrada) se validan en los procedimientos de la Parte 2, porque '
        'no son expresables como constraints declarativas estáticas.',
        'body'
    ))

    reglas = [
        ['Activos/Suspendidos (usuario y agente)', 'CHECK de dominio (chk_*_estado)'],
        ['Tipo de agente acotado',                 'CHECK chk_agente_tipo'],
        ['Comunidad archivada con fecha coherente','CHECK chk_comunidad_archivado'],
        ['Título de publicación no vacío',         'CHECK chk_pub_titulo_nv (LENGTH(TRIM(titulo)) > 0)'],
        ['Auto-cita prohibida',                    'CHECK chk_pub_autocita'],
        ['Cita: id y fecha todo-o-nada',           'CHECK chk_pub_cita'],
        ['Un comentario no es su propio padre',    'CHECK chk_com_no_self'],
        ['Voto único por agente/publicación',       'UNIQUE uk_voto_agente_pub'],
        ['Solo agentes moderadores miembros moderan','FK a comunidad + validación rol en SP (Parte 2)'],
    ]
    items.append(simple_table(
        ['Regla de negocio', 'Dónde se garantiza'],
        reglas,
        col_widths=[avail*0.50, avail*0.50]
    ))

    items.append(SP(10))
    items.append(H3('Supuestos adicionales explícitos'))
    supuestos = [
        'IDs subrogados (GENERATED ALWAYS AS IDENTITY) en todas las entidades fuertes; las FK en datos de prueba se resuelven por claves naturales para que el script sea reejecutable.',
        'Un agente suspendido no puede generar contenido ni votar; el estado se evalúa al ejecutar el servicio (Parte 2), no por constraint.',
        'AGENTE_COMUNIDAD.tipo_participacion: "seguidor" solo visualiza; "miembro" participa (publica/comenta/modera).',
        'MODERACION conserva tipo_accion, fecha y los vínculos a agente/contenido/comunidad; no se borra al revertir una acción.',
        'ON DELETE CASCADE solo hacia dependientes hijos; no en FK de auditoría (transferencias, administrador) para no perder historia.',
        'El "no vacío" estricto sobre CLOB requeriría trigger (DBMS_LOB.GETLENGTH no es válido en CHECK); se asume suficiente NOT NULL a nivel DDL y validación en el SP.',
    ]
    for i, s in enumerate(supuestos, 1):
        items.append(P(f'{i}. {s}', 'bullet'))

    items.append(SP(16))

    # 1.2 Tabla de restricciones
    items.append(toc_h2('1.2 Tabla de Restricciones de Integridad'))
    items.append(SP(4))
    items.append(P(
        'Dividimos la tabla entre los tres integrantes según las entidades asignadas a cada uno: '
        'Jeronimo se encargó del módulo de identidad y administración (USUARIO, AGENTE, CONFIGURACION_HISTORICA, TRANSFERENCIA_AGENTE); '
        'Felipe del módulo de pertenencia (COMUNIDAD, AGENTE_COMUNIDAD); '
        'Renzo del módulo de contenido e interacción (CONTENIDO, PUBLICACION, COMENTARIO, VOTO, MODERACION). '
        'En total identificamos 30 restricciones distribuidas en 11 tablas.',
        'body'
    ))
    items.append(SP(6))

    # Bloque Jero
    items.append(H3('Módulo de identidad y administración (responsable: Jeronimo Sardina)'))
    rows_jero = [
        ['pk_usuario',               'USUARIO',                 'Entidad',   'Estructural',     'Primary key autoincremental'],
        ['uk_usuario_email',          'USUARIO',                 'Dominio',   'Estructural',     'Email debe ser único'],
        ['uk_usuario_alias',          'USUARIO',                 'Dominio',   'Estructural',     'Alias debe ser único'],
        ['chk_usuario_estado',        'USUARIO',                 'Semántica', 'No estructural',  "Solo permite 'Activo' o 'Suspendido'"],
        ['pk_telefono_usuario',       'TELEFONO_USUARIO',        'Entidad',   'Estructural',     'Primary key autoincremental'],
        ['fk_telefono_usuario',       'TELEFONO_USUARIO',        'Referencial','Estructural',    'Teléfono pertenece a un usuario (1:N)'],
        ['uk_telefono_usuario',       'TELEFONO_USUARIO',        'Dominio',   'Estructural',     'Un usuario no repite el mismo número'],
        ['pk_agente',                 'AGENTE',                  'Entidad',   'Estructural',     'Primary key autoincremental'],
        ['uk_agente_identificador',   'AGENTE',                  'Dominio',   'Estructural',     'Identificador único del agente'],
        ['fk_agente_usuario',         'AGENTE',                  'Referencial','Estructural',    'Agente pertenece a un usuario admin'],
        ['chk_agente_config',         'AGENTE',                  'Semántica', 'No estructural',  "Solo 'Simple' o 'Compuesta'"],
        ['chk_agente_estado',         'AGENTE',                  'Semántica', 'No estructural',  "Solo 'Activo' o 'Suspendido'"],
        ['chk_agente_tipo',           'AGENTE',                  'Semántica', 'No estructural',  "Solo 'GENERADOR', 'MODERADOR' u 'OBSERVADOR'"],
        ['pk_config_historica',       'CONFIGURACION_HISTORICA', 'Entidad',   'Estructural',     'Primary key autoincremental'],
        ['fk_config_agente',          'CONFIGURACION_HISTORICA', 'Referencial','Estructural',    'Config pertenece a un agente (no existe sin él)'],
        ['uk_config_agente_version',  'CONFIGURACION_HISTORICA', 'Dominio',   'Estructural',     'Un agente no tiene 2 versiones iguales'],
        ['chk_config_version',        'CONFIGURACION_HISTORICA', 'Semántica', 'No estructural',  'Versión debe ser mayor a 0'],
        ['pk_transferencia_agente',   'TRANSFERENCIA_AGENTE',    'Entidad',   'Estructural',     'Primary key autoincremental'],
        ['fk_transf_agente',          'TRANSFERENCIA_AGENTE',    'Referencial','Estructural',    'La transferencia refiere a un agente existente'],
        ['fk_transf_usuario_ant',     'TRANSFERENCIA_AGENTE',    'Referencial','Estructural',    'Usuario administrador anterior'],
        ['fk_transf_usuario_nuevo',   'TRANSFERENCIA_AGENTE',    'Referencial','Estructural',    'Usuario administrador nuevo'],
        ['chk_transf_distintos',      'TRANSFERENCIA_AGENTE',    'Semántica', 'No estructural',  'El usuario anterior y el nuevo deben ser distintos'],
    ]
    items.append(restricciones_table(rows_jero))

    items.append(SP(10))
    items.append(H3('Módulo de pertenencia (responsable: Felipe Baz)'))
    rows_feli = [
        ['pk_comunidad',          'COMUNIDAD',       'Entidad',   'Estructural',    'Primary key autoincremental'],
        ['uk_comunidad_nombre',   'COMUNIDAD',       'Dominio',   'Estructural',    'El nombre de comunidad no se repite'],
        ['chk_comunidad_estado',  'COMUNIDAD',       'Semántica', 'No estructural', "Solo 'Activa' o 'Archivada'"],
        ['chk_comunidad_archivado','COMUNIDAD',      'Semántica', 'No estructural', 'Archivada implica fecha_archivado no nula (coherencia estado/fecha)'],
        ['pk_agente_comunidad',   'AGENTE_COMUNIDAD','Entidad',   'Estructural',    'Primary key autoincremental'],
        ['fk_ac_agente',          'AGENTE_COMUNIDAD','Referencial','Estructural',   'La participación refiere a un agente existente'],
        ['fk_ac_comunidad',       'AGENTE_COMUNIDAD','Referencial','Estructural',   'La participación refiere a una comunidad existente'],
        ['chk_ac_tipo',           'AGENTE_COMUNIDAD','Semántica', 'No estructural', "Solo 'seguidor' o 'miembro'"],
        ['uk_ac_agente_comunidad','AGENTE_COMUNIDAD','Dominio',   'Estructural',    'Un agente participa una sola vez por comunidad'],
    ]
    items.append(restricciones_table(rows_feli))

    items.append(SP(10))
    items.append(H3('Módulo de contenido e interacción (responsable: Renzo De Marco)'))
    items.append(P(
        'El modelo de contenido usa supertipo/subtipo: CONTENIDO es supertipo de PUBLICACION y COMENTARIO. '
        'Los subtipos comparten la PK con el supertipo (id_contenido). El autor y la fecha de creación '
        'viven en CONTENIDO. El "contenido no vacío" se garantiza con NOT NULL: un CHECK con '
        'DBMS_LOB.GETLENGTH no es válido en Oracle (funciones de paquete prohibidas en constraints).',
        'body'
    ))
    rows_renzo = [
        ['pk_contenido',        'CONTENIDO',   'Entidad',   'Estructural',    'Primary key autoincremental (IDENTITY) del supertipo'],
        ['fk_contenido_agente', 'CONTENIDO',   'Referencial','Estructural',   'Autor del contenido existe en AGENTE'],
        ['pk_publicacion',      'PUBLICACION', 'Entidad',   'Estructural',    'PK = id_contenido (compartida con CONTENIDO)'],
        ['fk_pub_contenido',    'PUBLICACION', 'Referencial','Estructural',   'Subtipo: id_contenido referencia a CONTENIDO'],
        ['fk_pub_comunidad',    'PUBLICACION', 'Referencial','Estructural',   'Publicación pertenece a una comunidad existente'],
        ['fk_pub_citada',       'PUBLICACION', 'Referencial','Estructural',   'Cita opcional a otra publicación (auto-referencia)'],
        ['chk_pub_estado',      'PUBLICACION', 'Semántica', 'No estructural', "Solo 'Activa', 'Cerrada' o 'Eliminada'"],
        ['chk_pub_titulo_nv',   'PUBLICACION', 'Dominio',   'No estructural', 'Título no vacío (LENGTH(TRIM(titulo)) > 0)'],
        ['chk_pub_cita',        'PUBLICACION', 'Semántica', 'No estructural', 'id_publicacion_citada y fecha_cita van juntas'],
        ['chk_pub_autocita',    'PUBLICACION', 'Semántica', 'No estructural', 'Una publicación no puede citarse a sí misma'],
        ['pk_comentario',       'COMENTARIO',  'Entidad',   'Estructural',    'PK = id_contenido (compartida con CONTENIDO)'],
        ['fk_com_contenido',    'COMENTARIO',  'Referencial','Estructural',   'Subtipo: id_contenido referencia a CONTENIDO'],
        ['fk_com_publicacion',  'COMENTARIO',  'Referencial','Estructural',   'Comentario pertenece a una publicación existente'],
        ['fk_com_padre',        'COMENTARIO',  'Referencial','Estructural',   'Comentario padre opcional (auto-referencia, jerarquía)'],
        ['chk_com_no_self',     'COMENTARIO',  'Semántica', 'No estructural', 'Un comentario no puede ser su propio padre'],
        ['pk_voto',             'VOTO',        'Entidad',   'Estructural',    'Primary key autoincremental (IDENTITY)'],
        ['fk_voto_agente',      'VOTO',        'Referencial','Estructural',   'Voto emitido por un agente existente'],
        ['fk_voto_publicacion', 'VOTO',        'Referencial','Estructural',   'Voto recae sobre una publicación'],
        ['uk_voto_agente_pub',  'VOTO',        'Dominio',   'Estructural',    'Un agente vota a lo sumo una vez la misma publicación'],
        ['chk_voto_tipo',       'VOTO',        'Semántica', 'No estructural', "Solo 'positivo' o 'negativo'"],
        ['pk_moderacion',       'MODERACION',  'Entidad',   'Estructural',    'Primary key autoincremental (IDENTITY)'],
        ['fk_mod_agente',       'MODERACION',  'Referencial','Estructural',   'Moderador existe en AGENTE'],
        ['fk_mod_contenido',    'MODERACION',  'Referencial','Estructural',   'Modera un CONTENIDO (publicación o comentario)'],
        ['fk_mod_comunidad',    'MODERACION',  'Referencial','Estructural',   'Moderación ocurre dentro de una comunidad existente'],
        ['chk_mod_accion',      'MODERACION',  'Semántica', 'No estructural', "Solo 'ocultar', 'cerrar' o 'eliminar'"],
    ]
    items.append(restricciones_table(rows_renzo))

    items.append(SP(16))

    # 1.3 DDL
    items.append(toc_h2('1.3 DDL Completo y Ejecutable'))
    items.append(SP(4))
    items.append(P(
        'El DDL está dividido en cuatro archivos que se ejecutan en orden con el runner '
        '<code>parte1/run_all.sql</code>. Creamos índices adicionales en las FK más consultadas '
        'para que las validaciones de pertenencia de la Parte 2 sean eficientes.',
        'body'
    ))

    items.append(SP(8))
    items.append(H3('00_usuario_agente.sql — Módulo de identidad'))
    items.append(P(
        'Define USUARIO, TELEFONO_USUARIO, AGENTE y CONFIGURACION_HISTORICA. La decisión más relevante '
        'aquí es que AGENTE.id_usuario_admin no tiene ON DELETE CASCADE: no queremos que borrar un '
        'usuario destruya el historial de agentes que administró.',
        'body'
    ))
    items.append(SP(4))

    ddl1 = open('/Users/jeronimo/Desktop/ObligatorioBDD2/parte1/00_usuario_agente.sql').read()
    items.append(code_block(ddl1))

    items.append(SP(12))
    items.append(H3('01_comunidad.sql — Módulo de pertenencia'))
    items.append(P(
        'Define COMUNIDAD y AGENTE_COMUNIDAD. El check chk_comunidad_archivado garantiza coherencia '
        'entre el campo estado y la fecha de archivado: o ambos indican "Archivada + fecha", o '
        'ambos indican "Activa + NULL". Esto evita estados inconsistentes sin necesidad de trigger.',
        'body'
    ))
    items.append(SP(4))

    ddl2 = open('/Users/jeronimo/Desktop/ObligatorioBDD2/parte1/01_comunidad.sql').read()
    items.append(code_block(ddl2))

    items.append(SP(12))
    items.append(H3('02_contenido.sql — Módulo de contenido e interacción'))
    items.append(P(
        'Define CONTENIDO, PUBLICACION, COMENTARIO, VOTO y MODERACION. Incluye la generalización '
        'supertipo/subtipo, el check de autocita, la unicidad del voto y los índices en las columnas '
        'más filtradas (estado de publicación, comunidad, agente del voto).',
        'body'
    ))
    items.append(SP(4))

    ddl3 = open('/Users/jeronimo/Desktop/ObligatorioBDD2/parte1/02_contenido.sql').read()
    items.append(code_block(ddl3, font_size=7))

    items.append(SP(12))
    items.append(H3('03_transferencia_agente.sql — Módulo de auditoría'))
    items.append(P(
        'Define TRANSFERENCIA_AGENTE como una tabla de auditoría inmutable. Las FK a USUARIO '
        'sin ON DELETE bloquean el borrado de cualquier usuario que haya sido parte de una '
        'transferencia, preservando la trazabilidad histórica.',
        'body'
    ))
    items.append(SP(4))

    ddl4 = open('/Users/jeronimo/Desktop/ObligatorioBDD2/parte1/03_transferencia_agente.sql').read()
    items.append(code_block(ddl4))

    items.append(SP(16))

    # 1.4 Datos de prueba
    items.append(toc_h2('1.4 Datos de Prueba'))
    items.append(SP(4))
    items.append(P(
        'Los datos de prueba cubren los casos límite más importantes: usuario suspendido '
        '(pedro_bans), agente suspendido (genbot-gamma), comunidad archivada (Robotica 2023), '
        'publicación cerrada (Encuesta 2024), publicación eliminada (SPAM), comentarios anidados '
        '(hilo de 3 niveles), cita entre publicaciones, votos positivos y negativos, y acciones '
        'de moderación. La inserción de contenido se hace en un bloque PL/SQL con RETURNING para '
        'resolver las FK sin depender del orden de autoincremento.',
        'body'
    ))
    items.append(SP(4))

    datos = open('/Users/jeronimo/Desktop/ObligatorioBDD2/parte1/datos_prueba.sql').read()
    items.append(code_block(datos, font_size=6))

    items.append(PageBreak())
    return items


def seccion_parte2():
    items = []
    items.append(toc_h1('Parte 2 — Servicios y Procedimientos Relacionales'))
    items.append(HR())

    items.append(P(
        'Dividimos los ocho procedimientos según las entidades que cada uno manejaba. '
        'Jeronimo se encargó de 2.1 (sp_registrar_agente), 2.4 (sp_emitir_voto) y 2.7 '
        '(sp_actualizar_config_agente), los tres ligados al ciclo de vida del agente y su '
        'historial de configuración. Renzo desarrolló 2.6 (sp_moderar_contenido) y 2.8 '
        '(sp_ranking_publicaciones). Los procedimientos restantes —2.2, 2.3 y 2.5— los '
        'trabajamos entre Jeronimo y Renzo coordinando las validaciones de membresía que '
        'se repiten en varios servicios. Felipe revisó la lógica de pertenencia a comunidades '
        'y contribuyó en los triggers.',
        'body'
    ))

    items.append(SP(10))

    # --- SP 2.1 ---
    items.append(toc_h2('Requerimiento 2.1 — sp_registrar_agente'))
    items.append(P(
        'Registra un agente de IA nuevo asociándolo a un usuario administrador y genera '
        'automáticamente el primer registro en CONFIGURACION_HISTORICA (versión 1).',
        'body'
    ))
    items.append(SP(4))
    sp1 = open('/Users/jeronimo/Desktop/ObligatorioBDD2/parte2/sp_registrar_agente.sql').read()
    items.append(code_block(sp1))
    items.append(SP(4))
    items.append(P(
        'Validamos que el usuario administrador exista y esté Activo antes de crear el agente. '
        'El RETURNING en el INSERT de AGENTE nos da el id para insertar el registro inicial de '
        'configuración en el mismo bloque atómico. Si el identificador del agente ya existe, '
        'DUP_VAL_ON_INDEX lo captura y devuelve un mensaje claro.',
        'body'
    ))

    items.append(SP(12))

    # --- SP 2.2 ---
    items.append(toc_h2('Requerimiento 2.2 — sp_transferir_administracion'))
    items.append(P(
        'Transfiere la administración de un agente de un usuario a otro, conservando el '
        'historial completo en TRANSFERENCIA_AGENTE.',
        'body'
    ))
    items.append(SP(4))
    sp2 = open('/Users/jeronimo/Desktop/ObligatorioBDD2/parte2/sp_transferir_administracion.sql').read()
    items.append(code_block(sp2))
    items.append(SP(4))
    items.append(P(
        'La validación clave aquí es que el nuevo administrador no sea el mismo que el actual, '
        'para evitar inserciones vacías en el historial. También verificamos que el usuario nuevo '
        'exista y esté Activo. El UPDATE sobre AGENTE y el INSERT en TRANSFERENCIA_AGENTE van en '
        'el mismo commit, preservando la atomicidad.',
        'body'
    ))

    items.append(SP(12))

    # --- SP 2.3 ---
    items.append(toc_h2('Requerimiento 2.3 — sp_publicar'))
    items.append(P(
        'Crea una nueva publicación en una comunidad, verificando que el agente sea GENERADOR, '
        'esté activo, y sea miembro de esa comunidad.',
        'body'
    ))
    items.append(SP(4))
    sp3 = open('/Users/jeronimo/Desktop/ObligatorioBDD2/parte2/sp_publicar.sql').read()
    items.append(code_block(sp3))
    items.append(SP(4))
    items.append(P(
        'La validación de membresía verifica tipo_participacion = "miembro" (no solo "seguidor"), '
        'lo que distingue el rol participante del observador. La cita opcional se valida verificando '
        'que la publicación citada exista antes de insertar. El parámetro p_id_contenido_out devuelve '
        'el id generado para que el llamador pueda encadenar operaciones.',
        'body'
    ))

    items.append(SP(12))

    # --- SP 2.4 ---
    items.append(toc_h2('Requerimiento 2.4 — sp_emitir_voto'))
    items.append(P(
        'Registra un voto sobre una publicación y actualiza atómicamente el puntaje_total, '
        'sumando 1 o restando 1 según el tipo.',
        'body'
    ))
    items.append(SP(4))
    sp4 = open('/Users/jeronimo/Desktop/ObligatorioBDD2/parte2/sp_emitir_voto.sql').read()
    items.append(code_block(sp4))
    items.append(SP(4))
    items.append(P(
        'Solo los agentes OBSERVADOR pueden votar: lo validamos explícitamente además del trigger '
        'trg_solo_observador_vota (doble red de seguridad). La actualización atómica '
        'puntaje_total = puntaje_total + v_delta evita race conditions en inserciones concurrentes, '
        'ya que Oracle serializa el UPDATE a nivel de fila.',
        'body'
    ))

    items.append(SP(12))

    # --- SP 2.5 ---
    items.append(toc_h2('Requerimiento 2.5 — sp_comentar'))
    items.append(P(
        'Genera un comentario sobre una publicación o como respuesta a otro comentario, '
        'validando membresía y estado de la publicación.',
        'body'
    ))
    items.append(SP(4))
    sp5 = open('/Users/jeronimo/Desktop/ObligatorioBDD2/parte2/sp_comentar.sql').read()
    items.append(code_block(sp5))
    items.append(SP(4))
    items.append(P(
        'Si se pasa un comentario padre, validamos que ese padre pertenezca a la misma '
        'publicación: un comentario no puede responder a otro que esté en una publicación '
        'diferente. Esta validación está en el SP y también respaldada por el trigger de membresía.',
        'body'
    ))

    items.append(SP(12))

    # --- SP 2.6 ---
    items.append(toc_h2('Requerimiento 2.6 — sp_moderar_contenido'))
    items.append(P(
        'Ejecuta una acción de moderación (ocultar, cerrar, eliminar) sobre contenido de '
        'una comunidad, verificando que el agente sea MODERADOR y miembro de esa comunidad.',
        'body'
    ))
    items.append(SP(4))
    sp6 = open('/Users/jeronimo/Desktop/ObligatorioBDD2/parte2/sp_moderar_contenido.sql').read()
    items.append(code_block(sp6))
    items.append(SP(4))
    items.append(P(
        'La comprobación más interesante es verificar que el contenido a moderar pertenece '
        'a la comunidad que el moderador administra: un MODERADOR de "IA General" no puede '
        'moderar contenido de "Ciencia de Datos". Resolvemos esto con una subconsulta NVL '
        'que busca la comunidad tanto en PUBLICACION como en el hilo padre de COMENTARIO.',
        'body'
    ))

    items.append(SP(12))

    # --- SP 2.7 ---
    items.append(toc_h2('Requerimiento 2.7 — sp_actualizar_config_agente'))
    items.append(P(
        'Agrega una nueva versión al historial de configuración del agente y opcionalmente '
        'actualiza el prompt y/o la configuración activa.',
        'body'
    ))
    items.append(SP(4))
    sp7 = open('/Users/jeronimo/Desktop/ObligatorioBDD2/parte2/sp_actualizar_config_agente.sql').read()
    items.append(code_block(sp7))
    items.append(SP(4))
    items.append(P(
        'Usamos NVL(MAX(version), 0) + 1 para calcular la siguiente versión, lo que maneja '
        'correctamente el caso borde donde el agente no tiene registros previos. Si no se '
        'pasan parámetros nuevos (prompt y config ambos NULL), se registra el evento en el '
        'historial pero no se modifica el agente — útil para registrar auditorías sin cambiar config.',
        'body'
    ))

    items.append(SP(12))

    # --- SP 2.8 ---
    items.append(toc_h2('Requerimiento 2.8 — sp_ranking_publicaciones'))
    items.append(P(
        'Devuelve el top 10 de publicaciones activas con mayor puntaje positivo en una '
        'comunidad, filtrando los últimos 30 días. Opcionalmente filtra por alias del '
        'administrador del agente autor.',
        'body'
    ))
    items.append(SP(4))
    sp8 = open('/Users/jeronimo/Desktop/ObligatorioBDD2/parte2/sp_ranking_publicaciones.sql').read()
    items.append(code_block(sp8))
    items.append(SP(4))
    items.append(P(
        'Retorna un SYS_REFCURSOR con las columnas puntaje_total, titulo, fecha_hora_creacion, '
        'nombre_agente y alias_admin. El filtro puntaje_total > 0 asegura que solo aparecen '
        'publicaciones con al menos un voto neto positivo. El filtro opcional por alias_admin '
        'se implementa con (p_alias_admin IS NULL OR u.alias = p_alias_admin) para evitar '
        'dos versiones del cursor.',
        'body'
    ))

    items.append(SP(16))

    # Capturas 2.8
    cap_path = '/Users/jeronimo/Desktop/ObligatorioBDD2/Documentación/capturas/parte2_8_ranking_publicaciones.png'
    items += img_if_exists(cap_path, width=14*cm,
        caption_text='Figura 1: Ejecución de sp_ranking_publicaciones en Oracle SQL Developer — '
                     'comunidad "IA General", top publicaciones activas con puntaje positivo en los últimos 30 días.')

    items.append(SP(16))

    # Triggers
    items.append(toc_h2('Triggers — Validaciones No Estructurales'))
    items.append(SP(4))
    items.append(P(
        'Decidimos mover algunas validaciones a triggers en lugar de hacerlo solo en los SPs '
        'porque los triggers actúan como última línea de defensa: si alguien inserta directamente '
        'en la tabla sin pasar por el SP (por ejemplo, desde SQL Developer durante pruebas), '
        'la regla de negocio igual se aplica. Los cinco triggers cubren las restricciones de estado '
        'y membresía que no son expresables como constraints declarativas.',
        'body'
    ))

    items.append(SP(8))

    triggers = [
        ('trg_no_votar_suspendido', 'Impide que un agente suspendido emita votos.'),
        ('trg_solo_observador_vota', 'Impide que agentes no-OBSERVADOR inserten filas en VOTO.'),
        ('trg_no_comentar_sin_membresia', 'Verifica que el agente sea miembro de la comunidad de la publicación antes de comentar.'),
        ('trg_no_publicar_comunidad_archivada', 'Bloquea inserciones en PUBLICACION si la comunidad ya está archivada.'),
        ('trg_no_comentar_publicacion_cerrada', 'Impide comentar en publicaciones con estado Cerrada o Eliminada.'),
    ]

    trigger_files = {
        'trg_no_votar_suspendido':             '/Users/jeronimo/Desktop/ObligatorioBDD2/parte2/trg_no_votar_suspendido.sql',
        'trg_solo_observador_vota':             '/Users/jeronimo/Desktop/ObligatorioBDD2/parte2/trg_solo_observador_vota.sql',
        'trg_no_comentar_sin_membresia':        '/Users/jeronimo/Desktop/ObligatorioBDD2/parte2/trg_no_comentar_sin_membresia.sql',
        'trg_no_publicar_comunidad_archivada':  '/Users/jeronimo/Desktop/ObligatorioBDD2/parte2/trg_no_publicar_comunidad_archivada.sql',
        'trg_no_comentar_publicacion_cerrada':  '/Users/jeronimo/Desktop/ObligatorioBDD2/parte2/trg_no_comentar_publicacion_cerrada.sql',
    }

    for name, desc in triggers:
        items.append(H3(name))
        items.append(P(desc, 'body'))
        items.append(SP(4))
        if os.path.exists(trigger_files[name]):
            code = open(trigger_files[name]).read()
            items.append(code_block(code))
        items.append(SP(8))

    items.append(PageBreak())
    return items


def seccion_parte3():
    items = []
    items.append(toc_h1('Parte 3 — Consulta SQL y Plan de Ejecución'))
    items.append(HR())

    items.append(toc_h2('3.1 Consulta SQL'))
    items.append(SP(4))
    items.append(P(
        '<b>Pregunta de negocio:</b> ¿Qué agentes generaron más publicaciones en cada comunidad '
        'en los últimos 30 días y cuántos votos positivos recibieron?',
        'body'
    ))
    items.append(SP(4))
    items.append(P(
        'Esta consulta es útil para Moltbook porque combina productividad (publicaciones generadas) '
        'con calidad validada por la comunidad (votos positivos). Un agente que publica mucho pero '
        'recibe pocos votos podría indicar contenido de baja relevancia; uno con pocos posts pero '
        'muchos votos es probablemente más valioso. La consulta involucra cinco tablas: AGENTE, '
        'CONTENIDO, PUBLICACION, COMUNIDAD y VOTO.',
        'body'
    ))
    items.append(SP(6))

    sql = open('/Users/jeronimo/Desktop/ObligatorioBDD2/parte3/ConsultaParte3.sql').read()
    items.append(code_block(sql))

    items.append(SP(16))
    items.append(toc_h2('3.2 Plan de Ejecución y Análisis'))
    items.append(SP(4))

    plan_raw = """Plan hash value: 1994302842

----------------------------------------------------------------------------------------------------------------
| Id  | Operation                                | Name                | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                         |                     |    29 |  7453 |     9  (34)| 00:00:01 |
|   1 |  SORT ORDER BY                           |                     |    29 |  7453 |     9  (34)| 00:00:01 |
|   2 |   HASH GROUP BY                          |                     |    29 |  7453 |     9  (34)| 00:00:01 |
|   3 |    VIEW                                  | VW_DAG_0            |    29 |  7453 |     7  (15)| 00:00:01 |
|   4 |     HASH GROUP BY                        |                     |    29 |  9251 |     7  (15)| 00:00:01 |
|   5 |      NESTED LOOPS OUTER                  |                     |    29 |  9251 |     6   (0)| 00:00:01 |
|*  6 |       HASH JOIN                          |                     |    16 |  4576 |     6   (0)| 00:00:01 |
|   7 |        NESTED LOOPS                      |                     |    10 |  1410 |     3   (0)| 00:00:01 |
|   8 |         NESTED LOOPS                     |                     |    12 |  1410 |     3   (0)| 00:00:01 |
|   9 |          TABLE ACCESS FULL               | COMUNIDAD           |     4 |   460 |     3   (0)| 00:00:01 |
|* 10 |          INDEX RANGE SCAN                | IX_PUB_COMUNIDAD    |     3 |       |     0   (0)| 00:00:01 |
|  11 |         TABLE ACCESS BY INDEX ROWID      | PUBLICACION         |     3 |    78 |     0   (0)| 00:00:01 |
|  12 |        VIEW                              | VW_GBF_17           |    16 |  2320 |     3   (0)| 00:00:01 |
|  13 |         NESTED LOOPS                     |                     |    16 |  2896 |     3   (0)| 00:00:01 |
|  14 |          NESTED LOOPS                    |                     |    30 |  2896 |     3   (0)| 00:00:01 |
|  15 |           TABLE ACCESS FULL              | AGENTE              |     6 |   852 |     3   (0)| 00:00:01 |
|* 16 |           INDEX RANGE SCAN               | IX_CONTENIDO_AGENTE |     5 |       |     0   (0)| 00:00:01 |
|* 17 |          TABLE ACCESS BY INDEX ROWID     | CONTENIDO           |     3 |   117 |     0   (0)| 00:00:01 |
|* 18 |       TABLE ACCESS BY INDEX ROWID BATCHED| VOTO                |     2 |    66 |     0   (0)| 00:00:01 |
|* 19 |        INDEX RANGE SCAN                  | IX_VOTO_PUBLICACION |     3 |       |     0   (0)| 00:00:01 |
----------------------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------
   6 - access("P"."ID_CONTENIDO"="ITEM_1")
  10 - access("C"."ID_COMUNIDAD"="P"."ID_COMUNIDAD")
  16 - access("CT"."ID_AGENTE"="A"."ID_AGENTE")
  17 - filter("CT"."FECHA_HORA_CREACION">=SYSDATE@!-30)
  18 - filter("V"."TIPO"(+)='positivo')
  19 - access("V"."ID_PUBLICACION"(+)="P"."ID_CONTENIDO")

Note: dynamic statistics used: dynamic sampling (level=2)"""

    items.append(code_block(plan_raw, font_size=6))

    items.append(SP(12))
    items.append(H3('Análisis del plan'))

    items.append(H3('Operaciones identificadas'))
    ops = [
        ['NESTED LOOPS (líneas 7, 8, 13, 14)', 'Algoritmo nested loop join: Oracle itera sobre cada fila de la tabla exterior y busca filas en la tabla interior usando un índice. Se usa cuando una de las tablas es pequeña o hay un índice eficiente. Aquí aplica entre COMUNIDAD–PUBLICACION (IX_PUB_COMUNIDAD) y AGENTE–CONTENIDO (IX_CONTENIDO_AGENTE).'],
        ['HASH JOIN (línea 6)',                 'Oracle construye una tabla hash en memoria con el resultado de un lado del join y prueba cada fila del otro lado contra esa tabla. Se usa cuando los conjuntos son medianos y no hay índice que cubra el join. Une PUBLICACION+COMUNIDAD con AGENTE+CONTENIDO.'],
        ['TABLE ACCESS FULL (líneas 9, 15)',    'COMUNIDAD y AGENTE se leen completas porque tienen 4 y 6 filas respectivamente. Con tablas tan pequeñas, un full scan es más barato que acceder a un índice — el optimizer tomó la decisión correcta.'],
        ['INDEX RANGE SCAN (líneas 10, 16, 19)','Usa los índices IX_PUB_COMUNIDAD, IX_CONTENIDO_AGENTE e IX_VOTO_PUBLICACION para leer solo las filas necesarias. Evita scans completos en las tablas más grandes.'],
        ['HASH GROUP BY (líneas 2, 4)',         'Agrupa usando tabla hash en memoria. Aparece dos veces porque COUNT(DISTINCT) requiere una pre-agregación interna antes de la agregación final.'],
        ['NESTED LOOPS OUTER (línea 5)',        'Implementa el LEFT JOIN a VOTO, preservando publicaciones sin votos.'],
    ]
    avail = PAGE_W - 2 * MARGIN
    items.append(simple_table(
        ['Operación', 'Descripción y relación con algoritmos de clase'],
        ops,
        col_widths=[avail*0.30, avail*0.70]
    ))

    items.append(SP(10))
    items.append(H3('Eficiencia del plan'))
    items.append(P(
        'El costo estimado es 9, con tiempo de ejecución de 1 segundo. Oracle tomó decisiones '
        'correctas dado el volumen actual: los full scans en COMUNIDAD y AGENTE son la opción '
        'óptima para tablas de 4 y 6 filas. Los índices que creamos en la Parte 1 '
        '(IX_PUB_COMUNIDAD, IX_CONTENIDO_AGENTE, IX_VOTO_PUBLICACION) se usan exactamente '
        'donde esperábamos.',
        'body'
    ))

    items.append(SP(8))
    items.append(H3('Mejoras propuestas'))
    mejoras = [
        '1. <b>Índice en CONTENIDO(fecha_hora_creacion):</b> el filtro de los 30 días aparece como "filter" en línea 17, lo que significa que Oracle lee todas las filas de CONTENIDO y descarta. Un índice en esa columna lo convertiría en INDEX RANGE SCAN.',
        '2. <b>Índice compuesto CONTENIDO(id_agente, fecha_hora_creacion):</b> cubriría tanto el join con AGENTE como el filtro de fecha en una sola estructura, reduciendo accesos a disco.',
        '3. <b>Con más datos:</b> el optimizer probablemente cambiaría algunos nested loops entre tablas grandes a hash joins, que escalan mejor con volúmenes altos. Con los datos de prueba actuales el plan es eficiente, pero el comportamiento cambia cuando las tablas crecen en órdenes de magnitud.',
    ]
    for m in mejoras:
        items.append(P(m, 'bullet'))

    items.append(PageBreak())
    return items


def seccion_parte4():
    items = []
    items.append(toc_h1('Parte 4 — Modelo MongoDB: Diseño e Integración'))
    items.append(HR())

    # 4.1 Análisis
    items.append(toc_h2('4.1 Análisis del subsistema de analítica'))
    items.append(SP(4))
    items.append(P(
        'El subsistema de analítica registra eventos heterogéneos: acciones de los agentes '
        '(publicar, comentar, votar, moderar), decisiones internas (selección de contenido, '
        'generación de respuestas), métricas de ejecución (tiempos, tokens, memoria) y '
        'detección de anomalías. Hay tres propiedades que dominan el diseño:',
        'body'
    ))
    items.append(SP(4))
    items.append(P(
        '1. <b>Alta heterogeneidad estructural.</b> La estructura de un evento de "decisión" '
        '(alternativas evaluadas, modelo, temperatura) no se parece a la de un "error" '
        '(código, mensaje) ni a la de una "interacción" (usuario, canal, resumen). En un '
        'relacional esto obligaría a tablas con decenas de columnas opcionales o a EAV.',
        'bullet'
    ))
    items.append(P(
        '2. <b>Dinamismo.</b> Van a aparecer tipos de evento no previstos sin poder migrar '
        'lo existente. El esquema tiene que absorber eso sin cambiar la estructura.',
        'bullet'
    ))
    items.append(P(
        '3. <b>Volumen alto y patrón analítico.</b> Se escribe mucho (un documento por acción) '
        'y se lee por agregaciones: rankings, conteos por hora, proporciones por criticidad. '
        'El Aggregation Framework de MongoDB cubre exactamente esos requerimientos.',
        'bullet'
    ))
    items.append(SP(8))
    items.append(P(
        'Estas tres propiedades son las que hacen a MongoDB más adecuado que Oracle para este '
        'subsistema. No elegimos Mongo por default, sino porque el patrón de datos encaja con '
        'lo que el modelo documental resuelve bien.',
        'body'
    ))

    items.append(SP(12))

    # 4.2 Diseño
    items.append(toc_h2('4.2 Diseño de Colecciones'))
    items.append(SP(4))

    items.append(H3('Decisión: máximo 2 colecciones'))
    col_rows = [
        ['eventos',  'Stream polimórfico de eventos crudos. Fuente principal para Parte 5.',   'Polymorphic + Embedding'],
        ['agentes',  'Snapshot de referencia de cada agente (sin los CLOB pesados de Oracle).',  'Subset / Extended Reference'],
    ]
    avail = PAGE_W - 2 * MARGIN
    items.append(simple_table(
        ['Colección', 'Propósito', 'Patrón principal'],
        col_rows,
        col_widths=[avail*0.15, avail*0.53, avail*0.32]
    ))
    items.append(SP(4))
    items.append(P(
        'Descartamos una tercera colección de buckets horarios (Bucket Pattern) para respetar el '
        'máximo de 2 de la consigna. La proponemos como mejora en la Parte 6.',
        'body'
    ))

    items.append(SP(10))
    items.append(H3('Colección eventos — campos predefinidos'))
    campos_fijos = [
        ['agente_id',   'int',    'Id del agente en Oracle (clave de correlación).'],
        ['tipo_agente', 'string', 'GENERADOR | MODERADOR | OBSERVADOR.'],
        ['tipo_evento', 'string', 'Conjunto abierto: creacion, comentario, voto, moderacion, decision, interaccion, error, ...'],
        ['criticidad',  'string', 'alta | media | baja.'],
        ['timestamp',   'date',   'Momento del evento (ISODate). Eje temporal de toda la analítica.'],
    ]
    items.append(simple_table(
        ['Campo', 'Tipo', 'Descripción'],
        campos_fijos,
        col_widths=[avail*0.18, avail*0.12, avail*0.70]
    ))

    items.append(SP(6))
    items.append(H3('Campos variables (polimórficos)'))
    campos_var = [
        ['contexto_operacional', 'objeto', 'casi todos',              '{ comunidad_id, comunidad_nombre, sesion_id, origen }'],
        ['parametros_entrada',   'objeto', 'decision, interaccion',   'Parámetros con los que el agente operó (varía por tipo_evento)'],
        ['metricas',             'objeto', 'eventos con cómputo',     '{ tiempo_respuesta_ms, tokens_procesados, uso_memoria_mb }'],
        ['detalle',              'objeto', 'polimórfico por tipo',     'El corazón del polymorphic pattern (ver ejemplos abajo)'],
        ['anomalia',             'objeto', 'eventos marcados',         '{ detectada: bool, patron, score }'],
    ]
    items.append(simple_table(
        ['Campo', 'Tipo', 'Aparece en', 'Contenido'],
        campos_var,
        col_widths=[avail*0.20, avail*0.10, avail*0.22, avail*0.48]
    ))

    items.append(SP(6))
    items.append(H3('Ejemplos de detalle polimórfico'))
    detalle_ej = """{
  // tipo_evento: "decision"
  "detalle": {
    "alternativas_evaluadas": [{"opcion":"A","score":0.81}, {"opcion":"B","score":0.64}],
    "opcion_elegida": "A",
    "modelo": { "nombre": "moltgpt-2", "temperatura": 0.7 }
  }
}

{
  // tipo_evento: "creacion"
  "detalle": { "contenido_id": 21, "titulo": "RAG en produccion", "etiquetas": ["rag","embeddings"] }
}

{
  // tipo_evento: "error"
  "detalle": { "codigo": "TIMEOUT", "mensaje": "El modelo no respondio a tiempo" }
}"""
    items.append(code_block(detalle_ej))

    items.append(SP(10))
    items.append(H3('Colección agentes — subset de referencia'))
    items.append(P(
        'Guardamos solo los atributos de agente necesarios para enriquecer la analítica '
        '(nombre, tipo, estado, administrador), dejando afuera deliberadamente los CLOB '
        'pesados de Oracle (prompt, descripcion) que la analítica no necesita. Reutilizamos '
        'el id_agente de Oracle como _id, que actúa como clave de correlación entre ambas bases.',
        'body'
    ))

    items.append(SP(10))
    items.append(H3('Índices'))
    idx_rows = [
        ['ix_agente_tipo_ts',  '{ agente_id: 1, tipo_evento: 1, timestamp: 1 }', 'Soporta consultas 5.1 y 5.3 (filtro por agente + tipo + ventana temporal)'],
        ['ix_ts_criticidad',   '{ timestamp: 1, criticidad: 1 }',                'Soporta consulta 5.2 (última semana con criticidad = "alta")'],
        ['ix_tipo (agentes)',   '{ tipo: 1 }',                                   'Filtros por tipo de agente en analítica'],
    ]
    items.append(simple_table(
        ['Índice', 'Definición', 'Propósito'],
        idx_rows,
        col_widths=[avail*0.22, avail*0.42, avail*0.36]
    ))

    items.append(SP(12))

    # 4.3 Validators
    items.append(toc_h2('4.3 Schema Validators ($jsonSchema)'))
    items.append(SP(4))
    items.append(P(
        'El validator de <b>eventos</b> exige los cinco campos predefinidos y aplica restricciones '
        'de tipo en cada uno (tipo_agente y criticidad como enums, timestamp como date, etc.). '
        'El campo tipo_evento es un string libre para mantener el conjunto abierto. '
        'Los campos variables (contexto_operacional, parametros_entrada, detalle, etc.) se validan '
        'solo como "object" sin restricciones internas, lo que materializa el schema-on-read. '
        'El validator de <b>agentes</b> es más estricto porque los datos son un snapshot de Oracle '
        'y la estructura es fija.',
        'body'
    ))
    items.append(SP(4))
    val_code = open('/Users/jeronimo/Desktop/ObligatorioBDD2/parte4/01_colecciones_validators.js').read()
    items.append(code_block(val_code, font_size=7))

    items.append(SP(12))

    # 4.4 Datos de prueba
    items.append(toc_h2('4.4 Datos de Prueba'))
    items.append(SP(4))
    items.append(P(
        'Los datos de prueba cubren los 9 agentes de la BD relacional y generan eventos de todos '
        'los tipos: creacion, comentario, voto y moderacion derivados de Oracle, más decision, '
        'interaccion y error generados como eventos de runtime del agente. El script es autocontenido '
        'y no requiere Oracle activo.',
        'body'
    ))
    items.append(SP(4))
    dp = open('/Users/jeronimo/Desktop/ObligatorioBDD2/parte4/02_datos_prueba.js').read()
    items.append(code_block(dp, font_size=7))

    items.append(SP(12))

    # 4.5 ETL
    items.append(toc_h2('4.5 Integración Oracle → MongoDB'))
    items.append(SP(4))
    items.append(P(
        'El script ETL conecta simultáneamente a Oracle (vía oracledb) y MongoDB (vía mongodb driver). '
        'Lee las tablas PUBLICACION, COMENTARIO, VOTO, MODERACION y CONFIGURACION_HISTORICA de Oracle '
        'y las convierte en eventos Mongo con la criticidad asignada por tipo de evento (error/moderacion = '
        '"alta"; decision/comentario = "media"; creacion/voto/interaccion = "baja"). Complementa con '
        'eventos de runtime (decision, interaccion, error) generados sintéticamente. '
        'Las credenciales se pasan por variables de entorno para no hardcodearlas. '
        'Elegimos Node.js porque oracledb y el driver oficial de MongoDB para Node son maduros '
        'y tienen buena interoperabilidad.',
        'body'
    ))
    items.append(SP(4))
    etl = open('/Users/jeronimo/Desktop/ObligatorioBDD2/parte4/03_integracion_oracle_mongo.js').read()
    items.append(code_block(etl, font_size=6))

    items.append(PageBreak())
    return items


def seccion_parte5():
    items = []
    items.append(toc_h1('Parte 5 — Consultas MongoDB'))
    items.append(HR())

    items.append(P(
        'Las consultas de esta parte las desarrolló Jeronimo trabajando contra la colección '
        '"eventos" del schema definido en Parte 4. Coordinamos los nombres de campos '
        '(agente_id, tipo_evento, criticidad, timestamp, contexto_operacional, parametros_entrada) '
        'para que las queries fueran compatibles tanto con los datos de prueba de '
        'parte4/02_datos_prueba.js como con el ETL de parte4/03_integracion_oracle_mongo.js.',
        'body'
    ))

    items.append(SP(12))

    # 5.1
    items.append(toc_h2('Requerimiento 5.1 — Eventos "decision" en rango de fechas'))
    items.append(SP(4))
    items.append(P(
        'Devuelve la lista cronológica de todos los eventos de tipo "decision" de un agente específico '
        'en un rango de fechas, proyectando contexto_operacional y parametros_entrada.',
        'body'
    ))
    items.append(SP(4))

    q51 = """db.eventos.find(
  {
    agente_id: 1,
    tipo_evento: "decision",
    timestamp: {
      $gte: ISODate("2026-01-01T00:00:00Z"),
      $lte: ISODate("2026-06-30T23:59:59Z")
    }
  },
  {
    _id: 0,
    agente_id: 1,
    tipo_evento: 1,
    criticidad: 1,
    timestamp: 1,
    contexto_operacional: 1,
    parametros_entrada: 1
  }
).sort({ timestamp: 1 })"""
    items.append(code_block(q51))
    items.append(SP(4))
    items.append(P(
        'El índice ix_agente_tipo_ts ({ agente_id, tipo_evento, timestamp }) cubre exactamente '
        'los tres campos del filtro, lo que hace que esta consulta sea un INDEX RANGE SCAN '
        'sin necesidad de leer la colección completa.',
        'body'
    ))

    cap_51 = '/Users/jeronimo/Desktop/ObligatorioBDD2/Documentación/capturas/parte5_1_consulta_decisiones.png'
    items += img_if_exists(cap_51, width=14*cm,
        caption_text='Figura 2: Consulta 5.1 ejecutada en MongoDB Compass — '
                     'eventos "decision" del agente 1, ordenados por timestamp, '
                     'proyectando contexto_operacional y parametros_entrada.')

    items.append(SP(12))

    # 5.2
    items.append(toc_h2('Requerimiento 5.2 — Top 5 agentes por criticidad "alta"'))
    items.append(SP(4))
    items.append(P(
        'Identifica los 5 agentes con mayor cantidad de eventos de criticidad "alta" en la '
        'última semana, mostrando la cantidad total y la proporción de cada agente sobre '
        'el total del período.',
        'body'
    ))
    items.append(SP(4))

    q52 = """db.eventos.aggregate([
  {
    $match: {
      criticidad: "alta",
      timestamp: { $gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) }
    }
  },
  {
    $group: {
      _id: "$agente_id",
      eventos_alta: { $sum: 1 }
    }
  },
  {
    $group: {
      _id: null,
      total_periodo: { $sum: "$eventos_alta" },
      agentes: { $push: { agente_id: "$_id", eventos_alta: "$eventos_alta" } }
    }
  },
  { $unwind: "$agentes" },
  {
    $project: {
      _id: 0,
      agente_id: "$agentes.agente_id",
      eventos_alta: "$agentes.eventos_alta",
      total_periodo: 1,
      proporcion: {
        $round: [{ $divide: ["$agentes.eventos_alta", "$total_periodo"] }, 2]
      }
    }
  },
  { $sort: { eventos_alta: -1 } },
  { $limit: 5 }
])"""
    items.append(code_block(q52))
    items.append(SP(4))
    items.append(P(
        'El doble $group es la técnica clave: el primer grupo acumula eventos_alta por agente; '
        'el segundo agrupa todos en _id: null para obtener el total del período. Sin ese segundo '
        '$group no sería posible calcular la proporción porque un solo $group no puede "ver" '
        'los valores de los otros agentes.',
        'body'
    ))

    cap_52 = '/Users/jeronimo/Desktop/ObligatorioBDD2/Documentación/capturas/parte5_2_top5_criticidad_alta.png'
    items += img_if_exists(cap_52, width=14*cm,
        caption_text='Figura 3: Consulta 5.2 — top 5 agentes por eventos de criticidad "alta" '
                     'en la última semana, con total_periodo y proporción.')

    items.append(SP(12))

    # 5.3
    items.append(toc_h2('Requerimiento 5.3 — Interacciones por hora en franja horaria'))
    items.append(SP(4))
    items.append(P(
        'Devuelve los eventos de tipo "interaccion" de un agente dentro de la franja 08:00–17:00, '
        'agrupados por hora con la cantidad total por hora.',
        'body'
    ))
    items.append(SP(4))

    q53 = """db.eventos.aggregate([
  {
    $match: {
      agente_id: 1,
      tipo_evento: "interaccion",
      $expr: {
        $and: [
          { $gte: [{ $hour: "$timestamp" }, 8] },
          { $lte: [{ $hour: "$timestamp" }, 17] }
        ]
      }
    }
  },
  {
    $group: {
      _id: { hora: { $hour: "$timestamp" } },
      total_interacciones: { $sum: 1 }
    }
  },
  {
    $project: {
      _id: 0,
      hora: "$_id.hora",
      total_interacciones: 1
    }
  },
  { $sort: { hora: 1 } }
])"""
    items.append(code_block(q53))
    items.append(SP(4))
    items.append(P(
        'Usamos $expr con $hour sobre el campo timestamp (ISODate) para extraer la hora UTC '
        'y filtrar en el mismo $match, evitando un $addFields adicional. '
        'El resultado es un documento por hora con la cantidad de interacciones, ordenado de 8 a 17.',
        'body'
    ))

    cap_53 = '/Users/jeronimo/Desktop/ObligatorioBDD2/Documentación/capturas/parte5_3_interacciones_por_hora.png'
    items += img_if_exists(cap_53, width=14*cm,
        caption_text='Figura 4: Consulta 5.3 — eventos "interaccion" del agente 1 '
                     'agrupados por hora dentro de la franja 08–17h.')

    items.append(PageBreak())
    return items


def seccion_parte6():
    items = []
    items.append(toc_h1('Parte 6 — Reflexión Comparativa: MongoDB vs Relacional'))
    items.append(HR())

    # Pregunta 1
    items.append(toc_h2('1. ¿Cómo aplicaron los conceptos del material de estudio?'))
    items.append(SP(4))
    items.append(P(
        'No elegimos MongoDB por default. Lo elegimos porque el subsistema tiene tres propiedades '
        'que el material de referencia (NoSQL Data Modeling Techniques de highlyscalable y '
        'Building with Patterns de MongoDB) asocia directamente al modelo documental: '
        'heterogeneidad estructural, dinamismo y volumen alto con acceso analítico. '
        'Sobre esa base aplicamos patrones concretos:',
        'body'
    ))

    items.append(SP(8))
    items.append(H3('Polymorphic Pattern — colección eventos'))
    items.append(P(
        'Es el patrón central. Una única colección almacena documentos con estructuras distintas, '
        'discriminados por el campo tipo_evento. Los cinco campos predefinidos están en todos los '
        'documentos; la parte variable depende del tipo de evento. En un relacional esto obligaría '
        'a una tabla con decenas de columnas opcionales nulas o a un esquema EAV difícil de consultar. '
        'En Mongo, un evento "decision" y un evento "error" conviven en la misma colección sin '
        'que ninguno tenga campos vacíos.',
        'body'
    ))

    items.append(SP(6))
    ej_poly = """{
  // tipo_evento: "decision"
  "detalle": {
    "alternativas_evaluadas": [{"opcion":"A","score":0.81}, {"opcion":"B","score":0.64}],
    "opcion_elegida": "A",
    "modelo": { "nombre": "moltgpt-2", "temperatura": 0.7 }
  }
}
{
  // tipo_evento: "error"
  "detalle": { "codigo": "TIMEOUT", "mensaje": "El modelo no respondio a tiempo" }
}"""
    items.append(code_block(ej_poly))

    items.append(SP(8))
    items.append(H3('Embedding — "data that is accessed together, stored together"'))
    items.append(P(
        'Los sub-documentos contexto_operacional, parametros_entrada, metricas y detalle se anidan '
        'dentro del propio evento porque nunca se consultan por separado del evento que los origina. '
        'Esto elimina joins en la lectura analítica. Se ve claramente en el requerimiento 5.1: '
        'devuelve cada evento junto a su contexto_operacional y parametros_entrada con un solo '
        'find y una proyección, sin ningún $lookup.',
        'body'
    ))

    items.append(SP(8))
    items.append(H3('Subset / Extended Reference Pattern — colección agentes'))
    items.append(P(
        'En lugar de volver a Oracle (o duplicar el agente entero) en cada dashboard, guardamos '
        'un subconjunto estable y de solo lectura de cada agente: nombre, identificador, tipo, '
        'estado y un sub-objeto usuario_admin. Dejamos afuera deliberadamente los CLOB pesados '
        '(prompt, descripcion) que la analítica no necesita. Además reutilizamos el id_agente de '
        'Oracle como _id, lo que funciona como clave de correlación entre ambas bases.',
        'body'
    ))

    items.append(SP(8))
    items.append(H3('Schema-on-read y diseño de índices guiado por consultas'))
    items.append(P(
        'El validator $jsonSchema es estricto en los cinco campos fijos pero deja tipo_evento como '
        'string libre y no restringe additionalProperties. Eso materializa el schema-on-read: '
        'nuevos tipos de evento y campos entran sin migrar el esquema. Los índices los diseñamos '
        'a partir del patrón de acceso (no de las entidades): '
        '{ agente_id, tipo_evento, timestamp } soporta 5.1 y 5.3, '
        'y { timestamp, criticidad } soporta 5.2.',
        'body'
    ))

    items.append(SP(14))

    # Pregunta 2
    items.append(toc_h2('2. ¿Puede mejorar el modelado?'))
    items.append(SP(4))
    items.append(P(
        'Sí. El diseño priorizó simplicidad y el límite de máximo 2 colecciones de la consigna; '
        'eso dejó mejoras concretas sobre la mesa:',
        'body'
    ))
    items.append(SP(6))

    mejoras = [
        ('Bucket Pattern (tercera colección de agregados horarios)',
         'Las consultas 5.2 y 5.3 recorren la colección eventos completa para contar. Una colección '
         'eventos_horarios que pre-agrupe conteos por agente y por hora reduciría drásticamente el '
         'trabajo. Se descartó solo para respetar el tope de 2 colecciones; queda como la mejora más rentable.'),
        ('Computed Pattern',
         'Calcular y persistir métricas derivadas en el momento de la escritura '
         '(totales por agente, proporción de criticidad "alta") en vez de recomputarlas en cada '
         'lectura. Conviene cuando la relación lectura/escritura es alta, como en un panel analítico.'),
        ('Schema Versioning Pattern',
         'Agregar un campo schema_version a cada evento permitiría evolucionar la forma de la parte '
         'polimórfica de manera explícita y coexistir versiones viejas y nuevas sin ambigüedad.'),
        ('Validación condicional por tipo de evento',
         'Actualmente "detalle" se valida solo como object libre. Se podría reforzar con '
         '$jsonSchema condicional (oneOf / if-then) que exija ciertos campos en detalle según '
         'tipo_evento — por ejemplo, "codigo" y "mensaje" obligatorios cuando tipo_evento = "error".'),
        ('Índice TTL',
         'Si la bitácora tuviera política de retención (conservar eventos un año), un índice TTL '
         'sobre timestamp purgaría los documentos viejos automáticamente.'),
    ]

    for nombre, desc in mejoras:
        items.append(H3(nombre))
        items.append(P(desc, 'body'))
        items.append(SP(4))

    items.append(SP(14))

    # Pregunta 3
    items.append(toc_h2('3. Ventajas y desventajas de MongoDB en este subsistema'))
    items.append(SP(4))

    items.append(H3('Ventajas'))
    ventajas = [
        '<b>Esquema flexible para datos heterogéneos y dinámicos.</b> Nuevos tipos de evento entran sin migración. El relacional exigiría columnas opcionales nulas o EAV.',
        '<b>Lecturas sin joins.</b> El embedding hace que cada evento traiga ya su contexto, métricas y detalle; la analítica de la Parte 5 se resuelve sobre una sola colección.',
        '<b>Escritura de alto volumen.</b> El subsistema es append-only (bitácora de auditoría); el modelo documental y el sharding por timestamp / agente_id escalan bien ese patrón.',
        '<b>Aggregation Framework.</b> Cubre directamente los requerimientos analíticos (rankings, conteos por hora, proporciones) de la Parte 5 sin necesidad de capas adicionales.',
    ]
    for v in ventajas:
        items.append(P(f'• {v}', 'bullet'))

    items.append(SP(8))
    items.append(H3('Desventajas'))
    desventajas = [
        '<b>Sin integridad referencial entre bases.</b> No hay FK Oracle↔Mongo; la correlación por agente_id queda como responsabilidad del proceso de integración, no del motor.',
        '<b>Sin el modelo transaccional ACID multi-tabla del relacional.</b> En este subsistema no duele porque es append-only, pero sería una limitación en un módulo con escrituras coordinadas.',
        '<b>Riesgo de datos desactualizados por denormalización.</b> El snapshot "agentes" debe re-sincronizarse cuando cambian los datos en Oracle; si no, queda stale.',
        '<b>Menor garantía de integridad por la flexibilidad.</b> Dejar la parte variable libre traslada parte de la validación a la aplicación.',
    ]
    for d in desventajas:
        items.append(P(f'• {d}', 'bullet'))

    items.append(SP(8))
    items.append(H3('¿Otro subsistema candidato a MongoDB?'))
    items.append(P(
        'Sí: el módulo de <b>contenido social (PUBLICACION + COMENTARIO + VOTO)</b>. '
        'Los comentarios son jerárquicos (un comentario responde a una publicación o a otro comentario). '
        'En el modelo relacional esto se resuelve con una FK recursiva y CTEs; en documento se modela '
        'de forma natural con un árbol de comentarios embebido dentro de la publicación. '
        'La publicación, su hilo de comentarios y el contador de votos se leen juntos '
        '(al abrir un post se muestra todo), lo que cumple la regla "lo que se accede junto '
        'se guarda junto". El conteo de votos encaja con el Computed Pattern.',
        'body'
    ))
    items.append(P(
        'Un segundo candidato menor es <b>CONFIGURACION_HISTORICA</b>: el historial de versiones '
        'de configuración de un agente se modela bien como un array versionado embebido dentro del '
        'documento del agente, ya que se consulta casi siempre junto al agente.',
        'body'
    ))

    items.append(PageBreak())
    return items


def seccion_anexo_ia():
    items = []
    items.append(toc_h1('Anexo — Uso de Inteligencia Artificial'))
    items.append(HR())

    items.append(P(
        'A continuación detallamos las herramientas de IA que usamos durante el proyecto, '
        'el contexto de cada uso y una aclaración sobre qué verificamos nosotros.',
        'body'
    ))

    items.append(SP(10))
    items.append(H2('Herramientas utilizadas'))

    herramientas = [
        ('Claude (claude.ai) — Anthropic',
         'Usado como asistente de chat para consultas puntuales, debugging de PL/SQL, '
         'revisión de lógica de procedimientos y estructuración del informe.'),
        ('Claude Code — Anthropic',
         'Usado para generación de scaffolding de SPs complejos, escritura de datos de prueba, '
         'generación de queries MongoDB, organización de archivos del proyecto y generación '
         'del PDF final del informe.'),
    ]

    for nombre, desc in herramientas:
        items.append(H3(nombre))
        items.append(P(desc, 'body'))
        items.append(SP(4))

    items.append(SP(10))
    items.append(H2('Contexto de uso por parte'))

    usos = [
        ['Parte 1', 'Revisión de restricciones y supuestos, ayuda para identificar casos borde en el DDL.'],
        ['Parte 2', 'Scaffolding de sp_registrar_agente y sp_ranking_publicaciones. Los demás SPs los escribimos nosotros con consultas puntuales para dudas específicas de PL/SQL.'],
        ['Parte 3', 'Revisión del análisis del plan de ejecución.'],
        ['Parte 4', 'Diseño del modelo MongoDB, validators $jsonSchema, script ETL Oracle→Mongo.'],
        ['Parte 5', 'Generación de las tres queries MongoDB y ajuste de la lógica del doble $group en 5.2.'],
        ['Parte 6', 'Estructuración de las respuestas a las tres preguntas; redacción final revisada por el equipo.'],
        ['Informe', 'Generación del PDF final a partir de los archivos del repositorio.'],
    ]
    avail = PAGE_W - 2 * MARGIN
    items.append(simple_table(
        ['Parte', 'Uso de IA'],
        usos,
        col_widths=[avail*0.12, avail*0.88]
    ))

    items.append(SP(12))
    items.append(H2('Aclaración'))
    items.append(P(
        'Todo lo generado con IA fue revisado y verificado por los integrantes del grupo. '
        'Entendemos el código y los diseños que presentamos. Los errores que pueda haber son nuestros.',
        'body'
    ))

    return items


# ---------------------------------------------------------------------------
# Ensamblaje final
# ---------------------------------------------------------------------------
def build_pdf():
    output_path = '/Users/jeronimo/Desktop/ObligatorioBDD2/Documentación/informe_moltbook.pdf'

    doc = MoltbookDocTemplate(
        output_path,
        pagesize=A4,
        leftMargin=MARGIN,
        rightMargin=MARGIN,
        topMargin=MARGIN,
        bottomMargin=MARGIN,
        title='Informe Obligatorio BD2 - Moltbook',
        author='Sardina, Baz, De Marco',
        subject='Obligatorio Bases de Datos 2 - ORT Uruguay 2026',
    )

    story = []

    # Portada (sin header/footer en la primera página — la doc template siempre dibuja)
    story += seccion_portada()

    # TOC
    toc_items, toc = seccion_toc()
    story += toc_items
    doc.toc = toc

    # Contenido
    story += seccion_parte1()
    story += seccion_parte2()
    story += seccion_parte3()
    story += seccion_parte4()
    story += seccion_parte5()
    story += seccion_parte6()
    story += seccion_anexo_ia()

    # Build — dos pasadas para el TOC
    doc.multiBuild(story)

    # Stat
    size_mb = os.path.getsize(output_path) / (1024 * 1024)
    print(f'\nPDF generado exitosamente.')
    print(f'  Ruta:  {output_path}')
    print(f'  Tamaño: {size_mb:.2f} MB')
    if size_mb > 40:
        print('  AVISO: el PDF supera 40 MB. Considera comprimir imágenes.')


if __name__ == '__main__':
    build_pdf()
