"""Export material-only GLB variants and assemble actual Godot palette captures."""
from pathlib import Path
import json, struct, zipfile, shutil, html
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'out/blender'
DEST=ROOT/'assets/models/flowers/variants';DEST.mkdir(exist_ok=True)
GALLERY=OUT/'flower_variants_gallery';GALLERY.mkdir(exist_ok=True)
DATA=json.loads((ROOT/'data/flower_variants.json').read_text(encoding='utf-8'))['variants']
NAMES=json.loads((ROOT/'data/flowers.json').read_text(encoding='utf-8'))['flowers']
FONT=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',24)
TITLE=ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf',30)

def linear(hex_value):
    v=[int(hex_value[i:i+2],16)/255 for i in (1,3,5)]
    return [c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4 for c in v]+[1.0]

exports=[]
for ident,choices in DATA.items():
    raw=(ROOT/f'assets/models/flowers/{ident}_toon.glb').read_bytes()
    length,kind=struct.unpack_from('<I4s',raw,12);assert kind==b'JSON'
    original=json.loads(raw[20:20+length]);binary=raw[20+length:]
    for choice in choices[1:]:
        doc=json.loads(json.dumps(original));changed=[]
        for mat in doc['materials']:
            if mat['name'] in choice['colors']:
                mat['pbrMetallicRoughness']['baseColorFactor']=linear(choice['colors'][mat['name']]);changed.append(mat['name'])
        assert set(changed)==set(choice['colors'])
        encoded=json.dumps(doc,separators=(',',':')).encode();encoded+=b' '*((-len(encoded))%4)
        dest=DEST/f'{ident}_{choice["id"]}.glb'
        dest.write_bytes(struct.pack('<4sII',b'glTF',2,20+len(encoded)+len(binary))+struct.pack('<I4s',len(encoded),b'JSON')+encoded+binary)
        # Geometry bytes are deliberately identical; only named material colors differ.
        assert dest.read_bytes()[20+len(encoded):]==binary
        exports.append(dest)
    shutil.copy2(OUT/f'{ident}_variants_in_game.png',GALLERY/f'{ident}.png')

def sheet(ids,filename):
    result=Image.new('RGB',(1074,len(ids)*610+16),'#FFF6E5');d=ImageDraw.Draw(result)
    for row,ident in enumerate(ids):
        y=16+row*610;d.text((14,y),NAMES[ident]['name'],font=TITLE,fill='#2B1E33')
        img=Image.open(OUT/f'{ident}_variants_in_game.png');assert img.size==(1600,1000)
        result.paste(img.crop((280,240,1330,765)),(12,y+42))
        for i,choice in enumerate(DATA[ident]):
            label=choice['name'];x=12+145+i*250
            d.text((x-d.textlength(label,font=FONT)/2,y+574),label,font=FONT,fill='#2B1E33')
    result.save(GALLERY/filename,quality=94)

sheet(['rose','tulip','lily'],'classic_variants.jpg')
sheet(['xeno_bloom','snap_orchid','pleurelune'],'alien_variants.jpg')
page=['<!doctype html><html lang="fr"><meta charset="utf-8"><title>Variantes de fleurs</title><style>body{margin:32px;background:#fff6e5;color:#2b1e33;font:18px system-ui}main{max-width:1500px;margin:auto}img{max-width:100%}section{margin:40px 0}p{line-height:1.5}</style><main><h1>18 nouvelles palettes de fleurs</h1><p>Captures réelles dans Godot. Quatre couleurs par fleur, dont celle d’origine. Ces variantes sont visuelles : les commandes utilisent les couleurs du catalogue logique existant. Les quatre variétés exclues conservent leur palette.</p>']
for ident,choices in DATA.items():
    page.append(f'<section><h2>{html.escape(NAMES[ident]["name"])}</h2><p>De gauche à droite : '+', '.join(html.escape(c['name']) for c in choices)+f'.</p><img src="{ident}.png" alt="Quatre variantes de {ident}"></section>')
page.append('</main></html>');(GALLERY/'index.html').write_text(''.join(page),encoding='utf-8')
with zipfile.ZipFile(OUT/'flower_color_variants.zip','w',zipfile.ZIP_DEFLATED) as z:
    for p in exports:z.write(p,p.relative_to(ROOT))
    for rel in ['data/flower_variants.json','src/world/flower_visual.gd','docs/flower_variants.md']:
        z.write(ROOT/rel,rel)
    for p in GALLERY.iterdir():z.write(p,'gallery/'+p.name)
print(json.dumps({'new_glb_palettes':len(exports),'protected_geometry':'binary chunks identical to original GLB','gallery':str(GALLERY/'index.html')},ensure_ascii=False))
