"""Validate and package native shop collection 14–33 and actual Godot captures."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import json,struct,html

ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'art/concepts/shop'
OUT=ROOT/'out/items_14_33_review'
MODELS=ROOT/'assets/models/shop'
BLEND=ROOT/'art/blender/shop'

def main():
    jobs=json.loads((ART/'items_14_33_prompts.json').read_text(encoding='utf-8'))['jobs']
    capture=json.loads((OUT/'manifest.json').read_text(encoding='utf-8'))
    assert len(capture['items'])==20
    stats=[]; files=[]
    for item in capture['items']:
        name=item['asset']; path=MODELS/(name+'.glb')
        raw=path.read_bytes(); assert raw[:4]==b'glTF'
        n=struct.unpack_from('<I',raw,12)[0]; doc=json.loads(raw[20:20+n])
        tris=sum(doc['accessors'][p['indices']]['count']//3 for m in doc['meshes'] for p in m['primitives'])
        assert tris>100 and len(doc['meshes'])>0
        stats.append({'number':item['number'],'asset':name,'triangles':tris,'metres':True})
        assert (BLEND/(name+'.blend')).is_file()
        files += [path,BLEND/(name+'.blend')]
        views=sorted(OUT.glob(f"{item['number']:02d}_{name}_*.png"))
        assert len(views)==2
        for shot in views:
            image=shot.read_bytes()
            assert image[:8]==b'\x89PNG\r\n\x1a\n'
            assert struct.unpack_from('>II',image,16)==(1600,900)
        files+=views
    (MODELS/'items_14_33.json').write_text(json.dumps(stats,indent=2),encoding='utf-8')
    page="""<!doctype html><html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Shop — 20 nouveaux modèles en jeu</title>
<style>*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#f8f3e8;color:#183837;font:17px/1.55 system-ui}main{max-width:1600px;margin:auto;padding:30px 24px}h1{line-height:1.2}a{color:#147775}.intro{max-width:1100px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:14px}.card{display:block;background:#fffaf0;border:1px solid #d9c8aa;padding:8px;border-radius:12px;text-decoration:none;font-weight:650}.card img{width:100%;aspect-ratio:16/9;object-fit:cover;border-radius:7px}.item{margin:45px 0;scroll-margin-top:20px}.views{display:grid;grid-template-columns:1fr 1fr;gap:15px}.views img,.overview img{width:100%;height:auto;display:block;border-radius:12px}.overview{margin:20px 0}figure{margin:0}figcaption{padding:8px;color:#486966}.back{float:right;font-size:15px}input{font:inherit;background:#fffaf0;border:1px solid #b8a588;padding:10px 15px;border-radius:9px;width:min(100%,560px);margin:16px 0 22px}[hidden]{display:none!important}.top{position:fixed;right:18px;bottom:18px;background:#146e69;color:white;padding:8px 18px;border-radius:30px;text-decoration:none}.downloads{font-size:15px}.muted{color:#687773}@media(max-width:900px){.views{grid-template-columns:1fr}}
</style><main id="top"><h1>Items 14 à 33 — 20 modèles 3D dans le jeu</h1>
<p class="intro">Captures réelles du jeu dans Godot. Les modèles remplacent les anciens visuels de la boutique. Pour les voir séparément, les petits objets sont temporairement présentés sur l’établi et les meubles optionnels sur le sol du shop. Cette mise en scène de contrôle ne modifie pas votre sauvegarde.</p>
<p class="intro">Le vase orange accepte toutes les fleurs du stock via le menu Vases. Les emballages utilisent les compositions réellement créées en jeu ; le bouquet sans emballage conserve ses tiges apparentes. Le présentoir garde six emplacements pour les bouquets prêts.</p>
<p><a href="../shop_items_14_33_models_and_renders.zip">Télécharger les 20 GLB, les sources Blender et les captures</a> · <a href="../../art/concepts/shop/items_14_33.html">Planches de référence</a> · <a href="model_report.json">Rapport des modèles</a></p>
"""
    for filename,title in [('00_boutique.png','Vue générale de la boutique'),('00_mur_accessoires.png','Mur des accessoires'),('00_bocaux_installes.png','Plantes et bocaux à leur emplacement habituel')]:
        assert (OUT/filename).is_file();files.append(OUT/filename)
        page+=f'<details class="overview" {"open" if filename=="00_boutique.png" else ""}><summary>{title}</summary><a href="{filename}"><img src="{filename}" alt="{title}"></a></details>'
    page+='<h2>Les 20 éléments</h2><label for="search">Rechercher par numéro ou nom</label><br><input id="search" type="search" placeholder="Vase, bouquet, bocal…"><nav class="grid">'
    for item,job in zip(capture['items'],jobs):
        number=item['number'];name=item['asset'];title=html.escape(f'{number:02d} — {job["title_fr"]}')
        page+=f'<a class="card" data-search="{title.lower()}" href="#item-{number}"><img loading="lazy" src="{number:02d}_{name}_face.png" alt=""><span>{title}</span></a>'
    page+='</nav>'
    for item,job,stat in zip(capture['items'],jobs,stats):
        number=item['number'];name=item['asset'];title=html.escape(f'{number:02d} — {job["title_fr"]}')
        page+=f'<section class="item" id="item-{number}"><h2>{title}<a class="back" href="#top">Sommaire ↑</a></h2><p class="downloads"><a href="../../assets/models/shop/{name}.glb">Modèle GLB</a> · <a href="../../art/blender/shop/{name}.blend">Source Blender</a> · <a href="../../art/concepts/shop/{job["output"]}">Planche</a> · {stat["triangles"]:,} triangles</p><div class="views">'
        views=[('face','Face / trois-quarts'),('dessus','Dessus')] if number==17 else ([('face','Étagère installée'),('detail','Détail des supports')] if number==22 else [('face','Face / trois-quarts'),('dos','Dos')])
        for suffix,label in views:
            filename=f'{number:02d}_{name}_{suffix}.png'
            page+=f'<figure><a href="{filename}"><img loading="lazy" src="{filename}" alt="{title} — {label}"></a><figcaption>{label}</figcaption></figure>'
        page+='</div></section>'
    page+='''<p class="muted">Images issues directement du viewport Godot, sans retouche ni génération d’images. Unité des modèles : mètre. Les variantes florales sont assemblées par le jeu.</p></main><a class="top" href="#top">↑ Sommaire</a><script>document.querySelector('#search').addEventListener('input',e=>{const q=e.target.value.toLocaleLowerCase('fr');document.querySelectorAll('.card').forEach(c=>c.hidden=!c.dataset.search.includes(q));});</script></html>'''
    (OUT/'index.html').write_text(page,encoding='utf-8')
    (OUT/'model_report.json').write_text(json.dumps(stats,indent=2),encoding='utf-8')
    files += [OUT/'index.html',OUT/'manifest.json',OUT/'model_report.json',MODELS/'items_14_33.json',ROOT/'docs/shop_items_14_33_models.md',ROOT/'tools/blender/shop_items_14_33.py',ROOT/'src/world/shop_collection_visual.gd',ROOT/'src/world/shop_collection_preview.gd',ROOT/'scenes/shop/shot_items_14_33.tscn',ROOT/'src/world/furniture_factory.gd',ROOT/'src/world/shop_decor.gd',ROOT/'src/world/shop_vase_visual.gd',ROOT/'tests/test_shop_collection.gd']
    with ZipFile(ROOT/'out/shop_items_14_33_models_and_renders.zip','w',ZIP_DEFLATED) as z:
        for p in files: z.write(p,p.relative_to(ROOT))
    print(f'VERIFIED: 20 GLBs, 20 Blender sources, 43 game captures; {len(files)} packaged files')

if __name__=='__main__':main()

