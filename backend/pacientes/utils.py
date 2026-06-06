import io
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors
from datetime import datetime

def generar_pdf_paciente(paciente, doctor):
    """
    Genera un reporte clínico consolidado en PDF para un paciente específico.
    """
    buffer = io.BytesIO()
    # Definir el documento con márgenes estándar
    doc = SimpleDocTemplate(
        buffer, 
        pagesize=letter, 
        rightMargin=50, 
        leftMargin=50, 
        topMargin=50, 
        bottomMargin=50
    )
    styles = getSampleStyleSheet()
    
    # Estilos personalizados para un aspecto profesional
    style_title = ParagraphStyle(
        'TitleStyle',
        parent=styles['Heading1'],
        fontSize=20,
        spaceAfter=25,
        alignment=1, # Centro
        textColor=colors.teal
    )
    style_header = ParagraphStyle(
        'HeaderStyle',
        parent=styles['Heading2'],
        fontSize=14,
        spaceAfter=12,
        spaceBefore=18,
        textColor=colors.darkblue,
        borderPadding=5,
    )
    style_normal = styles['Normal']
    style_label = ParagraphStyle(
        'LabelStyle',
        parent=styles['Normal'],
        fontSize=10,
        fontName='Helvetica-Bold'
    )
    
    elements = []

    # 1. Encabezado del Reporte
    fecha_actual = datetime.now().strftime("%d/%m/%Y %H:%M")
    elements.append(Paragraph("REPORTE CLÍNICO INTEGRAL", style_title))
    elements.append(Paragraph(f"<b>Fecha de Emisión:</b> {fecha_actual}", style_normal))
    
    try:
        nombre_dr = f"{doctor.perfil.nombre} {doctor.perfil.apellido}"
    except Exception:
        nombre_dr = doctor.email

    elements.append(Paragraph(f"<b>Médico Responsable:</b> Dr. {nombre_dr} ({doctor.email})", style_normal))
    elements.append(Spacer(1, 25))

    # 2. Sección: Datos del Paciente
    elements.append(Paragraph("1. PERFIL DEL PACIENTE", style_header))
    try:
        nombre_p = f"{paciente.usuario.perfil.nombre} {paciente.usuario.perfil.apellido}"
    except:
        nombre_p = paciente.usuario.email

    datos_paciente = [
        ["Nombre Completo:", nombre_p],
        ["Edad:", f"{paciente.edad} años"],
        ["Sexo:", paciente.get_sexo_display()],
        ["Peso / Talla:", f"{paciente.peso_inicial} kg / {paciente.talla_inicial} m"],
        ["Alergias:", paciente.alergias or "Ninguna"],
        ["Antecedentes Base:", paciente.antecedentes_base or "Ninguno"]
    ]
    
    t_paciente = Table(datos_paciente, colWidths=[120, 380])
    t_paciente.setStyle(TableStyle([
        ('GRID', (0,0), (-1,-1), 0.5, colors.grey),
        ('BACKGROUND', (0,0), (0,-1), colors.whitesmoke),
        ('FONTNAME', (0,0), (0,-1), 'Helvetica-Bold'),
        ('PADDING', (0,0), (-1,-1), 7),
    ]))
    elements.append(t_paciente)
    elements.append(Spacer(1, 15))

    # 3. Sección: Historial Clínico
    elements.append(Paragraph("2. REGISTROS DE HISTORIAL CLÍNICO", style_header))
    historiales = paciente.historiales_clinicos.filter(activo=True).order_by('-fecha_registro')
    if historiales.exists():
        for h in historiales:
            elements.append(Paragraph(f"<b>Fecha:</b> {h.fecha_registro.strftime('%d/%m/%Y')}", style_normal))
            elements.append(Paragraph(f"<b>Motivo Consulta:</b> {h.motivo_consulta}", style_normal))
            elements.append(Paragraph(f"<b>Estado Actual:</b> {h.estado_actual}", style_normal))
            if h.observaciones_medicas:
                elements.append(Paragraph(f"<b>Observaciones:</b> {h.observaciones_medicas}", style_normal))
            elements.append(Spacer(1, 5))
            elements.append(Paragraph("<font color='grey'>________________________________________________________________________________</font>", style_normal))
            elements.append(Spacer(1, 10))
    else:
        elements.append(Paragraph("<i>No se encontraron registros de historial clínico activos.</i>", style_normal))

    # 4. Sección: Reporte de Arritmias
    elements.append(Paragraph("3. EVALUACIÓN DE ARRITMIAS", style_header))
    arritmias = paciente.arritmias.all().order_by('-fecha_deteccion')
    if arritmias.exists():
        for a in arritmias:
            elements.append(Paragraph(f"<b>Evento:</b> {a.tipo_arritmia} (Detección: {a.fecha_deteccion})", style_normal))
            elements.append(Paragraph(f"<b>Riesgo:</b> {a.nivel_riesgo} | <b>Estado Actual:</b> {a.estado}", style_normal))
            
            seguimientos = a.seguimientos.all().order_by('-fecha_control')[:3]
            if seguimientos.exists():
                elements.append(Paragraph("<i>Seguimientos Recientes:</i>", style_normal))
                for s in seguimientos:
                    elements.append(Paragraph(f"  • {s.fecha_control}: {s.frecuencia_cardiaca} lpm - Estado: {s.estado}", style_normal))
            elements.append(Spacer(1, 10))
    else:
        elements.append(Paragraph("<i>No se han registrado episodios de arritmia para este paciente.</i>", style_normal))

    # 5. Sección: Plan de Tratamiento
    elements.append(Paragraph("4. PLAN DE TRATAMIENTO VIGENTE", style_header))
    tratamientos = paciente.tratamientos.filter(estado='Activo').order_by('-fecha_inicio')
    if tratamientos.exists():
        for t in tratamientos:
            elements.append(Paragraph(f"<b>Periodo:</b> {t.fecha_inicio} a {t.fecha_fin or 'Indefinido'}", style_normal))
            
            # Medicamentos en tabla
            if t.medicamentos.exists():
                elements.append(Spacer(1, 5))
                elements.append(Paragraph("<b>Medicamentos Prescritos:</b>", style_normal))
                data_m = [["Fármaco", "Dosis", "Frecuencia", "Duración"]]
                for m in t.medicamentos.all():
                    data_m.append([m.nombre_medicamento, m.dosis, m.frecuencia, m.duracion])
                
                t_meds = Table(data_m, colWidths=[150, 90, 110, 100])
                t_meds.setStyle(TableStyle([
                    ('BACKGROUND', (0,0), (-1,0), colors.teal),
                    ('TEXTCOLOR', (0,0), (-1,0), colors.whitesmoke),
                    ('ALIGN', (0,0), (-1,-1), 'LEFT'),
                    ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
                    ('GRID', (0,0), (-1,-1), 0.5, colors.grey),
                    ('FONTSIZE', (0,0), (-1,-1), 9),
                    ('PADDING', (0,0), (-1,-1), 5),
                ]))
                elements.append(t_meds)
                elements.append(Spacer(1, 10))

            # Recomendaciones
            if t.recomendaciones.exists():
                elements.append(Paragraph("<b>Indicaciones Médicas:</b>", style_normal))
                for r in t.recomendaciones.all():
                    elements.append(Paragraph(f" • <b>{r.tipo_recomendacion}:</b> {r.descripcion}", style_normal))
            elements.append(Spacer(1, 10))
    else:
        elements.append(Paragraph("<i>No hay planes de tratamiento activos registrados.</i>", style_normal))

    # Finalizar el PDF
    doc.build(elements)
    pdf_content = buffer.getvalue()
    buffer.close()
    return pdf_content
