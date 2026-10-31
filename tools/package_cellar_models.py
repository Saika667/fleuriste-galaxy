"""Publish actual Godot captures, editable Blender models and a 44-sheet coverage map."""
from pathlib import Path
from zipfile import ZipFile,ZIP_DEFLATED
from PIL import Image,ImageStat,ImageDraw,ImageFont
import json,html,re,textwrap,math
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'out/cellar_remodel_review';MODELS=ROOT/'assets/models/cellar';BLEND=ROOT/'art/blender/cellar'
FAMILIES={
1:[],2:['ceiling','vent_socket','filter_cartridge','duct_module'],3:['vent_socket','filter_cartridge','duct_module','duct_elbow'],4:['floor'],5:['stairs'],6:['entry_sign','step_warning','boots'],7:['bulb','garland'],8:['lantern'],9:['culture_jar','label'],10:['trowel','shears','watering_can','bucket'],11:['power_strip','cable_tray'],12:['terminal_capacity','terminal_lamp','terminal_filter','terminal_lock'],13:['cabinet','cabinet_lock'],14:['composter'],15:['counter','register','tip_jar','desk_bell','harvest_jar_q2'],16:['visitor_door','door_frame'],17:['seed_crate'],18:['sewer','sewer_sign','cone','pipes','mushroom_mint'],19:['skeleton'],20:['pipes'],21:['fusebox'],22:['window'],23:['shelf_150','culture_jar'],24:['shelf_150','shelf_200','found_sign','contraband_sign'],25:['duck','toaster'],26:['cartoon_bomb','gold_bananas'],27:['fish_jar','space_helmet'],28:['skull_mug','mini_rocket','mini_moon'],29:['shipping_crate','paper_parcel'],30:['barrel','jerrycan_red','jerrycan_yellow','sack','syrup_sign'],31:['mushroom_mint','mushroom_pink','mushroom_lilac','moss_patch'],32:['drying_line'],33:['sleeping_cat','radio','nap_sign'],34:['warning_poster','tariffs_sign','payments_sign'],35:['doormat','wilted_pot'],36:['grow_bed'],37:['bed_lamp'],38:['herb_'+s for s in ['seedling','growing','budding','ripe']],39:['lotus_'+s for s in ['seedling','growing','budding','ripe']],40:['moss_crop_'+s for s in ['seedling','growing','budding','ripe']],41:['star_vine_'+s for s in ['seedling','growing','budding','ripe']],42:['harvest_jar_q'+str(i) for i in range(1,5)],43:['single_pot'],44:['single_lamp']}
TITLES=dict(floor='Sol et plinthes — 24 × 18 m',ceiling='Plafond et poutres',vent_socket='Bouche d’aération et logement du filtre',filter_cartridge='Cartouche de filtre à charbon amovible',duct_module='Conduit métallique — module droit',duct_elbow='Coude de conduit métallique',stairs='Escalier et rampe',entry_sign='Pancarte boutique',step_warning='Pancarte de marche',boots='Bottes oubliées',bulb='Ampoule suspendue',garland='Guirlande multicolore',lantern='Lanterne',culture_jar='Bocal de culture',trowel='Truelle',shears='Cisailles',watering_can='Arrosoir',bucket='Seau métallique',label='Étiquette clipsable',power_strip='Multiprise et câble',cable_tray='Chemin de câbles',terminal_capacity='Terminal espace',terminal_lamp='Terminal lampes',terminal_filter='Terminal filtre',terminal_lock='Terminal serrure',cabinet='Armoire à récoltes',cabinet_lock='Serrure renforcée',composter='Composteur animé',counter='Comptoir de vente',register='Caisse enregistreuse',tip_jar='Pot à pourboires',desk_bell='Sonnette de comptoir',visitor_door='Porte articulée des visiteurs',door_frame='Encadrement de porte',seed_crate='Caisse et sachets de graines',sewer='Bouche d’égout articulée',sewer_sign='Pancarte sortie d’égout',cone='Cône de chantier',skeleton='Ancien associé',pipes='Tuyaux décoratifs et vanne',fusebox='Boîte à fusibles',window='Soupirail grillagé',shelf_150='Étagère murale — 1,50 m',shelf_200='Étagère murale — 2 m',duck='Canard décoratif',toaster='Grille-pain',cartoon_bomb='Bombe cartoon décorative',gold_bananas='Bananes dorées',fish_jar='Bocal à poisson',space_helmet='Casque spatial sous cloche',skull_mug='Tasse crâne',mini_rocket='Mini-fusée',mini_moon='Mini-lune',shipping_crate='Caisse de contrebande',barrel='Tonneau cerclé',jerrycan_red='Bidon rouge',jerrycan_yellow='Bidon jaune',sack='Sac en toile',mushroom_mint='Champignon menthe',mushroom_pink='Champignon rose',mushroom_lilac='Champignon lilas',moss_patch='Mousse décorative',drying_line='Corde et bouquets suspendus',sleeping_cat='Chat endormi et coussin',radio='Radio',warning_poster='Affiche interdit aux flics',tariffs_sign='Pancarte tarifs',payments_sign='Moyens de paiement',found_sign='Pancarte objets trouvés',contraband_sign='Pancarte zone de contrebande',nap_sign='Pancarte sieste',syrup_sign='Pancarte sirop',doormat='Paillasson',wilted_pot='Pot fleuri destiné au compost',paper_parcel='Colis de terre',single_pot='Pot individuel — un seul pied',single_lamp='Lampe individuelle sur pied',grow_bed='Bac de culture à quatre emplacements',bed_lamp='Rampe lumineuse de grand bac')
FAMILIES[13].extend(['cabinet_lock_electronic','cabinet_lock_heavy'])
TITLES.update(cabinet_lock_electronic='Serrure électronique — niveau 2',cabinet_lock_heavy='Serrure blindée — niveau 3')
STAGES=dict(seedling='petite pousse',growing='croissance',budding='bourgeonnement',ripe='maturité')
for kind,label in [('herb','Herbe sombre'),('lotus','Lotus xéno'),('moss_crop','Mousse de gouffre'),('star_vine','Liane d’étoile')]:
    for st,text in STAGES.items():TITLES[kind+'_'+st]=label+' — '+text
for i in range(1,5):TITLES['harvest_jar_q'+str(i)]=f'Bocal de récolte — qualité {i}'
CONTEXT=[('00_ensemble','Vue générale du sous-sol'),('01_contrechamp','Contrechamp'),('12_vue_du_dessus','Plan vu du dessus — plafond masqué'),('02_grands_bacs','Quatre grands bacs et stades des plantes'),('03_pots_individuels','Zone des pots individuels'),('04_pot_et_lampe','Un pot individuel et sa lampe'),('05_plafond_filtres','Deux aérations et conduits métalliques'),('06_filtre_detail','Logement et cartouche de filtre'),('07_comptoir','Comptoir, caisse et accessoires'),('08_stock_etageres','Armoire et étagères garnies'),('09_compost_service','Compost et équipements'),('10_escalier','Escalier d’accès'),('11_egout_decor','Égout et décorations')]

def main():
    built=json.loads((MODELS/'manifest.json').read_text());inventory=json.loads((OUT/'inventory.json').read_text(encoding='utf-8'))
    refs=json.loads((ROOT/'art/concepts/cellar/prompts.json').read_text(encoding='utf-8'))['jobs'];jobs={j['number']:j for j in refs}
    ids={r['asset'] for r in built};entries=inventory['entries']
    assert set(e['id'] for e in entries)==ids
    assert set(TITLES)==ids,(ids-set(TITLES),set(TITLES)-ids)
    assert set(FAMILIES)==set(range(1,45))
    assert set(x for group in FAMILIES.values() for x in group)==ids
    for r in built:
        for p in [MODELS/(r['asset']+'.glb'),BLEND/(r['asset']+'.blend')]:assert p.stat().st_size>1000,p
    for p in [OUT/(n+'.png') for n,_ in CONTEXT]+[OUT/e[v] for e in entries for v in ['front','back']]:
        with Image.open(p) as im:
            assert im.width>=1200 and im.height>=900
            assert sum(ImageStat.Stat(im.resize((80,60))).stddev)>4,p
            thumb=p.with_suffix('.jpg');im.convert('RGB').resize((600,450) if im.width==1200 else (960,540)).save(thumb,quality=88)
    contacts=[]
    font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',17)
    for k in range(0,len(entries),12):
        board=Image.new('RGB',(1440,960),'#f6f1e6');draw=ImageDraw.Draw(board)
        for i,e in enumerate(entries[k:k+12]):
            x=i%4*360;y=i//4*320
            with Image.open(OUT/e['front']) as im:board.paste(im.convert('RGB').resize((352,264)),(x+4,y))
            for line,text in enumerate(textwrap.wrap(TITLES[e['id']],34)[:2]):draw.text((x+6,y+268+line*21),text,font=font,fill='#203b37')
        name=f'contact_{k//12+1:02d}.jpg';board.save(OUT/name,quality=94);contacts.append(name)
    coverage={str(n):dict(title=jobs[n]['title'],assets=group,kind='Playable room layout' if n==1 else 'Native models') for n,group in FAMILIES.items()}
    (OUT/'sheet_coverage.json').write_text(json.dumps(coverage,ensure_ascii=False,indent=2),encoding='utf-8')
    notes=f'''# Sous-sol — collection intégrée

{len(built)} modèles GLB et {len(built)} sources Blender éditables couvrent les 44 familles de planches. La planche 01 correspond à l’agencement de la scène réelle. Les murs gardent leurs matériaux d’origine ; la pièce mesure désormais 24 × 18 m, hauteur 3,80 m. Les illustrations de référence ont été interprétées en géométrie native, sans textures de rendu plaquées sur les meubles.

La scène jouable scenes/cellar/cellar.tscn charge les nouveaux modèles via CellarView et CellarRemodel. Les captures proviennent de cette scène et de ses actifs réels dans Godot ; elles utilisent une sauvegarde de présentation distincte, avec quatre bacs, huit pots et des cultures à différents stades. La sauvegarde du joueur n’est pas remplacée. La vue du dessus masque uniquement le plafond pour rendre le plan lisible.

Les pots individuels possèdent une capacité effective de un, sont intégrés au comptage des cultures, poussent avec le temps du jeu et envoient la récolte dans le stock existant. Plantation, ressources, récolte unique et sauvegarde sont testées. Les grands bacs conservent quatre emplacements. Les quatre cultures ont chacune quatre modèles de stades, et l’herbe sombre réutilise la géométrie du cannabis approuvé, sans son ancien pot ni sa coque de contour.

Deux bouches au plafond portent chacune une cartouche amovible. Le joueur débloque l’équipement au terminal FILTRE, puis installe ou retire les cartouches en interaction avec les bouches. Chaque cartouche montée contribue à la réduction des nuisances existantes, reliées au système de soupçons et de police. Les anciennes sauvegardes conservent l’effet des améliorations déjà achetées jusqu’à la première gestion manuelle des cartouches.

Les étagères exposent leurs surfaces libres sous forme de métadonnées pour le système de placement ; leurs accessoires sont des modèles distincts. L’éditeur de placement de mobilier du shop n’est pas étendu au sous-sol dans cette livraison. Les bacs et huit pots sont installés dans l’agencement de la cave.

Les collisions du sol, des murs, des marches, des grands meubles et des pots sont posées séparément du rendu. Un contrôle physique avec le volume d’un joueur vérifie dix points de l’allée centrale. Les poignées de porte, les mâchoires du composteur et le couvercle d’égout restent articulés. Le commerce et les visiteurs continuent d’utiliser le système existant.

Validation : 6 279 vérifications passent, zéro échec ; compilation et capture de la scène sans erreur de script. Le runner signale encore des objets et ressources non libérés à la fermeture, déjà signalés par les exécutions précédentes.

## Sources

- tools/blender/cellar_collection.py — génération métrique et export des modèles.
- src/cellar_view/cellar_remodel.gd — installation du décor et des collisions.
- src/cellar_view/single_pot_view.gd — interactions des pots individuels.
- src/cellar_view/cellar_equipment_visual.gd — bouches et cartouches.
- tests/test_cellar_remodel.gd — capacité, ressources, croissance, récolte, filtres, migration de sauvegarde.

## Correspondance planches / modèles

'''
    for n,group in FAMILIES.items():notes+=f'{n:02d} — {jobs[n]["title"]} : '+(', '.join(group) if group else 'agencement de la scène 24 × 18 m')+'\n\n'
    (OUT/'modeling_notes.md').write_text(notes,encoding='utf-8');(ROOT/'docs/cellar_remodel.md').write_text(notes,encoding='utf-8')
    css='*{box-sizing:border-box}body{margin:0;background:#f6f1e6;color:#203b37;font:17px/1.6 system-ui}main{max-width:1620px;margin:auto;padding:28px 24px}a{color:#24786c}h1,h2{line-height:1.2}img{width:100%;border-radius:10px}.grid{display:grid;grid-template-columns:1fr 1fr;gap:18px}.hero{margin:20px 0}.note{background:#e0eadf;padding:18px;border-radius:12px}.card,article{padding:16px;border:1px solid #d7c8b1;border-radius:12px;background:#fffbf4;margin:20px 0;scroll-margin-top:100px}figure{margin:0}figcaption{padding:6px 0}.meta{font-size:14px;color:#766371}input,select{font:inherit;padding:10px;border:1px solid #b1b6a6;border-radius:8px}header{position:sticky;top:0;background:#f6f1e6ed;backdrop-filter:blur(8px);padding:10px 0;z-index:2}summary{cursor:pointer;font-weight:650}.index{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:8px}[hidden]{display:none!important}@media(max-width:750px){.grid{grid-template-columns:1fr}}'
    page=f'<!doctype html><html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Sous-sol — nouveaux modèles en jeu</title><style>{css}</style><main id="top"><h1>Sous-sol — {len(built)} modèles 3D intégrés au jeu</h1>'
    page+='<p class="note"><strong>24 × 18 m · plafond à 3,80 m · murs conservés.</strong><br>Quatre grands bacs, huit pots individuels, lampes dédiées, deux bouches reliées par des conduits métalliques et leurs filtres amovibles. Mobilier, accessoires et quatre stades de chaque culture.<br>Captures réelles dans Godot, avec un état de présentation distinct de la sauvegarde du joueur.</p><p><a href="../cellar_models_and_renders.zip">Télécharger les GLB, les fichiers Blender et les captures (ZIP)</a> · <a href="modeling_notes.md">Détails et validation</a> · <a href="sheet_coverage.json">Couverture des 44 planches</a> · <a href="interaction_checks.json">Contrôles de circulation</a> · <a href="../../art/concepts/cellar/index.html">Planches de référence</a></p>'
    page+='<figure class="hero"><a href="00_ensemble.png"><img src="00_ensemble.png" alt="Sous-sol agrandi dans le jeu"></a><figcaption>Vue générale dans la scène jouable</figcaption></figure><h2>Les zones en jeu</h2><div class="grid">'
    for name,label in CONTEXT[1:]:page+=f'<figure class="card"><a href="{name}.png"><img src="{name}.jpg" loading="lazy" alt="{label}"></a><figcaption>{label}</figcaption></figure>'
    page+='</div><details><summary>Tous les modèles en un coup d’œil</summary>'
    for name in contacts:page+=f'<a href="{name}"><img src="{name}" loading="lazy" alt="Récapitulatif des modèles"></a>'
    page+='</details><h2>44 planches — modèles correspondants</h2><details><summary>Afficher la correspondance complète</summary><nav class="index">'
    for n,group in FAMILIES.items():
        links=' · '.join(f'<a href="#asset-{html.escape(id)}">{html.escape(TITLES[id])}</a>' for id in group)
        page+=f'<p><a href="../../art/concepts/cellar/{jobs[n]["output"]}">{n:02d} — {html.escape(jobs[n]["title"])}</a><br><small>{links or "Agencement visible dans les vues d’ensemble"}</small></p>'
    page+='</nav></details><h2>Tous les modèles — face et dos</h2><header><input id="search" type="search" placeholder="Meuble, plante ou numéro de planche…"><select id="family"><option value="">Toutes les planches</option>'
    for n in range(2,45):page+=f'<option value="{n}">{n:02d} — {html.escape(jobs[n]["title"])}</option>'
    page+='</select> <span id="count"></span></header>'
    for e in entries:
        id=e['id'];families=[n for n,group in FAMILIES.items() if id in group];title=html.escape(TITLES[id]);key=html.escape((TITLES[id]+' '+id+' '+' '.join(f'{n:02d}' for n in families)).lower(),quote=True)
        page+=f'<article id="asset-{id}" data-key="{key}" data-family="{",".join(map(str,families))}"><h2>{title}</h2><p class="meta">Planches : {", ".join(f"{n:02d}" for n in families)} · <a href="../../assets/models/cellar/{id}.glb" download>Modèle GLB</a> · <a href="../../art/blender/cellar/{id}.blend" download>Source Blender</a></p><div class="grid">'
        for view,label in [('front','Face / trois-quarts'),('back','Dos / contre-vue')]:
            p=e[view];page+=f'<figure><a href="{p}"><img src="{Path(p).with_suffix(".jpg").name}" loading="lazy" alt="{title} — {label}"></a><figcaption>{label}</figcaption></figure>'
        page+='</div></article>'
    page+='</main><script>function f(){let q=document.querySelector("#search").value.toLocaleLowerCase("fr"),g=document.querySelector("#family").value,n=0;document.querySelectorAll("article").forEach(e=>{e.hidden=!(e.dataset.key.includes(q)&&(!g||e.dataset.family.split(",").includes(g)));if(!e.hidden)n++});document.querySelector("#count").textContent=n+" modèles"}document.querySelector("#search").oninput=f;document.querySelector("#family").onchange=f;f();</script></html>'
    (OUT/'index.html').write_text(page,encoding='utf-8')
    for p in re.findall(r'(?:src|href)="([^"]+)"',page):
        if p.startswith('#') or p.endswith('.zip'):continue
        assert (OUT/p).exists(),p
    bundle=ROOT/'out/cellar_models_and_renders.zip'
    with ZipFile(bundle,'w',ZIP_DEFLATED) as z:
        for r in built:
            for p in [MODELS/(r['asset']+'.glb'),BLEND/(r['asset']+'.blend')]:z.write(p,p.relative_to(ROOT))
        active={n+'.png' for n,_ in CONTEXT}|{n+'.jpg' for n,_ in CONTEXT}|set(contacts)|{'inventory.json','interaction_checks.json','sheet_coverage.json','modeling_notes.md'}
        for e in entries:
            for view in ['front','back']:active.add(e[view]);active.add(Path(e[view]).with_suffix('.jpg').name)
        for name in sorted(active):
            p=OUT/name;z.write(p,p.relative_to(ROOT))
        z.writestr('out/cellar_remodel_review/index.html',page.replace('../cellar_models_and_renders.zip','#top'))
        for p in [ROOT/'art/concepts/cellar/prompts.json',ROOT/'art/concepts/cellar/modeling_notes.md']+[ROOT/'art/concepts/cellar'/j['output'] for j in refs]:z.write(p,p.relative_to(ROOT))
        concepts=(ROOT/'art/concepts/cellar/index.html').read_text(encoding='utf-8')
        concepts=re.sub(r'<a href="../../../out/cellar_reference_sheets.zip">.*?</a>','<a href="../../../out/cellar_remodel_review/index.html">Retour aux rendus 3D</a>',concepts)
        concepts=concepts.replace('../../../out/cellar_catalog/index.html','../../../out/cellar_remodel_review/index.html')
        z.writestr('art/concepts/cellar/index.html',concepts)
        z.write(MODELS/'manifest.json','assets/models/cellar/manifest.json')
    with ZipFile(bundle) as z:assert z.testzip() is None
    print(f'Verified {len(built)} GLBs + editable BLENDs, 44 concept families, {len(entries)*2} isolated views, {len(CONTEXT)} context views, all gallery links and ZIP CRC.')
    print(f'Triangles: {sum(r["triangles"] for r in built):,}; ZIP: {bundle.stat().st_size/1048576:.1f} MiB')
if __name__=='__main__':main()
