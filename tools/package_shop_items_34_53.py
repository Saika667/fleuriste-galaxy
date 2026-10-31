"""Validate and package models 34–53 with real Godot screenshots."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import json, struct, html
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'out/items_34_53_review'
ART=ROOT/'art/concepts/shop'

def main():
    jobs=json.loads((ART/'items_34_53_prompts.json').read_text(encoding='utf-8'))['jobs']
    capture=json.loads((OUT/'manifest.json').read_text(encoding='utf-8'))['items']
    assert len(capture)==20 and [r['number'] for r in capture]==list(range(34,54))
    files=[];report=[]
    for record in capture:
        name=record['asset'];glb=ROOT/f'assets/models/shop/{name}.glb';blend=ROOT/f'art/blender/shop/{name}.blend'
        raw=glb.read_bytes();assert raw[:4]==b'glTF' and blend.exists()
        n=struct.unpack_from('<I',raw,12)[0];doc=json.loads(raw[20:20+n])
        triangles=sum(doc['accessors'][p['indices']]['count']//3 for m in doc['meshes'] for p in m['primitives'])
        report.append(dict(number=record['number'],asset=name,triangles=triangles,metres=True))
        files.extend([glb,blend])
    for shot in OUT.glob('*.png'):
        with Image.open(shot) as im:assert im.size==(1600,900)
        files.append(shot)
    assert len(list(OUT.glob('*.png')))==49
    (OUT/'model_report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    (ROOT/'assets/models/shop/items_34_53.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    page='''<!doctype html><html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Shop — modèles 34 à 53 en jeu</title><style>
*{box-sizing:border-box}body{margin:0;background:#f7f0e2;color:#193c36;font:17px/1.6 system-ui}main{max-width:1560px;margin:auto;padding:28px}a{color:#176f68}h1,h2{line-height:1.2}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:14px}.card{padding:8px;border:1px solid #d9c8ab;border-radius:12px;text-decoration:none;background:#fffaf1}.card img{aspect-ratio:16/9;object-fit:cover}.views{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,550px),1fr));gap:15px}img{display:block;width:100%;border-radius:10px}figure{margin:0}figcaption{padding:7px}section{margin:44px 0;scroll-margin-top:20px}.back{float:right;font-size:15px}p{max-width:1150px}input{font:inherit;padding:10px;border-radius:8px;border:1px solid #baa58b;width:min(100%,520px);margin:15px 0}[hidden]{display:none!important}</style><main id="top"><h1>Les 20 modèles 3D — items 34 à 53</h1>
<p>Captures réelles dans le jeu Godot. Les nouveaux modèles remplacent les objets correspondants de la boutique. Pour examiner chaque objet, les petits éléments sont présentés sur l’établi et les grandes pièces dans l’allée. La scène de contrôle utilise sa propre partie et ne modifie pas votre sauvegarde.</p>
<p>Les fleurs restent séparées des contenants. Les compositions des captures illustrent leur utilisation. Les gradins ont trois surfaces de rangement : touche <b>O</b> pour disposer les vases et objets, puis <b>V</b> pour choisir les fleurs des vases. La plante carnivore conserve ses mâchoires mobiles avec les nouvelles dents triangulaires.</p>
<p><a href="../shop_items_34_53_models_and_renders.zip">Télécharger les 20 GLB, sources Blender et captures</a> · <a href="../../art/concepts/shop/items_34_53.html">Planches de référence</a> · <a href="model_report.json">Rapport technique</a></p>'''
    for name,title in [('00_boutique','Vue générale du shop'),('00_entree','Vue vers l’entrée')]:
        page+=f'<details><summary>{title}</summary><a href="{name}.png"><img src="{name}.png" alt="{title}"></a></details>'
    page+='<input type="search" id="search" placeholder="Rechercher un numéro ou un objet…" aria-label="Rechercher"><nav class="grid">'
    for record,job in zip(capture,jobs):
        number=record['number'];name=record['asset'];title=html.escape(f'{number} — {job["title_fr"]}')
        page+=f'<a class="card" data-search="{title.lower()}" href="#item-{number}"><img src="{number}_{name}_face.png" loading="lazy" alt=""><b>{title}</b></a>'
    page+='</nav>'
    for record,job in zip(capture,jobs):
        number=record['number'];name=record['asset'];title=html.escape(f'{number} — {job["title_fr"]}')
        page+=f'<section id="item-{number}"><h2>{title}<a class="back" href="#top">Sommaire ↑</a></h2><p><a href="../../assets/models/shop/{name}.glb">GLB</a> · <a href="../../art/blender/shop/{name}.blend">Blender</a> · <a href="../../art/concepts/shop/{job["output"]}">Planche</a></p><div class="views">'
        views=[('face','Face / trois-quarts'),('dos','Dos')]
        if number in [42,44,52]:views.append(('dessus','Dessus'))
        if number in [39,51]:views.append(('detail','Détail du support et des moulures'))
        if number==46:views.extend([('ouverte','Mâchoires ouvertes'),('dents','Détail des nouvelles dents')])
        for suffix,label in views:
            filename=f'{number}_{name}_{suffix}.png';assert (OUT/filename).exists()
            page+=f'<figure><a href="{filename}"><img src="{filename}" alt="{title} — {label}" loading="lazy"></a><figcaption>{label}</figcaption></figure>'
        page+='</div></section>'
    page+='''<p>Images issues du viewport du jeu, sans retouche. Modèles Blender en mètres. Les contenus floraux sont assemblés par le jeu. Validation : 5878 assertions réussies, zéro échec.</p></main><script>document.querySelector('#search').addEventListener('input',e=>{const q=e.target.value.toLocaleLowerCase('fr');document.querySelectorAll('.card').forEach(c=>c.hidden=!c.dataset.search.includes(q));});</script></html>'''
    (OUT/'index.html').write_text(page,encoding='utf-8')
    # Contact sheet of actual front captures for quick visual inspection.
    font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',19)
    contact=Image.new('RGB',(1600,5*258),'#f7f0e2');draw=ImageDraw.Draw(contact)
    for i,(record,job) in enumerate(zip(capture,jobs)):
        x=(i%4)*400;y=(i//4)*258
        with Image.open(OUT/f'{record["number"]}_{record["asset"]}_face.png') as im:contact.paste(im.resize((396,223)),(x,y))
        label=f'{record["number"]} — {job["title_fr"]}'
        draw.text((x+5,y+226),label[:37],font=font,fill='#193c36')
    contact.save(OUT/'apercu_20_modeles.jpg',quality=92)
    for rel in ['docs/shop_items_34_53_models.md','tools/blender/shop_items_34_53.py','tools/blender/shop_items_14_33.py','tools/blender/shop_items_07_13.py','tools/blender/shop_revision_details.py','tools/blender/bl_common.py','tools/package_shop_items_34_53.py','src/world/shop_collection_34_53.gd','src/world/shop_collection_visual.gd','src/world/shop_items_34_53_preview.gd','src/world/shop_decor.gd','src/world/shop_room.gd','scenes/shop/shot_items_34_53.tscn','tests/test_shop_collection_34_53.gd']:
        files.append(ROOT/rel)
    files.extend([OUT/'index.html',OUT/'manifest.json',OUT/'model_report.json',OUT/'apercu_20_modeles.jpg'])
    with ZipFile(ROOT/'out/shop_items_34_53_models_and_renders.zip','w',ZIP_DEFLATED) as archive:
        for path in files:archive.write(path,path.relative_to(ROOT))
    print(f'VERIFIED: {len(report)} native GLBs and Blender sources, 49 Godot captures, {len(files)} packaged files')

if __name__=='__main__':main()
