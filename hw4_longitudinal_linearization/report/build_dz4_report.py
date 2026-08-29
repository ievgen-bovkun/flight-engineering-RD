from __future__ import annotations

import csv
from datetime import date
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    Image,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)


PROJECT_DIR = Path(__file__).resolve().parents[1]
RESULTS_DIR = PROJECT_DIR / "results"
OUTPUT_PATH = Path(__file__).resolve().parent / "DZ4_Longitudinal_Linearization_Report.pdf"
GITHUB_URL = (
    "https://github.com/ievgen-bovkun/flight-engineering-RD/"
    "tree/codex/homework4-longitudinal-linearization"
)


def read_summary() -> dict[str, float]:
    with (RESULTS_DIR / "dz4_variant_1_numeric_summary.csv").open(
        encoding="utf-8", newline=""
    ) as stream:
        return {row["names"]: float(row["values"]) for row in csv.DictReader(stream)}


def register_fonts() -> None:
    fonts_dir = Path(r"C:\Windows\Fonts")
    pdfmetrics.registerFont(TTFont("Arial", str(fonts_dir / "arial.ttf")))
    pdfmetrics.registerFont(TTFont("Arial-Bold", str(fonts_dir / "arialbd.ttf")))


def create_styles() -> dict[str, ParagraphStyle]:
    sample = getSampleStyleSheet()
    blue = colors.HexColor("#2E75B6")
    return {
        "body": ParagraphStyle(
            "body",
            parent=sample["BodyText"],
            fontName="Arial",
            fontSize=10.2,
            leading=14,
            spaceAfter=8,
        ),
        "h1": ParagraphStyle(
            "h1",
            parent=sample["Heading1"],
            fontName="Arial-Bold",
            fontSize=20,
            leading=24,
            textColor=blue,
            spaceBefore=2,
            spaceAfter=10,
        ),
        "h2": ParagraphStyle(
            "h2",
            parent=sample["Heading2"],
            fontName="Arial-Bold",
            fontSize=13,
            leading=16,
            textColor=blue,
            spaceBefore=4,
            spaceAfter=7,
        ),
        "cover_title": ParagraphStyle(
            "cover_title",
            parent=sample["Title"],
            fontName="Arial-Bold",
            fontSize=25,
            leading=31,
            textColor=colors.HexColor("#1F426F"),
            alignment=TA_CENTER,
        ),
        "cover_subtitle": ParagraphStyle(
            "cover_subtitle",
            parent=sample["Normal"],
            fontName="Arial",
            fontSize=15,
            leading=20,
            alignment=TA_CENTER,
        ),
        "small": ParagraphStyle(
            "small",
            parent=sample["BodyText"],
            fontName="Arial",
            fontSize=8.8,
            leading=11,
        ),
        "mono": ParagraphStyle(
            "mono",
            parent=sample["Code"],
            fontName="Courier",
            fontSize=7.8,
            leading=10,
        ),
    }


def paragraph(text: str, styles: dict[str, ParagraphStyle], name: str = "body") -> Paragraph:
    return Paragraph(text, styles[name])


def image(path: Path, max_width: float, max_height: float) -> Image:
    picture = Image(str(path))
    ratio = min(max_width / picture.imageWidth, max_height / picture.imageHeight)
    picture.drawWidth = picture.imageWidth * ratio
    picture.drawHeight = picture.imageHeight * ratio
    picture.hAlign = "CENTER"
    return picture


def make_table(rows: list[list[str]], widths: list[float], styles: dict[str, ParagraphStyle]) -> Table:
    formatted = [
        [paragraph(cell, styles, "small") for cell in row]
        for row in rows
    ]
    table = Table(formatted, colWidths=widths, repeatRows=1)
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#DCE6F1")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.HexColor("#1F4E79")),
                ("FONTNAME", (0, 0), (-1, 0), "Arial-Bold"),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#666666")),
                ("LEFTPADDING", (0, 0), (-1, -1), 5),
                ("RIGHTPADDING", (0, 0), (-1, -1), 5),
                ("TOPPADDING", (0, 0), (-1, -1), 4),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
            ]
        )
    )
    return table


def footer(canvas, document) -> None:
    canvas.saveState()
    canvas.setFont("Arial", 8)
    canvas.setFillColor(colors.HexColor("#777777"))
    canvas.drawCentredString(
        letter[0] / 2,
        0.38 * inch,
        f"Домашня робота №4 | Інженерія польоту | сторінка {document.page}",
    )
    canvas.restoreState()


def main() -> None:
    register_fonts()
    styles = create_styles()
    values = read_summary()
    doc = SimpleDocTemplate(
        str(OUTPUT_PATH),
        pagesize=letter,
        rightMargin=0.68 * inch,
        leftMargin=0.68 * inch,
        topMargin=0.62 * inch,
        bottomMargin=0.66 * inch,
        title="Домашня робота №4 - лінеаризація поздовжнього руху ЛА",
        author="Dmytro Povolotskyi, Ievgen Bovkun",
    )
    story = []

    story.extend(
        [
            Spacer(1, 2.15 * inch),
            paragraph("ДОМАШНЯ РОБОТА №4", styles, "cover_title"),
            Spacer(1, 0.28 * inch),
            paragraph("Інженерія польоту", styles, "cover_subtitle"),
            Spacer(1, 0.24 * inch),
            paragraph(
                "Лінеаризація математичної моделі поздовжнього руху ЛА "
                "та опис у просторі станів",
                styles,
                "cover_subtitle",
            ),
            Spacer(1, 0.55 * inch),
            paragraph(
                "Виконали: Dmytro Povolotskyi, Ievgen Bovkun",
                styles,
                "cover_subtitle",
            ),
            Spacer(1, 0.15 * inch),
            paragraph("Дата: 29.08.2026", styles, "cover_subtitle"),
            Spacer(1, 0.58 * inch),
            paragraph("Репозиторій з MATLAB-файлами та результатами:", styles, "cover_subtitle"),
            Spacer(1, 0.12 * inch),
            Paragraph(f'<link href="{GITHUB_URL}">GitHub: codex/homework4-longitudinal-linearization</link>', styles["cover_subtitle"]),
            PageBreak(),
        ]
    )

    story.append(paragraph("1. Мета та постановка задачі", styles, "h1"))
    story.append(
        paragraph(
            "Мета роботи - отримати лінеаризовану модель поздовжнього руху "
            "літального апарата як об’єкта керування у просторі станів, "
            "реалізувати її в MATLAB/Simulink і дослідити реакцію на "
            "ступінчасте відхилення керма висоти.",
            styles,
        )
    )
    story.append(paragraph("Варіант 1: нормальна аеродинамічна схема.", styles, "h2"))
    input_rows = [
        ["Параметр", "Значення", "Пояснення"],
        ["m", "44 кг", "маса ЛА"],
        ["I_z", "13.46 кг м^2", "момент інерції відносно поперечної осі"],
        ["V*", "476 м/с", "швидкість незбуреного руху"],
        ["theta*", "-9 град", "кут нахилу траєкторії"],
        ["alpha*", "0.6 град", "кут атаки"],
        ["P*", "8000 Н", "тяга"],
        ["d1", "-4 град у t = 1 с", "ступінчасте відхилення руля"],
    ]
    story.append(make_table(input_rows, [0.8 * inch, 1.4 * inch, 4.4 * inch], styles))
    story.append(Spacer(1, 0.12 * inch))
    story.append(paragraph("2. Вибір моделі та лінеаризація", styles, "h1"))
    story.append(
        paragraph(
            "Використано систему (7) методичних вказівок: швидкість V* та "
            "тяга P* сталі. Вектор стану X = [dtheta, dalpha, dvartheta, "
            "domega_z, dH]^T, керування u = dd1.",
            styles,
        )
    )
    story.append(
        paragraph(
            "Лінеаризація виконується в околі незбуреного руху за рядом "
            "Тейлора: f(x* + dx) приблизно дорівнює f(x*) + (df/dx)|* dx. Члени вище першого "
            "порядку малості відкидаються.",
            styles,
        )
    )
    story.append(
        paragraph(
            "Для варіанта 1 аеродинамічні похідні переведено з 1/град у 1/рад "
            "множенням на 180/pi; кути та керування подано в радіанах.",
            styles,
        )
    )
    story.append(paragraph("Коефіцієнти лінеаризованої моделі:", styles, "h2"))
    story.append(
        paragraph(
            "Q1theta = g sin(theta*) / V*; "
            "Q1alpha = cy_alpha rho S V* / (2m) + P* cos(alpha*) / (m V*); "
            "Q1d1 = cy_d1 rho S V* / (2m).",
            styles,
            "small",
        )
    )
    story.append(
        paragraph(
            "Q2theta = -Q1theta; Q2alpha = -Q1alpha; Q2omega_z = 1; "
            "Q2d1 = -Q1d1; Q3omega_z = 1.",
            styles,
            "small",
        )
    )
    story.append(
        paragraph(
            "Q4alpha = mz_alpha rho V*^2 S L / (2Iz); "
            "Q4omega_z = mz_omega_z rho V* S L^2 / (2Iz); "
            "Q4d1 = mz_d1 rho V*^2 S L / (2Iz); "
            "Q5theta = V* cos(theta*).",
            styles,
            "small",
        )
    )
    story.append(PageBreak())

    story.append(paragraph("3. Коефіцієнти та матриці простору станів", styles, "h1"))
    coefficient_rows = [
        ["Коефіцієнт", "Значення", "Одиниці"],
        ["Q1theta", f"{values['Q1_theta']:.9f}", "1/с"],
        ["Q1alpha", f"{values['Q1_alpha']:.9f}", "1/с"],
        ["Q1d1", f"{values['Q1_delta']:.9f}", "1/с"],
        ["Q4alpha", f"{values['Q4_alpha']:.6f}", "1/с^2"],
        ["Q4omega_z", f"{values['Q4_omega']:.9f}", "1/с"],
        ["Q4d1", f"{values['Q4_delta']:.6f}", "1/с^2"],
    ]
    story.append(make_table(coefficient_rows, [1.15 * inch, 2.15 * inch, 1.35 * inch], styles))
    story.append(Spacer(1, 0.15 * inch))
    story.append(paragraph("Матриця стану A та матриця керування B:", styles, "h2"))
    matrix_a = (
        "[ -0.003224   2.485296   0   0          0 ]<br/>"
        "[  0.003224  -2.485296   0   1          0 ]<br/>"
        "A = [ 0          0          0   1          0 ]<br/>"
        "[  0       -817.688207   0  -6.680626   0 ]<br/>"
        "[470.139655   0          0   0          0 ]"
    )
    matrix_b = (
        "B = [ 0.632545; -0.632545; 0; -957.290212; 0 ]^T"
    )
    story.append(paragraph(matrix_a, styles, "mono"))
    story.append(Spacer(1, 0.1 * inch))
    story.append(paragraph(matrix_b, styles, "mono"))
    story.append(Spacer(1, 0.18 * inch))
    story.append(
        paragraph(
            "Незалежне повторне обчислення Qij, A і B з буквальних даних "
            "варіанта 1 дало максимальну різницю 0.",
            styles,
        )
    )
    story.append(paragraph("4. Реалізація у Simulink", styles, "h1"))
    story.append(
        paragraph(
            "Модель складається з Step, State-Space, Demux, блоків Gain "
            "для переведення кутових виходів у градуси, Scope та To Workspace. "
            "Вхід Step подається безпосередньо в радіанах; тому окремий Gain "
            "pi/180 на вході не потрібний.",
            styles,
        )
    )
    story.append(image(RESULTS_DIR / "dz4_variant_1_simulink_scheme.png", 6.45 * inch, 3.55 * inch))
    story.append(PageBreak())

    story.append(paragraph("5. Перехідні процеси та числова перевірка", styles, "h1"))
    story.append(
        paragraph(
            "MATLAB lsim та Simulink використовують однакові матриці, керування "
            "та часовий інтервал. Максимальна абсолютна похибка становить "
            f"{values['max_abs_error']:.3e}, а загальна RMS-похибка - "
            f"{values['rms_error_global']:.3e}.",
            styles,
        )
    )
    error_rows = [
        ["Метрика", "Значення"],
        ["Max |MATLAB - Simulink|", f"{values['max_abs_error']:.3e}"],
        ["RMS, усі стани", f"{values['rms_error_global']:.3e}"],
        ["RMS dtheta", f"{values['rms_theta']:.3e}"],
        ["RMS dalpha", f"{values['rms_alpha']:.3e}"],
        ["RMS domega_z", f"{values['rms_omega_z']:.3e}"],
        ["RMS dH", f"{values['rms_H']:.3e}"],
    ]
    story.append(make_table(error_rows, [2.5 * inch, 2.0 * inch], styles))
    story.append(Spacer(1, 0.12 * inch))
    story.append(image(RESULTS_DIR / "dz4_variant_1_state_responses.png", 6.45 * inch, 4.05 * inch))
    story.append(PageBreak())

    story.append(paragraph("6. Аналіз динаміки та висновки", styles, "h1"))
    story.append(
        paragraph(
            "Короткоперіодична мода має wn = "
            f"{values['short_period_wn_rad_s']:.3f} рад/с та zeta = "
            f"{values['short_period_zeta']:.3f}. Квазіусталені значення "
            f"dalpha = {values['quasi_steady_alpha_deg']:.3f} град і "
            f"domega_z = {values['quasi_steady_omega_z_deg_s']:.3f} град/с.",
            styles,
        )
    )
    story.append(
        paragraph(
            "Повна матриця має два нульові власні числа, тому dtheta і dvartheta мають "
            "інтегруючу складову, а dH після перехідного процесу зростає "
            "приблизно квадратично. Повільний дійсний режим має сталу часу "
            f"{values['slow_real_time_constant_s']:.1f} с.",
            styles,
        )
    )
    story.append(
        paragraph(
            "Для нормальної схеми спочатку виникає від’ємна підйомна сила руля, "
            "тому висота короткочасно зменшується. Мінімум dH = "
            f"{values['altitude_dip_m']:.6f} м досягається у t = "
            f"{values['altitude_dip_time_s']:.3f} с, після чого висота зростає.",
            styles,
        )
    )
    story.append(image(RESULTS_DIR / "dz4_variant_1_altitude_dip.png", 6.45 * inch, 3.85 * inch))
    story.append(Spacer(1, 0.12 * inch))
    story.append(paragraph("Підсумок:", styles, "h2"))
    story.append(
        paragraph(
            "Лінеаризовану модель варіанта 1 побудовано, реалізовано у "
            "MATLAB/Simulink та перевірено незалежним порівнянням. Усі "
            "автоматичні тести математичних коефіцієнтів, структури моделі, "
            "симуляції та експорту артефактів проходять.",
            styles,
        )
    )

    doc.build(story, onFirstPage=footer, onLaterPages=footer)
    print(OUTPUT_PATH)


if __name__ == "__main__":
    main()
