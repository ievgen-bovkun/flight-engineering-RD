"""Build a UTF-8 test fragment for the Homework 2 report."""

from pathlib import Path

from PIL import Image as PillowImage
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Image, PageBreak, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle


REPORT_DIR = Path(__file__).resolve().parent
HOMEWORK_DIR = REPORT_DIR.parent
OUTPUT = REPORT_DIR / "output" / "pdf" / "HW2_test_fragment.pdf"


def register_fonts() -> None:
    fonts = {
        "Arial": r"C:\Windows\Fonts\arial.ttf",
        "Arial-Bold": r"C:\Windows\Fonts\arialbd.ttf",
        "Arial-Italic": r"C:\Windows\Fonts\ariali.ttf",
        "TimesNewRoman": r"C:\Windows\Fonts\times.ttf",
    }
    for name, path in fonts.items():
        pdfmetrics.registerFont(TTFont(name, path))


def make_styles() -> dict[str, ParagraphStyle]:
    base = getSampleStyleSheet()
    return {
        "title": ParagraphStyle("title", parent=base["Title"], fontName="Arial-Bold", fontSize=17, leading=21, alignment=TA_CENTER, spaceAfter=12),
        "body": ParagraphStyle("body", parent=base["BodyText"], fontName="Arial", fontSize=10.5, leading=14, spaceAfter=7),
        "head": ParagraphStyle("head", parent=base["Heading2"], fontName="Arial-Bold", fontSize=13, leading=16, spaceBefore=8, spaceAfter=7),
        "formula": ParagraphStyle("formula", parent=base["BodyText"], fontName="TimesNewRoman", fontSize=13, leading=18, leftIndent=12, spaceAfter=8),
        "caption": ParagraphStyle("caption", parent=base["BodyText"], fontName="Arial-Italic", fontSize=9, leading=11, alignment=TA_CENTER, spaceBefore=4, spaceAfter=8),
    }


def report_image(path: Path, width: float) -> Image:
    # Read pixel dimensions directly. This avoids DPI metadata in MATLAB PNGs
    # causing ReportLab to crop an image wider than the document frame.
    with PillowImage.open(path) as source:
        pixel_width, pixel_height = source.size
    return Image(str(path), width=width, height=width * pixel_height / pixel_width)


def footer(canvas, doc) -> None:
    canvas.saveState()
    canvas.setFont("Arial", 8)
    canvas.setFillColor(colors.grey)
    canvas.drawCentredString(A4[0] / 2, 1.1 * cm, f"Тестовий фрагмент звіту ДЗ №2 | сторінка {doc.page}")
    canvas.restoreState()


def build() -> None:
    register_fonts()
    styles = make_styles()
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)

    def paragraph(text: str, style: str = "body") -> Paragraph:
        return Paragraph(text, styles[style])

    story = [
        paragraph("Домашня робота №2", "title"),
        paragraph("Тестовий фрагмент для перевірки формул, українського тексту та графіків."),
        Spacer(1, 8),
        paragraph("1. Обернений маятник на візку", "head"),
        paragraph("Вектор стану: X = [x, ẋ, φ, φ̇]<super>T</super>. Лінеаризована модель: Ẋ = AX + BF, y = CX + DF."),
        paragraph("(M + m)ẍ + bẋ − mlφ̈ cos φ + mlφ̇<super>2</super> sin φ = F", "formula"),
        paragraph("(I + ml<super>2</super>)φ̈ − mlẍ cos φ − mgl sin φ = 0", "formula"),
        paragraph("X(t) = exp(At)X(0) + ∫<sub>0</sub><super>t</super> exp(A(t − τ))BF(τ)dτ.", "formula"),
        report_image(HOMEWORK_DIR / "inverted_pendulum" / "assets" / "task1_method_comparison.png", 16.3 * cm),
        paragraph("Рисунок 1 - Порівняння аналітичного розв’язку, RK4 і Simulink.", "caption"),
        PageBreak(),
        paragraph("2. Повороти у NED системі координат", "head"),
        paragraph("Перехід NED → body виконується послідовністю Z-Y-X: рискання ψ, тангаж θ, крен φ."),
        paragraph("R = R<sub>z</sub>(ψ) R<sub>y</sub>(θ) R<sub>x</sub>(φ).", "formula"),
        report_image(HOMEWORK_DIR / "ned_rotations" / "assets" / "ned_yaw_pitch_roll_sequence.png", 15.0 * cm),
        paragraph("Рисунок 2 - Загальна послідовність NED → body.", "caption"),
        PageBreak(),
        paragraph("3. Символьне виведення рівнянь у MATLAB", "head"),
        paragraph("Символьне виведення підтверджує матриці CTMS. Тут p = I(M+m) + Mml<super>2</super>."),
    ]

    matrix = Table([
        [paragraph("<b>A =</b>"), paragraph("[0, 1, 0, 0;<br/>0, −b(ml<super>2</super>+I)/p, gl<super>2</super>m<super>2</super>/p, 0;<br/>0, 0, 0, 1;<br/>0, −blm/p, glm(M+m)/p, 0]")],
        [paragraph("<b>B =</b>"), paragraph("[0; (ml<super>2</super>+I)/p; 0; lm/p]")],
    ], colWidths=[1.1 * cm, 15.2 * cm])
    matrix.setStyle(TableStyle([
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("BOX", (0, 0), (-1, -1), 0.4, colors.lightgrey),
        ("INNERGRID", (0, 0), (-1, -1), 0.25, colors.lightgrey),
        ("LEFTPADDING", (0, 0), (-1, -1), 7),
        ("RIGHTPADDING", (0, 0), (-1, -1), 7),
        ("TOPPADDING", (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
    ]))
    story += [
        matrix,
        Spacer(1, 10),
        paragraph("Максимальні розбіжності з CTMS: для A та B по 8.882e−16."),
        report_image(REPORT_DIR / "assets" / "task3_symbolic_output.png", 15.8 * cm),
        paragraph("Рисунок 3 - Виведення рівнянь та числова перевірка MATLAB.", "caption"),
    ]

    document = SimpleDocTemplate(str(OUTPUT), pagesize=A4, rightMargin=1.6 * cm, leftMargin=1.6 * cm, topMargin=1.5 * cm, bottomMargin=1.8 * cm)
    document.build(story, onFirstPage=footer, onLaterPages=footer)
    print(OUTPUT)


if __name__ == "__main__":
    build()
