"""Package ten native growth props and thirty actual Godot screenshots."""
from pathlib import Path
import json,zipfile,shutil
from PIL import Image,ImageDraw,ImageFont

ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'out/blender'
DEST=OUT/'cannabis_remaining_growth_gallery';DEST.mkdir(exist_ok=True)
FAMILIES={'elancee':'L’élancée','pourpre':'La pourpre','eventail':'L’éventail','sauvage':'La sauvage','menthe_rose':'La menthe rose'}
STAGES=[('seedling','Petite pousse'),('growing','En croissance')]
VIEWS=[('front','Face'),('back','Dos'),('top','Dessus')]
FONT=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',24)
TITLE=ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf',30)
PAPER='#FFF6E5';INK='#2B1E33'

def crop(ident,view):
    picture=Image.open(OUT/f'{ident}_{view}_in_game.png');assert picture.size==(1600,1000)
    return picture.crop((400,60,1200,930)).resize((400,435),Image.Resampling.LANCZOS)

overview=Image.new('RGB',(832,5*495+60),PAPER);draw=ImageDraw.Draw(overview)
draw.text((16,12),'Deux stades — rendus réels dans Godot',font=TITLE,fill=INK)
page=['<!doctype html><html lang="fr"><meta charset="utf-8"><title>Cinq plantes : deux stades en jeu</title><style>body{margin:30px auto;max-width:1280px;padding:0 20px;background:#fff6e5;color:#2b1e33;font:18px system-ui}img{max-width:100%}section{margin:45px 0}a{color:inherit}</style><h1>Les cinq autres plantes — deux stades en jeu</h1><p>Captures réelles dans Godot : petite pousse et en croissance. Le pot et le cadrage restent identiques entre les deux stades d’une même variété. Modèles statiques de présentation.</p>']
all_ids=[]
for row,(family,name) in enumerate(FAMILIES.items()):
    sheet=Image.new('RGB',(1232,1120),PAPER);draw_sheet=ImageDraw.Draw(sheet)
    draw_sheet.text((16,12),name,font=TITLE,fill=INK)
    for stage_index,(stage,label) in enumerate(STAGES):
        ident='cannabis_'+family+'_'+stage;all_ids.append(ident)
        y=60+stage_index*530
        draw_sheet.text((16,y),label,font=TITLE,fill=INK)
        for col,(view,view_label) in enumerate(VIEWS):
            draw_sheet.text((16+col*408,y+40),view_label,font=FONT,fill=INK)
            sheet.paste(crop(ident,view),(8+col*408,y+80))
            shutil.copy2(OUT/f'{ident}_{view}_in_game.png',DEST/f'{ident}_{view}.png')
        x=8+stage_index*416;oy=60+row*495
        draw.text((x+6,oy),name+' — '+label,font=FONT,fill=INK)
        overview.paste(crop(ident,'front'),(x,oy+40))
    sheet.save(DEST/f'{family}_views.jpg',quality=95)
    page.append(f'<section><h2>{name}</h2><img src="{family}_views.jpg" alt="Deux stades de {name}, face dos et dessus">')
    for stage,label in STAGES:
        page.append('<p>'+label+' : '+' · '.join(f'<a href="cannabis_{family}_{stage}_{v}.png">{vl}</a>' for v,vl in VIEWS)+'</p>')
    page.append('</section>')
overview.save(DEST/'overview_in_game.jpg',quality=95)
(DEST/'index.html').write_text(''.join(page)+'</html>',encoding='utf-8')
with zipfile.ZipFile(OUT/'cannabis_remaining_growth_3d.zip','w',zipfile.ZIP_DEFLATED) as archive:
    for ident in all_ids:
        report=json.loads((ROOT/f'assets/models/plants/{ident}_toon.json').read_text())
        assert report['features']['stage'] in ('seedling','growing')
        assert report['features']['flower_clusters']==0 if ident.endswith('_seedling') else report['features']['flower_clusters']>0
        for rel in [f'art/blender/plants/{ident}.blend',f'art/blender/plants/{ident}_toon.blend',f'assets/models/plants/{ident}_toon.glb',f'assets/models/plants/{ident}_toon.json',f'scenes/props/{ident}.tscn']:
            archive.write(ROOT/rel,rel)
    archive.write(ROOT/'docs/cannabis_remaining_growth.md','README.md')
with zipfile.ZipFile(OUT/'cannabis_remaining_growth_renders.zip','w',zipfile.ZIP_DEFLATED) as archive:
    for path in DEST.iterdir():archive.write(path,path.name)
print('Packaged 10 native models, 30 Godot screenshots, 5 two-stage contact sheets.')
