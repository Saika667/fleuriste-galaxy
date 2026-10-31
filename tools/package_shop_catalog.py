"""Indexed design catalogue assembled from actual isolated Godot renders."""
from pathlib import Path
from html import escape
import json, math, textwrap, zipfile
from PIL import Image,ImageDraw,ImageFont

ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'out/shop_catalog'
data=json.loads((OUT/'inventory.json').read_text(encoding='utf-8'));entries=data['entries']
FONT=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',20)
SMALL=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',16)
TITLE=ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf',27)
PAPER='#FFF6E5';INK='#2B1E33'

def group(entry):
    id=entry['id']
    if id in ['counter','workbench','fridge','display','plant_pot','rug']:return 'Mobilier principal'
    if id.startswith(('bucket_','vase_','bouquet_','stand_')) or id=='coffin_planter':return 'Fleurs et contenants'
    if id.startswith(('pot_','hanging_')) or id in ['big_plant','flytrap','flowered_skull']:return 'Plantes décoratives'
    if id.startswith(('jar_','book_','crate_','workbench_')) or id in ['cash_register','counter_bell','candy_jar']:return 'Accessoires et rangement'
    if id.startswith(('shelf_','stock_shelf_','poster_','framed_')) or id in ['clock','chalkboard','rip_sign','pegboard','open_sign','queue_sign']:return 'Décor mural et signalétique'
    if id.startswith(('pendant_','neon_')) or id in ['curtains','back_neon','bunting']:return 'Éclairage et textiles'
    return 'Architecture et accès'

translations={'eyes':'yeux','bulbs':'bulbes','slime':'gel fluorescent','teeth':'dents','seeds':'graines','ivy':'lierre','skull':'crâne','skulls':'crânes','flowers':'fleurs','seedlings':'jeunes plants','pink':'rose','white':'blanc','yellow':'jaune','purple':'violet','red':'rouge','orange':'orange','front':'entrée','back':'service','silk':'soie','paper':'kraft','none':'sans emballage','black':'noir','rose':'roses','tulip':'tulipes','lily':'lys','sunflower':'tournesols','lavender':'lavande','daisy':'marguerites','poppy':'coquelicots','xeno_bloom':'fleurs xéno'}
for entry in entries:
    title=entry['title']
    for key,value in translations.items():
        if title.endswith('— '+key):title=title[:-(len(key))]+value
        if title.endswith('emballage '+key):title=title[:-(len(key))]+value
    entry['title_fr']=title;entry['group']=group(entry)
    entry['code_source']='src/world/furniture_factory.gd' if entry['id'] in ['counter','workbench','fridge','display','plant_pot','rug'] or entry['id'].startswith(('vase_','bouquet_','workbench_')) or entry['id'] in ['cash_register','counter_bell','candy_jar'] else ('src/world/shop_decor.gd' if entry['id'].startswith(('bucket_','jar_','crate_','pot_','stand_','poster_','shelf_')) or entry['id'] in ['big_plant','flytrap','bunting','pegboard','chalkboard','rip_sign'] else 'src/world/shop_room.gd')
    for view in ['front','back']:
        picture=Image.open(OUT/entry[view]);assert picture.size==(1200,900)
        picture.resize((600,450),Image.Resampling.LANCZOS).convert('RGB').save(OUT/(entry[view].replace('.png','.jpg')),quality=91)

def contact(items,path,title):
    cols=4;rows=math.ceil(len(items)/cols)
    sheet=Image.new('RGB',(1440,rows*340+70),PAPER);draw=ImageDraw.Draw(sheet)
    draw.text((16,15),title,font=TITLE,fill=INK)
    for index,entry in enumerate(items):
        x=(index%cols)*360;y=70+(index//cols)*340
        picture=Image.open(OUT/entry['front']).resize((352,264),Image.Resampling.LANCZOS)
        sheet.paste(picture,(x+4,y))
        label=f"{entry['number']:02d} — {entry['title_fr']}"
        for line_index,line in enumerate(textwrap.wrap(label,width=31)[:3]):
            draw.text((x+8,y+269+line_index*21),line,font=FONT,fill=INK)
    sheet.save(path,quality=94)

for page in range(math.ceil(len(entries)/12)):
    contact(entries[page*12:(page+1)*12],OUT/f'planche_{page+1:02d}.jpg',f'Shop — inventaire séparé · planche {page+1}')
featured=['counter','workbench','fridge','display','bucket_0','bucket_1','stand_1','coffin_planter','clock','pegboard','curtains','hanging_flowered']
contact([next(e for e in entries if e['id']==id) for id in featured],OUT/'apercu_elements.jpg','Shop — meubles et décorations, modèles actuels')

style='body{max-width:1500px;margin:30px auto;padding:0 24px;background:#fff6e5;color:#2b1e33;font:18px system-ui}h1{font-size:36px}p{line-height:1.55}img{max-width:100%;height:auto;border-radius:8px}.views,.context{display:grid;grid-template-columns:1fr 1fr;gap:16px}article{background:#fffaf2;padding:20px;margin:28px 0;border:1px solid #d7c9b8;border-radius:12px}figure{margin:0}figcaption{padding:8px 0}a{color:inherit}header{position:sticky;top:0;background:#fff6e5ed;padding:12px 0;z-index:2;backdrop-filter:blur(6px)}input,select{font:inherit;padding:9px;border:1px solid #b9a7aa;border-radius:8px;max-width:90%}.meta{font-size:15px;color:#62576c}.hidden{display:none}nav{display:flex;gap:15px;flex-wrap:wrap}summary{cursor:pointer}button{font:inherit;cursor:pointer} @media(max-width:700px){.views,.context{grid-template-columns:1fr}}'
page=[f'<!doctype html><html lang="fr"><meta charset="utf-8"><title>Shop — catalogue des éléments 3D</title><style>{style}</style><h1>Shop — {len(entries)} références pour retravailler les modèles</h1><p>Géométrie réelle du jeu capturée séparément dans Godot. Un numéro stable identifie chaque meuble, accessoire ou variante. Les objets répétés sont regroupés ; les composants de certains meubles sont aussi présentés à part.</p><p>Les fleurs 3D existantes remplacent les formes simplifiées dans les contenants fleuris. Les vases de stock vides respectent l’inventaire. Le présentoir optionnel est garni pour montrer son usage. Les dessins floraux des affiches et cadres restent des motifs graphiques.</p><details><summary>Voir le shop avec les fleurs intégrées</summary><div class="context"><a href="shop_overview.png"><img src="shop_overview.png" alt="Shop avec fleurs natives"></a><a href="shop_flowers.png"><img src="shop_flowers.png" alt="Gradins et fleurs 3D en jeu"></a></div><a href="shop_reverse.png">Contrechamp de la boutique</a></details><p><a href="inventaire.md">Inventaire écrit</a> · <a href="inventory.json">Relevé technique</a></p><details><summary>Planches récapitulatives numérotées</summary>']
for index in range(math.ceil(len(entries)/12)):
    page.append(f'<a href="planche_{index+1:02d}.jpg"><img loading="lazy" src="planche_{index+1:02d}.jpg" alt="Planche {index+1}"></a>')
page.append('</details><header><input id="query" type="search" placeholder="Chercher un numéro ou un élément…" aria-label="Rechercher"><select id="group" aria-label="Catégorie"><option value="">Toutes les catégories</option>')
page.extend(f'<option>{escape(category)}</option>' for category in dict.fromkeys(e['group'] for e in entries))
page.append('</select> <span id="count"></span></header><main>')
for entry in entries:
    title=f"{entry['number']:02d} — {entry['title_fr']}"
    dims=' × '.join(f'{v:.2f}' for v in entry['size_m'])
    note=' · État du stock : vase vide' if entry['id'].startswith('vase_') and not entry['native_flowers'] else ''
    page.append(f'<article id="asset-{entry["number"]:02d}" data-group="{escape(entry["group"])}" data-search="{escape(title.lower()+" "+entry["id"])}"><h2>{escape(title)}</h2><p class="meta">{escape(entry["group"])} · {dims} m · {entry["native_flowers"]} fleurs natives{note}</p><div class="views">')
    for view,label in [('front','Vue principale'),('back','Vue opposée')]:
        page.append(f'<figure><a href="{entry[view]}"><img loading="lazy" src="{entry[view].replace(".png",".jpg")}" alt="{escape(title)} — {label}"></a><figcaption>{label} — <a href="{entry[view]}">PNG original</a></figcaption></figure>')
    page.append(f'</div><p class="meta">Identifiant : {entry["id"]} · Source : {entry["code_source"]}</p></article>')
if (OUT/'shop_merged_check.png').exists():
    page.append('<p><a href="shop_merged_check.png">Vérification dans le shop en fonctionnement normal, avec fusion des éléments statiques activée</a></p>')
page.append('</main><script>const q=document.querySelector("#query"),g=document.querySelector("#group"),cards=[...document.querySelectorAll("article")];function filter(){let n=0;for(const c of cards){const yes=c.dataset.search.includes(q.value.toLowerCase().trim())&&(!g.value||c.dataset.group===g.value);c.classList.toggle("hidden",!yes);if(yes)n++}document.querySelector("#count").textContent=n+" / "+cards.length+" références"}q.addEventListener("input",filter);g.addEventListener("change",filter);filter();</script></html>')
(OUT/'index.html').write_text(''.join(page),encoding='utf-8')
notes=['# Shop — catalogue des modèles actuels','',f'{len(entries)} références distinctes, deux vues isolées par référence et trois vues en contexte. Les numéros incluent variantes et sous-ensembles ; les objets répétés sont regroupés.','', 'Les images isolent la géométrie du jeu dans un studio Godot. Elles ne sont pas des concepts générés. Les fleurs natives sont intégrées aussi aux objets du jeu via leurs constructeurs partagés. Le présentoir est garni pour la présentation ; les vases de stock reflètent le stock de la session de référence.','', '| N° | Élément | Identifiant | Fleurs natives |','|---|---|---|---|']
notes.extend(f'| {e["number"]:02d} | {e["title_fr"]} | {e["id"]} | {e["native_flowers"]} |' for e in entries)
(OUT/'inventaire.md').write_text('\n'.join(notes),encoding='utf-8')
(ROOT/'docs/shop_asset_catalog.md').write_text('\n'.join(notes)+'\n\nRégénération : scène `scenes/shop/shot_shop_catalog.tscn`, arguments `-- shop_catalog nomerge`, puis `tools/package_shop_catalog.py`. Le mode catalogue extrait les géométries avant fusion, les capture dans un SubViewport propre et ne modifie pas la sauvegarde joueur. Les croquis imprimés des affiches, les feuilles vertes du lierre et la plante carnivore spécifique restent leurs modèles existants. Les primitives de fleurs présentes dans la rue ou les bâtiments voisins ne font pas partie de cette passe sur le shop.\n',encoding='utf-8')
(OUT/'inventory.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
with zipfile.ZipFile(ROOT/'out/shop_catalog_reference.zip','w',zipfile.ZIP_DEFLATED) as archive:
    files={'index.html','inventory.json','inventaire.md','apercu_elements.jpg','shop_overview.png','shop_reverse.png','shop_flowers.png'}
    if (OUT/'shop_merged_check.png').exists():files.add('shop_merged_check.png')
    files.update(f'planche_{index+1:02d}.jpg' for index in range(math.ceil(len(entries)/12)))
    for entry in entries:
        for view in ['front','back']:
            files.add(entry[view]);files.add(entry[view].replace('.png','.jpg'))
    for name in sorted(files):archive.write(OUT/name,name)
print(f'Packaged {len(entries)} references, {len(entries)*2} isolated views, {math.ceil(len(entries)/12)} numbered sheets, searchable gallery and ZIP.')
