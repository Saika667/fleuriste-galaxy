"""Package native models and assemble labelled crops of actual Godot screenshots."""
from pathlib import Path
import json, zipfile, shutil, html
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'out/blender'
GALLERY=OUT/'flowers_gallery';GALLERY.mkdir(exist_ok=True)
IDS=['tulip','lily','sunflower','lavender','daisy','poppy','xeno_bloom','snap_orchid','pleurelune']
NAMES=json.loads((ROOT/'data/flowers.json').read_text(encoding='utf-8'))['flowers']
FONT=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',24)
TITLE=ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf',30)
INK='#2B1E33';PAPER='#FFF6E5'
views=[('front','Face'),('back','Dos'),('top','Dessus')]

def thumb(ident,view):
    src=OUT/f'{ident}_{view}_in_game.png'
    im=Image.open(src);assert im.size==(1600,1000)
    # Crop and resize only; no paint-over or generated image content.
    return im.crop((450,60,1150,930)).resize((400,497),Image.Resampling.LANCZOS)

for ident in IDS:
    plate=Image.new('RGB',(1232,597),PAPER);draw=ImageDraw.Draw(plate)
    draw.text((16,12),NAMES[ident]['name'],font=TITLE,fill=INK)
    for i,(view,label) in enumerate(views):
        draw.text((16+i*408,55),label,font=FONT,fill=INK)
        plate.paste(thumb(ident,view),(8+i*408,90))
        shutil.copy2(OUT/f'{ident}_{view}_in_game.png',GALLERY/f'{ident}_{view}.png')
    plate.save(GALLERY/f'{ident}_views.jpg',quality=94)

def overview(ids,name,title):
    rows=(len(ids)+2)//3
    plate=Image.new('RGB',(1232,80+rows*550),PAPER);draw=ImageDraw.Draw(plate)
    draw.text((16,18),title,font=TITLE,fill=INK)
    for i,ident in enumerate(ids):
        x=8+(i%3)*408;y=80+(i//3)*550
        draw.text((x+8,y),NAMES[ident]['name'],font=FONT,fill=INK)
        plate.paste(thumb(ident,'front'),(x,y+40))
    plate.save(GALLERY/name)

overview(IDS[:6],'classiques_in_game.jpg','Fleurs classiques — captures dans Godot')
overview(IDS[6:],'aliens_in_game.jpg','Fleurs extraterrestres — captures dans Godot')

parts=['<!doctype html><html lang="fr"><meta charset="utf-8"><title>Fleurs 3D en jeu</title>',
       '<style>body{margin:28px;background:#fff6e5;color:#2b1e33;font:18px system-ui}main{max-width:1280px;margin:auto}img{max-width:100%;border-radius:8px}section{margin:40px 0}nav{display:flex;gap:18px;flex-wrap:wrap}a{color:#67437f}p{line-height:1.5}</style><main><h1>Les neuf nouvelles fleurs 3D</h1>',
       '<p>Captures réelles dans la boutique Godot. Chaque planche présente la face, le dos et le dessus. Les aperçus sont des recadrages ; les liens ouvrent les captures complètes en 1600 × 1000.</p><nav>']
parts.extend(f'<a href="#{i}">{html.escape(NAMES[i]["name"])}</a>' for i in IDS);parts.append('</nav>')
for ident in IDS:
    parts.append(f'<section id="{ident}"><h2>{html.escape(NAMES[ident]["name"])}</h2><img src="{ident}_views.jpg" alt="Face, dos et dessus"><p>Captures complètes : ')
    parts.append(' · '.join(f'<a href="{ident}_{v}.png">{label}</a>' for v,label in views));parts.append('</p></section>')
parts.append('</main></html>');(GALLERY/'index.html').write_text(''.join(parts),encoding='utf-8')

with zipfile.ZipFile(OUT/'flowers_3d_models.zip','w',zipfile.ZIP_DEFLATED) as z:
    for ident in ['rose']+IDS:
        for p in [ROOT/f'art/blender/flowers/{ident}.blend',ROOT/f'art/blender/flowers/{ident}_toon.blend',ROOT/f'assets/models/flowers/{ident}_toon.glb',ROOT/f'assets/models/flowers/{ident}_toon.json']:
            z.write(p,p.relative_to(ROOT))
    z.write(ROOT/'docs/flowers_models.md','README.md')
    for p in (ROOT/'assets/models/flowers/variants').glob('*.glb'):
        z.write(p,p.relative_to(ROOT))
    for rel in ['data/flower_variants.json','src/world/flower_visual.gd','docs/flower_variants.md']:
        if (ROOT/rel).exists():z.write(ROOT/rel,rel)
with zipfile.ZipFile(OUT/'flowers_in_game_gallery.zip','w',zipfile.ZIP_DEFLATED) as z:
    for p in GALLERY.iterdir():z.write(p,p.name)
print(json.dumps({'new_models':len(IDS),'screenshots':len(list(GALLERY.glob('*.png'))),'gallery':str(GALLERY/'index.html'),'archives':['flowers_3d_models.zip','flowers_in_game_gallery.zip']},ensure_ascii=False))
