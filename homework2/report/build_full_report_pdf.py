"""Build the complete Ukrainian Homework 2 report PDF."""

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
OUTPUT = REPORT_DIR / "output" / "pdf" / "HW2_Report.pdf"
REPOSITORY_URL = "https://github.com/ievgen-bovkun/flight-engineering-RD"


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
        "title": ParagraphStyle("title", parent=base["Title"], fontName="Arial-Bold", fontSize=18, leading=23, alignment=TA_CENTER, textColor=colors.HexColor("#17365D"), spaceAfter=10),
        "subtitle": ParagraphStyle("subtitle", parent=base["BodyText"], fontName="Arial", fontSize=12, leading=17, alignment=TA_CENTER, spaceAfter=7),
        "body": ParagraphStyle("body", parent=base["BodyText"], fontName="Arial", fontSize=10.3, leading=14, spaceAfter=7),
        "head": ParagraphStyle("head", parent=base["Heading2"], fontName="Arial-Bold", fontSize=14, leading=18, textColor=colors.HexColor("#17365D"), spaceBefore=7, spaceAfter=8),
        "subhead": ParagraphStyle("subhead", parent=base["Heading3"], fontName="Arial-Bold", fontSize=11.5, leading=15, textColor=colors.HexColor("#214B70"), spaceBefore=5, spaceAfter=6),
        "formula": ParagraphStyle("formula", parent=base["BodyText"], fontName="TimesNewRoman", fontSize=13, leading=18, leftIndent=12, spaceAfter=8),
        "caption": ParagraphStyle("caption", parent=base["BodyText"], fontName="Arial-Italic", fontSize=9, leading=11, alignment=TA_CENTER, spaceBefore=4, spaceAfter=6),
        "small": ParagraphStyle("small", parent=base["BodyText"], fontName="Arial", fontSize=8.7, leading=11),
    }


def image(path: Path, width: float) -> Image:
    with PillowImage.open(path) as source:
        pixel_width, pixel_height = source.size
    return Image(str(path), width=width, height=width * pixel_height / pixel_width)


def footer(canvas, doc) -> None:
    canvas.saveState()
    canvas.setFont("Arial", 8)
    canvas.setFillColor(colors.grey)
    canvas.drawCentredString(A4[0] / 2, 1.05 * cm, f"Домашня робота №2 | Інженерія польоту | сторінка {doc.page}")
    canvas.restoreState()


def build() -> None:
    register_fonts()
    styles = make_styles()
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)

    def p(text: str, style: str = "body") -> Paragraph:
        return Paragraph(text, styles[style])

    def figure_page(title: str, description: str, path: Path, caption: str, width: float, page_break: bool = True) -> list:
        content = []
        if page_break:
            content.append(PageBreak())
        content += [
            p(title, "head"),
            p(description),
            image(path, width),
            p(caption, "caption"),
        ]
        return content

    story = [
        Spacer(1, 3.3 * cm),
        p("ДОМАШНЯ РОБОТА №2", "title"),
        p("Інженерія польоту", "subtitle"),
        p("Обернений маятник. Повороти у NED. Символьне виведення рівнянь руху", "subtitle"),
        Spacer(1, 1.2 * cm),
        p("Виконали: Dmytro Povolotskyi, Ievgen Bovkun", "subtitle"),
        p("Дата: 27.07.2026", "subtitle"),
        Spacer(1, 1.1 * cm),
        p(f"Репозиторій з MATLAB-файлами та результатами:<br/><link href='{REPOSITORY_URL}' color='#17365D'>{REPOSITORY_URL}</link>", "subtitle"),
        PageBreak(),
        p("Вступ", "head"),
        p("У роботі досліджено нестійку систему «обернений маятник на візку», побудовано її лінійну, нелінійну й Simulink-реалізації. Також показано перехід із навігаційної системи NED у зв'язану body-систему координат і виконано символьну перевірку рівнянь у MATLAB."),
        p("1. Обернений маятник на візку", "head"),
        p("1.1. Вихідні дані", "subhead"),
        p("Параметри взято з навчального прикладу CTMS (University of Michigan). Вектор стану: X = [x, ẋ, φ, φ̇]<super>T</super>, де x - координата візка, φ - кут маятника від верхнього вертикального положення."),
    ]

    parameters = [
        [p("Параметр", "small"), p("Значення", "small")],
        [p("Маса візка M", "small"), p("0.5 kg", "small")],
        [p("Маса маятника m", "small"), p("0.2 kg", "small")],
        [p("Тертя b", "small"), p("0.1 N s/m", "small")],
        [p("Відстань l", "small"), p("0.3 m", "small")],
        [p("Момент інерції I", "small"), p("0.006 kg m²", "small")],
        [p("Прискорення g", "small"), p("9.8 m/s²", "small")],
    ]
    parameter_table = Table(parameters, colWidths=[8.0 * cm, 8.0 * cm])
    parameter_table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#17365D")),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("GRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#B7C9DB")),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("LEFTPADDING", (0, 0), (-1, -1), 6),
        ("RIGHTPADDING", (0, 0), (-1, -1), 6),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
    ]))
    story += [
        parameter_table,
        Spacer(1, 9),
        p("1.2. Рівняння моделі", "subhead"),
        p("Повна нелінійна модель:", "body"),
        p("(M + m)ẍ + bẋ − mlφ̈ cos φ + mlφ̇<super>2</super> sin φ = F", "formula"),
        p("(I + ml<super>2</super>)φ̈ − mlẍ cos φ − mgl sin φ = 0", "formula"),
        p("Біля верхньої точки рівноваги застосовано sin φ ≈ φ та cos φ ≈ 1. Отримано лінійну модель Ẋ = AX + BF, y = CX + DF."),
        p("Аналітичний розв’язок:", "body"),
        p("X(t) = exp(At)X(0) + ∫<sub>0</sub><super>t</super> exp(A(t − τ))BF(τ)dτ.", "formula"),
        p("Для перевірки реалізовано чотири незалежні підходи: аналітичний розв’язок через expm, власний RK4, Simulink та Control System Toolbox."),
    ]

    story += figure_page(
        "1.3. Порівняння аналітичного розв’язку, RK4 і Simulink",
        "Для ступінчастої сили F = 0.01 N, поданої в момент 0.5 s, усі три методи дають практично однакові траєкторії.",
        HOMEWORK_DIR / "inverted_pendulum" / "assets" / "task1_method_comparison.png",
        "Рисунок 1 - Порівняння аналітичного розв’язку, RK4 і Simulink.",
        16.1 * cm,
    )
    story += [
        p("Максимальні абсолютні розбіжності: аналітичний розв’язок - RK4: 1.313e−10; аналітичний розв’язок - Simulink: 2.747e−08; RK4 - Simulink: 2.760e−08."),
    ]
    story += figure_page(
        "1.4. Лінійна та нелінійна реакції",
        "Вільний рух із початковим відхиленням φ(0) = 3 deg порівнює лінеаризовану модель з повними нелінійними рівняннями, інтегрованими ode45.",
        HOMEWORK_DIR / "inverted_pendulum" / "assets" / "task1_linear_vs_nonlinear.png",
        "Рисунок 2 - Порівняння лінійної та нелінійної моделей.",
        16.1 * cm,
    )
    story += [
        p("На початку траєкторії моделі близькі. Після виходу за межу близько |φ| = 12 deg лінеаризація поступово втрачає точність, тому для великих кутів потрібна нелінійна модель."),
    ]
    story += figure_page(
        "1.5. Незалежна перевірка Control System Toolbox",
        "Імпульсну реакцію моделі ss(A,B,C,D) порівняно з аналітичним виразом C exp(At) B.",
        HOMEWORK_DIR / "inverted_pendulum" / "assets" / "task1_impulse_validation.png",
        "Рисунок 3 - Перевірка імпульсної реакції через Control System Toolbox.",
        16.1 * cm,
    )
    story += [
        p("Максимальна різниця між impulse(ss) і аналітичним розв’язком становить 2.132e−12. Зростання реакції фізично очікуване, бо система не містить регулятора і верхня точка рівноваги нестійка."),
    ]

    story += [
        PageBreak(),
        p("2. Повороти у NED системі координат", "head"),
        p("NED означає North-East-Down: x<sub>N</sub> спрямована на північ, y<sub>E</sub> - на схід, z<sub>D</sub> - вниз. Використано стандартну авіаційну послідовність Z-Y-X: рискання ψ, тангаж θ, крен φ."),
        p("R = R<sub>z</sub>(ψ) R<sub>y</sub>(θ) R<sub>x</sub>(φ).", "formula"),
        p("Для ілюстрації задано ψ = 45 deg, θ = 20 deg, φ = 30 deg. Ортогональність і визначник матриць повороту перевірено автоматичними MATLAB-тестами."),
    ]
    story += figure_page(
        "2.1. Загальний вигляд послідовності NED → body",
        "На одному рисунку відображено початкову NED-систему та орієнтації після yaw, pitch і roll.",
        HOMEWORK_DIR / "ned_rotations" / "assets" / "ned_yaw_pitch_roll_sequence.png",
        "Рисунок 4 - Усі проміжні NED та body-системи координат.",
        12.5 * cm,
        page_break=False,
    )
    story += figure_page(
        "2.2. Покрокове представлення поворотів",
        "Кожна панель показує один крок. Бліді стрілки - стан до повороту, кольорові - стан після нього.",
        HOMEWORK_DIR / "ned_rotations" / "assets" / "ned_yaw_pitch_roll_steps.png",
        "Рисунок 5 - Окремі етапи yaw, pitch і roll.",
        16.1 * cm,
    )

    story += [
        PageBreak(),
        p("3. Символьне виведення рівнянь руху", "head"),
        p("Скрипт run_task3_symbolic_pendulum у Symbolic Math Toolbox відтворює нелінійні рівняння маятника, лінеаризує їх у верхній точці рівноваги та порівнює отримані матриці з CTMS."),
        p("Позначимо p = I(M+m) + Mml<super>2</super>. Тоді:", "body"),
    ]
    matrices = Table([
        [p("<b>A =</b>"), p("[0, 1, 0, 0;<br/>0, −b(ml<super>2</super>+I)/p, gl<super>2</super>m<super>2</super>/p, 0;<br/>0, 0, 0, 1;<br/>0, −blm/p, glm(M+m)/p, 0]")],
        [p("<b>B =</b>"), p("[0; (ml<super>2</super>+I)/p; 0; lm/p]")],
    ], colWidths=[1.1 * cm, 15.2 * cm])
    matrices.setStyle(TableStyle([
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("BOX", (0, 0), (-1, -1), 0.4, colors.lightgrey),
        ("INNERGRID", (0, 0), (-1, -1), 0.25, colors.lightgrey),
        ("LEFTPADDING", (0, 0), (-1, -1), 7),
        ("RIGHTPADDING", (0, 0), (-1, -1), 7),
        ("TOPPADDING", (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
    ]))
    story += [
        matrices,
        Spacer(1, 10),
        p("Максимальна різниця між символьно отриманими та CTMS-матрицями A і B дорівнює 8.882e−16, тобто збіг досягається з машинною точністю."),
        image(REPORT_DIR / "assets" / "task3_symbolic_output.png", 15.3 * cm),
        p("Рисунок 6 - Символьне виведення та числова перевірка в MATLAB.", "caption"),
        PageBreak(),
        p("Висновки", "head"),
        p("1. Аналітичний розв’язок, RK4 і Simulink узгоджені у малому діапазоні відхилень."),
        p("2. Нелінійна модель показує обмеження лінеаризації для великих кутів маятника."),
        p("3. Control System Toolbox незалежно підтвердив імпульсну реакцію аналітичної моделі."),
        p("4. Повороти NED реалізовані за послідовністю Z-Y-X та перевірені на ортогональність."),
        p("5. Символьне виведення в MATLAB підтвердило матриці CTMS до машинної точності."),
        p("Джерела", "head"),
        p("1. <link href='https://ctms.engin.umich.edu/CTMS/index.php?example=InvertedPendulum&amp;section=SystemModeling' color='#17365D'>CTMS: Inverted Pendulum - System Modeling.</link>"),
        p("2. <link href='https://www.cureusjournals.com/articles/8517-modeling-and-balancing-control-of-inverted-pendulum' color='#17365D'>Cureus: Modeling and Balancing Control of Inverted Pendulum.</link>"),
        p("3. <link href='https://www.youtube.com/watch?v=fi54Hz5TiWI&amp;t=252s' color='#17365D'>Відеоматеріал з моделювання оберненого маятника.</link>"),
        p("4. Конспект заняття 5, наданий викладачем."),
        p(f"5. Репозиторій роботи: <link href='{REPOSITORY_URL}' color='#17365D'>{REPOSITORY_URL}</link>."),
    ]

    document = SimpleDocTemplate(str(OUTPUT), pagesize=A4, rightMargin=1.6 * cm, leftMargin=1.6 * cm, topMargin=1.5 * cm, bottomMargin=1.8 * cm)
    document.build(story, onFirstPage=footer, onLaterPages=footer)
    print(OUTPUT)


if __name__ == "__main__":
    build()
