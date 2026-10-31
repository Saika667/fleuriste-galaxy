"""Package native potted props and labelled crops of actual Godot screenshots."""
from pathlib import Path
import json,zipfile,shutil,html
from PIL import Image,ImageDraw,ImageFont

ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'out/blender';GALLERY=OUT/'cannabis_gallery';GALLERY.mkdir(exist_ok=True)
NAMES={'cannabis_compact':'La compacte','cannabis_elancee':'L’élancée','cannabis_pourpre':'La pourpre','cannabis_eventail':'L’éventail','cannabis_sauvage':'La sauvage','cannabis_menthe_rose':'La menthe rose'}
VIEWS=[('front','Face'),('back','Dos'),('top','Dessus')]
FONT=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',24);TITLE=ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf',30)
PAPER='#FFF6E5';INK='#2B1E33'
def crop(ident,view):
    image=Image.open(OUT/f'{ident}_{view}_in_game.png');assert image.size==(1600,1000)
    return image.crop((400,60,1200,930)).resize((400,435),Image.Resampling.LANCZOS)

for ident,name in NAMES.items():
    sheet=Image.new('RGB',(1232,535),PAPER);draw=ImageDraw.Draw(sheet);draw.text((16,12),name,font=TITLE,fill=INK)
    for k,(view,label) in enumerate(VIEWS):
        draw.text((16+k*408,55),label,font=FONT,fill=INK)
        sheet.paste(crop(ident,view),(8+k*408,90))
        shutil.copy2(OUT/f'{ident}_{view}_in_game.png',GALLERY/f'{ident}_{view}.png')
    sheet.save(GALLERY/f'{ident}_views.jpg',quality=94)

overview=Image.new('RGB',(1232,1050),PAPER);draw=ImageDraw.Draw(overview)
draw.text((16,18),'Les six plantes — petites ramifications et feuillage dense',font=TITLE,fill=INK)
for k,(ident,name) in enumerate(NAMES.items()):
    x=8+(k%3)*408;y=80+(k//3)*480
    draw.text((x+8,y),name,font=FONT,fill=INK);overview.paste(crop(ident,'front'),(x,y+34))
overview.save(GALLERY/'overview_in_game.jpg',quality=95)

page=['<!doctype html><html lang="fr"><meta charset="utf-8"><title>Plantes cartoon 3D</title><style>body{margin:30px;background:#fff6e5;color:#2b1e33;font:18px system-ui}main{max-width:1280px;margin:auto}img{max-width:100%;border-radius:8px}section{margin:40px 0}nav{display:flex;gap:18px;flex-wrap:wrap}p{line-height:1.5}a{color:inherit}</style><main><h1>Les six plantes au feuillage étoffé</h1><p>Captures réelles de la boutique dans Godot. Les aperçus sont recadrés ; les liens ouvrent les vues complètes en 1600 × 1000. Modèles statiques de présentation.</p><nav>']
page.extend(f'<a href="#{ident}">{html.escape(name)}</a>' for ident,name in NAMES.items());page.append('</nav>')
for ident,name in NAMES.items():
    page.append(f'<section id="{ident}"><h2>{html.escape(name)}</h2><img src="{ident}_views.jpg" alt="Face, dos et dessus de {html.escape(name)}"><p>Captures complètes : ')
    page.append(' · '.join(f'<a href="{ident}_{view}.png">{label}</a>' for view,label in VIEWS));page.append('</p></section>')
page.append('</main></html>');(GALLERY/'index.html').write_text(''.join(page),encoding='utf-8')

with zipfile.ZipFile(OUT/'cannabis_models_3d.zip','w',zipfile.ZIP_DEFLATED) as z:
    for ident in NAMES:
        for rel in [f'art/blender/plants/{ident}.blend',f'art/blender/plants/{ident}_toon.blend',f'assets/models/plants/{ident}_toon.glb',f'assets/models/plants/{ident}_toon.json',f'scenes/props/{ident}.tscn']:
            z.write(ROOT/rel,rel)
    z.write(ROOT/'docs/cannabis_models.md','README.md')
with zipfile.ZipFile(OUT/'cannabis_in_game_gallery.zip','w',zipfile.ZIP_DEFLATED) as z:
    for p in GALLERY.iterdir():z.write(p,p.name)
print(json.dumps({'models':len(NAMES),'screenshots':len(list(GALLERY.glob('*.png'))),'archive_models':6,'gallery':str(GALLERY/'index.html')},ensure_ascii=False))
