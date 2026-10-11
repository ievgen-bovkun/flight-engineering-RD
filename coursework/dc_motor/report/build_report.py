"""Build a Ukrainian progress PDF from checked evidence; final mode fails closed."""
import argparse
import csv
import hashlib
import json
import math
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from xml.sax.saxutils import escape

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (Image, KeepTogether, PageBreak, Paragraph,
                               SimpleDocTemplate, Spacer, Table, TableStyle)

ROOT = Path(__file__).resolve().parents[1]
CORE_SECTIONS = ("modeling", "pid", "optimization", "disturbance", "python", "compensator_design")
FULL_SECTIONS = CORE_SECTIONS + ("simscape", "compensators", "fmu", "clean_copy")
REQUIRED_INPUTS = (
    "config/parameters.json", "config/scenarios.json", "report/report_uk.md",
    "results/json/optimization.json", "results/json/environment.json",
    "results/json/matlab_run.json", "results/json/disturbance.json",
    "results/csv/plant_comparison_summary.csv", "results/csv/controller_metrics.csv",
    "results/csv/disturbance_summary.csv", "results/csv/python_matlab_comparison.csv",
    "results/csv/pid_optimized.csv", "results/csv/disturbance_1_PID.csv",
    "results/figures/dc_motor_diffeq_subsystem.png", "results/figures/dc_motor_statespace_subsystem.png",
    "results/figures/optimized_pid_comparison.png", "results/figures/optimization_tradeoffs.png",
    "results/figures/required_disturbance.png", "results/figures/python_matlab_comparison.png",
    "results/csv/compensator_reference_metrics.csv", "results/json/compensator_reference.json",
    "results/figures/compensator_reference_comparison.png",
)


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def load_json(path):
    return json.loads(Path(path).read_text(encoding="utf-8-sig"))


def rows(root, filename):
    with (root / "results/csv" / filename).open(encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))


def safe_file(root, relative):
    path = (root / relative).resolve()
    if not path.is_relative_to(root.resolve()):
        raise ValueError(f"Evidence path leaves project: {relative}")
    if not path.is_file():
        raise ValueError(f"Missing evidence: {relative}")
    return path


def create_manifest(root=ROOT):
    """Snapshot only after recorded source provenance and numerical gates pass."""
    root = Path(root).resolve()
    # Git ships these generated text artifacts with LF. Hash their shipped bytes,
    # otherwise Windows CSV/JSON newlines invalidate the report after checkout.
    for folder, suffix in [("results/json", "*.json"), ("results/csv", "*.csv")]:
        for filename in (root / folder).glob(suffix):
            filename.write_bytes(filename.read_bytes().replace(b"\r\n", b"\n"))
    requirements = root / "requirements.txt"
    requirements.write_bytes(requirements.read_bytes().replace(b"\r\n", b"\n"))
    for name in REQUIRED_INPUTS:
        safe_file(root, name)
    sys.path.insert(0, str(root / "python"))
    from dc_motor.run_comparison import validated_gains
    from dc_motor.metrics import performance_metrics
    import numpy as np
    validated_gains(root / "results/json/optimization.json")
    run = load_json(root / "results/json/matlab_run.json")
    if not run.get("corePassed") or run["tests"]["failed"] or run["tests"]["incomplete"]:
        raise ValueError("Failed MATLAB core run")
    for source in run["sources"]:
        if sha(safe_file(root, source["path"])) != source["sha256"]:
            raise ValueError(f"Stale MATLAB run: {source['path']}")
    plant = rows(root, "plant_comparison_summary.csv")
    if {r["scenario"] for r in plant} != {"zero_input", "open_loop_12V", "plant_load_step", "nonzero_initial"}:
        raise ValueError("Incomplete plant comparison")
    for row in plant:
        for key, value in row.items():
            if key != "scenario" and (not math.isfinite(float(value)) or float(value) > (1e-4 if "speed" in key else 1e-5)):
                raise ValueError("Failed plant comparison")
    comparison = rows(root, "python_matlab_comparison.csv")
    compensators = rows(root, "compensator_reference_metrics.csv")
    compensator_record = load_json(root / "results/json/compensator_reference.json")
    if ({r["controller"] for r in compensators} != {"PID", "lag", "lead"}
            or compensator_record["physicalValidated"] is not False or compensator_record["horizon"] != 12):
        raise ValueError("Incomplete or mislabeled compensator reference study")
    expected = {"zero_input", "open_loop_12V", "plant_load_step", "nonzero_initial", "pid_nominal", "pid_required_load"}
    if {r["scenario"] for r in comparison} != expected:
        raise ValueError("Incomplete Python comparison")
    for row in comparison:
        for key, limit in [("max_speed_error", 1e-3), ("max_current_error", 1e-4),
                           ("max_voltage_error", 1e-2), ("settling_difference_s", .002)]:
            if not math.isfinite(float(row[key])) or float(row[key]) > limit:
                raise ValueError("Failed Python comparison")
    optimized = next(r for r in rows(root, "controller_metrics.csv") if r["controller"] == "optimized")
    trace = np.genfromtxt(root / "results/csv/pid_optimized.csv", delimiter=",", names=True)
    metrics = performance_metrics({"time": trace["time_s"], "omega": trace["omega_rad_s"],
                                  "current": trace["current_A"], "voltage": trace["voltage_V"], "reference": 100})
    for field, column in [("ts", "settling_s"), ("iae", "IAE_rad"), ("effort", "effort_Vs"), ("os", "overshoot_pct")]:
        if not math.isclose(metrics[field], float(optimized[column]), abs_tol=1e-6, rel_tol=1e-8):
            raise ValueError(f"Metrics differ from trajectory: {field}")
    targets = load_json(root / "config/parameters.json")["chosenTargets"]
    if (metrics["ts"] > targets["settlingTime"] or metrics["os"] > targets["overshootPercent"]
            or float(optimized["tail_error_rad_s"]) > targets["steadyError"]
            or optimized["tail_equilibrium_validated"] != "1"):
        raise ValueError("Failed optimized controller acceptance")
    patterns = ["config/*.json", "matlab/**/*.m", "matlab/models/*.slx", "python/**/*.py",
                "report/*.py", "report/*.md", "scripts/*.ps1", "requirements.txt",
                "results/json/*.json", "results/csv/*.csv", "results/figures/*.png"]
    paths = sorted({p for pattern in patterns for p in root.glob(pattern) if p.is_file()})
    sections = {name: {"status": "passed"} for name in CORE_SECTIONS}
    sections.update({name: {"status": "blocked" if name != "clean_copy" else "pending"}
                     for name in FULL_SECTIONS if name not in CORE_SECTIONS})
    manifest = {"schemaVersion": 1, "complete": False,
                "timestampUTC": datetime.now(timezone.utc).isoformat(),
                "sections": sections, "matlabTests": run["tests"],
                "files": [{"path": p.relative_to(root).as_posix(), "sha256": sha(p)} for p in paths]}
    (root / "results/run_manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
    return manifest


def validate_manifest(root=ROOT, draft=False):
    root = Path(root).resolve()
    manifest = load_json(safe_file(root, "results/run_manifest.json"))
    if manifest.get("schemaVersion") != 1 or not manifest.get("files"):
        raise ValueError("Incomplete evidence inventory")
    for record in manifest["files"]:
        if sha(safe_file(root, record["path"])) != record["sha256"]:
            raise ValueError(f"Stale evidence: {record['path']}")
    if not draft:
        if not manifest.get("complete") or any(manifest.get("sections", {}).get(s, {}).get("status") != "passed" for s in FULL_SECTIONS):
            raise ValueError("Incomplete project: final report requires all mandatory comparisons")
        mandatory = ["matlab/models/dc_motor_simscape.slx", "results/csv/simscape_comparison.csv",
                     "results/csv/compensator_comparison.csv", "results/csv/fmu_comparison.csv",
                     "fmu/dc_motor_plant.fmu", "fmu/dc_motor_pid.fmu", "results/json/clean_copy.json"]
        inventory = {r["path"] for r in manifest["files"]}
        if not set(mandatory).issubset(inventory):
            raise ValueError("Incomplete final artifact inventory")
    return manifest


def build_report(root=ROOT, draft=False, output=None):
    root = Path(root).resolve()
    manifest = validate_manifest(root, draft)
    inventory = {r["path"] for r in manifest["files"]}
    if not set(REQUIRED_INPUTS).issubset(inventory) or any(manifest["sections"].get(s, {}).get("status") != "passed" for s in CORE_SECTIONS):
        raise ValueError("Incomplete core report evidence")
    output = Path(output or root / "report" / ("DC_Motor_Progress_UA.pdf" if draft else "DC_Motor_Coursework_UA.pdf"))
    output.parent.mkdir(parents=True, exist_ok=True)
    import matplotlib
    fonts = Path(matplotlib.get_data_path()) / "fonts/ttf"
    pdfmetrics.registerFont(TTFont("Coursework", str(fonts / "DejaVuSans.ttf")))
    pdfmetrics.registerFont(TTFont("Coursework-Bold", str(fonts / "DejaVuSans-Bold.ttf")))
    pdfmetrics.registerFontFamily("Coursework", normal="Coursework", bold="Coursework-Bold", italic="Coursework", boldItalic="Coursework-Bold")
    styles = getSampleStyleSheet()
    styles.add(ParagraphStyle("BodyUA", fontName="Coursework", fontSize=9.7, leading=14.2, spaceAfter=8))
    styles.add(ParagraphStyle("TitleUA", fontName="Coursework-Bold", fontSize=23, leading=30, spaceAfter=22))
    styles.add(ParagraphStyle("HeadingUA", fontName="Coursework-Bold", fontSize=15, leading=21, spaceAfter=14))
    styles.add(ParagraphStyle("CellUA", fontName="Coursework", fontSize=8, leading=11))
    styles.add(ParagraphStyle("CaptionUA", fontName="Coursework", fontSize=8, leading=11, alignment=TA_CENTER, spaceAfter=10))
    cfg = load_json(root / "config/parameters.json")
    opt = load_json(root / "results/json/optimization.json")
    env = load_json(root / "results/json/environment.json")
    controllers = rows(root, "controller_metrics.csv")
    selected = next(r for r in controllers if r["controller"] == "optimized")
    baseline = next(r for r in controllers if r["controller"] == "pole_placement")
    py = rows(root, "python_matlab_comparison.csv")
    comp = rows(root, "compensator_reference_metrics.csv")
    fmt = lambda x, digits=3: f"{float(x):.{digits}f}"
    sci = lambda x: f"{float(x):.2e}"
    labels = {"ziegler_nichols": "Зіглер-Нікольс", "pole_placement": "Розміщення полюсів", "buddy_baseline": "Коефіцієнти колеги", "optimized": "Оптимізований ПІД"}
    tables = {
        "milestones": [["Етап", "Стан"], ["Рівняння та дві моделі Simulink", "Перевірено"], ["ПІД та оптимізація", "Перевірено"], ["Збурення й Python", "Перевірено"], ["Simscape, lag/lead та FMU", "Не завершено"], ["Фінальний PDF та ZIP", "Не завершено"]],
        "parameters": [["Параметр", "Значення", "Одиниця"]] + [[k, str(v), u] for k, v, u in zip(cfg["physical"], cfg["physical"].values(), ["Ом", "Гн", "Н·м/А", "В/(рад/с)", "кг·м²", "Н·м·с/рад", "кг·м²"])],
        "plant": [["Сценарій", "Δω: рівняння", "Δω: стани", "Макс. Δi, А"]] + [[r["scenario"], sci(r["max_speed_error_diffeq"]), sci(r["max_speed_error_statespace"]), sci(max(float(r[k]) for k in r if "current" in k))] for r in rows(root, "plant_comparison_summary.csv")],
        "controllers": [["Регулятор", "ts, с", "OS, %", "IAE, рад", "∫|V|dt, В·с", "Похибка, рад/с"]] + [[labels[r["controller"]], fmt(r["settling_s"]), fmt(r["overshoot_pct"]), fmt(r["IAE_rad"]), fmt(r["effort_Vs"]), sci(r["tail_error_rad_s"]) + ("*" if r["tail_equilibrium_validated"] != "1" else "")] for r in controllers],
        "gains": [["Kp", "Ki", "Kd", "Горизонт", "Крок виводу"] , [*[fmt(v, 6) for v in opt["K"]], "5 с", "0.001 с"]],
        "compensators": [["Регулятор", "ts, с", "OS, %", "Похибка, рад/с", "IAE, рад", "∫|V|dt, В·с"]] + [[r["controller"], fmt(r["settling_s"]), fmt(r["overshoot_pct"]), fmt(r["tail_error_rad_s"]), fmt(r["IAE_rad"]), fmt(r["effort_Vs"])] for r in comp],
        "python": [["Сценарій", "Δω, рад/с", "Δi, А", "ΔV, В", "Δts, с"]] + [[r["scenario"], sci(r["max_speed_error"]), sci(r["max_current_error"]), sci(r["max_voltage_error"]), fmt(r["settling_difference_s"])] for r in py],
        "disturbance": [["Момент / час", "Регулятор", "ts, с", "Провал, рад/с", "Відновлення, с"]] + [[{1: "0.05 / 1 с", 2: "0.05 / 3 с", 3: "0.5 / 3 с", 4: "1.5 / 3 с"}[int(r["scenario"])], "ПІД" if r["controller"] == "PID" else "ПІД + спост.", fmt(r["settling_s"]), fmt(r["trajectory_dip_rad_s"]), fmt(r["recovery_s"])] for r in rows(root, "disturbance_summary.csv")],
        "pending": [["Вимога", "Перевірка завершення"], ["Simscape / Electrical", "Реальні фізичні блоки та чисельний збіг"], ["Lag та lead", "Порівняння з ПІД на фізичній моделі"], ["FMU Builder / компілятор", "Автономний експорт та запуск FMPy"], ["Повне подання", "Фінальний PDF, ZIP та чисте відтворення"]],
    }
    summaries = {
        "environment": f"Середовище: {env['version']}; {env['platform']}. Сітка виводу: 0.001 с. MATLAB: {manifest['matlabTests']['passed']}/{manifest['matlabTests']['total']} перевірок у записаному запуску. Чисельні таблиці та зображення перевіряються за SHA256 перед складанням PDF.",
        "assumptions": f"Обрана межа напруги: від {cfg['control']['Vmin']:g} до {cfg['control']['Vmax']:g} В. Перерегулювання ≤{cfg['chosenTargets']['overshootPercent']:g}% та статична похибка ≤{cfg['chosenTargets']['steadyError']:g} рад/с є інженерними цілями; викладач задав лише 100 рад/с протягом 2 с і вимогу мінімізації. Горизонт порівняння базових регуляторів: 5 с.",
        "optimization": f"Використано п'ять стартів Nelder-Mead (fminsearch) та генетичний пошук; seed = {opt['seed']}, сумарно {opt['evaluations']} обчислень основного пошуку. Межі коефіцієнтів: Kp [2, 300], Ki [1, 800], Kd [0.1, 40]. Вибрано багатостартовий Nelder-Mead; λ = {opt['cfg']['lambda']}. Досліджено сім ваг. Пошук використовує RK4 з кроком 0.0005 с, остаточна перевірка - ode45 та Simulink, RelTol = 1e-8, AbsTol = 1e-10.",
        "tradeoff": f"Порівняно з розміщенням полюсів час усталення змінився з {fmt(baseline['settling_s'])} до {fmt(selected['settling_s'])} с, IAE - з {fmt(baseline['IAE_rad'])} до {fmt(selected['IAE_rad'])} рад. Абсолютний керуючий вплив зріс з {fmt(baseline['effort_Vs'])} до {fmt(selected['effort_Vs'])} В·с. Отже, швидкодія та IAE покращилися ціною невеликого збільшення витрат напруги; одночасного покращення всіх критеріїв немає.",
        "provenance": f"Маніфест: results/run_manifest.json. Зафіксовано {len(manifest['files'])} файлів; час формування UTC: {manifest['timestampUTC']}. Конфігурація, MATLAB/Python-код, дані та зображення мають контрольні суми. Оптимізовані коефіцієнти додатково звіряються з хешами початкової конфігурації й обчислювального коду; прихована підстановка значень не допускається.",
        "compensators": f"Виміряний час усталення: ПІД {fmt(comp[0]['settling_s'])} с, lag {fmt(comp[1]['settling_s'])} с, lead {fmt(comp[2]['settling_s'])} с. Для lag та lead немає інтегратора, тому залишкова похибка не нульова. Lag перевищує ціль 2 с, lead перевищує обрану межу статичної похибки 0.2 рад/с. Абсолютний керуючий вплив: lag {fmt(comp[1]['effort_Vs'])} В·с, lead {fmt(comp[2]['effort_Vs'])} В·с. У цьому налаштуванні lead швидший за lag та витрачає трохи менше напруги; універсальна перевага не доведена.",
        "conclusions": f"Номінальний оптимізований ПІД: ts = {fmt(selected['settling_s'])} с, OS = {fmt(selected['overshoot_pct'])}%, IAE = {fmt(selected['IAE_rad'])} рад, ∫|V|dt = {fmt(selected['effort_Vs'])} В·с. Максимальна різниця швидкості Python/MATLAB: {sci(max(float(r['max_speed_error']) for r in py))} рад/с. Зіглер-Нікольс має ts = {fmt(controllers[0]['settling_s'])} с та OS = {fmt(controllers[0]['overshoot_pct'])}% і не відповідає обраним цілям.",
    }
    figures = {"diffeq": ("dc_motor_diffeq_subsystem.png", "Підсистема двигуна: диференціальні рівняння", 150), "statespace": ("dc_motor_statespace_subsystem.png", "Підсистема двигуна: простір станів", 115), "pid": ("optimized_pid_comparison.png", "Номінальна швидкість і прикладена напруга", 255), "tradeoffs": ("optimization_tradeoffs.png", "Емпіричні компроміси IAE та керуючого впливу", 290), "disturbance": ("required_disturbance.png", "Реакція на необхідний момент навантаження", 250), "python": ("python_matlab_comparison.png", "Незалежні траєкторії MATLAB та Python", 285)}
    figures["compensators"] = ("compensator_reference_comparison.png", "ПІД, lag та lead на рівняннях двигуна, 12 с", 265)
    width = A4[0] - 88
    story = []
    figure_number = 0
    table_number = 0

    def paragraph(text, style="BodyUA"):
        return Paragraph(escape(text), styles[style])

    for block in (root / "report/report_uk.md").read_text(encoding="utf-8").strip().split("\n\n"):
        marker = re.fullmatch(r"\{\{(table|summary|figure|commands):([^}]+)\}\}", block.strip())
        if marker:
            kind, key = marker.groups()
            if kind == "summary":
                story.append(paragraph(summaries[key]))
            elif kind == "table":
                table_number += 1
                data = [[paragraph(str(v), "CellUA") for v in row] for row in tables[key]]
                widths = None
                if key == "controllers": widths = [114, 45, 46, 59, 72, width - 336]
                if key == "python": widths = [124] + [(width - 124) / 4] * 4
                if key == "plant": widths = [126] + [(width - 126) / 3] * 3
                table = Table(data, colWidths=widths or [width / len(data[0])] * len(data[0]), repeatRows=1, hAlign="LEFT")
                table.setStyle(TableStyle([("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#e7eef5")), ("VALIGN", (0, 0), (-1, -1), "TOP"), ("GRID", (0, 0), (-1, -1), .35, colors.HexColor("#afbfce")), ("LEFTPADDING", (0, 0), (-1, -1), 6), ("RIGHTPADDING", (0, 0), (-1, -1), 6), ("TOPPADDING", (0, 0), (-1, -1), 6), ("BOTTOMPADDING", (0, 0), (-1, -1), 6)]))
                story.extend([paragraph(f"Таблиця {table_number}", "CaptionUA"), table, Spacer(1, 12)])
            elif kind == "figure":
                figure_number += 1
                filename, caption, max_height = figures[key]
                image = Image(str(root / "results/figures" / filename))
                scale = min(width / image.imageWidth, max_height / image.imageHeight)
                image.drawWidth, image.drawHeight = image.imageWidth * scale, image.imageHeight * scale
                story.append(KeepTogether([image, Spacer(1, 5), paragraph(f"Рисунок {figure_number}. {caption}", "CaptionUA")]))
            else:
                commands = ["PowerShell, з кореня репозиторію:", "./coursework/dc_motor/scripts/run_all.ps1 -Mode Core", "Для повторної оптимізації: додайте -RegenerateOptimization", "Повний режим: -Mode Full (поки завершується помилкою)"]
                story.extend(paragraph(c) for c in commands)
        elif block.startswith("## "):
            story.extend([PageBreak(), paragraph(block[3:], "HeadingUA")])
        elif block.startswith("# "):
            story.extend([Spacer(1, 24), paragraph(block[2:], "TitleUA")])
        else:
            story.append(paragraph(block.replace("\n", " ")))

    def footer(canvas, doc):
        canvas.saveState()
        canvas.setFont("Coursework", 7.5)
        canvas.setFillColor(colors.HexColor("#53677a"))
        canvas.drawString(44, 25, "Проміжний звіт - обов'язкові Simscape/FMU етапи не завершено" if draft else "Курсова робота - ДПС")
        canvas.drawRightString(A4[0] - 44, 25, str(doc.page))
        canvas.restoreState()

    doc = SimpleDocTemplate(str(output), pagesize=A4, rightMargin=44, leftMargin=44, topMargin=40, bottomMargin=44, title="Система керування ДПС - проміжний звіт" if draft else "Система керування ДПС", author="Ievgen Bovkun")
    doc.build(story, onFirstPage=footer, onLaterPages=footer)
    return output


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--draft", action="store_true", help="Explicitly incomplete progress report")
    parser.add_argument("--refresh-manifest", action="store_true")
    args = parser.parse_args()
    if args.refresh_manifest:
        create_manifest()
    print(build_report(draft=args.draft))
