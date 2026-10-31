from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import html

root = Path(__file__).resolve().parents[1]
out = root / 'out/workbench_review'
shots = [('01_etabli_en_jeu.png','Établi dans la boutique'),('02_etabli_face.png','Vue de face'),
    ('03_plan_de_travail.png','Plan de travail et accessoires'),('04_ciseaux_detail.png','Gros plan sur les ciseaux'),
    ('05_etagere_vide.png','Étagère inférieure vide')]
page = '''<!doctype html><html lang="fr"><meta charset="utf-8"><title>Établi — rendu en jeu</title>
<style>body{margin:32px auto;max-width:1400px;padding:0 24px;background:#f6efe4;color:#243d3d;font:18px system-ui}img{width:100%;border-radius:14px}section{margin:40px 0}a{color:#197776}nav{display:flex;gap:18px;flex-wrap:wrap}</style>
<h1>Établi de fleuriste — rendu en jeu</h1><p>Captures réelles dans Godot. Modèle natif Blender avec accessoires séparés, trois roses et étagère vide. L’interaction de travail est conservée. Le stockage manuel des pots reste à développer.</p>
<p><a href="../workbench_models_and_renders.zip">Modèles GLB, sources Blender et captures</a></p><nav>'''
page += ''.join(f'<a href="#{i}">{html.escape(title)}</a>' for i,(_,title) in enumerate(shots))+'</nav>'
for i,(filename,title) in enumerate(shots):
    assert (out/filename).is_file()
    page += f'<section id="{i}"><h2>{html.escape(title)}</h2><a href="{filename}"><img src="{filename}" alt="{html.escape(title)}"></a></section>'
(out/'index.html').write_text(page+'</html>',encoding='utf-8')
files=list(out.glob('*.png'))+[out/'index.html',root/'docs/workbench_models.md',root/'tools/blender/shop_workbench.py']
files+=list((root/'assets/models/shop').glob('workbench*.glb'))+[root/'assets/models/shop/workbench_assets.json']
files+=list((root/'art/blender/shop').glob('workbench*.blend'))
with ZipFile(root/'out/workbench_models_and_renders.zip','w',ZIP_DEFLATED) as archive:
    for path in files:archive.write(path,path.relative_to(root))
print('WORKBENCH_PACKAGE_COMPLETE',len(files),'files')
