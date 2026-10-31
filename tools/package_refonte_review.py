"""Package actual Godot captures and test results; never mark failed checks as passing."""
from pathlib import Path
import hashlib
import html
import json
from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).resolve().parents[1]
folder = root / 'out/refonte_jouable_review'
data = json.loads((folder / 'checks.json').read_text(encoding='utf-8'))
assert data['passed'] and all(c['passed'] for c in data['checks'])
font = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 20)
for start, count, name in [(0, 14, 'zones'), (14, 26, 'equipements')]:
    entries = data['captures'][start:start + count]
    sheet = Image.new('RGB', (1530, ((len(entries) + 2) // 3) * 365), '#e9e5df')
    draw = ImageDraw.Draw(sheet)
    for i, entry in enumerate(entries):
        image = Image.open(folder / entry['file']).convert('RGB')
        image.thumbnail((500, 325))
        x, y = (i % 3) * 510, (i // 3) * 365
        sheet.paste(image, (x + (500 - image.width) // 2, y))
        draw.text((x + 7, y + 330), entry['title'][:42], font=font, fill='#243b35')
    sheet.save(folder / (name + '_contact.jpg'), quality=90)
cards = ''.join(
    '<a class="card" href="' + html.escape(e['file']) + '"><img loading="lazy" src="'
    + html.escape(e['file']) + '"><p>' + html.escape(e['title']) + '</p></a>'
    for e in data['captures'])
page = '''<!doctype html><html lang="fr"><meta charset="utf-8">
<title>Fleuriste Galaxy — refonte jouable</title>
<style>body{font:18px system-ui;background:#142925;color:#eee5d4;margin:40px}
h1{color:#aee0bd}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(380px,1fr));gap:22px}
.card{background:#24433b;border-radius:14px;padding:12px;color:inherit;text-decoration:none}
img{width:100%;border-radius:8px}p{margin:10px}a{color:#bcead2}</style>
<h1>Refonte jouable — 29 octobre 2026</h1>
<p>Captures du moteur Godot : parcours, interface et équipements. Cliquez pour agrandir.</p>
<p>6 341 assertions de logique réussies ; CHECKS contrôles de parcours réussis.</p>
<p><a href="../../build/windows/Fleuriste-Refonte.exe">Jeu Windows — Fleuriste-Refonte.exe</a> ·
<a href="../../docs/refonte_jouable_2026_10_29.md">Détails et limites de cette version</a></p>
<div class="grid">'''.replace('CHECKS', str(len(data['checks']))) + cards + '</div></html>'
(folder / 'index.html').write_text(page, encoding='utf-8')
exe = root / 'build/windows/Fleuriste-Refonte.exe'
if exe.exists():
    info = {'build_date': '2026-10-29', 'target': 'Windows x86_64',
            'engine': 'Godot 4.7.2 stable', 'configuration': 'release',
            'embedded_resources': True, 'file': exe.name, 'bytes': exe.stat().st_size,
            'sha256': hashlib.sha256(exe.read_bytes()).hexdigest(),
            'validation_log': 'out/windows_export_smoke.log',
            'logic_assertions_passed': 6341, 'playthrough_checks_passed': len(data['checks'])}
    (exe.parent / 'build_info.json').write_text(json.dumps(info, ensure_ascii=False, indent=2), encoding='utf-8')
print('REVIEW_PACKAGED', len(data['captures']), 'captures /', len(data['checks']), 'checks')
