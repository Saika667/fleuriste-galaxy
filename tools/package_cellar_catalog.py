"""Build a searchable French catalogue from actual cellar scene captures."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageStat
from zipfile import ZipFile,ZIP_DEFLATED
import json,re,html,math,textwrap
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'out/cellar_catalog'
data=json.loads((OUT/'inventory.json').read_text(encoding='utf-8'));entries=data['entries']
titles={
'cellar_view__build_room_1':'Poutres du plafond','cellar_view__build_room_2':'Plinthes sombres',
'cellar_view__build_lighting_1':'Ampoules et fils de suspension','cellar_view__build_stairs_1':'Pancarte de l’accès à la boutique',
'cellar_view__build_consoles_0':'Ensemble des quatre terminaux d’amélioration','cellar_view__build_consoles_1':'Chemin de câbles et enseigne AMÉLIORATIONS',
'cellar_view__build_counter_0':'Comptoir clandestin, sonnette et enseignes','cellar_view__build_counter_1':'Bocal de transaction et pièces','cellar_view__build_counter_2':'Porte des visiteurs et enseigne ENTRÉE DISCRÈTE',
'cellar_view__build_decor_1':'Squelette de l’ancien associé et sa pancarte','cellar_view__build_decor_3':'Barils et caisse du coin nord-est','cellar_view__build_decor_4':'Conduites du plafond et colliers','cellar_view__build_decor_5':'Flaque au sol','cellar_view__build_decor_6':'Soupirail grillagé','cellar_view__build_decor_7':'Affiche INTERDIT AUX FLICS',
'scenery__props_0':'Guirlande lumineuse multicolore','scenery__props_1':'Étagère de cinq bocaux et pancarte NE PAS BOIRE','scenery__props_2':'Vanne rouge','scenery__props_3':'Boîte à fusibles, diode et panneau haute tension',
'dressing_stairs_0':'Marches patinées, nez de marche et clous','dressing_stairs_1':'Rampe d’escalier en bois','dressing_stairs_2':'Lanterne de l’escalier','dressing_stairs_3':'Bottes oubliées et pancarte de la 7e marche',
'dressing_pipes_1':'Conduites cuivre et turquoise du mur est','dressing_pipes_2':'Colonne de tuyau et vanne rouge','dressing_pipes_3':'Conduite rouillée du mur sud','dressing_pipes_4':'Tuyau vertical au-dessus du seau',
'dressing_shelves_0':'Étagères garnies du mur sud et pancarte OBJETS TROUVÉS','dressing_shelves_1':'Étagères garnies du mur est et pancarte ZONE DE CONTREBANDE',
'dressing_crates_0':'Pile de caisses FRAGILE et CE CÔTÉ VERS LE HAUT','dressing_crates_1':'Caisses ÉCHANTILLONS et SOUPE DE FLICS','dressing_crates_2':'Tonneau vert et pancarte SIROP','dressing_crates_3':'Bidons rouge et jaune, sacs en toile',
'dressing_mushrooms_0':'Groupe de champignons lumineux','dressing_mushrooms_1':'Mousse lumineuse au pied du mur',
'dressing_dryer_0':'Corde de séchage, bouquets suspendus et pancarte','dressing_nap_corner_0':'Chat endormi','dressing_nap_corner_2':'Radio et pancarte SIESTE',
'dressing_counter_3':'Affichettes TARIFS et moyens de paiement','dressing_floor_clutter_0':'Paillasson BIENVENUE (non)','dressing_floor_clutter_1':'Colis empilés TERRE et HAUT','dressing_floor_clutter_2':'Pot fleuri destiné au compost',
}
props={1:'Bocaux sur le rebord',2:'Truelle',3:'Arrosoir / cisailles',4:'Étiquette du bac',5:'Câble et multiprise',6:'Seau au sol'}
for e in entries:
    stem=e['id'].rsplit('_',1)[0]
    if stem in titles:e['title']=titles[stem]
    m=re.match(r'planter_view__build_props_(\d+)_(\d+)',e['id'])
    if m:
        section,instance=map(int,m.groups());e['title']=props[section]+f' — variante {instance}'
        if section==3:e['title']=('Arrosoir' if instance%2 else 'Cisailles')+f' — variante {instance}'
    e['title_fr']=e['title']
    e['group']=e['category']
    if e['id'].startswith(('architecture','cellar_view__build_room')) or e['id'] in ['floor','ceiling']:e['group']='Architecture'
    if e['id'].startswith(('shelf_','dressing_shelves','scenery__props_1')):e['group']='Étagères et rangement'
    if e['id'].startswith(('lantern','lampe_','scenery__props_0')):e['group']='Éclairage'
    if e['id'].startswith(('mushroom','dressing_mushrooms')):e['group']='Champignons et végétation'
    if e['id'].startswith(('crate_','barrel_','dressing_crates')):e['group']='Caisses, tonneaux et sacs'
    for view in ['front','back']:
        p=OUT/e[view]
        with Image.open(p) as im:
            assert im.size==(1200,900)
            assert sum(ImageStat.Stat(im.resize((80,60))).stddev)>3,p
            im.convert('RGB').resize((600,450)).save(p.with_suffix('.jpg'),quality=88)
(OUT/'inventory.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',18);large=ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf',25)
for page in range(math.ceil(len(entries)/12)):
    batch=entries[page*12:(page+1)*12];contact=Image.new('RGB',(1440,70+math.ceil(len(batch)/4)*320),'#fff6e5');draw=ImageDraw.Draw(contact)
    draw.text((16,16),f'Sous-sol — catalogue des éléments · planche {page+1}',font=large,fill='#2b1e33')
    for i,e in enumerate(batch):
        x=i%4*360;y=70+i//4*320
        with Image.open(OUT/e['front']) as im:contact.paste(im.resize((352,264)),(x+4,y))
        for k,line in enumerate(textwrap.wrap(f'{e["number"]:03d} — {e["title"]}',33)[:2]):draw.text((x+7,y+267+k*21),line,font=font,fill='#2b1e33')
    contact.save(OUT/f'planche_{page+1:02d}.jpg',quality=93)
css='body{max-width:1520px;margin:28px auto;padding:0 24px;background:#fff6e5;color:#2b1e33;font:18px/1.6 system-ui}h1,h2{line-height:1.2}a{color:#386759}img{width:100%;border-radius:10px}.views,.context{display:grid;grid-template-columns:1fr 1fr;gap:18px}article{background:#fffaf2;padding:20px;margin:30px 0;border:1px solid #d7c9b8;border-radius:12px;scroll-margin-top:105px}figure{margin:0}figcaption{padding:6px 0}header{position:sticky;top:0;background:#fff6e5ee;padding:14px 0;z-index:2;backdrop-filter:blur(6px)}input,select{font:inherit;padding:9px;border:1px solid #b9a7aa;border-radius:8px;max-width:90%}.meta{font-size:14px;color:#62576c}.hidden{display:none}.note{background:#e5e9dd;padding:17px;border-radius:12px}.index{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:7px}summary{cursor:pointer}@media(max-width:700px){.views,.context{grid-template-columns:1fr}}'
page=f'<!doctype html><html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Sous-sol — catalogue des éléments</title><style>{css}</style><h1>Sous-sol — {len(entries)} références du jeu</h1>'
page+='<p>Catalogue des modèles actuels du sous-sol, photographiés séparément dans Godot. Il comprend les meubles, accessoires, équipements, éléments d’architecture, décorations et plantes. Les ensembles et leurs composants peuvent apparaître tous deux ; les exemplaires répétés et les stades de croissance sont repérés séparément.</p><p class="note">Pour montrer les éléments disponibles, la scène de relevé utilise les quatre bacs, les équipements au niveau 3, les quatre cultures à différents stades et des produits de qualités 1 à 4. Ce sont les constructeurs réels du jeu, sans nouveau design. Cette présentation n’utilise pas la sauvegarde du joueur. Les personnages visiteurs, l’interface, le son et les particules atmosphériques ne sont pas des références de mobilier.</p><p><a href="../cellar_asset_catalog.zip">Télécharger le catalogue complet (ZIP)</a> · <a href="inventaire.md">Inventaire écrit</a> · <a href="inventory.json">Relevé technique</a> · <a href="coverage.json">Audit de couverture des géométries</a></p><details open><summary>Le sous-sol dans son ensemble</summary><div class="context">'
for f,label in [('00_vue_ensemble','Vue générale'),('00_contrechamp','Contrechamp'),('00_cultures','Zone de culture'),('00_comptoir','Comptoir clandestin')]:page+=f'<figure><a href="{f}.png"><img src="{f}.png" alt="{label}"></a><figcaption>{label}</figcaption></figure>'
page+='</div></details><details><summary>Planches récapitulatives</summary>'
for i in range(math.ceil(len(entries)/12)):page+=f'<a href="planche_{i+1:02d}.jpg"><img src="planche_{i+1:02d}.jpg" loading="lazy" alt="Planche {i+1}"></a>'
page+='</details><header><input id="query" type="search" placeholder="Numéro, meuble ou accessoire…" aria-label="Rechercher"><select id="group"><option value="">Toutes les catégories</option>'
for group in dict.fromkeys(e['group'] for e in entries):page+=f'<option>{html.escape(group)}</option>'
page+='</select> <span id="count"></span></header><details><summary>Sommaire des références</summary><nav class="index">'
for e in entries:page+=f'<a href="#item-{e["number"]}">{e["number"]:03d} — {html.escape(e["title"])}</a>'
page+='</nav></details><main>'
md=f'# Catalogue du sous-sol — {len(entries)} références\n\nEnsembles, composants, exemplaires et stades ; modèles réels capturés dans Godot. État de présentation complet, sans sauvegarde joueur.\n\n| N° | Élément | Catégorie | Source |\n|---|---|---|---|\n'
for e in entries:
    title=html.escape(f'{e["number"]:03d} — {e["title"]}');dims=' × '.join(f'{x:.2f}' for x in e['size_m'])
    page+=f'<article id="item-{e["number"]}" data-group="{html.escape(e["group"])}" data-search="{html.escape((title+" "+e["id"]).lower())}"><h2>{title}</h2><p class="meta">{html.escape(e["group"])} · encombrement visuel : {dims} m · source : {html.escape(e.get("source",""))}</p><div class="views">'
    for view,label in [('front','Face / trois-quarts'),('back','Dos / contre-vue')]:
        png=e[view];jpg=Path(png).with_suffix('.jpg').name
        page+=f'<figure><a href="{png}"><img src="{jpg}" loading="lazy" alt="{title} — {label}"></a><figcaption>{label} · <a href="{png}">Image originale</a></figcaption></figure>'
    page+='</div></article>'
    md+=f'| {e["number"]:03d} | {e["title"]} | {e["group"]} | {e.get("source","")} |\n'
page+='</main><script>function filter(){const q=document.querySelector("#query").value.toLocaleLowerCase("fr");const g=document.querySelector("#group").value;let n=0;document.querySelectorAll("article").forEach(e=>{const show=(!g||e.dataset.group===g)&&e.dataset.search.includes(q);e.classList.toggle("hidden",!show);if(show)n++;});document.querySelector("#count").textContent=n+" références";}document.querySelector("#query").oninput=filter;document.querySelector("#group").onchange=filter;filter();</script></html>'
(OUT/'index.html').write_text(page,encoding='utf-8');(OUT/'inventaire.md').write_text(md,encoding='utf-8');(ROOT/'docs/cellar_asset_catalog.md').write_text(md,encoding='utf-8')
with ZipFile(ROOT/'out/cellar_asset_catalog.zip','w',ZIP_DEFLATED) as archive:
    for p in OUT.iterdir():
        if p.is_file() and p.suffix in ['.png','.jpg','.html','.md','.json']:archive.write(p,p.name)
with ZipFile(ROOT/'out/cellar_asset_catalog.zip') as archive:assert archive.testzip() is None
print(f'Verified {len(entries)} references, {len(entries)*2} isolated images, four context views, gallery and ZIP CRC.')
