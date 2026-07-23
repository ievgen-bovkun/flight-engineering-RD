"""Build the Ukrainian Task 1 report PDF from its Markdown source."""

from __future__ import annotations

import html
import re
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Image, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle


REPORT_DIR = Path(__file__).resolve().parent
SOURCE = REPORT_DIR / "Task1_Report.md"
OUTPUT = REPORT_DIR / "Task1_Report.pdf"
PAGE_WIDTH, _ = A4
MARGIN = 18 * mm
CONTENT_WIDTH = PAGE_WIDTH - 2 * MARGIN


def register_fonts() -> None:
    fonts = {
        "Arial": r"C:\Windows\Fonts\arial.ttf",
        "Arial-Bold": r"C:\Windows\Fonts\arialbd.ttf",
        "Arial-Italic": r"C:\Windows\Fonts\ariali.ttf",
        "TimesNewRoman": r"C:\Windows\Fonts\times.ttf",
        "TimesNewRoman-Bold": r"C:\Windows\Fonts\timesbd.ttf",
        "TimesNewRoman-Italic": r"C:\Windows\Fonts\timesi.ttf",
    }
    for name, path in fonts.items():
        pdfmetrics.registerFont(TTFont(name, path))


def make_styles() -> dict[str, ParagraphStyle]:
    return {
        "title": ParagraphStyle(
            "title", fontName="Arial-Bold", fontSize=18, leading=23,
            alignment=TA_CENTER, textColor=colors.HexColor("#17365D"), spaceAfter=7 * mm,
        ),
        "h2": ParagraphStyle(
            "h2", fontName="Arial-Bold", fontSize=14, leading=18,
            textColor=colors.HexColor("#17365D"), spaceBefore=6 * mm, spaceAfter=3 * mm,
        ),
        "h3": ParagraphStyle(
            "h3", fontName="Arial-Bold", fontSize=11.5, leading=15,
            textColor=colors.HexColor("#214B70"), spaceBefore=4 * mm, spaceAfter=2 * mm,
        ),
        "body": ParagraphStyle(
            "body", fontName="Arial", fontSize=10, leading=14, spaceAfter=2.2 * mm,
        ),
        "list": ParagraphStyle(
            "list", fontName="Arial", fontSize=10, leading=14, leftIndent=6 * mm,
            firstLineIndent=-5 * mm, spaceAfter=1.2 * mm,
        ),
        "equation": ParagraphStyle(
            "equation", fontName="TimesNewRoman", fontSize=14, leading=19,
            alignment=TA_CENTER,
        ),
        "caption": ParagraphStyle(
            "caption", fontName="Arial-Italic", fontSize=8.5, leading=11,
            alignment=TA_CENTER, textColor=colors.HexColor("#4F4F4F"), spaceAfter=2.5 * mm,
        ),
        "table_head": ParagraphStyle(
            "table_head", fontName="Arial-Bold", fontSize=8.5, leading=10,
            alignment=TA_CENTER, textColor=colors.white,
        ),
        "table_cell": ParagraphStyle(
            "table_cell", fontName="Arial", fontSize=8.5, leading=10.5,
        ),
    }


def math_markup(value: str) -> str:
    """Convert the small LaTeX subset used in the report into ReportLab markup."""
    value = value.strip()
    value = value.replace(r"\qquad", "     ").replace(r"\,", " ")
    value = re.sub(r"\\frac\{([^{}]+)\}\{([^{}]+)\}", r"(\1)/(\2)", value)
    replacements = {
        r"\Omega": "Ω", r"\phi": "φ", r"\theta": "θ", r"\psi": "ψ",
        r"\tau": "τ", r"\cdot": "·", r"\sin": "sin", r"\cos": "cos",
        r"\dot u": "u̇", r"\dot v": "v̇", r"\dot w": "ẇ",
    }
    for source, target in replacements.items():
        value = value.replace(source, target)
    value = value.replace("\\", "")
    # Handle Ω_1^2 in one pass before applying standalone indices or powers.
    value = re.sub(
        r"([A-Za-zΩφθψ])_([A-Za-z0-9]+)\^\{?(-?[0-9]+)\}?",
        r"\1<sub>\2</sub><super>\3</super>",
        value,
    )
    value = re.sub(r"([A-Za-zΩφθψ])_([A-Za-z0-9]+)", r"\1<sub>\2</sub>", value)
    value = re.sub(r"([A-Za-z0-9Ωφθψ])\^\{?(-?[0-9]+)\}?", r"\1<super>\2</super>", value)
    return value


def inline_markup(value: str) -> str:
    value = html.escape(value)
    value = value.replace("{{BR}}", "<br/>")
    value = re.sub(r"`([^`]+)`", r'<font name="TimesNewRoman">\1</font>', value)
    value = re.sub(r"\*\*([^*]+)\*\*", r"<b>\1</b>", value)
    value = re.sub(r"\*([^*]+)\*", r"<i>\1</i>", value)
    value = re.sub(
        r"\[([^\]]+)\]\((https?://[^)]+)\)",
        r'<link href="\2" color="#185A91"><u>\1</u></link>',
        value,
    )
    return re.sub(
        r"\$([^$]+)\$",
        lambda match: f'<font name="TimesNewRoman">{math_markup(match.group(1))}</font>',
        value,
    )


def formula_box(markup: str, styles: dict[str, ParagraphStyle]) -> Table:
    box = Table([[Paragraph(math_markup(markup), styles["equation"])]], colWidths=[CONTENT_WIDTH])
    box.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#F3F7FA")),
        ("BOX", (0, 0), (-1, -1), 0.45, colors.HexColor("#B7C7D6")),
        ("LEFTPADDING", (0, 0), (-1, -1), 6 * mm),
        ("RIGHTPADDING", (0, 0), (-1, -1), 6 * mm),
        ("TOPPADDING", (0, 0), (-1, -1), 2.4 * mm),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 2.4 * mm),
    ]))
    return box


def image_flowable(path: Path) -> Image:
    image = Image(str(path))
    image._restrictSize(CONTENT_WIDTH, 205 * mm)
    return image


def markdown_table(lines: list[str], styles: dict[str, ParagraphStyle]) -> Table:
    rows: list[list[Paragraph]] = []
    for index, line in enumerate(lines):
        if index == 1:
            continue
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        style = styles["table_head"] if index == 0 else styles["table_cell"]
        rows.append([Paragraph(inline_markup(cell), style) for cell in cells])
    columns = len(rows[0])
    widths = [CONTENT_WIDTH / columns] * columns
    table = Table(rows, colWidths=widths, repeatRows=1)
    table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#2F5D84")),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("GRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#B8C7D4")),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F5F8FB")]),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("LEFTPADDING", (0, 0), (-1, -1), 2.1 * mm),
        ("RIGHTPADDING", (0, 0), (-1, -1), 2.1 * mm),
        ("TOPPADDING", (0, 0), (-1, -1), 1.7 * mm),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 1.7 * mm),
    ]))
    return table


def build_story(markdown: str, styles: dict[str, ParagraphStyle]) -> list:
    story: list = []
    lines = markdown.splitlines()
    index = 0
    first_heading = True

    while index < len(lines):
        raw_line = lines[index]
        line = raw_line.strip()
        if not line:
            index += 1
            continue

        if line == "$$":
            formula: list[str] = []
            index += 1
            while index < len(lines) and lines[index].strip() != "$$":
                formula.append(lines[index].strip())
                index += 1
            story.extend([formula_box(" ".join(formula), styles), Spacer(1, 1.8 * mm)])
            index += 1
            continue

        image_match = re.fullmatch(r"!\[([^\]]*)\]\(([^)]+)\)", line)
        if image_match:
            story.append(image_flowable(REPORT_DIR / image_match.group(2)))
            story.append(Paragraph(image_match.group(1), styles["caption"]))
            index += 1
            continue

        if line.startswith("# "):
            story.append(Paragraph(inline_markup(line[2:]), styles["title"] if first_heading else styles["h2"]))
            first_heading = False
            index += 1
            continue
        if line.startswith("## "):
            story.append(Paragraph(inline_markup(line[3:]), styles["h2"]))
            index += 1
            continue
        if line.startswith("### "):
            story.append(Paragraph(inline_markup(line[4:]), styles["h3"]))
            index += 1
            continue

        if line.startswith("|") and index + 1 < len(lines) and re.match(r"^\|[-|: ]+\|$", lines[index + 1].strip()):
            table_lines = [line, lines[index + 1].strip()]
            index += 2
            while index < len(lines) and lines[index].strip().startswith("|"):
                table_lines.append(lines[index].strip())
                index += 1
            story.extend([markdown_table(table_lines, styles), Spacer(1, 2 * mm)])
            continue

        numbered = re.match(r"^(\d+)\.\s+(.*)$", line)
        bullet = re.match(r"^-\s+(.*)$", line)
        if numbered:
            story.append(Paragraph(f"{numbered.group(1)}. {inline_markup(numbered.group(2))}", styles["list"]))
            index += 1
            continue
        if bullet:
            story.append(Paragraph(f"• {inline_markup(bullet.group(1))}", styles["list"]))
            index += 1
            continue

        paragraph = [line + ("{{BR}}" if raw_line.endswith("  ") else " ")]
        index += 1
        while index < len(lines) and lines[index].strip() and not lines[index].startswith(("#", "!", "|", "- ")):
            if re.match(r"^\d+\.\s+", lines[index].strip()) or lines[index].strip() == "$$":
                break
            paragraph.append(lines[index].strip() + ("{{BR}}" if lines[index].endswith("  ") else " "))
            index += 1
        story.append(Paragraph(inline_markup("".join(paragraph)), styles["body"]))

    return story


def footer(canvas, document) -> None:
    canvas.saveState()
    canvas.setStrokeColor(colors.HexColor("#B8C7D4"))
    canvas.line(MARGIN, 13 * mm, PAGE_WIDTH - MARGIN, 13 * mm)
    canvas.setFont("Arial", 7.5)
    canvas.setFillColor(colors.HexColor("#5B6770"))
    canvas.drawString(MARGIN, 8.8 * mm, "Практичне завдання 1 - нелінійна модель квадрокоптера")
    canvas.drawRightString(PAGE_WIDTH - MARGIN, 8.8 * mm, f"Сторінка {document.page}")
    canvas.restoreState()


def main() -> None:
    register_fonts()
    styles = make_styles()
    document = SimpleDocTemplate(
        str(OUTPUT), pagesize=A4, leftMargin=MARGIN, rightMargin=MARGIN,
        topMargin=17 * mm, bottomMargin=19 * mm, title="Практичне завдання 1",
        author="Dmytro Povolotskyi, Ievgen Bovkun",
    )
    document.build(build_story(SOURCE.read_text(encoding="utf-8"), styles), onFirstPage=footer, onLaterPages=footer)
    print(OUTPUT)


if __name__ == "__main__":
    main()
