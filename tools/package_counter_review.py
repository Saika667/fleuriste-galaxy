"""Package actual Godot screenshots and editable/native counter assets."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import html

root = Path(__file__).resolve().parents[1]
out = root / 'out/counter_review'
shots = [
    ('01_comptoir_face.png', 'Comptoir — face côté client'),
    ('02_comptoir_dos.png', 'Comptoir — dos côté personnel'),
    ('03_comptoir_dessus.png', 'Vue du dessus'),
    ('04_caisse_detail.png', 'Caisse — clavier, écran, tiroir et ticket'),
    ('05_accessoires_detail.png', 'Clochette et bocal de bonbons en os'),
]
page = '''<!doctype html><html lang="fr"><meta charset="utf-8"><title>Comptoir — rendu en jeu</title>
<style>body{margin:32px auto;max-width:1400px;padding:0 24px;background:#f6efe4;color:#243d3d;font:18px system-ui}img{width:100%;border-radius:14px}section{margin:40px 0}a{color:#197776}nav{display:flex;gap:18px;flex-wrap:wrap}</style>
<h1>Comptoir et accessoires — rendu en jeu</h1><p>Captures réelles de la boutique dans Godot. Quatre modèles Blender/GLB intégrés : comptoir, caisse, clochette et bocal. Les bouquets sont les fleurs natives du jeu. Le tiroir est modélisé séparément, sans animation d’ouverture pour le moment.</p>
<p><a href="../counter_models_and_renders.zip">Télécharger les modèles, sources Blender et captures</a></p><nav>'''
page += ''.join(f'<a href="#{i}">{html.escape(title)}</a>' for i, (_, title) in enumerate(shots)) + '</nav>'
for i, (filename, title) in enumerate(shots):
    assert (out / filename).is_file()
    page += f'<section id="{i}"><h2>{html.escape(title)}</h2><a href="{filename}"><img src="{filename}" alt="{html.escape(title)}"></a></section>'
(out / 'index.html').write_text(page + '</html>', encoding='utf-8')
files = list(out.glob('*.png')) + [out / 'index.html', root / 'docs/counter_models.md', root / 'tools/blender/shop_counter.py']
files += list((root / 'assets/models/shop').glob('*.glb')) + [root / 'assets/models/shop/counter_assets.json']
files += list((root / 'art/blender/shop').glob('*.blend'))
with ZipFile(root / 'out/counter_models_and_renders.zip', 'w', ZIP_DEFLATED) as archive:
    for path in files:
        archive.write(path, path.relative_to(root))
print('COUNTER_PACKAGE_COMPLETE', len(files), 'files')
