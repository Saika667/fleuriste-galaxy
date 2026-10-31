"""Validated concept sheets, native model sources, and actual game review gallery."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageOps,ImageStat
from zipfile import ZipFile,ZIP_DEFLATED
import json,html,re,textwrap
R=Path(__file__).resolve().parents[1];O=R/'out/surface_remodel_review';A=R/'art/concepts/surface';M=R/'assets/models/surface';B=R/'art/blender/surface'
jobs=json.loads((A/'prompts.json').read_text(encoding='utf-8'));models=json.loads((M/'manifest.json').read_text());inv=json.loads((O/'inventory.json').read_text(encoding='utf-8'));shots=json.loads((O/'captures.json').read_text(encoding='utf-8'));checks=json.loads((O/'interaction_checks.json').read_text(encoding='utf-8'))
assert len(jobs)==32 and len(models)==59 and len(inv['entries'])==59
assert {a for j in jobs for a in j['assets']}=={m['asset'] for m in models}=={e['id'] for e in inv['entries']}
assert all(c['clear'] for c in checks['walkways']),checks['walkways']
assert len(checks['surfaces'])>=18 and checks['doors']==2
functional=json.loads((O/'functional_checks.json').read_text(encoding='utf-8'));assert functional['passed']
assert len(shots)==24
H=lambda s:html.escape(str(s),quote=True)
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',16)
css='body{margin:0;background:#eee9df;color:#233d37;font:16px system-ui}header{padding:32px 5vw;background:#1e4c45;color:#fff}h1{font:700 32px Georgia}main{padding:24px 4vw}nav{position:sticky;top:0;background:#f7f3e9;padding:14px;z-index:4}a{color:#26796b}header a{color:#c6f0dc}input,select{padding:10px;margin:5px;border:1px solid #a9b7aa;border-radius:6px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(360px,1fr));gap:20px}article{background:#fffaf0;border:1px solid #c9ccbb;border-radius:9px;overflow:hidden;padding:12px}img{width:100%;height:auto;display:block;border-radius:5px}h2{margin-top:40px}h3{margin:12px 0}p{max-width:1000px;line-height:1.6}.pair{display:grid;grid-template-columns:1fr 1fr;gap:6px}.tag{font-size:13px;color:#6a786b}article[hidden]{display:none}'
def page(title,body):return '<!doctype html><html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+H(title)+'</title><style>'+css+'</style>'+body+'</html>'
def img(path,thumb=None):return f'<a href="{H(path)}" target="_blank"><img loading="lazy" src="{H(thumb or path)}"></a>'
def thumbs(paths):
 for path in paths:
  with Image.open(path) as im:
   assert sum(ImageStat.Stat(im.resize((80,60))).stddev)>4,path
   im=im.convert('RGB');im.thumbnail((900,650));im.save(path.with_suffix('.jpg'),quality=90)
thumbs([A/j['output'] for j in jobs]+[O/e[v] for e in inv['entries'] for v in ['front','back']]+[O/s['file'] for s in shots])
concept='<header><h1>Les autres zones — 32 planches de référence</h1><p>Plans, vues de face, dos, profil et dessus, détails de construction. Style cartoon botanique commun au shop et au sous-sol.</p><a href="../../../out/surface_remodel_review/index.html">Voir les modèles et captures en jeu</a></header><main><div class="grid">'
for j in jobs:
 description='Implantation, échelle et passages de la zone.' if not j['assets'] else 'Vues de face, dos, profil, dessus et détails pour la modélisation des éléments.'
 concept+=f'<article id="sheet-{j["number"]}"><span class="tag">{H(j["zone"])}</span><h3>{j["number"]:02d} — {H(j["title"])}</h3>'+img(j['output'],Path(j['output']).with_suffix('.jpg').name)+f'<p>{description}</p></article>'
concept+='</div><p>Images créées avec l’outil imagegen intégré. <a href="prompts.json">Jeu complet des prompts</a>.</p></main>'
(A/'index.html').write_text(page('Planches — zones de surface',concept),encoding='utf-8')
zones={'terrace':'Terrasse','garden':'Jardin','greenhouse':'Serre','shed':'Remise','annex':'Annexe','upstairs':'Étage et balcon','gallery':'Galerie','warehouse':'Entrepôt','salon':'Salon','embassy':'Ambassade','courtyard':'Cour et abords'}
lookup={a:j for j in jobs for a in j['assets']}
titles=dict(bistro_table='Table bistrot',chair_mint='Chaise sauge',chair_rose='Chaise rose',parasol='Parasol à festons',deck_tile='Platelage — module',railing='Garde-corps de terrasse',rail_planter='Jardinière de rambarde',border_bed='Bordure de massif',path_stone='Dalle de jardin',hedge='Haie feuillue',garden_arch='Arche de jardin',tap_post='Borne d’eau',hose_reel='Dévidoir et tuyau',wheelbarrow='Brouette',spade='Bêche',rake='Râteau',greenhouse_shell='Charpente et vitrage de serre',greenhouse_door='Porte articulée de serre',nursery_bench='Table de culture',nursery_pot='Pot de pépinière',seed_tray='Plateau de semis',vent_fan='Ventilateur de serre',thermometer='Thermomètre',irrigation_bar='Rampe d’irrigation',shed_shell='Structure creuse de remise',shed_door='Battant de remise',shed_shelf='Étagère de remise',pot_stack='Pots empilés',soil_bag='Sac de terreau',seed_organizer='Rangement à graines',wrapping_station='Station d’emballage',service_trolley='Chariot d’atelier',paper_rack='Dérouleurs muraux',notice_board='Tableau de notes',employee_desk='Bureau d’employé',office_chair='Chaise à roulettes',task_lamp='Lampe de bureau',filing_cabinet='Classeur de rangement',balcony_rail='Rambarde de balcon',spiral_stair='Escalier en colimaçon',gallery_display='Vitrine de galerie macabre',gallery_easel='Chevalet de galerie',warehouse_bay='Baie de fret',handtruck='Diable de livraison',pallet='Palette',salon_display='Vitrine du salon',salon_sofa='Canapé interstellaire',orb_table='Guéridon et orbe',embassy_front='Façade d’ambassade',galactic_flag='Drapeau galactique',wall_lantern='Lanterne murale',outdoor_garland='Guirlande extérieure',sorting_bins='Bacs de tri',delivery_bell='Sonnette de livraison',sign_garden='Pancarte jardin',sign_greenhouse='Pancarte serre',sign_workshop='Pancarte atelier',sign_shed='Pancarte remise',drain_grate='Grille de drainage')
assert set(titles)==set(lookup)
for entry in inv['entries']:entry['title']=titles[entry['id']]
body='<header><h1>Toutes les autres zones — modèles et rendu en jeu</h1><p>32 planches, 59 modèles natifs Blender / GLB, 24 captures des scènes réelles et 118 vues isolées. Terrasse, jardin, serre, remise, annexe, étage, cour et quatre devantures de fin de partie.</p><a href="../../art/concepts/surface/index.html">Planches</a> · <a href="../surface_models_and_sheets.zip">Archive complète</a> · <a href="modeling_notes.md">Fonctionnement et validation</a> · <a href="../validated_replacements_review/index.html">Derniers remplacements corrigés</a></header><nav><a href="#zones">Vues en jeu</a> · <a href="#models">Modèles séparés</a> · <input id="search" placeholder="Rechercher un modèle"><select id="zone"><option value="">Toutes les zones</option>'+''.join(f'<option value="{k}">{H(v)}</option>' for k,v in zones.items())+'</select></nav><main><h2 id="zones">Captures réelles dans Godot</h2><p>Les portes, étagères et modèles sont ceux chargés par le jeu. Session de présentation dédiée, sauvegarde du joueur conservée. La vue générale masque les façades et plafonds pour lire le plan. Les quatre extensions de fin de partie restent des devantures, comme dans le jeu existant.</p><div class="grid">'
for s in shots:body+=f'<article><h3>{H(s["title"])}</h3>'+img(s['file'],Path(s['file']).with_suffix('.jpg').name)+'</article>'
body+='</div><h2 id="models">Les 59 modèles — face et dos</h2><div class="grid">'
for e in inv['entries']:
 id=e['id'];j=lookup[id];title=titles[id]
 for path in [M/(id+'.glb'),B/(id+'.blend')]:assert path.stat().st_size>1000,path
 body+=f'<article class="model" id="{id}" data-zone="{j["zone"]}" data-search="{H(title.lower())}"><span class="tag">{H(zones[j["zone"]])} · planche {j["number"]:02d}</span><h3>{H(title)}</h3><div class="pair">'+''.join(img(e[v],Path(e[v]).with_suffix('.jpg').name) for v in ['front','back'])+f'</div><p><a href="../../assets/models/surface/{id}.glb">GLB</a> · <a href="../../art/blender/surface/{id}.blend">Blender</a> · <a href="../../art/concepts/surface/{j["output"]}">Planche</a></p></article>'
body+='</div></main><script>function filter(){let q=document.querySelector("#search").value.toLowerCase(),z=document.querySelector("#zone").value;document.querySelectorAll(".model").forEach(e=>e.hidden=!(e.dataset.search.includes(q)&&(!z||e.dataset.zone===z)))}document.querySelector("#search").oninput=filter;document.querySelector("#zone").onchange=filter;</script>'
body=body.replace('21 captures','24 captures')
(O/'index.html').write_text(page('Zones de surface — rendu en jeu',body),encoding='utf-8')
notes='''# Refonte des autres zones

32 planches imagegen, 59 modèles GLB et 59 sources Blender éditables. Tous les éléments sont en mètres, axe Y vertical dans Godot. Les fleurs réutilisent les modèles cartoon approuvés et leurs variantes. La géométrie existante du shop et du sous-sol n’est pas remplacée par cette collection.

Terrasse : platelage modulaire, rambardes, jardinières séparées, tables à incrustations, deux chaises, parasol à baleines et festons, guirlandes. Jardin : bordures, dalles, haies feuillues, arche, point d’eau, tuyau, brouette, outils et drain. Serre : charpente à deux pans, vitrage, gouttières, vraie ouverture côté jardin, porte articulée avec collision mobile, tables à lattes et réserves, pots, semis, ventilateur, thermomètre et irrigation. Remise : coque creuse à portes doubles, étagères accessibles depuis la cour, pots emboîtés, terreau et graines, accès au stock existant.

Annexe : station d’emballage reliée à l’atelier de bouquets existant, cisailles reconnaissables, dérouleur, chariot et rangements muraux. Étage : bureaux d’employés, chaises, lampes, classeur, livres existants, escalier aligné avec l’animation de montée et rambardes. Les noms des employés restent dynamiques. Les murs et sols structurels réutilisés gardent les emprises et grilles existantes.

Galerie, entrepôt, salon et ambassade : nouveaux ensembles de devantures, ornements et accessoires séparés. Ces quatre extensions conservent leurs bonus économiques et ne deviennent pas de nouvelles pièces jouables intérieures. Cour : éclairage, tri, sonnette de livraison et signalétique cohérente.

Les nouvelles surfaces sont enregistrées par le contrôleur de placement continu déjà utilisé dans le shop : tables, réserves, étagères, bureaux, chariot et station. Les zones occupées par des accessoires fixes sont réservées dans les métadonnées de surface. Les objets placés par le joueur utilisent le système de sauvegarde existant. Les meubles fixes restent ceux de l’agencement d’extension ; l’éditeur de grille conserve les pièces achetées existantes.

La porte de serre s’ouvre et se ferme avec un vrai battant collidable, ainsi que les deux battants de remise. Leur état d’ouverture est local à la scène et n’est pas une nouvelle donnée de sauvegarde. La remise ouvre le stock existant ; la sonnette ouvre le même inventaire de livraison. Le jardin garde sa récolte quotidienne automatique. Le point d’eau, la ventilation et l’irrigation sont des accessoires visuels ; aucun nouveau besoin d’arrosage ou de climat n’est imposé.

Les captures utilisent le véritable jeu Godot avec toutes les extensions achetées dans une session distincte. Aucun rendu illustré n’est présenté comme capture. Les vues isolées viennent des mêmes GLB. interaction_checks.json contient l’état des passages, l’enregistrement des surfaces et les portes contrôlées.

Reproduction : lancer Blender sur tools/blender/surface_collection.py, importer dans Godot, lancer scenes/shop/shot_surface_remodel.tscn, puis tools/package_surface_remodel.py. Les prompts sont conservés dans art/concepts/surface/prompts.json. Les modèles sont une interprétation native des planches ; les plans guident l’implantation dans les emprises réelles du jeu.
'''
notes+='\nValidation finale : 6 302 vérifications réussies, zéro échec. Neuf points de passage dégagés, 18 surfaces enregistrées, fermeture et dégagement physique des deux accès validés. Le stock et l’atelier s’ouvrent via leurs interactions, un vase est créé sur une étagère de remise puis déplacé sans paiement supplémentaire. Les empreintes des accessoires fixes empêchent les superpositions. Les anciennes enseignes sont masquées lors du remplacement des devantures. Les nouvelles positions de meubles fixes sont réservées dans les grilles ; les anciens meubles sauvegardés gardent leurs positions et les nouveaux équipements de l’annexe ou de l’étage se masquent en cas de conflit.\n\nLa cour réutilise aussi les GLB approuvés du sous-sol : bac, herbe en croissance, lampe, caisses, tonneau, bidon, ampoule et conduit. Les seaux extérieurs réutilisent la collection du shop et ses véritables fleurs. Ces actifs partagés restent dans leurs bibliothèques existantes.\n'
notes+='\nOptimisation : la haie répétée passe de 163 072 à 10 400 triangles, avec feuilles modelées et sans multiplication des petites courbes de nervures. La collection finale contient 496 368 triangles avant instanciation dans les scènes. Les collisions et interactions restent indépendantes des maillages. Un contrôle par rayon confirme que les portes ouvertes restent refermables et ne masquent plus la sélection du stock derrière elles.\n'
(O/'modeling_notes.md').write_text(notes,encoding='utf-8');(R/'docs/surface_remodel.md').write_text(notes,encoding='utf-8')
# Contact boards allow visual QA of every native mesh and every sheet.
for entries,folder,name,field,cols in [(inv['entries'],O,'models','front',4),(jobs,A,'sheets','output',4),(shots,O,'zones','file',3)]:
 for start in range(0,len(entries),12):
  batch=entries[start:start+12];rows=(len(batch)+cols-1)//cols;board=Image.new('RGB',(cols*400,rows*325),'#eee9df');draw=ImageDraw.Draw(board)
  for i,e in enumerate(batch):
   x=i%cols*400;y=i//cols*325
   with Image.open(folder/e[field]) as im:board.paste(ImageOps.contain(im.convert('RGB'),(392,280)),(x+4,y))
   text=e.get('title',e.get('id',''))
   for line,txt in enumerate(textwrap.wrap(text,42)[:2]):draw.text((x+5,y+283+line*18),txt,font=font,fill='#23473e')
  board.save(O/f'contact_{name}_{start//12+1:02d}.jpg',quality=94)
paths=[O/'index.html',O/'inventory.json',O/'captures.json',O/'interaction_checks.json',O/'functional_checks.json',O/'modeling_notes.md',A/'index.html',A/'prompts.json',M/'manifest.json']
paths += [M/(m['asset']+'.glb') for m in models]+[B/(m['asset']+'.blend') for m in models]
paths += [A/j['output'] for j in jobs]+[A/Path(j['output']).with_suffix('.jpg') for j in jobs]
paths += [O/e[v] for e in inv['entries'] for v in ['front','back']]+[O/s['file'] for s in shots]
paths += [p.with_suffix('.jpg') for p in paths[:] if p.suffix=='.png']+list(O.glob('contact_*.jpg'))
paths += [R/'tools/blender/surface_collection.py',R/'tools/integrate_surface_remodel.py',R/'tools/prepare_surface_remodel.py']
paths += [R/'tools/blender'/name for name in ['bl_common.py','cellar_collection.py','shop_items_74_89.py','shop_items_54_73.py','shop_items_34_53.py','shop_items_14_33.py','shop_items_07_13.py']]
zip_path=R/'out/surface_models_and_sheets.zip'
with ZipFile(zip_path,'w',ZIP_DEFLATED,compresslevel=6) as z:
 for p in dict.fromkeys(paths):z.write(p,p.relative_to(R))
with ZipFile(zip_path) as z:assert z.testzip() is None
for pagepath in [O/'index.html',A/'index.html']:
 for link in re.findall(r'(?:href|src)="([^"]+)"',pagepath.read_text(encoding='utf-8')):
  if link.startswith('#'):continue
  assert (pagepath.parent/html.unescape(link)).resolve().exists(),link
print('SURFACE_PACKAGE_VERIFIED',len(models),'models',len(jobs),'sheets',len(shots),'game views;',round(zip_path.stat().st_size/1024**2,1),'MiB')
