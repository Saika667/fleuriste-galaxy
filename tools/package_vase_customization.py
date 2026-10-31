from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import html
root=Path(__file__).resolve().parents[1]
out=root/'out/vase_customization_review'
shots=[('01_smegli.png','SMEGLI — nouveau lettrage de la vitrine'),('03_ruban_corrige.png','Ruban corrigé — pans orientés vers le bas'),('02_melanges_libres.png','Mélanges libres dans les cinq modèles de vases'),('04_menu_composition.png','Le nouveau menu de composition en jeu')]
page='''<!doctype html><html lang="fr"><meta charset="utf-8"><title>SMEGLI et vases personnalisables</title><style>body{margin:32px auto;max-width:1400px;padding:0 24px;background:#f6efe4;color:#243d3d;font:18px system-ui}img{width:100%;border-radius:14px}section{margin:40px 0}a{color:#197776}nav{display:flex;gap:18px;flex-wrap:wrap}</style><h1>SMEGLI, ruban corrigé et compositions libres</h1><p>Captures réelles de la boutique dans Godot. Tous les modèles de vases peuvent accueillir les fleurs choisies dans votre stock, sans restriction liée au décor. Ouvrir avec E en visant un vase ou le bouton Vases / V. Les compositions sont sauvegardées, et les tiges retirées retournent au stock.</p><p><a href="../vase_customization_models_and_renders.zip">Télécharger les modèles, les sources et les captures</a></p><nav>'''
page+=''.join(f'<a href="#{i}">{html.escape(title)}</a>' for i,(_,title) in enumerate(shots))+'</nav>'
for i,(filename,title) in enumerate(shots):
    assert (out/filename).is_file()
    page+=f'<section id="{i}"><h2>{html.escape(title)}</h2><a href="{filename}"><img src="{filename}" alt="{html.escape(title)}"></a></section>'
(out/'index.html').write_text(page+'</html>',encoding='utf-8')
files=list(out.glob('*.png'))+[out/'index.html',root/'docs/vase_customization.md',root/'tools/blender/shop_items_07_13.py']
for folder,extension in [('assets/models/shop','glb'),('art/blender/shop','blend')]:
    for prefix in ['vase_rose','vase_lily','vase_sunflower','vase_lavender','vase_poppy','flower_fridge','task_lamp']:
        files += list((root/folder).glob(prefix+'*.'+extension))
for relative in ['src/core/vase_arrangements.gd','src/world/shop_vase_visual.gd','src/world/vase_controller.gd','src/ui/vase_screen.gd','tests/test_vases.gd']:
    files.append(root/relative)
with ZipFile(root/'out/vase_customization_models_and_renders.zip','w',ZIP_DEFLATED) as archive:
    for path in files:archive.write(path,path.relative_to(root))
print('VASE_CUSTOMIZATION_PACKAGE_COMPLETE',len(files),'files')
