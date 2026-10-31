"""Present and package real Godot captures of the two compact growth props."""
from pathlib import Path
import zipfile, shutil
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'out/blender';DEST=OUT/'cannabis_compact_growth_gallery';DEST.mkdir(exist_ok=True)
STAGES={'cannabis_compact_seedling':'Petite pousse','cannabis_compact_growing':'En croissance'}
VIEWS=[('front','Face'),('back','Dos'),('top','Dessus')]
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',24)
title=ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf',30)
overview=Image.new('RGB',(1232,1070),'#FFF6E5')
page=['<!doctype html><html lang="fr"><meta charset="utf-8"><title>La compacte — deux stades en jeu</title><style>body{margin:30px auto;max-width:1280px;padding:0 20px;background:#fff6e5;color:#2b1e33;font:18px system-ui}img{max-width:100%}section{margin:40px 0}a{color:inherit}</style><h1>La compacte — deux stades en jeu</h1><p>Captures réelles dans la boutique Godot. Même pot et même cadrage pour comparer les tailles. Modèles statiques de présentation.</p>']
for row,(ident,name) in enumerate(STAGES.items()):
    sheet=Image.new('RGB',(1232,535),'#FFF6E5');draw=ImageDraw.Draw(sheet)
    draw.text((16,12),name,font=title,fill='#2B1E33')
    for col,(view,label) in enumerate(VIEWS):
        source=OUT/f'{ident}_{view}_in_game.png'
        picture=Image.open(source);assert picture.size==(1600,1000)
        # Only crop/resize the actual viewport; no image generation or repainting.
        crop=picture.crop((400,60,1200,930)).resize((400,435),Image.Resampling.LANCZOS)
        sheet.paste(crop,(8+col*408,90));draw.text((16+col*408,55),label,font=font,fill='#2B1E33')
        shutil.copy2(source,DEST/f'{ident}_{view}.png')
    sheet.save(DEST/f'{ident}_views.jpg',quality=95);overview.paste(sheet,(0,row*535))
    page.append(f'<section><h2>{name}</h2><img src="{ident}_views.jpg" alt="{name}, face dos dessus"><p>'+ ' · '.join(f'<a href="{ident}_{v}.png">{label}</a>' for v,label in VIEWS)+'</p></section>')
overview.save(DEST/'overview_in_game.jpg',quality=95)
(DEST/'index.html').write_text(''.join(page)+'</html>',encoding='utf-8')
with zipfile.ZipFile(OUT/'cannabis_compact_growth_3d.zip','w',zipfile.ZIP_DEFLATED) as archive:
    for ident in STAGES:
        for rel in [f'art/blender/plants/{ident}.blend',f'art/blender/plants/{ident}_toon.blend',f'assets/models/plants/{ident}_toon.glb',f'assets/models/plants/{ident}_toon.json',f'scenes/props/{ident}.tscn']:
            archive.write(ROOT/rel,rel)
    archive.write(ROOT/'docs/cannabis_compact_growth.md','README.md')
print('Packaged two native models and six real Godot screenshots.')
