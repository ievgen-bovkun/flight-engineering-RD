# Нотатка: український PDF

Для PDF зі звітом потрібно реєструвати TrueType-шрифти через ReportLab:

```python
pdfmetrics.registerFont(TTFont("Arial", r"C:\Windows\Fonts\arial.ttf"))
pdfmetrics.registerFont(TTFont("Arial-Bold", r"C:\Windows\Fonts\arialbd.ttf"))
pdfmetrics.registerFont(TTFont("TimesNewRoman", r"C:\Windows\Fonts\times.ttf"))
```

Генератор слід зберігати як Python-файл у UTF-8 та запускати напряму.
Не варто передавати український текст у Python через inline-скрипт
PowerShell: кодова сторінка консолі може перетворити кирилицю на `?`.

Для тексту застосовується `Arial`, для формул - `TimesNewRoman`.
Після генерації PDF обов'язково треба відрендерити його сторінки в PNG і
перевірити кирилицю, формули, графіки та переноси рядків візуально.
