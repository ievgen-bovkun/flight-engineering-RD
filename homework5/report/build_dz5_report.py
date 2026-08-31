from __future__ import annotations

import csv
from datetime import date
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    Image,
    KeepTogether,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)


PROJECT = Path(__file__).resolve().parents[1]
TASK1 = PROJECT / "task1_integrators"
TASK2 = PROJECT / "task2_discretization"
OUTPUT = Path(__file__).resolve().parent / "DZ5_Numerical_Methods_Report.pdf"
GITHUB_URL = "https://github.com/ievgen-bovkun/flight-engineering-RD/tree/main/homework5"


def load_csv(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8", newline="") as stream:
        return list(csv.DictReader(stream))


def number(row: dict[str, str], key: str) -> float:
    return float(row[key])


def register_fonts() -> None:
    fonts = Path(r"C:\Windows\Fonts")
    pdfmetrics.registerFont(TTFont("Arial", str(fonts / "arial.ttf")))
    pdfmetrics.registerFont(TTFont("Arial-Bold", str(fonts / "arialbd.ttf")))


def styles() -> dict[str, ParagraphStyle]:
    sample = getSampleStyleSheet()
    blue = colors.HexColor("#2E75B6")
    return {
        "body": ParagraphStyle(
            "body", parent=sample["BodyText"], fontName="Arial", fontSize=10.2,
            leading=14, spaceAfter=8,
        ),
        "h1": ParagraphStyle(
            "h1", parent=sample["Heading1"], fontName="Arial-Bold", fontSize=19,
            leading=23, textColor=blue, spaceBefore=3, spaceAfter=10,
        ),
        "h2": ParagraphStyle(
            "h2", parent=sample["Heading2"], fontName="Arial-Bold", fontSize=13,
            leading=16, textColor=blue, spaceBefore=7, spaceAfter=7,
        ),
        "cover_title": ParagraphStyle(
            "cover_title", parent=sample["Title"], fontName="Arial-Bold", fontSize=25,
            leading=31, textColor=colors.HexColor("#1F426F"), alignment=TA_CENTER,
        ),
        "cover_subtitle": ParagraphStyle(
            "cover_subtitle", parent=sample["Normal"], fontName="Arial", fontSize=14,
            leading=19, alignment=TA_CENTER,
        ),
        "caption": ParagraphStyle(
            "caption", parent=sample["BodyText"], fontName="Arial", fontSize=8.8,
            leading=11, alignment=TA_CENTER, textColor=colors.HexColor("#555555"),
            spaceBefore=3, spaceAfter=9,
        ),
        "small": ParagraphStyle(
            "small", parent=sample["BodyText"], fontName="Arial", fontSize=8.8,
            leading=11,
        ),
        "formula": ParagraphStyle(
            "formula", parent=sample["Code"], fontName="Courier", fontSize=8.6,
            leading=11, leftIndent=12, spaceAfter=7,
        ),
    }


def p(text: str, s: dict[str, ParagraphStyle], kind: str = "body") -> Paragraph:
    return Paragraph(text, s[kind])


def table(rows: list[list[str]], widths: list[float], s: dict[str, ParagraphStyle]) -> Table:
    prepared = [[p(cell, s, "small") for cell in row] for row in rows]
    result = Table(prepared, colWidths=widths, repeatRows=1, hAlign="LEFT")
    result.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#DCE6F1")),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.HexColor("#1F4E79")),
        ("FONTNAME", (0, 0), (-1, 0), "Arial-Bold"),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#777777")),
        ("LEFTPADDING", (0, 0), (-1, -1), 5),
        ("RIGHTPADDING", (0, 0), (-1, -1), 5),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
    ]))
    return result


def figure(path: Path, caption: str, s: dict[str, ParagraphStyle], height: float = 3.7) -> KeepTogether:
    image = Image(str(path))
    scale = min(6.35 * inch / image.imageWidth, height * inch / image.imageHeight)
    image.drawWidth = image.imageWidth * scale
    image.drawHeight = image.imageHeight * scale
    image.hAlign = "CENTER"
    return KeepTogether([image, p(caption, s, "caption")])


def footer(canvas, document) -> None:
    canvas.saveState()
    canvas.setFont("Arial", 8)
    canvas.setFillColor(colors.HexColor("#777777"))
    canvas.drawCentredString(
        letter[0] / 2, 0.38 * inch,
        f"Домашня робота №5 | Інженерія польоту | сторінка {document.page}",
    )
    canvas.restoreState()


def main() -> None:
    register_fonts()
    s = styles()
    rk_rows = load_csv(TASK1 / "results" / "task1_metrics.csv")
    nominal = load_csv(TASK2 / "results" / "task2_nominal_metrics.csv")
    clock = load_csv(TASK2 / "results" / "task2_clock_deviation_metrics.csv")
    doc = SimpleDocTemplate(
        str(OUTPUT), pagesize=letter, rightMargin=0.68 * inch, leftMargin=0.68 * inch,
        topMargin=0.62 * inch, bottomMargin=0.66 * inch,
        title="Домашня робота №5 - чисельне інтегрування та дискретизація",
        author="Dmytro Povolotskyi, Ievgen Bovkun",
    )
    story: list[object] = []

    story.extend([
        Spacer(1, 2.1 * inch),
        p("ДОМАШНЯ РОБОТА №5", s, "cover_title"),
        Spacer(1, 0.28 * inch),
        p("Інженерія польоту", s, "cover_subtitle"),
        Spacer(1, 0.22 * inch),
        p("Чисельне інтегрування RK4 / RKF45 та дискретизація передатної функції", s, "cover_subtitle"),
        Spacer(1, 0.54 * inch),
        p("Виконали: Dmytro Povolotskyi, Ievgen Bovkun", s, "cover_subtitle"),
        Spacer(1, 0.14 * inch),
        p(f"Дата: {date.today():%d.%m.%Y}", s, "cover_subtitle"),
        Spacer(1, 0.52 * inch),
        p("Репозиторій з MATLAB-кодом, тестами, даними та графіками:", s, "cover_subtitle"),
        Spacer(1, 0.1 * inch),
        Paragraph(f'<link href="{GITHUB_URL}">GitHub: main/homework5</link>', s["cover_subtitle"]),
        PageBreak(),
    ])

    story.append(p("1. Мета та склад роботи", s, "h1"))
    story.append(p(
        "Мета - реалізувати та порівняти два чисельні інтегратори для звичайних "
        "диференціальних рівнянь, а також дослідити дискретне подання заданої "
        "передатної функції. Усі розрахунки виконано власними MATLAB-функціями; "
        "інструменти Control System Toolbox використано як незалежну еталонну перевірку.", s))
    story.append(p("До складу роботи входять:", s, "h2"))
    story.append(table([
        ["Частина", "Реалізовано", "Контроль"],
        ["1", "Кроки та цикли RK4 і RKF45, оцінка похибки, прийняття / відхилення кроку", "Порівняння з sin(2 pi f t) на 10...10000 Гц"],
        ["2", "Неперервна модель, точна ZOH-дискретизація і власний дискретний симулятор", "c2d: ZOH, FOH, Tustin; девіація тактової частоти +/-10%"],
        ["Якість", "Автоматичні тести, CSV, MAT і PNG-артефакти", "Повторюваний запуск із чистої MATLAB-сесії"],
    ], [0.6 * inch, 3.0 * inch, 2.1 * inch], s))

    story.append(p("2. Завдання 1 - чисельне інтегрування", s, "h1"))
    story.append(p(
        "Тестова задача побудована для гармонічного сигналу y(t) = sin(2 pi f t): "
        "y_dot = 2 pi f cos(2 pi f t), y(0) = 0. Частоти f = 10, 100, 1000, 10000 Гц. "
        "Таке формулювання дає точний аналітичний розв'язок для оцінки похибки.", s))
    story.append(p("2.1. Алгоритми", s, "h2"))
    story.append(p(
        "Для RK4 один крок використовує чотири значення правої частини. Для RKF45 "
        "обчислюються шість проміжних похідних, а різниця розв'язків 4-го і 5-го "
        "порядків служить локальною оцінкою похибки. Крок приймається, якщо e <= tol; "
        "інакше він відхиляється та повторюється з меншим h.", s))
    story.append(p("RK4: k1=f(t,y); k2=f(t+h/2,y+h*k1/2); k3=f(t+h/2,y+h*k2/2); k4=f(t+h,y+h*k3);", s, "formula"))
    story.append(p("y(k+1)=y(k)+h*(k1+2*k2+2*k3+k4)/6.", s, "formula"))
    story.append(p("Для RKF45 новий крок обчислюється за формулою:", s))
    story.append(p("h_new = clamp(0.9*h*(tol/e)^(1/5), h_min, h_max).", s, "formula"))

    rk4 = [row for row in rk_rows if row["method"] == "RK4"]
    rkf = [row for row in rk_rows if row["method"] == "RKF45"]
    story.append(p("2.2. Точність RK4 та адаптація RKF45", s, "h2"))
    rk4_rows = [["Відліків/період", "h/T", "Max |похибка|"]] + [
        [f"{round(1 / (number(row, 'h') * number(row, 'frequency_hz'))):d}", f"{number(row, 'h') * number(row, 'frequency_hz'):.5f}", f"{number(row, 'max_abs_error'):.3e}"]
        for row in rk4[:4]
    ]
    story.append(table(rk4_rows, [1.7 * inch, 1.5 * inch, 2.0 * inch], s))
    story.append(Spacer(1, 0.08 * inch))
    story.append(p(
        "Зі зменшенням h похибка RK4 спадає приблизно як h^4. На найточнішому "
        "дослідженому кроці (80 відліків на період) максимальна похибка становить 1.321e-08.", s))
    story.append(figure(TASK1 / "results" / "rk4_error_vs_step.png", "Рисунок 1 - залежність похибки RK4 від нормованого кроку інтегрування." , s))
    story.append(figure(TASK1 / "results" / "rkf45_step_history.png", "Рисунок 2 - автоматична зміна кроку RKF45 під час інтегрування сигналу 10000 Гц.", s))
    story.append(PageBreak())
    story.append(figure(TASK1 / "results" / "rkf45_accuracy_effort.png", "Рисунок 3 - компроміс між допуском RKF45, досягнутою точністю та кількістю пробних кроків.", s))
    story.append(figure(TASK1 / "results" / "method_overlay_10000hz.png", "Рисунок 4 - узгодженість RK4, RKF45 та аналітичного розв'язку на 10000 Гц.", s))
    story.append(p("Числовий підсумок RKF45", s, "h2"))
    rkf_rows = [["Допуск", "Середній max |похибка|", "Прийнято", "Відхилено"]]
    for tolerance in sorted({row["tolerance"] for row in rkf}, reverse=True):
        group = [row for row in rkf if row["tolerance"] == tolerance]
        rkf_rows.append([
            tolerance, f"{sum(number(row, 'max_abs_error') for row in group) / len(group):.3e}",
            f"{sum(number(row, 'accepted_steps') for row in group) / len(group):.1f}",
            f"{sum(number(row, 'rejected_steps') for row in group) / len(group):.1f}",
        ])
    story.append(table(rkf_rows, [0.9 * inch, 2.0 * inch, 1.0 * inch, 1.0 * inch], s))

    story.append(PageBreak())
    story.append(p("3. Завдання 2 - дискретизація передатної функції", s, "h1"))
    story.append(p(
        "Досліджено T(s) = 0.3333 / (s^2 + s + 33.33). Неперервну модель переведено "
        "у форму простору станів. Власна ZOH-дискретизація отримує A_d і B_d через "
        "експоненту розширеної матриці; вихід обчислюється рекурсією x[k+1] = A_d x[k] + B_d u[k].", s))
    story.append(p("[A_d  B_d; 0  1] = expm([A  B; 0  0] * T_s).", s, "formula"))
    story.append(p(
        "Для порівняння використано три штатні дискретизації MATLAB (ZOH, FOH, Tustin) "
        "та неперервну еталонну реакцію. Дослідження проведено для Fs = 10, 100, 1000 Гц.", s))
    zoh = [row for row in nominal if row["method"] == "custom_zoh"]
    foh = [row for row in nominal if row["method"] == "foh"]
    tustin = [row for row in nominal if row["method"] == "tustin"]
    nominal_rows = [["Fs, Гц", "Власний ZOH vs c2d ZOH", "FOH vs неперервна", "Tustin vs неперервна"]]
    for freq in [10, 100, 1000]:
        get = lambda group: next(row for row in group if int(float(row["frequency_hz"])) == freq)
        nominal_rows.append([
            str(freq), f"{number(get(zoh), 'max_abs_error'):.3e}",
            f"{number(get(foh), 'max_abs_error'):.3e}", f"{number(get(tustin), 'max_abs_error'):.3e}",
        ])
    story.append(table(nominal_rows, [0.75 * inch, 1.75 * inch, 1.55 * inch, 1.55 * inch], s))
    story.append(Spacer(1, 0.1 * inch))
    story.append(figure(TASK2 / "results" / "method_comparison.png", "Рисунок 5 - часові реакції неперервної та дискретних моделей для трьох частот дискретизації.", s))
    story.append(PageBreak())
    story.append(figure(TASK2 / "results" / "discretization_error_vs_fs.png", "Рисунок 6 - спадання похибки FOH і Tustin зі зростанням частоти дискретизації.", s))
    story.append(figure(TASK2 / "results" / "frequency_response_comparison.png", "Рисунок 7 - частотні характеристики неперервної моделі та дискретизацій ZOH, FOH, Tustin.", s, height=4.25))

    story.append(p("3.1. Девіація тактової частоти", s, "h2"))
    story.append(p(
        "Коефіцієнти ZOH зафіксовано для номінального T_s, після чого модель "
        "порівняно з неперервною системою за фактичної частоти (1 + delta)Fs, де delta = -10%, 0%, +10%. "
        "Найбільша похибка виникає за -10%: фактична дискретизація повільніша за номінальну.", s))
    clock_rows = [["Номінальна Fs, Гц", "Max |похибка| за -10%", "за 0%", "за +10%"]]
    for freq in [10, 100, 1000]:
        values = []
        for deviation in [-0.1, 0.0, 0.1]:
            row = next(item for item in clock if int(float(item["nominal_frequency_hz"])) == freq and abs(number(item, "deviation") - deviation) < 1e-12)
            values.append(f"{number(row, 'clock_max_abs_error'):.3e}")
        clock_rows.append([str(freq), *values])
    story.append(table(clock_rows, [1.35 * inch, 1.55 * inch, 1.45 * inch, 1.45 * inch], s))
    story.append(Spacer(1, 0.1 * inch))
    story.append(figure(TASK2 / "results" / "clock_deviation.png", "Рисунок 8 - вплив девіації тактової частоти на похибку ZOH-моделі.", s))

    story.append(PageBreak())
    story.append(p("4. Відтворюваність та перевірка", s, "h1"))
    story.append(p(
        "Кожна частина має власні підпапки src, scripts, tests, results та report. "
        "Скрипти run_task1_integrator_study.m і run_task2_discretization_study.m створюють "
        "CSV, MAT та PNG. Тести перевіряють порядок точності RK4, адаптацію RKF45, "
        "еквівалентність власної ZOH реалізації c2d та наявність усіх артефактів.", s))
    story.append(table([
        ["Перевірка", "Результат", "Доказ"],
        ["RK4", "Пройдено", "Тест точності та збіжності при зменшенні кроку"],
        ["RKF45", "Пройдено", "Тест прийняття / відхилення кроку та меж h"],
        ["Власний ZOH", "Пройдено", "Max |власний ZOH - c2d ZOH| = 1.041e-17"],
        ["Артефакти", "Пройдено", "8 PNG-графіків, CSV та MAT для обох частин"],
    ], [1.25 * inch, 0.85 * inch, 3.7 * inch], s))
    story.append(p("5. Висновки", s, "h1"))
    story.append(p(
        "1. RK4 коректно відтворює синусоїду, а зменшення постійного кроку дає очікуване "
        "суттєве зниження похибки. 2. RKF45 автоматично розподіляє обчислення: суворіший "
        "допуск зменшує похибку, але збільшує кількість прийнятих кроків. 3. Власна ZOH "
        "реалізація чисельно збігається з MATLAB c2d. 4. За більшої Fs FOH і Tustin "
        "наближаються до неперервної системи, а відхилення тактової частоти створює вимірювану "
        "похибку, найбільшу для повільнішої фактичної дискретизації. Графіки 1-8 показують "
        "як часові, так і частотні наслідки цих висновків.", s))

    doc.build(story, onFirstPage=footer, onLaterPages=footer)
    print(OUTPUT)


if __name__ == "__main__":
    main()
