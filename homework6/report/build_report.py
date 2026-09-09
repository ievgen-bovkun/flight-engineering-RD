"""Build the final PDF report for Homework 6 from generated artefacts."""

from __future__ import annotations

import json
from datetime import date
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Image, PageBreak, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle


PROJECT = Path(__file__).resolve().parents[1]
RESULTS = PROJECT / "results"
SIMULINK = PROJECT / "simulink"
ASSETS = Path(__file__).resolve().parent / "assets"
OUTPUT = Path(__file__).resolve().parent / "DZ6_Control_and_Pendulum_Report.pdf"
GITHUB_URL = "https://github.com/ievgen-bovkun/flight-engineering-RD/tree/main/homework6"


def register_fonts() -> None:
    fonts = Path(r"C:\Windows\Fonts")
    pdfmetrics.registerFont(TTFont("Arial", str(fonts / "arial.ttf")))
    pdfmetrics.registerFont(TTFont("Arial-Bold", str(fonts / "arialbd.ttf")))


def make_styles() -> dict[str, ParagraphStyle]:
    sample = getSampleStyleSheet()
    blue = colors.HexColor("#1F4E79")
    return {
        "body": ParagraphStyle("body", parent=sample["BodyText"], fontName="Arial", fontSize=10, leading=14, spaceAfter=7),
        "h1": ParagraphStyle("h1", parent=sample["Heading1"], fontName="Arial-Bold", fontSize=18, leading=22, textColor=blue, spaceBefore=3, spaceAfter=10),
        "h2": ParagraphStyle("h2", parent=sample["Heading2"], fontName="Arial-Bold", fontSize=12.5, leading=16, textColor=blue, spaceBefore=7, spaceAfter=6),
        "cover_title": ParagraphStyle("cover_title", parent=sample["Title"], fontName="Arial-Bold", fontSize=25, leading=31, textColor=blue, alignment=TA_CENTER),
        "cover_subtitle": ParagraphStyle("cover_subtitle", parent=sample["Normal"], fontName="Arial", fontSize=14, leading=19, alignment=TA_CENTER),
        "caption": ParagraphStyle("caption", parent=sample["BodyText"], fontName="Arial", fontSize=8.4, leading=10.5, alignment=TA_CENTER, textColor=colors.HexColor("#555555"), spaceBefore=3, spaceAfter=8),
        "small": ParagraphStyle("small", parent=sample["BodyText"], fontName="Arial", fontSize=8.5, leading=10.5),
        "formula": ParagraphStyle("formula", parent=sample["Code"], fontName="Courier", fontSize=8.2, leading=10.5, leftIndent=10, spaceAfter=6),
    }


def p(text: str, styles: dict[str, ParagraphStyle], kind: str = "body") -> Paragraph:
    return Paragraph(text, styles[kind])


def fig(path: Path, caption: str, styles: dict[str, ParagraphStyle], max_height_cm: float = 14.5) -> list[object]:
    image = Image(str(path))
    scale = min(17.0 * cm / image.imageWidth, max_height_cm * cm / image.imageHeight)
    image.drawWidth = image.imageWidth * scale
    image.drawHeight = image.imageHeight * scale
    image.hAlign = "CENTER"
    return [image, p(caption, styles, "caption")]


def table(rows: list[list[str]], widths: list[float], styles: dict[str, ParagraphStyle]) -> Table:
    formatted = [[p(cell, styles, "small") for cell in row] for row in rows]
    result = Table(formatted, colWidths=[width * cm for width in widths], repeatRows=1)
    result.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#D9EAF7")),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.HexColor("#1F4E79")),
        ("FONTNAME", (0, 0), (-1, 0), "Arial-Bold"),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("GRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#777777")),
        ("LEFTPADDING", (0, 0), (-1, -1), 5), ("RIGHTPADDING", (0, 0), (-1, -1), 5),
        ("TOPPADDING", (0, 0), (-1, -1), 4), ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
    ]))
    return result


def footer(canvas, document) -> None:
    canvas.saveState()
    canvas.setFont("Arial", 8)
    canvas.setFillColor(colors.HexColor("#777777"))
    canvas.drawCentredString(A4[0] / 2, 0.55 * cm, f"Домашня робота №6 | Flight Systems Engineering | сторінка {document.page}")
    canvas.restoreState()


def main() -> None:
    register_fonts()
    styles = make_styles()
    with (RESULTS / "summary.json").open(encoding="utf-8") as stream:
        summary = json.load(stream)
    tf = summary["transfer_function"]
    pendulum = summary["pendulum"]
    doc = SimpleDocTemplate(str(OUTPUT), pagesize=A4, rightMargin=1.55 * cm, leftMargin=1.55 * cm, topMargin=1.45 * cm, bottomMargin=1.35 * cm, title="ДЗ 6 - передатна функція та перевернутий маятник", author="Ievgen Bovkun, Dmytro Povolotskyi")
    story: list[object] = []

    story += [Spacer(1, 5.35 * cm), p("ДОМАШНЯ РОБОТА №6", styles, "cover_title"), Spacer(1, 0.55 * cm), p("Flight Systems Engineering", styles, "cover_subtitle"), Spacer(1, 0.4 * cm), p("Дослідження передатної функції та моделювання лінійної й нелінійної системи перевернутого маятника", styles, "cover_subtitle"), Spacer(1, 1.05 * cm), p("Виконали: Ievgen Bovkun, Dmytro Povolotskyi", styles, "cover_subtitle"), Spacer(1, 0.22 * cm), p("Інструменти: Python (control, NumPy, SciPy, Matplotlib) і MATLAB/Simulink", styles, "cover_subtitle"), Spacer(1, 0.24 * cm), p(f"Дата формування: {date.today():%d.%m.%Y}", styles, "cover_subtitle"), Spacer(1, 0.48 * cm), p("Репозиторій з кодом, Simulink-моделями та результатами:", styles, "cover_subtitle"), Spacer(1, 0.1 * cm), Paragraph(f'<link href="{GITHUB_URL}">GitHub: main/homework6</link>', styles["cover_subtitle"]), PageBreak()]

    story += [p("1. Мета та склад роботи", styles, "h1"), p("Мета роботи - дослідити перехідну характеристику неперервної системи за допомогою бібліотеки <i>control</i>, визначити її показники якості та полюси, а також побудувати лінійну і нелінійну моделі перевернутого маятника у просторі станів. Для перевірки реалізовано один фіксований крок інтегрування, дискретний PID-регулятор, Simulink-схеми та автоматизовані перевірки.", styles), p("Виконані пункти", styles, "h2"), table([["Частина", "Результат", "Доказ виконання"], ["Передатна функція", "Створено G(s), отримано step_response(), максимум, час піку, 2%-й час встановлення, полюси та висновок про стійкість.", "Python-скрипт, графік та pole map."], ["Маятник", "Побудовано нелінійну систему Лагранжа й лінеаризацію в околі вертикального положення.", "Порівняльні графіки та перевірка лінеаризації."], ["Керування", "PID із фільтрованою похідною, насиченням ±20 Н і захистом від накопичення інтеграла.", "Часові діаграми theta(t), u(t), x(t)."], ["Simulink", "Згенеровано State-Space модель і нелінійну схему з чотирма інтеграторами.", "Два .slx-файли та їхні знімки."], ["Перевірка", "Задано залежності й автоматичні unit-тести.", "requirements.txt, tests/ і run_analysis.py."]], [2.4, 7.6, 6.0], styles), PageBreak()]

    story += [p("2. Дослідження передатної функції", styles, "h1"), p("У числовому експерименті використано систему другого порядку:", styles), p("G(s) = 10 / (s² + 3s + 10).", styles, "formula"), p("Передатна функція створюється викликом <i>control.tf</i>; для одиничного стрибка застосовано <i>control.step_response</i>. Усталене значення визначено через статичний коефіцієнт передачі G(0). Час встановлення - перший відлік після останнього виходу за межі ±2% від усталеного значення; якщо вибраний часовий горизонт недостатній, алгоритм повертає None, а не помилкове значення 0 с.", styles), p("Результати", styles, "h2"), table([["Показник", "Значення", "Інтерпретація"], ["Усталене значення", f"{tf['steady_state']:.4f}", "G(0) = 1."], ["Максимум", f"{tf['peak']:.4f}", "Перерегулювання близько 18.4%."], ["Час максимуму", f"{tf['peak_time_s']:.4f} с", "Перший пік коливального процесу."], ["Час встановлення ±2%", f"{tf['settling_time_2pct_s']:.4f} с", "Сигнал надалі лишається в коридорі."], ["Полюси", "-1.5000 ± 2.7839j", "Дійсні частини від’ємні."], ["Стійкість", "асимптотично стійка", "Полюси лежать у лівій півплощині."]], [4.0, 4.0, 8.0], styles)]
    story += fig(RESULTS / "part1_transfer_function.png", "Рисунок 1 - перехідна характеристика, 2%-й коридор та розташування полюсів на s-площині.", styles, 10.0)
    story += [PageBreak(), p("3. Перевернутий маятник: математична модель", styles, "h1"), p("Вектор стану X = [x, x_dot, theta, theta_dot]ᵀ, де x - координата візка, theta - відхилення маятника від верхнього вертикального положення. Вхід u - горизонтальна сила на візку. Нелінійна модель отримана з рівнянь Лагранжа:", styles), p("(M+m)x_ddot + b x_dot + m l theta_ddot cos(theta) - m l theta_dot² sin(theta) = u;\n m l x_ddot cos(theta) + (I+m l²)theta_ddot - m g l sin(theta) = 0.", styles, "formula"), p("Використано M=0.5 кг, m=0.2 кг, b=0.1 Н/(м/с), l=0.3 м, I=0.006 кг·м², g=9.81 м/с². Для малих кутів sin(theta)≈theta, cos(theta)≈1 отримано модель X_dot=A X+B u:", styles), p("A = [[0,1,0,0], [0,-0.1818,-26.7545,0], [0,0,0,1], [0,0.4545,31.2136,0]]; B=[0,1.8182,0,-4.5455]ᵀ.", styles, "formula"), p("Моделювання виконується методом RK4 із фіксованим кроком dt=0.005 с. На кожному кроці регулятор обчислює силу, ця сила утримується сталою (ZOH) до наступного кроку інтегратора. Unit-тест незалежно звіряє нелінійну похідну з A X+B u у малому околі рівноваги.", styles), PageBreak()]

    story += [p("4. PID-регулятор та порівняння моделей", styles, "h1"), p("Використано дискретний закон u=Kp e + Ki∫e dt + Kd de/dt із Kp=40, Ki=50, Kd=5. Похідна згладжується фільтром Tf=0.02 с. Насичення ±20 Н та умовне інтегрування запобігають надмірному накопиченню інтегральної складової.", styles), table([["Експеримент", "Умова", "Висновок"], ["Відкритий контур", "theta(0)=10°, u=0", "Вертикальна рівновага нестійка: відхилення швидко зростає."], ["Замкнений контур", "theta(0)=10°, dt=5 мс", f"Кут входить у ±0.5° приблизно за {pendulum['angle_settling_time']:.2f} с; максимальна сила {pendulum['max_force_n']:.2f} Н."], ["Великий кут", "theta(0)=60°", f"Максимальна різниця лінійної та нелінійної моделей становить {pendulum['large_angle_model_gap_deg']:.2f}°."], ["Координата візка", "регулюється лише кут", f"Фінальне зміщення x={pendulum['final_cart_position_m']:.3f} м; для утримання x=0 потрібен зовнішній контур або LQR."]], [3.0, 4.7, 8.3], styles)]
    story += fig(RESULTS / "part2_inverted_pendulum.png", "Рисунок 2 - відкритий і замкнений контури, керуюча сила та межа застосовності лінеаризації.", styles, 13.2)
    story += [PageBreak(), p("5. Реалізація у MATLAB/Simulink", styles, "h1"), p("Для незалежної наочної перевірки створено дві Simulink-моделі. Лінійна схема містить блок State-Space з отриманими матрицями A, B, C, D. Нелінійна схема містить MATLAB Function для обчислення прискорень, чотири блоки Integrator, дискретний PID, Saturation та реєстрацію станів. В обох моделях задано фіксований solver ode4 із кроком 0.005 с. Команда <i>build_hw6_models</i> повністю відтворює .slx-файли та PNG-знімки.", styles)]
    story += fig(SIMULINK / "hw6_linear_pendulum_scheme.png", "Рисунок 3 - лінійна State-Space модель перевернутого маятника в Simulink.", styles, 8.2)
    story += fig(SIMULINK / "hw6_nonlinear_pendulum_scheme.png", "Рисунок 4 - нелінійна схема: PID(z), saturation, математична функція прискорень і чотири інтегратори.", styles, 8.2)
    story += [PageBreak(), p("6. Висновки", styles, "h1"), p("1. Передатна функція G(s)=10/(s²+3s+10) є асимптотично стійкою, оскільки обидва її полюси мають від’ємні дійсні частини. Перехідний процес коливальний: максимум 1.1840 досягається за 1.1280 с, а 2%-й час встановлення становить 2.6110 с.", styles), p("2. Верхнє положення перевернутого маятника є нестійким у відкритому контурі. PID із дискретизацією 200 Гц стабілізує мале початкове відхилення 10° у лінійній і нелінійній моделях.", styles), p("3. При 60° лінеаризована модель вже суттєво відрізняється від нелінійної. Отже, лінійна модель застосовна для синтезу та аналізу малих відхилень, але не замінює нелінійну перевірку діапазону працездатності.", styles), p("4. Додатково перевірено, що регулювання лише кута не гарантує нульового зміщення візка. Практичним наступним кроком є каскадний контур за x або повний зворотний зв’язок за станом (LQR).", styles), p("Відтворюваність", styles, "h2"), p("Python: створити віртуальне середовище, встановити <i>requirements.txt</i> та виконати <i>python -m homework6.run_analysis</i>. Simulink: у MATLAB виконати <i>addpath('homework6/simulink'); build_hw6_models</i>. Unit-тести: <i>python -m unittest discover -s homework6/tests -v</i>.", styles), PageBreak()]

    story += [p("Додаток A. Візуальна спадкоємність попередніх робіт", styles, "h1"), p("На прохання додано знімки з двох останніх робіт. Вони є контекстними артефактами ДЗ4/ДЗ5, а не результатами ДЗ6: це дозволяє відокремити поточні результати перевернутого маятника від попередніх експериментів.", styles)]
    story += fig(ASSETS / "hw4_simulink_scheme.png", "Рисунок A1 - ДЗ4: State-Space схема Simulink для лінеаризованої моделі поздовжнього руху ЛА.", styles, 8.4)
    story += fig(ASSETS / "hw4_state_responses.png", "Рисунок A2 - ДЗ4: порівняння MATLAB lsim та Simulink для станів лінеаризованого ЛА.", styles, 11.5)
    story += [PageBreak()]
    story += fig(ASSETS / "hw5_rk4_error.png", "Рисунок A3 - ДЗ5: залежність похибки RK4 від кроку інтегрування.", styles, 11.8)
    story += fig(ASSETS / "hw5_discretization.png", "Рисунок A4 - ДЗ5: порівняння неперервної та дискретних моделей за різних частот дискретизації.", styles, 11.2)

    doc.build(story, onFirstPage=footer, onLaterPages=footer)
    print(OUTPUT)


if __name__ == "__main__":
    main()
