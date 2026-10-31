"""Package real Godot captures and verified Windows build; no synthetic game renders."""
from pathlib import Path
import json,re,html,hashlib,datetime
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'out/district_revision_review'
checks={}
for name in ['district_traversal_checks.json','district_traversal_furnished_checks.json']:
 data=json.loads((ROOT/'out'/name).read_text(encoding='utf-8'))
 assert data['passed'] and all(x['passed'] for x in data['checks']),name
 checks[name]=len(data['checks'])
core=(ROOT/'out/district_core_final.log').read_text(encoding='utf-8',errors='replace')
assert re.search(r'RESULT: 6507 passed, 0 failed',core)
assert 'STREET_WALK_COMPLETE true' in (ROOT/'out/district_walk_final.log').read_text(encoding='utf-8',errors='replace')
assert 'EXPORT_SMOKE_PASSED' in (ROOT/'out/district_windows_smoke_engine.log').read_text(encoding='utf-8',errors='replace')
assert 'EXPORT_SMOKE_PASSED' in (ROOT/'out/district_windows_graphics.log').read_text(encoding='utf-8',errors='replace')
exe=ROOT/'build/windows/Fleuriste-30-octobre.exe'
build={'built_at':datetime.datetime.fromtimestamp(exe.stat().st_mtime).isoformat(),'file':exe.name,'bytes':exe.stat().st_size,'sha256':hashlib.sha256(exe.read_bytes()).hexdigest(),'engine':'Godot 4.7.2 stable','platform':'Windows x86_64','configuration':'release','embedded_resources':True,'core_assertions':6507,'targeted_checks':checks,'physical_street_waypoints':7,'export_smoke':'passed'}
build['graphics_smoke']='passed'
(ROOT/'build/windows/build_info_30_octobre.json').write_text(json.dumps(build,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
captures=json.loads((OUT/'captures.json').read_text(encoding='utf-8'))
assert len(captures)==24
for c in captures:assert (OUT/c['file']).stat().st_size>10000,c
cards=''.join(f'<article id="{c["id"]}"><h2>{html.escape(c["title"])}</h2><a href="{c["file"]}"><img loading="lazy" src="{c["file"]}" alt="{html.escape(c["title"])}"></a></article>' for c in captures)
page='''<!doctype html><html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Fleuriste — Révision du 30 octobre</title><style>
:root{color-scheme:dark}*{box-sizing:border-box}body{margin:0;background:#152624;color:#eee8da;font:17px/1.55 system-ui,sans-serif}main{max-width:1560px;margin:auto;padding:32px}h1{font-size:38px;margin-bottom:8px}h2{font-size:18px}a{color:#a9d6bf}nav{display:flex;gap:18px;flex-wrap:wrap;margin:24px 0}.button{background:#c4d5b0;color:#20332a;padding:12px 18px;border-radius:12px;text-decoration:none;font-weight:700}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(520px,1fr));gap:24px}article{background:#233a35;padding:16px;border-radius:16px;scroll-margin-top:20px}img{display:block;width:100%;border-radius:9px}p{max-width:1100px}.note{color:#b7c8bc}.concept{max-width:900px} @media(max-width:650px){.grid{grid-template-columns:1fr}main{padding:16px}h1{font-size:28px}}
</style><main><h1>Fleuriste — Révision du 30 octobre</h1><p>24 captures du véritable jeu Godot : rue, place basse, sous-sol, accès intérieurs, jardin et interfaces. Cliquez sur une image pour la voir en plein format.</p>
<nav><a class="button" href="../../build/windows/Fleuriste-30-octobre.exe">Version Windows prête à tester</a><a href="#street">Rue</a><a href="#plaza">Place basse</a><a href="#cellar">Sous-sol</a><a href="#stairs_below">Escaliers</a><a href="#garden">Jardin</a><a href="#placement">Placement</a><a href="#notary">Notaire</a></nav>
<p><strong>Commandes :</strong> Espace pour sauter. En déplacement de meuble : R = 90°, T = 180°, molette = 15°, clic pour poser, Échap pour annuler. Deux cartons pleins et cinq cartons vides peuvent être portés. G pose le dernier carton ; les poubelles recyclent les emballages vides.</p>
<p class="note">Contrôles : 6 507 assertions sans échec, 33 vérifications ciblées en boutique vide et 33 en boutique meublée, sept étapes de marche réelle sur la rampe. Exécutable testé depuis un autre répertoire, sans dépendre du dossier source.</p>
<div class="grid">'''+cards+'''</div><article style="margin-top:24px"><h2>Référence du notaire et modèle 3D</h2><p>Planche créée avec l’outil intégré image_gen, puis personnage modélisé en géométrie 3D et rendu dans le dialogue avec une caméra dédiée.</p><p><a href="../../art/concepts/notary/notary_sheet.png">Planche originale</a> · <a href="../../art/concepts/notary/prompt.txt">Prompt complet utilisé</a> · <a href="../../assets/models/district/notary.glb">Modèle GLB</a> · <a href="../../art/blender/district/notary.blend">Source Blender</a></p><img class="concept" loading="lazy" src="../../art/concepts/notary/notary_sheet.png"></article>
<p><a href="../../docs/revision_quartier_30_octobre.md">Détail des modifications et vérifications</a></p></main></html>'''
(OUT/'index.html').write_text(page,encoding='utf-8')
(ROOT/'build/windows/LIRE_MOI_30_OCTOBRE.txt').write_text('''FLEURISTE — VERSION DU 30 OCTOBRE 2026

Lancer Fleuriste-30-octobre.exe. Toutes les ressources sont intégrées à cet exécutable.
Fermer l’ancienne version du jeu avant de lancer celle-ci.
Continuer réutilise la sauvegarde de jeu habituelle ; Nouvelle partie relance le tutoriel et le notaire.

Nouvelles commandes :
- Espace : sauter.
- Placement : R 90°, T 180°, molette 15°, clic poser, Échap annuler, Ctrl grille fine.
- Cartons : E prendre ou ouvrir ; G poser le dernier. Deux pleins et cinq vides maximum.
- Recyclage : viser une poubelle et E pour jeter les emballages vides.
- La grande poubelle de la place basse accepte aussi l’objet acheté en cours de déplacement.
- Pause > Se décoincer reste disponible.

La montée du sous-sol à la boutique se fait à pied par l’escalier intérieur.
L’étage possède un escalier visible ; son accès reste conditionné à la progression.
Le jardin et la serre restent visitables avant leur déblocage de production.

Galerie : out/district_revision_review/index.html dans le projet.
''',encoding='utf-8')
print(json.dumps({'exe':str(exe),'bytes':build['bytes'],'captures':len(captures),'checks':checks},ensure_ascii=False))
