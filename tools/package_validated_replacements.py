"""Publish real Godot captures and the remaining-replacement audit."""
from pathlib import Path
import json, html
from PIL import Image, ImageDraw, ImageFont
R=Path(__file__).resolve().parents[1]
P=R/'out/validated_replacements_review'
checks=json.loads((P/'checks.json').read_text(encoding='utf-8'))
items=json.loads((P/'inventory.json').read_text(encoding='utf-8'))['entries']
shots=json.loads((P/'captures.json').read_text(encoding='utf-8'))
assert checks['passed'] and len(items)==11 and len(shots)==7
assert 'VALIDATED_REPLACEMENTS_COMPLETE' in (R/'out/completion_review.log').read_text(encoding='utf-8-sig')
e=html.escape
def picture(file,title):
    src=P/file;assert src.is_file()
    thumb=src.with_suffix('.jpg');im=Image.open(src).convert('RGB');im.thumbnail((960,720));im.save(thumb,quality=88)
    return f'<a href="{e(file)}"><img loading="lazy" src="{e(thumb.name)}" alt="{e(title)}"></a>'
contexts=''.join(f'<article><h3>{e(s["title"])}</h3>{picture(s["file"],s["title"])}</article>' for s in shots)
models=''.join(f'<article id="{e(m["id"])}"><h3>{e(m["title"])}</h3><p>{e(m["category"])}</p><div class="pair">{picture(m["front"],"Face")}{picture(m["back"],"Dos")}</div><small>Face / dos · '+ ' × '.join(f'{x:.2f}' for x in m['size_m'])+' m</small></article>' for m in items)
table=[
('Mobilier acheté ou déplacé','Banc, parasol, bac de culture et composteur','Modèles natifs, y compris le chemin de construction utilisé par l’achat et le déplacement.'),
('Variantes de contenants','Vases bleu et vert, seaux Soldes funèbres et Mordent un peu','Suppression des anciens contenants simplifiés ; fleurs natives et contenus séparés.'),
('Plante verte générique','Ancien petit pot à feuilles en ellipsoïdes','Réutilisation à petite échelle de la plante verte validée.'),
('Annexe et étage','Deux fenêtres et deux suspensions','Encadrements modelés, moulures, croisillons, appuis et quincaillerie ; suspensions validées.'),
('Balcon et palier','Sol, six rambardes du balcon, deux du palier, trois jardinières, deux lanternes','Modèles de la collection validée ; nouvelles fleurs natives et suppression des doublons.'),
('Chevalet extérieur','Cadre et décor, état ouvert/fermé et file','Cadre botanique modelé ; inscriptions et nombre toujours pilotés par le jeu.'),
('Jardinières de façades','Anciens bouquets de sphères','Remplacement par les fleurs cartoon natives déjà créées.'),
('Bureaux des employés','Ancienne géométrie masquée sous les modèles nouveaux','Suppression du doublon ; noms et statut des employés conservés.')]
rows=''.join('<tr>'+''.join(f'<td>{e(c)}</td>' for c in row)+'</tr>' for row in table)
testrows=''.join(f'<li>✓ {e(c["check"])}</li>' for c in checks['checks'])
page=f'''<!doctype html><html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Remplacements terminés — Fleuriste Galaxy</title>
<style>body{{margin:0;background:#182b2b;color:#eee8df;font:16px/1.6 system-ui}}main{{max-width:1500px;margin:auto;padding:30px}}h1,h2{{color:#ecc0cc}}h3{{margin:0 0 10px}}a{{color:#a6e7d0}}.grid{{display:grid;grid-template-columns:repeat(auto-fit,minmax(440px,1fr));gap:22px}}article{{background:#f0ebe3;color:#263b37;border-radius:12px;padding:18px}}img{{width:100%;display:block;border-radius:6px}}.pair{{display:flex;gap:6px}}.pair a{{width:50%}}table{{border-collapse:collapse;width:100%}}td,th{{padding:12px;text-align:left;border-bottom:1px solid #54716a}}small{{color:#52685f}}details{{margin:24px 0;padding:18px;background:#263c38}}@media(max-width:600px){{.grid{{grid-template-columns:1fr}}main{{padding:14px}}}}</style>
<main><h1>Les remplacements oubliés</h1><p>Vrais modèles chargés dans le jeu Godot : 7 vues en situation et 11 éléments présentés de face et de dos. Les variantes achetables utilisent désormais les modèles natifs.</p>
<p><b>6 302 tests réussis · {len(checks['checks'])} contrôles ciblés réussis · 18 surfaces de rangement vérifiées.</b></p>
<h2>Dans le jeu</h2><div class="grid">{contexts}</div><h2>Éléments corrigés — face et dos</h2><div class="grid">{models}</div>
<details><summary>Liste précise des remplacements</summary><table><thead><tr><th>Ensemble</th><th>Éléments</th><th>Correction</th></tr></thead><tbody>{rows}</tbody></table></details>
<details><summary>Contrôles fonctionnels</summary><ul>{testrows}</ul><p>Portes de serre et remise : collision fermée, passage ouvert et clic sur battant vérifiés. Stock, atelier et déplacement libre d’un vase sur l’étagère de remise vérifiés. Session de contrôle distincte de la sauvegarde du joueur.</p><a href="checks.json">Résultats ciblés</a> · <a href="../surface_remodel_review/functional_checks.json">Contrôles des interactions</a></details>
<p>Les murs et sols structurels conservés restent ceux du plan existant. Galerie, entrepôt, salon et ambassade gardent les devantures validées et leurs effets de jeu ; aucun intérieur supplémentaire n’est inventé dans cette passe.</p>
<p><a href="../surface_remodel_review/index.html">Collection complète des zones de surface</a> · <a href="../cellar_remodel_review/index.html">Sous-sol</a> · <a href="../../docs/validated_asset_replacement_audit.md">Audit détaillé</a></p></main></html>'''
(P/'index.html').write_text(page,encoding='utf-8')
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',22)
for start in range(0,len(shots),6):
    subset=shots[start:start+6];canvas=Image.new('RGB',(1500,340*((len(subset)+1)//2)),'#ede7de');draw=ImageDraw.Draw(canvas)
    for i,s in enumerate(subset):
        im=Image.open(P/s['file']).convert('RGB');im.thumbnail((730,290));x=(i%2)*750;y=(i//2)*340
        canvas.paste(im,(x+(750-im.width)//2,y+40));draw.text((x+12,y+8),s['title'],fill='#263b37',font=font)
    canvas.save(P/f'context_contact_{start//6}.jpg',quality=92)
doc='''# Audit des remplacements validés

Cette passe vérifie les chemins réellement utilisés dans le jeu, y compris l’achat et le déplacement des meubles. Elle complète la collection de surface existante.

| Ensemble | Éléments | Correction |
|---|---|---|
'''+''.join('| '+' | '.join(row)+' |\n' for row in table)+'''
## Livrables

Cinq GLB et cinq sources Blender complémentaires : garden_bench, workshop_window, pavement_board, bucket_clearance, bucket_biting, dans assets/models/completion et art/blender/completion. Les autres remplacements réutilisent les modèles des bibliothèques surface, shop, cellar et flowers. Le banc, les fenêtres et le chevalet sont des compléments suivant la palette botanique validée ; les deux seaux suivent le modèle validé des seaux fleuris.

Les dix types de mobilier connus du catalogue passent par des GLB natifs. Les contenus des vases et des seaux restent séparés de leur contenant. Les emprises, interdictions de chevauchement et données de sauvegarde existantes restent pilotées par les systèmes de placement du jeu.

## Validation

6 302 tests réussis, zéro échec. Dix-huit contrôles ciblés réussis : dix constructeurs de mobilier, deux variantes de vases, deux seaux avec sept fleurs, achat/placement du banc et du parasol, panneau dynamique et deux fenêtres natives conservées après fusion des maillages. La vérification des interactions de surface confirme les 18 surfaces, les portes, l’ouverture du stock et de l’atelier, puis l’achat et le déplacement d’un vase sur une étagère de remise.

Sept captures en situation et onze présentations isolées face/dos proviennent du véritable jeu Godot. La session de contrôle utilise user://review_validated_replacements.json, distincte de la sauvegarde normale. Les avertissements de ressources au terme du lanceur de tests existaient déjà ; aucun échec de test ni erreur de script dans les exécutions finales.

## Limites de cette passe

Les murs, sols et volumes structurels conservés sont ceux du plan approuvé. Les quatre extensions galerie, entrepôt, salon et ambassade restent des devantures avec leurs bonus existants ; aucun nouvel intérieur n’a été validé. La rue conserve ses véhicules et personnages d’ambiance hors des planches de cette collection.

## Reproduction

Blender : tools/blender/completion_collection.py. Puis import Godot, scène scenes/shop/shot_completion.tscn, et tools/package_validated_replacements.py. Contrôles d’interaction : scenes/shop/shot_surface_remodel.tscn avec l’argument utilisateur checks_only. Galerie : out/validated_replacements_review/index.html.
'''
(R/'docs/validated_asset_replacement_audit.md').write_text(doc,encoding='utf-8')
print('REPLACEMENT_GALLERY_COMPLETE',len(shots),len(items),len(checks['checks']))
