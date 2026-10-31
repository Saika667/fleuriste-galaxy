from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import html

root=Path(__file__).resolve().parents[1]
out=root/'out/items_07_13_review'
shots=[('01_cinq_vases.png','Les cinq nouveaux vases — présentation dans la boutique'),
    ('08_lampe.png','08 — Lampe articulée sur l’établi'),('09_vitrine_face.png','09 — Vitrine réfrigérée'),
    ('07_roses.png','07 — Vase à roses'),('10_lys.png','10 — Vase à lys'),
    ('11_tournesols.png','11 — Vase à tournesols'),('12_lavande.png','12 — Vase à lavande'),
    ('13_coquelicots.png','13 — Vase à coquelicots'),('09_vitrine_cote.png','Vitrine — autre côté'),('00_boutique.png','Vue générale de la boutique')]
page='''<!doctype html><html lang="fr"><meta charset="utf-8"><title>Items 07–13 — modèles en jeu</title>
<style>body{margin:32px auto;max-width:1400px;padding:0 24px;background:#f6efe4;color:#243d3d;font:18px system-ui}img{width:100%;border-radius:14px}section{margin:40px 0}a{color:#197776}nav{display:flex;gap:18px;flex-wrap:wrap}</style>
<h1>Éléments 07 à 13 — modèles 3D dans le jeu</h1><p>Captures réelles dans Godot : cinq vases fleuris, lampe articulée et vitrine réfrigérée. Les vases sont alignés sur l’établi uniquement pour cette présentation ; les nouveaux modèles sont également utilisés dans la disposition normale du shop.</p>
<p><a href="../shop_items_07_13_models_and_renders.zip">Télécharger les modèles GLB, sources Blender et captures</a></p><nav>'''
page+=''.join(f'<a href="#{i}">{html.escape(title)}</a>' for i,(_,title) in enumerate(shots))+'</nav>'
for i,(filename,title) in enumerate(shots):
    assert (out/filename).is_file()
    page+=f'<section id="{i}"><h2>{html.escape(title)}</h2><a href="{filename}"><img src="{filename}" alt="{html.escape(title)}"></a></section>'
(out/'index.html').write_text(page+'</html>',encoding='utf-8')
names=['vase_rose','task_lamp','flower_fridge','vase_lily','vase_sunflower','vase_lavender','vase_poppy']
files=list(out.glob('*.png'))+[out/'index.html',root/'docs/shop_items_07_13_models.md',root/'tools/blender/shop_items_07_13.py',root/'assets/models/shop/items_07_13.json']
for name in names:
    for stem in [name]+([name+'_flowers'] if name.startswith('vase_') else []):
        files+=[root/'assets/models/shop'/f'{stem}.glb',root/'art/blender/shop'/f'{stem}.blend']
with ZipFile(root/'out/shop_items_07_13_models_and_renders.zip','w',ZIP_DEFLATED) as archive:
    for path in files:archive.write(path,path.relative_to(root))
print('SHOP_ITEMS_PACKAGE_COMPLETE',len(files),'files')
