"""Package twenty Blender/GLB models and actual Godot game screenshots."""
from pathlib import Path
from zipfile import ZipFile,ZIP_DEFLATED
from PIL import Image,ImageDraw,ImageFont
import json,html,struct,re

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'out/items_54_73_review'
ART=ROOT/'art/concepts/shop'

def main():
    jobs=json.loads((ART/'items_54_73_prompts.json').read_text(encoding='utf-8'))['jobs']
    records=json.loads((OUT/'manifest.json').read_text(encoding='utf-8'))['items']
    assert len(records)==20 and [r['number'] for r in records]==list(range(54,74))
    checks=json.loads((OUT/'interaction_checks.json').read_text(encoding='utf-8'))
    assert all(checks.values())
    files=[];report=[]
    for r in records:
        asset=r['asset'];glb=ROOT/'assets/models/shop'/f'{asset}.glb';blend=ROOT/'art/blender/shop'/f'{asset}.blend'
        assert glb.exists() and blend.exists()
        raw=glb.read_bytes();assert raw[:4]==b'glTF'
        n=struct.unpack_from('<I',raw,12)[0];doc=json.loads(raw[20:20+n])
        tris=sum(doc['accessors'][p['indices']]['count']//3 for m in doc['meshes'] for p in m['primitives'])
        report.append(dict(number=r['number'],asset=asset,triangles=tris,metres=True))
        files.extend([glb,blend])
    (ROOT/'assets/models/shop/items_54_73.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    (OUT/'model_report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    captures=sorted(OUT.glob('*.png'))
    assert len(captures)==68,f'Expected68 actual captures, got{len(captures)}'
    for p in captures:
        with Image.open(p) as im:assert im.width>=1600 and im.height>=900,(p,im.size)
    files.extend(captures)
    files.extend([ROOT/'src/world/vase_controller.gd',ROOT/'assets/models/shop/items_54_73.json'])
    page='''<!doctype html><html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Shop — Modèles 54 à 73 en jeu</title><style>
*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#f7f0e2;color:#193c36;font:17px/1.6 system-ui}main{max-width:1600px;margin:auto;padding:30px 24px}h1,h2{line-height:1.2}a{color:#176f68}p{max-width:1150px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:14px}.card{padding:8px;border:1px solid #d9c8ab;border-radius:12px;text-decoration:none;background:#fffaf1;font-weight:650}.card img{aspect-ratio:16/9;object-fit:cover}.views{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,580px),1fr));gap:15px}img{display:block;width:100%;border-radius:10px}figure{margin:0}figcaption{padding:7px}section{margin:44px 0;scroll-margin-top:20px}.back{float:right;font-size:15px}input{font:inherit;padding:10px;border-radius:8px;border:1px solid #baa58b;width:min(100%,550px);margin:15px 0}.notes{padding:18px;background:#e1eee5;border-radius:12px}[hidden]{display:none!important}</style><main id="top"><h1>Les 20 modèles 3D — items 54 à 73</h1>
<p>Captures réelles du jeu Godot. Les modèles remplacent les éléments correspondants dans la boutique. Le sol et le plafond sont photographiés en place ; les objets sont aussi présentés individuellement à l’intérieur du shop pour pouvoir examiner leur design.</p>
<p class="notes">Les huit nouveaux vases acceptent les fleurs de votre choix. Ils sont disponibles dans le rangement des étagères (<b>O</b>), puis leur composition se modifie avec <b>V</b>. Les portes conservent leurs collisions et interactions ; leurs cadres restent fixes. L’horloge suit l’heure du jeu, l’enseigne suit l’état d’ouverture et le tableau affiche la vraie file d’attente. La scène de contrôle utilise une partie dédiée, sans modifier votre sauvegarde.</p>
<p><a href="../shop_items_54_73_models_and_renders.zip">Modèles Blender + GLB et captures (ZIP)</a> · <a href="../../art/concepts/shop/items_54_73.html">Planches de référence</a> · <a href="../../docs/shop_items_54_73_models.md">Détails de réalisation et validation</a></p>
<details open><summary>La boutique avec les nouveaux modèles</summary><div class="views">'''
    for f,label in [('00_boutique','Boutique — modèles intégrés'),('00_entree','Entrée et signalétique'),('00_plafond_installe','Plafond et suspensions installés'),('00_portes_ouvertes','Portes actionnées dans le shop')]:
        page+=f'<figure><a href="{f}.png"><img src="{f}.png" alt="{label}"></a><figcaption>{label}</figcaption></figure>'
    page+='</div></details><label for="search">Rechercher un élément</label><br><input id="search" type="search" placeholder="Numéro, vase, porte, horloge…"><nav class="grid">'
    for r,j in zip(records,jobs):
        title=html.escape(f'{r["number"]} — {j["title_fr"]}')
        page+=f'<a class="card" data-search="{title.lower()}" href="#item-{r["number"]}"><img src="{r["number"]}_{r["asset"]}_face.png" alt="" loading="lazy">{title}</a>'
    page+='</nav>'
    labels={'face':'Face / trois-quarts','dos':'Dos / seconde vue','ouverte':'Porte ouverte — cadre fixe','vide':'Vase vide','dessus':'Ouverture et intérieur','dessous':'Intérieur de l’abat-jour','detail':'Coutures et attaches','14h30':'Horloge à 14 h 30','ferme':'État fermé','12':'Affichage de douze clients'}
    for r,j in zip(records,jobs):
        n=r['number'];asset=r['asset'];title=html.escape(f'{n} — {j["title_fr"]}')
        page+=f'<section class="sheet" data-search="{title.lower()}" id="item-{n}"><h2>{title}<a class="back" href="#top">Sommaire ↑</a></h2><p><a href="../../assets/models/shop/{asset}.glb">GLB</a> · <a href="../../art/blender/shop/{asset}.blend">Source Blender</a> · <a href="../../art/concepts/shop/{j["output"]}">Planche</a></p><div class="views">'
        for suffix in labels:
            f=f'{n}_{asset}_{suffix}.png'
            if not (OUT/f).exists():continue
            label=labels[suffix]
            page+=f'<figure><a href="{f}"><img src="{f}" loading="lazy" alt="{title} — {label}"></a><figcaption>{label}</figcaption></figure>'
        page+='</div></section>'
    page+='''<p>Les images proviennent du viewport du jeu, sans retouche. Les compositions florales restent séparées des contenants. Les faces architecturales sont des vues en contexte, pas des fonds de studio.</p></main><script>document.querySelector('#search').addEventListener('input',e=>{const q=e.target.value.toLocaleLowerCase('fr');document.querySelectorAll('[data-search]').forEach(c=>c.hidden=!c.dataset.search.includes(q));});</script></html>'''
    revisions=ROOT/'out/items_69_72_revisions_review'
    if (revisions/'index.html').exists():
        page=page.replace('<details open>','<p class="notes"><b>Crâne, horloge et panneaux mis à jour :</b> <a href="../items_69_72_revisions_review/index.html">voir les quatre corrections et l’enseigne animée sur la porte d’entrée →</a></p><details open>',1)
        files.extend(p for p in revisions.iterdir() if p.is_file() and p.suffix in ['.html','.png','.gif','.json'])
        files.extend(ROOT/p for p in ['src/world/shop_world.gd','src/world/shop_items_69_72_revisions_preview.gd','scenes/shop/shot_items_69_72_revisions.tscn','tools/package_shop_items_69_72_revisions.py','docs/shop_items_69_72_revisions.md'])
    (OUT/'index.html').write_text(page,encoding='utf-8')
    for ref in re.findall(r'(?:src|href)="([^"]+)"',page):
        if not ref.startswith(('#','http')) and not ref.endswith('.zip'):assert (OUT/ref).exists(),ref
    contact=Image.new('RGB',(1600,5*258),'#f7f0e2');draw=ImageDraw.Draw(contact);font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',18)
    for i,(r,j) in enumerate(zip(records,jobs)):
        x=i%4*400;y=i//4*258
        with Image.open(OUT/f'{r["number"]}_{r["asset"]}_face.png') as im:contact.paste(im.resize((396,223)),(x,y))
        draw.text((x+5,y+227),f'{r["number"]} — {j["title_fr"]}'[:37],font=font,fill='#193c36')
    contact.save(OUT/'apercu_20_modeles.jpg',quality=93)
    for rel in ['tools/blender/shop_items_54_73.py','tools/blender/shop_items_34_53.py','tools/blender/shop_items_34_53_revision.py','tools/blender/shop_items_14_33.py','tools/blender/shop_items_07_13.py','tools/blender/shop_revision_details.py','tools/blender/bl_common.py','tools/package_shop_items_54_73.py','src/world/shop_collection_54_73.gd','src/world/shop_items_54_73_preview.gd','src/world/shop_vase_visual.gd','src/world/shop_room.gd','src/world/shop_decor.gd','src/core/surface_layout.gd','scenes/shop/shot_items_54_73.tscn','tests/test_shop_collection_54_73.gd','docs/shop_items_54_73_models.md']:
        files.append(ROOT/rel)
    files.extend([OUT/n for n in ['index.html','manifest.json','model_report.json','interaction_checks.json','apercu_20_modeles.jpg']])
    with ZipFile(ROOT/'out/shop_items_54_73_models_and_renders.zip','w',ZIP_DEFLATED) as z:
        for p in files:z.write(p,p.relative_to(ROOT))
    with ZipFile(ROOT/'out/shop_items_54_73_models_and_renders.zip') as z:assert z.testzip() is None
    print(f'VERIFIED:20 native GLBs +20 Blender sources; {len(captures)} real game captures; gallery links and ZIP CRC valid.')

if __name__=='__main__':main()
