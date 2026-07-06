from __future__ import annotations

import json
from datetime import datetime
from io import BytesIO

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import (
    KeepTogether,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

from app.models.equipment import Equipment
from app.models.result import SimulationResult
from app.models.simulation import Simulation
from app.models.site import Site
from app.schemas.simulation_schema import ReportRead, SimulationResultRead

PRIMARY = colors.HexColor("#21372d")
ACCENT = colors.HexColor("#b9683f")
TEXT = colors.HexColor("#433c35")
MUTED = colors.HexColor("#6e655c")
BORDER = colors.HexColor("#d9d1c7")
GRID = colors.HexColor("#e8dfd4")
SOFT_BG = colors.HexColor("#f7f3ee")
HEADER_BG = colors.HexColor("#eef2ee")


def build_report_payload(
    *,
    site: Site,
    simulation: Simulation,
    equipment: list[Equipment],
    result: SimulationResult | None,
    academic_notice: str,
) -> ReportRead:
    return ReportRead(
        academic_notice=academic_notice,
        site=site,
        equipment=equipment,
        simulation=simulation,
        result=SimulationResultRead.model_validate(result) if result else None,
        assumptions=[
            "Toutes les donnees sont simulees pour une demonstration academique.",
            "La puissance PV est calculee avec l'energie corrigee et les heures solaires.",
            "Les batteries integrent la profondeur de decharge choisie.",
            "Le regulateur et l'onduleur incluent une marge de securite de 25%.",
        ],
    )


def generate_report_pdf(report: ReportRead) -> bytes:
    buffer = BytesIO()
    doc = SimpleDocTemplate(
        buffer,
        pagesize=A4,
        leftMargin=1.5 * cm,
        rightMargin=1.5 * cm,
        topMargin=1.7 * cm,
        bottomMargin=1.5 * cm,
        title=f"HAYAT-Solar Sizer - Simulation {report.simulation.id}",
        author="HAYAT-Solar Sizer",
    )

    styles = _build_styles()
    story: list = []
    result = report.result
    generated_at = datetime.now().strftime("%d/%m/%Y %H:%M")
    critical_count = sum(1 for item in report.equipment if item.is_critical)
    non_critical_count = len(report.equipment) - critical_count
    equipment_plan = {}
    if result and result.recommended_configuration_json:
        try:
            equipment_plan = json.loads(result.recommended_configuration_json).get("equipment_usage_plan", {})
        except json.JSONDecodeError:
            equipment_plan = {}

    story.extend(
        [
            Paragraph("APPLICATION WEB PROFESSIONNELLE", styles["eyebrow"]),
            Spacer(1, 0.25 * cm),
            Paragraph("HAYAT-Solar Sizer", styles["cover_title"]),
            Spacer(1, 0.1 * cm),
            Paragraph(
                "Rapport de dimensionnement photovoltaique de back-up pour site telecom",
                styles["cover_subtitle"],
            ),
            Spacer(1, 0.75 * cm),
            _summary_band(
                [
                    ("Site", report.site.name),
                    ("Localisation", f"{report.site.city}, {report.site.country}"),
                    ("Simulation", f"#{report.simulation.id}"),
                    ("Genere le", generated_at),
                ]
            ),
            Spacer(1, 0.4 * cm),
            _summary_band(
                [
                    ("Verdict", result.feasibility_status.replace("_", " ") if result else "NON CALCULE"),
                    (
                        "Autonomie ciblee",
                        f"{report.site.target_backup_hours:.2f} h",
                    ),
                    (
                        "Surface disponible",
                        f"{report.site.available_area_m2:.2f} m2",
                    ),
                    ("Equipements", str(len(report.equipment))),
                ]
            ),
            Spacer(1, 0.55 * cm),
            Paragraph("Objet du rapport", styles["section"]),
            Paragraph(
                "Ce document presente les hypotheses, les contraintes terrain, l'audit des charges "
                "et l'etat final du dimensionnement automatique du systeme photovoltaique de secours.",
                styles["body"],
            ),
            Spacer(1, 0.35 * cm),
            Paragraph("Mention importante", styles["section"]),
            Paragraph(report.academic_notice, styles["body_muted"]),
            Spacer(1, 0.35 * cm),
            Paragraph("Conclusion executive", styles["section"]),
            Paragraph(
                result.dimensioning_state
                if result
                else "Le calcul n'a pas encore ete lance pour cette simulation.",
                styles["callout"],
            ),
            Spacer(1, 0.55 * cm),
            _summary_band(
                [
                    ("Charges critiques", str(critical_count)),
                    ("Charges non critiques", str(non_critical_count)),
                    (
                        "PV requis",
                        f"{result.required_pv_power_wc:.2f} Wc" if result else "-",
                    ),
                    (
                        "Batteries",
                        str(result.number_of_batteries) if result else "-",
                    ),
                ]
            ),
            PageBreak(),
        ]
    )

    story.extend(
        _section_table(
            "1. Identification du site",
            [
                ["Nom du site", report.site.name],
                ["Ville", report.site.city],
                ["Pays", report.site.country],
                ["Type de site", report.site.site_type],
                ["Latitude", f"{report.site.latitude:.6f}"],
                ["Longitude", f"{report.site.longitude:.6f}"],
                ["Surface disponible", f"{report.site.available_area_m2:.2f} m2"],
                ["Ratio utile", f"{(report.site.usable_area_ratio or 1) * 100:.0f}%"],
                ["Autonomie ciblee", f"{report.site.target_backup_hours:.2f} h"],
                ["Scenario groupe", _generator_status(report.site.generator_failure_scenario)],
            ],
            styles,
        )
    )

    story.extend(
        _section_table(
            "2. Hypotheses de calcul",
            [[str(index + 1), item] for index, item in enumerate(report.assumptions)],
            styles,
            [1.0 * cm, 15.8 * cm],
        )
    )

    story.extend(
        _section_table(
            "3. Parametres de simulation",
            [
                ["Type de panneau", report.simulation.panel_type],
                ["Puissance panneau", f"{report.simulation.panel_power_watts:.0f} Wc"],
                ["Surface panneau", f"{report.simulation.panel_area_m2:.2f} m2"],
                ["Facteur d'espacement", f"{report.simulation.panel_spacing_factor:.2f}"],
                ["Type de batterie", report.simulation.battery_type],
                ["Capacite batterie", f"{report.simulation.battery_capacity_ah:.0f} Ah"],
                ["Tension batterie", f"{report.simulation.battery_voltage:.0f} V"],
                ["Profondeur de decharge", f"{report.simulation.battery_dod * 100:.0f}%"],
                ["Rendement regulateur", f"{report.simulation.controller_efficiency * 100:.0f}%"],
                ["Rendement onduleur", f"{report.simulation.inverter_efficiency * 100:.0f}%"],
                ["Pertes cables", f"{report.simulation.cable_loss_factor * 100:.0f}%"],
                ["Longueur cable DC", f"{report.simulation.dc_cable_length_m:.0f} m"],
                ["Longueur cable AC", f"{report.simulation.ac_cable_length_m:.0f} m"],
                ["Chute tension DC max", f"{report.simulation.dc_voltage_drop_limit_percent:.0f}%"],
                ["Chute tension AC max", f"{report.simulation.ac_voltage_drop_limit_percent:.0f}%"],
                ["Pertes temperature", f"{report.simulation.temperature_loss_factor * 100:.0f}%"],
                ["Pertes poussiere", f"{report.simulation.dust_loss_factor * 100:.0f}%"],
                ["Facteur de securite", f"{report.simulation.safety_factor:.2f}"],
            ],
            styles,
        )
    )

    story.append(Paragraph("4. Audit energetique des equipements", styles["section"]))
    equipment_rows = [["Equipement", "Categorie", "Qte", "Puissance", "Heures/j", "Criticite"]]
    for item in report.equipment:
        equipment_rows.append(
            [
                item.name,
                item.category,
                str(item.quantity),
                f"{item.power_watts:.0f} W",
                f"{item.hours_per_day:.1f}",
                "Critique" if item.is_critical else "Non critique",
            ]
        )
    equipment_table = Table(
        equipment_rows,
        colWidths=[4.4 * cm, 3.1 * cm, 1.1 * cm, 2.4 * cm, 2.2 * cm, 2.9 * cm],
        repeatRows=1,
    )
    equipment_table.setStyle(_table_style(header=True, compact=True, striped=True))
    story.append(equipment_table)
    story.append(Spacer(1, 0.35 * cm))

    if result:
        story.append(
            KeepTogether(
                [
                    Paragraph("5. Verdict et etat final genere", styles["section"]),
                    Paragraph(result.dimensioning_state, styles["callout"]),
                    Spacer(1, 0.2 * cm),
                ]
            )
        )
        story.extend(
            _section_table(
                "6. Resultats de dimensionnement",
                [
                    ["Verdict", result.feasibility_status.replace("_", " ")],
                    ["Puissance totale", f"{result.total_power_watts:.2f} W"],
                    ["Energie journaliere", f"{result.daily_energy_wh:.2f} Wh/j"],
                    ["Puissance PV requise", f"{result.required_pv_power_wc:.2f} Wc"],
                    ["Nombre de panneaux", str(result.number_of_panels)],
                    ["Surface panneaux nus", f"{result.panel_surface_required_m2:.2f} m2"],
                    ["Surface avec espacement", f"{result.panel_surface_with_spacing_m2:.2f} m2"],
                    ["Surface disponible", f"{result.available_surface_m2:.2f} m2"],
                    ["Etat surface", result.surface_status],
                    ["Capacite batterie requise", f"{result.required_battery_capacity_ah:.2f} Ah"],
                    ["Nombre de batteries", str(result.number_of_batteries)],
                    ["Autonomie obtenue", f"{result.backup_time_hours:.2f} h"],
                    ["Courant regulateur", f"{result.controller_current_a:.2f} A"],
                    ["Onduleur recommande", f"{result.inverter_power_watts:.2f} W"],
                    ["Delestage", result.load_shedding_message],
                    ["Cout total estimatif", f"{result.total_cost:.2f} USD"],
                ],
                styles,
            )
        )
        story.extend(
            _section_table(
                "7. Protection, cables et mise a la terre",
                [
                    ["Section cable DC recommandee", f"{result.dc_cable_section_mm2:.2f} mm2"],
                    ["Section cable AC recommandee", f"{result.ac_cable_section_mm2:.2f} mm2"],
                    ["Section conducteur de terre", f"{result.earth_cable_section_mm2:.2f} mm2"],
                    ["Disjoncteur / fusible DC", f"{result.dc_breaker_rating_a:.2f} A"],
                    ["Disjoncteur AC", f"{result.ac_breaker_rating_a:.2f} A"],
                    ["Parafoudre DC", "Oui" if result.dc_spd_required else "Non"],
                    ["Parafoudre AC", "Oui" if result.ac_spd_required else "Non"],
                    ["Protection foudre pylone/BTS", "Oui" if result.lightning_protection_required else "Non"],
                    ["Mise a la terre", "Oui" if result.earthing_required else "Non"],
                    ["Resistance de terre cible", f"{result.recommended_earthing_resistance_ohm:.2f} ohm"],
                    ["Resistance de terre mesuree", f"{result.measured_earthing_resistance_ohm:.2f} ohm"],
                    ["Statut de terre", result.grounding_status.replace("_", " ")],
                ],
                styles,
            )
        )
        if equipment_plan:
            supported_rows = equipment_plan.get("supported_equipment", [])
            unsupported_rows = equipment_plan.get("unsupported_equipment", [])
            story.extend(
                _section_table(
                    "8. Plan d'usage recommande des equipements",
                    [
                        ["Equipements alimentables", str(equipment_plan.get("supported_equipment_count", 0))],
                        ["Unites alimentables", str(equipment_plan.get("supported_units_total", 0))],
                        ["Equipements a limiter", str(equipment_plan.get("unsupported_equipment_count", 0))],
                        ["Marge puissance restante", f"{equipment_plan.get('remaining_power_watts', 0):.2f} W"],
                    ],
                    styles,
                )
            )
            if supported_rows:
                story.extend(
                    _section_table(
                        "8.1 Equipements supportes",
                        [
                            [
                                item["name"],
                                f"{item['supported_quantity']}/{item['requested_quantity']} unite(s) - {item['unit_power_watts']:.0f} W",
                            ]
                            for item in supported_rows
                        ],
                        styles,
                    )
                )
            if unsupported_rows:
                story.extend(
                    _section_table(
                        "8.2 Equipements a delester ou reduire",
                        [
                            [
                                item["name"],
                                f"{item['supported_quantity']}/{item['requested_quantity']} unite(s) - {item['reason']}",
                            ]
                            for item in unsupported_rows
                        ],
                        styles,
                    )
                )
        story.extend(
            _section_table(
                "9. Recommandations",
                [["Synthese", result.recommendations]],
                styles,
            )
        )
    else:
        story.append(Paragraph("Aucun resultat de calcul disponible pour cette simulation.", styles["body"]))

    story.append(Paragraph("10. Validation", styles["section"]))
    validation = Table(
        [
            ["Elabore par", "Valide par"],
            [
                "Nom: ____________________\nDate: ____________________\nSignature: _______________",
                "Nom: ____________________\nDate: ____________________\nSignature: _______________",
            ],
        ],
        colWidths=[8.0 * cm, 8.0 * cm],
    )
    validation.setStyle(_table_style(header=True))
    story.append(validation)

    doc.build(
        story,
        onFirstPage=lambda canvas, document: _draw_page_chrome(canvas, document, report, True),
        onLaterPages=lambda canvas, document: _draw_page_chrome(canvas, document, report, False),
    )
    return buffer.getvalue()


def _build_styles() -> dict[str, ParagraphStyle]:
    styles = getSampleStyleSheet()
    return {
        "eyebrow": ParagraphStyle(
            "Eyebrow",
            parent=styles["BodyText"],
            fontName="Helvetica-Bold",
            fontSize=8,
            leading=10,
            textColor=ACCENT,
            alignment=1,
        ),
        "cover_title": ParagraphStyle(
            "CoverTitle",
            parent=styles["Heading1"],
            fontName="Helvetica-Bold",
            fontSize=22,
            leading=26,
            textColor=PRIMARY,
            alignment=1,
        ),
        "cover_subtitle": ParagraphStyle(
            "CoverSubtitle",
            parent=styles["BodyText"],
            fontName="Helvetica",
            fontSize=11,
            leading=14,
            textColor=MUTED,
            alignment=1,
        ),
        "section": ParagraphStyle(
            "Section",
            parent=styles["Heading2"],
            fontName="Helvetica-Bold",
            fontSize=11,
            leading=14,
            textColor=PRIMARY,
            spaceBefore=6,
            spaceAfter=6,
        ),
        "body": ParagraphStyle(
            "Body",
            parent=styles["BodyText"],
            fontName="Helvetica",
            fontSize=9,
            leading=12,
            textColor=TEXT,
        ),
        "body_muted": ParagraphStyle(
            "BodyMuted",
            parent=styles["BodyText"],
            fontName="Helvetica",
            fontSize=8,
            leading=11,
            textColor=MUTED,
        ),
        "callout": ParagraphStyle(
            "Callout",
            parent=styles["BodyText"],
            fontName="Helvetica-Bold",
            fontSize=10,
            leading=14,
            textColor=PRIMARY,
            borderColor=BORDER,
            borderWidth=0.6,
            borderPadding=8,
            backColor=SOFT_BG,
        ),
    }


def _summary_band(items: list[tuple[str, str]]) -> Table:
    header_row = [label for label, _ in items]
    value_row = [value for _, value in items]
    table = Table([header_row, value_row], colWidths=[4.1 * cm, 4.1 * cm, 4.1 * cm, 4.1 * cm])
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), HEADER_BG),
                ("BACKGROUND", (0, 1), (-1, 1), colors.white),
                ("TEXTCOLOR", (0, 0), (-1, 0), PRIMARY),
                ("TEXTCOLOR", (0, 1), (-1, 1), TEXT),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("FONTNAME", (0, 1), (-1, 1), "Helvetica"),
                ("FONTSIZE", (0, 0), (-1, 0), 8),
                ("FONTSIZE", (0, 1), (-1, 1), 10),
                ("ALIGN", (0, 0), (-1, -1), "CENTER"),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("BOX", (0, 0), (-1, -1), 0.7, BORDER),
                ("INNERGRID", (0, 0), (-1, -1), 0.4, GRID),
                ("TOPPADDING", (0, 0), (-1, -1), 6),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
            ]
        )
    )
    return table


def _section_table(
    title: str,
    rows: list[list[str]],
    styles: dict[str, ParagraphStyle],
    widths: list[float] | None = None,
) -> list:
    body_style = styles["body"]
    data = [[Paragraph(str(left), body_style), Paragraph(str(right), body_style)] for left, right in rows]
    table = Table(data, colWidths=widths or [5.1 * cm, 11.5 * cm])
    table.setStyle(_table_style(striped=True))
    return [Paragraph(title, styles["section"]), table, Spacer(1, 0.28 * cm)]


def _table_style(*, header: bool = False, compact: bool = False, striped: bool = False) -> TableStyle:
    padding = 4 if compact else 6
    commands: list[tuple] = [
        ("BOX", (0, 0), (-1, -1), 0.6, BORDER),
        ("INNERGRID", (0, 0), (-1, -1), 0.3, GRID),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("FONTNAME", (0, 0), (-1, -1), "Helvetica"),
        ("FONTSIZE", (0, 0), (-1, -1), 8.2 if compact else 8.8),
        ("TEXTCOLOR", (0, 0), (-1, -1), TEXT),
        ("LEFTPADDING", (0, 0), (-1, -1), padding),
        ("RIGHTPADDING", (0, 0), (-1, -1), padding),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
        ("BACKGROUND", (0, 0), (-1, -1), colors.white),
    ]
    if header:
        commands.extend(
            [
                ("BACKGROUND", (0, 0), (-1, 0), HEADER_BG),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("TEXTCOLOR", (0, 0), (-1, 0), PRIMARY),
            ]
        )
    if striped:
        start_row = 1 if header else 0
        commands.append(("ROWBACKGROUNDS", (0, start_row), (-1, -1), [SOFT_BG, colors.white]))
    return TableStyle(commands)


def _draw_page_chrome(canvas, document, report: ReportRead, first_page: bool) -> None:
    canvas.saveState()
    width, height = A4

    if not first_page:
        canvas.setStrokeColor(BORDER)
        canvas.setLineWidth(0.6)
        canvas.line(document.leftMargin, height - 1.15 * cm, width - document.rightMargin, height - 1.15 * cm)
        canvas.setFont("Helvetica-Bold", 8)
        canvas.setFillColor(PRIMARY)
        canvas.drawString(document.leftMargin, height - 0.9 * cm, "HAYAT-Solar Sizer")
        canvas.setFont("Helvetica", 8)
        canvas.drawRightString(
            width - document.rightMargin,
            height - 0.9 * cm,
            f"Simulation #{report.simulation.id} - {report.site.name}",
        )

    canvas.setStrokeColor(BORDER)
    canvas.setLineWidth(0.6)
    canvas.line(document.leftMargin, 1.0 * cm, width - document.rightMargin, 1.0 * cm)
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(MUTED)
    canvas.drawString(document.leftMargin, 0.7 * cm, "HAYAT-Solar Sizer - Rapport technique")
    canvas.drawRightString(width - document.rightMargin, 0.7 * cm, f"Page {canvas.getPageNumber()}")
    canvas.restoreState()


def _generator_status(failure_scenario: bool) -> str:
    if failure_scenario:
        return "Defaillance du groupe prise en compte"
    return "Groupe disponible comme secours complementaire"
