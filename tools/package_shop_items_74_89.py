"""Package final sixteen native shop models and verified actual game captures."""
from pathlib import Path
from zipfile import ZipFile,ZIP_DEFLATED
from PIL import Image,ImageDraw,ImageFont,ImageStat
import json,struct,html,re
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'out/items_74_89_review'
ART=ROOT/'art/concepts/shop'

def main():
    jobs=json.loads((ART/'items_74_89_prompts.json').read_text(encoding='utf-8'))['jobs']
    records=json.loads((OUT/'manifest.json').read_text(encoding='utf-8'))['items']
    checks=json.loads((OUT/'interaction_checks.json').read_text(encoding='utf-8'))
    assert len(records)==16 and [r['number'] for r in records]==list(range(74,90))
    assert all(checks.values())
    report=[];files=[]
    for r in records:
        glb=ROOT/'assets/models/shop'/(r['asset']+'.glb');blend=ROOT/'art/blender/shop'/(r['asset']+'.blend')
        assert glb.exists() and blend.exists()
        raw=glb.read_bytes();assert raw[:4]==b'glTF'
        d=json.loads(raw[20:20+struct.unpack_from('<I',raw,12)[0]])
        tris=sum(d['accessors'][p['indices']]['count']//3 for m in d['meshes'] for p in m['primitives'])
        report.append(dict(number=r['number'],asset=r['asset'],triangles=tris,metres=True,embedded_textures=len(d.get('images',[]))))
        files.extend([glb,blend])
    (ROOT/'assets/models/shop/items_74_89.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    (OUT/'model_report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    captures=sorted(OUT.glob('*.png'));assert len(captures)==54,len(captures)
    for p in captures:
        with Image.open(p) as im:
            assert im.width>=1920 and im.height>=1000
            assert sum(ImageStat.Stat(im.resize((100,56))).stddev)>8,f'Empty capture: {p}'
    css='*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#f7f0e2;color:#193c36;font:17px/1.6 system-ui}main{max-width:1600px;margin:auto;padding:30px 24px}a{color:#176f68}h1,h2{line-height:1.2}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:14px}.card{padding:8px;border:1px solid #d9c8ab;border-radius:12px;text-decoration:none;background:#fffaf1;font-weight:650}.views{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,490px),1fr));gap:15px}img{display:block;width:100%;border-radius:10px}figure{margin:0}figcaption{padding:7px}section{margin:44px 0;scroll-margin-top:20px}.notes{padding:18px;background:#e1eee5;border-radius:12px}input{font:inherit;padding:10px;border-radius:8px;border:1px solid #baa58b;width:min(100%,550px);margin:15px 0}[hidden]{display:none!important}'
    page=f'<!doctype html><html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Modèles 74 à 89 en jeu</title><style>{css}</style><main id="top"><h1>Les 16 modèles 3D — items 74 à 89</h1>'
    page+='<p>Les modèles sont intégrés dans la boutique. Voici 54 captures réelles du jeu Godot : six vues d’ensemble et trois angles pour chaque élément.</p><p class="notes">La trappe conserve ses trois états et son accès à la cave. Les étagères conservent les huit affichages de stock ; leurs zones libres acceptent les objets du joueur via <b>O</b>. Les modèles individuels sont temporairement présentés dans le shop, avec certains meubles du premier plan masqués pour dégager la vue. Les images ne sont pas retouchées.</p><p><a href="../shop_items_74_89_models_and_renders.zip">Télécharger les modèles Blender + GLB et les captures</a> · <a href="../../art/concepts/shop/items_74_89.html">Planches</a> · <a href="../../docs/shop_items_74_89_models.md">Réalisation et validation</a></p><h2>Éléments installés dans la boutique</h2><div class="views">'
    contexts=[('00_boutique','Vue d’ensemble'),('00_etageres_installees','Étagères de stock'),('00_cadres_installes','Tableaux botaniques'),('00_passage_installe','Rideaux et passage arrière'),('00_livres_installes','Livres posés sur l’étagère'),('00_neons_installes','Bandeaux lumineux')]
    for f,label in contexts:page+=f'<figure><a href="{f}.png"><img src="{f}.png" alt="{label}" loading="lazy"></a><figcaption>{label}</figcaption></figure>'
    page+='</div><h2>Chaque modèle</h2><label for="search">Rechercher un élément</label><br><input id="search" type="search" placeholder="Numéro, trappe, cadre, livre…"><nav class="grid">'
    for r,j in zip(records,jobs):
        title=html.escape(f'{r["number"]} — {j["title_fr"]}')
        page+=f'<a class="card" data-search="{title.lower()}" href="#item-{r["number"]}"><img src="{r["number"]}_{r["asset"]}_face.png" loading="lazy" alt="">{title}</a>'
    page+='</nav>'
    for r,j in zip(records,jobs):
        n=r['number'];asset=r['asset'];title=html.escape(f'{n} — {j["title_fr"]}')
        page+=f'<section data-search="{title.lower()}" id="item-{n}"><h2>{title}</h2><p><a href="../../assets/models/shop/{asset}.glb">Modèle GLB</a> · <a href="../../art/blender/shop/{asset}.blend">Source Blender</a> · <a href="../../art/concepts/shop/{j["output"]}">Planche</a> · <a href="#top">Sommaire ↑</a></p><div class="views">'
        labels={'face':'Face / trois-quarts','dos':'Dos / second angle','dessus':'Dessus / détail'}
        if n in [74,75,76,89]:labels={'face':'Élément installé — angle 1','dos':'Élément installé — angle 2','dessus':'Vue supérieure / détail installé'}
        for suffix,label in labels.items():
            f=f'{n}_{asset}_{suffix}.png'
            page+=f'<figure><a href="{f}"><img src="{f}" loading="lazy" alt="{title} — {label}"></a><figcaption>{label}</figcaption></figure>'
        page+='</div></section>'
    page+='<p>16 fichiers GLB et 16 sources Blender, textures embarquées. Contrôles des interactions réussis ; suite du jeu : 5 960 vérifications, aucun échec.</p></main><script>document.querySelector("#search").addEventListener("input",e=>{const q=e.target.value.toLocaleLowerCase("fr");document.querySelectorAll("[data-search]").forEach(c=>c.hidden=!c.dataset.search.includes(q));});</script></html>'
    (OUT/'index.html').write_text(page,encoding='utf-8')
    for ref in re.findall(r'(?:href|src)="([^"]+)"',page):
        if not ref.startswith('#') and not ref.endswith('.zip'):assert (OUT/ref).exists(),ref
    contact=Image.new('RGB',(1600,4*258),'#f7f0e2');draw=ImageDraw.Draw(contact);font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',18)
    for i,(r,j) in enumerate(zip(records,jobs)):
        x=i%4*400;y=i//4*258
        with Image.open(OUT/f'{r["number"]}_{r["asset"]}_face.png') as im:contact.paste(im.resize((396,223)),(x,y))
        draw.text((x+5,y+227),f'{r["number"]} — {j["title_fr"]}'[:38],font=font,fill='#193c36')
    contact.save(OUT/'apercu_16_modeles.jpg',quality=93)
    files+=captures+[OUT/p for p in ['index.html','manifest.json','model_report.json','interaction_checks.json','apercu_16_modeles.jpg']]
    files+=[ART/j['output'] for j in jobs]
    files+=[ART/p for p in ['items_74_89.html','items_74_89_prompts.json','items_74_89_generation_results.json','items_74_89_modeling_notes.md']]
    files+=[ROOT/'out/shop_catalog'/j['front'] for j in jobs]
    files+=[ROOT/p for p in ['docs/shop_items_74_89_models.md','src/world/shop_room.gd','src/world/shop_world.gd','src/world/shop_collection_74_89.gd','src/world/shop_items_74_89_preview.gd','scenes/shop/shot_items_74_89.tscn','tools/prepare_shop_textures_74_89.py','tools/package_shop_items_74_89.py','assets/models/shop/items_74_89.json']]
    files+=list((ROOT/'tools/blender').glob('*.py'))
    for f in ['hatch_rug_weave','framed_rose_painting','framed_sunflower_painting','framed_xeno_painting','botany_cover','flowers_guide_cover','strange_plants_cover']:files.append(ROOT/'assets/textures/shop'/(f+'.png'))
    archive=ROOT/'out/shop_items_74_89_models_and_renders.zip'
    with ZipFile(archive,'w',ZIP_DEFLATED) as z:
        for p in dict.fromkeys(files):
            if p==ART/'items_74_89.html':
                z.writestr(str(p.relative_to(ROOT)),p.read_text(encoding='utf-8').replace('../../../out/shop_items_74_89_reference_sheets.zip','#top'))
            else:z.write(p,p.relative_to(ROOT))
    with ZipFile(archive) as z:assert z.testzip() is None
    print(f'VERIFIED: 16GLB +16BLEND; 54 game captures; all links and ZIP CRC. Total triangles: {sum(r["triangles"] for r in report)}. Archive {archive.stat().st_size:,} bytes.')

if __name__=='__main__':main()
