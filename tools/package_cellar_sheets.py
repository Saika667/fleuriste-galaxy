"""Verify, cross-reference and package illustrated cellar concept sheets."""
from pathlib import Path
from zipfile import ZipFile,ZIP_DEFLATED
from PIL import Image
import json,html,shutil,re
ROOT=Path(__file__).resolve().parents[1];ART=ROOT/'art/concepts/cellar'

def main():
    manifest=json.loads((ART/'prompts.json').read_text(encoding='utf-8'));jobs=manifest['jobs']
    results=json.loads((ART/'generation_results.json').read_text(encoding='utf-8'))
    results.extend(json.loads(p.read_text(encoding='utf-8')) for p in ART.glob('result_*.json'))
    bynum={r['number']:r for r in results}
    assert len(bynum)==len(jobs)==44
    results=[bynum[n] for n in sorted(bynum)]
    (ART/'generation_results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
    covered=set()
    for j in jobs:
        r=bynum[j['number']]
        if r.get('output'):j['output']=r['output']
        target=ART/j['output']
        for key in ['prompt','refs']:
            if key in r:j[key]=r[key]
        if Path(r['source']).resolve()!=target.resolve():shutil.copy2(r['source'],target)
        with Image.open(target) as im:
            im.verify()
        with Image.open(target) as im:
            assert im.width>=1536 and im.height>=1024
        covered.update(j['catalogue_numbers'])
    (ART/'prompts.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
    assert covered==set(range(5,150))
    mapping={str(n):[j['number'] for j in jobs if n in j['catalogue_numbers']] for n in range(5,150)}
    (ART/'catalogue_mapping.json').write_text(json.dumps(dict(excluded_walls=[1,2,3,4],references=mapping),ensure_ascii=False,indent=2),encoding='utf-8')
    notes='''# Sous-sol — directives de modélisation et d’intégration

## Portée

44 planches de concepts, générées avec l’outil intégré image_gen, couvrent les 145 références hors murs du catalogue et les ajouts demandés. Une famille partage sa planche entre exemplaires identiques, accessoires et stades : ce ne sont pas 145 nouveaux modèles indépendants. Les murs 001 à 004 gardent leur aspect actuel. Les fichiers du jeu jouable ne sont pas modifiés par cette livraison de concepts.

## Plan de référence

La planche 01 définit le zonage proposé : 24 × 18 m, hauteur 3,80 m, contre 10 × 8 × 3 m dans la scène actuelle. Le jeu conservera la texture et le style des murs existants lors de l’extension. L’escalier débouche au sud-ouest ; vente et porte visiteurs au sud-est ; stockage à l’est ; service et compost à l’ouest ; grands bacs au nord et pots individuels au centre. Allée principale de 2 m et passages dégagés à vérifier avec le contrôleur joueur et les visiteurs lors de l’intégration. Quatre bacs et huit pots sur le plan sont des exemples de placement, pas une limite de capacité du jeu. Les vues d’ambiance des autres planches sont illustratives ; ne pas en reprendre les implantations divergentes. Corriger la seconde étiquette A de l’axonométrie 01 en B lors de la réalisation.

## Deux aérations et filtres de jeu

Exactement deux bouches A et B au plafond, reliées par des conduits métalliques argentés, avec un logement distinct pour une cartouche de filtre à charbon amovible sur chacune. Planche 02 pour l’assemblage au plafond, planche 03 pour la géométrie détaillée du kit et ses états. Créer une seule géométrie maîtresse de bouche et la dupliquer pour A et B : les différences de forme dessinées entre vues ne créent pas de troisième modèle. Aucun soupirail ou accès d’égout ne compte comme bouche supplémentaire.

Prévoir des points d’interaction accessibles au joueur pour les cartouches (emplacement vide / cartouche installée / remplacement). Les états visuels doivent pouvoir suivre les règles de jeu : absence ou inefficacité du filtre → odeur perceptible côté boutique → réaction des clients et risque d’alerte de la police. Ces interactions et règles restent à réaliser et à tester dans le jeu lors de l’intégration des nouveaux modèles. Le schéma est une fiction de gameplay, sans dimensionnement d’une installation réelle.

## Culture et placement

Les pots individuels n’acceptent qu’un seul pied chacun, via un point central unique. Pot, soucoupe, terre, plante et étiquette sont des pièces distinctes. La lampe individuelle est un objet autonome, de taille adaptée au pot, avec un socle stable ; la rampe des grands bacs reste un autre modèle. Les pots et lampes du plan 01 sont des silhouettes de placement : utiliser les planches 43 et 44 pour leurs formes définitives.

La version corrigée de la planche 44 remplace le brouillon miniature : pot de 0,48 m de diamètre et 0,42 m de hauteur, lampe sur pied de 1,40 à 2,20 m, base de 0,85 × 0,80 m et ouverture intérieure de 0,60 m. Ce sont des cotes de maillage pour le jeu. Le brouillon initial n’est pas une référence d’intégration.

Pour l’herbe sombre, réutiliser et adapter les géométries et animations cartoon existantes du cannabis dans assets/models/plants/cannabis_*_toon.glb. La planche 38 guide la palette sombre et la cohérence des quatre états, sans reconstruire inutilement les six variétés déjà produites. Conserver les feuilles nombreuses et les petites ramifications. Les stades doivent partager la même origine de tige pour l’animation de croissance. Lotus, mousse et liane ont leurs stades dédiés.

## Objets et lisibilité

Armoire 13 : retenir une hauteur cible de 1,80 m (largeur 1 m, profondeur 0,45 m) pour rendre cohérents les deux dégagements intérieurs de 0,60 m et le rangement inférieur ; la cote 1,20 m imprimée dans l’illustration est à corriger lors de la modélisation.

Étagères et comptoirs : surfaces libres, accessoires non fusionnés, supports et dégagements réels ; le joueur doit pouvoir disposer les objets. Bocaux : contenu posé au fond, couvercle séparé. Cisailles : deux boucles, un pivot et de vraies lames. Toute écriture finale doit être composée dans Godot/Blender avec une vraie police pour corriger les imperfections éventuelles des lettres dans les concepts. Les cotes des images sont des propositions ; les dimensions contradictoires d’une vue à l’autre sont à résoudre avec le plan de référence et les collisions. Aucun effet de lumière dessiné n’est une géométrie solide.

## Correspondance avec le catalogue

'''
    inventory=json.loads((ROOT/'out/cellar_catalog/inventory.json').read_text(encoding='utf-8'))['entries']
    notes+='| Réf. catalogue | Élément | Planche(s) |\n|---|---|---|\n'
    for e in inventory:
        n=e['number'];sheet='Murs conservés — pas de nouvelle planche' if n<=4 else ', '.join(f'{k:02d}' for k in mapping[str(n)])
        notes+=f'| {n:03d} | {e["title"]} | {sheet} |\n'
    notes+='\n## Briefs de production complets\n\n'
    for j in jobs:notes+=f'### {j["number"]:02d} — {j["title"]}\n\n{j["brief"]}\n\n'
    (ART/'modeling_notes.md').write_text(notes,encoding='utf-8')
    css='*{box-sizing:border-box}body{background:#f7f0df;color:#253534;font:17px/1.6 system-ui;margin:0}main{max-width:1650px;margin:auto;padding:30px 24px}a{color:#287c71}h1,h2{line-height:1.2}.note{padding:20px;background:#e3eada;border-radius:14px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:14px}.card{padding:12px;border:1px solid #cfc3aa;border-radius:12px;text-decoration:none;background:#fffbf0}.card img{width:100%;aspect-ratio:1.5;object-fit:contain}article{margin:45px 0;scroll-margin-top:20px}article img{width:100%;border-radius:12px}input{font:inherit;padding:12px;margin:20px 0;width:min(100%,600px)}small{display:block;color:#61576c}[hidden]{display:none!important}'
    page=f'<!doctype html><html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Sous-sol — 44 planches de référence</title><style>{css}</style><main id="top"><h1>Sous-sol — 44 planches pour la 3D</h1><p>Révision cartoon des éléments du sous-sol, avec vues complémentaires, variantes et détails de construction. Les répétitions du catalogue sont réunies par famille : toutes les références 005 à 149 sont couvertes. Les quatre murs actuels sont conservés.</p>'
    page+='<div class="note"><strong>Nouvel aménagement proposé : 24 × 18 m, plafond à 3,80 m.</strong><br>Deux bouches au plafond reliées par des conduits métalliques, cartouches de filtre à charbon amovibles, pots à un seul plant et lampes individuelles, bacs, stockage et espace de vente.<br>Il s’agit de planches de conception : l’agrandissement, les nouveaux modèles et les interactions ne sont pas encore intégrés dans la scène jouable. La planche 01 fixe le zonage, les planches 02–03 détaillent le plafond et la ventilation, les planches 43–44 les pots et lampes individuels.</div>'
    page+='<p><a href="../../../out/cellar_reference_sheets.zip">Télécharger les 44 planches (ZIP)</a> · <a href="modeling_notes.md">Consignes de modélisation et correspondance complète</a> · <a href="prompts.json">Prompts utilisés — outil intégré image_gen</a> · <a href="../../../out/cellar_catalog/index.html">Catalogue actuel du jeu</a></p><label for="search">Rechercher une planche ou une référence</label><br><input id="search" type="search" placeholder="Bouche, pot, comptoir, 119…"><nav class="grid">'
    for j in jobs:
        title=html.escape(f'{j["number"]:02d} — {j["title"]}');refs=', '.join(f'{n:03d}' for n in j['catalogue_numbers']) or 'Nouvelle proposition'
        key=html.escape((j['title']+' '+refs).lower(),quote=True)
        page+=f'<a class="card" data-key="{key}" href="#sheet-{j["number"]}"><img src="{j["output"]}" loading="lazy" alt="{title}">{title}<small>Catalogue : {refs}</small></a>'
    page+='</nav>'
    for j in jobs:
        title=html.escape(f'{j["number"]:02d} — {j["title"]}');refs=', '.join(f'{n:03d}' for n in j['catalogue_numbers']) or 'Nouvelle proposition'
        key=html.escape((j['title']+' '+refs).lower(),quote=True)
        page+=f'<article id="sheet-{j["number"]}" data-key="{key}"><h2>{title}</h2><small>Références du catalogue : {refs}</small><a href="{j["output"]}"><img src="{j["output"]}" loading="lazy" alt="{title}"></a><p><a href="{j["output"]}" download>Image originale</a> · <a href="#top">Sommaire</a></p></article>'
    page+='</main><script>document.querySelector("#search").oninput=e=>{let q=e.target.value.toLocaleLowerCase("fr");document.querySelectorAll("[data-key]").forEach(x=>x.hidden=!x.dataset.key.includes(q));};</script></html>'
    (ART/'index.html').write_text(page,encoding='utf-8')
    for name in re.findall(r'(?:src|href)="([^"]+)"',page):
        if name.startswith('#') or name.endswith('.zip'):continue
        assert (ART/name).exists(),name
    out=ROOT/'out/cellar_reference_sheets.zip'
    with ZipFile(out,'w',ZIP_DEFLATED) as z:
        for j in jobs:z.write(ART/j['output'],j['output'])
        for name in ['prompts.json','generation_results.json','catalogue_mapping.json','modeling_notes.md']:z.write(ART/name,name)
        portable=page.replace('../../../out/cellar_reference_sheets.zip','#top').replace('../../../out/cellar_catalog/index.html','modeling_notes.md')
        z.writestr('index.html',portable)
    with ZipFile(out) as z:assert z.testzip() is None
    print('Verified44 full-size sheets;145 non-wall catalogue references covered; gallery links and ZIP CRC valid.')
if __name__=='__main__':main()
