"""Extract playable previews from the actual Godot MJPEG recording."""
from pathlib import Path
from io import BytesIO
import json
from PIL import Image

ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'out/blender'
DEST=OUT/'cannabis_growth_animation_gallery';DEST.mkdir(exist_ok=True)
raw=(OUT/'cannabis_growth_animations.avi').read_bytes();frames=[];offset=0
while True:
    start=raw.find(b'\xff\xd8\xff',offset)
    if start<0:break
    end=raw.find(b'\xff\xd9',start)+2
    if end<2:break
    frames.append((start,end));offset=end
assert len(frames)==1154, f'Expected 2 setup frames and six 192-frame animations; got {len(frames)}'

def frame(index):
    a,b=frames[index]
    return Image.open(BytesIO(raw[a:b])).convert('RGB')

names={'compact':'La compacte','elancee':'L’élancée','pourpre':'La pourpre','eventail':'L’éventail','sauvage':'La sauvage','menthe_rose':'La menthe rose'}
page=['<!doctype html><html lang="fr"><meta charset="utf-8"><title>Croissance animée dans Godot</title><style>body{margin:30px auto;max-width:1200px;padding:0 20px;background:#fff6e5;color:#2b1e33;font:18px system-ui}img,video{max-width:100%}section{margin:40px 0}a{color:inherit}</style><h1>Petite pousse → croissance → adulte</h1><p>Animations visuelles enregistrées dans la boutique Godot. Le pot garde sa taille ; la végétation se déploie et passe progressivement au modèle suivant. Durée de démonstration accélérée, indépendante des temps du gameplay.</p><video controls preload="metadata" src="../cannabis_growth_animations.mp4"></video>']
for group,(ident,name) in enumerate(names.items()):
    first=2+group*192
    palette=frame(first+174).resize((960,540)).quantize(colors=128)
    pictures=[]
    for index in range(first,first+192,2):
        picture=frame(index).resize((960,540),Image.Resampling.LANCZOS)
        pictures.append(picture.quantize(palette=palette,dither=Image.Dither.NONE))
    pictures[0].save(DEST/f'{ident}.gif',save_all=True,append_images=pictures[1:],duration=[80,90,80]*32,loop=0,optimize=True,disposal=1)
    for label,index in [('seedling',18),('transition_one',52),('growing',84),('transition_two',126),('adult',174)]:
        frame(first+index).save(DEST/f'{ident}_{label}.jpg',quality=94)
    page.append(f'<section><h2>{name}</h2><img loading="lazy" src="{ident}.gif" alt="Animation de croissance de {name}"></section>')
page.append('</html>');(DEST/'index.html').write_text(''.join(page),encoding='utf-8')
(DEST/'recording.json').write_text(json.dumps({'engine':'Godot 4.7.2','fps':24,'frames':len(frames),'duration_seconds':48,'families':list(names),'source':'../cannabis_growth_animations.avi','mode':'actual game viewport; resize and palette conversion only'},indent=2),encoding='utf-8')
print('Created six 8-second animated GIFs and 30 review frames from real Godot video.')
