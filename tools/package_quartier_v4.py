"""Package verified native Godot captures, animal references and a self-contained build."""
from pathlib import Path
import datetime,hashlib,html,json,re
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'out/quartier_v4_review'
def log(name):return (ROOT/'out'/name).read_text(encoding='utf-8',errors='replace')
assert 'RESULT: 6507 passed, 0 failed' in log('quartier_v4_core.log')
assert 'STREET_WALK_COMPLETE true' in log('quartier_v4_walk.log')
checks={}
for name in ['quartier_v4_traversal_checks.json','quartier_v4_traversal_furnished_checks.json']:
    result=json.loads((ROOT/'out'/name).read_text(encoding='utf-8'))
    assert result['passed'] and all(c['passed'] for c in result['checks']),name
    checks[name]=len(result['checks'])
for name in ['quartier_v4_windows_smoke_engine.log','quartier_v4_windows_graphics_engine.log']:
    assert 'EXPORT_SMOKE_PASSED' in log(name),name
for name in ['quartier_v4_visual.log','quartier_v4_traversal.log','quartier_v4_furnished.log','quartier_v4_windows_smoke_engine.log','quartier_v4_windows_graphics_engine.log']:
    assert 'SCRIPT ERROR' not in log(name),name
captures=json.loads((OUT/'captures.json').read_text(encoding='utf-8'))
assert len(captures)==35
for c in captures:assert (OUT/c['file']).stat().st_size>10000,c
exe=ROOT/'build/windows/Fleuriste-quartier-revise.exe'
meta={'file':exe.name,'built_at':datetime.datetime.fromtimestamp(exe.stat().st_mtime).isoformat(),'bytes':exe.stat().st_size,'sha256':hashlib.sha256(exe.read_bytes()).hexdigest(),'engine':'Godot 4.7.2 stable','embedded_resources':True,'core_checks':6507,'targeted_checks':checks,'street_walk_waypoints':7,'headless_export_smoke':'passed','vulkan_export_smoke':'passed','native_captures':len(captures),'animal_concept_sheets':5}
(ROOT/'build/windows/quartier_revise_build_info.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
cards=''.join(f'<article id="{c["id"]}"><h2>{html.escape(c["title"])}</h2><a href="{c["file"]}"><img loading="lazy" src="{c["file"]}" alt="{html.escape(c["title"])}"></a></article>' for c in captures)
references=''
for id,label in [('cat','Chat'),('pigeon','Pigeon'),('spider','Araignée'),('butterfly','Papillon'),('firefly','Luciole')]:
    references+=f'''<article id="sheet-{id}"><h2>{label} — planche de référence</h2><a href="../../art/concepts/animals/{id}_sheet.png"><img loading="lazy" src="../../art/concepts/animals/{id}_sheet.png" alt="Planche {label}"></a><p><a href="../../assets/models/animals/{id}.glb">Modèle GLB</a> · <a href="../../art/blender/animals/{id}.blend">Source Blender</a> · <a href="../../art/concepts/animals/{id}_prompt.txt">Prompt exact</a> · <a href="#animal_{id}">Rendu dans Godot</a></p></article>'''
page='''<!doctype html><html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Fleuriste — Quartier révisé</title><style>
:root{color-scheme:dark}*{box-sizing:border-box}body{margin:0;background:#14241f;color:#eee8d7;font:17px/1.55 system-ui,sans-serif}main{max-width:1560px;margin:auto;padding:32px}h1{font-size:38px;margin:0 0 12px}h2{font-size:18px}a{color:#b9dbc0}nav{display:flex;flex-wrap:wrap;gap:16px;margin:24px 0}.button{display:inline-block;padding:13px 20px;background:#c7d7ae;color:#20342a;border-radius:12px;font-weight:700;text-decoration:none}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(520px,1fr));gap:24px}article{background:#243b32;padding:16px;border-radius:14px;scroll-margin-top:16px}img{display:block;width:100%;border-radius:8px}p{max-width:1150px}.muted{color:#bac9bc}.concepts{margin-top:40px}.stats{padding:16px 20px;background:#304337;border-radius:12px}@media(max-width:650px){main{padding:16px}.grid{grid-template-columns:1fr}h1{font-size:29px}}</style><main>
<h1>Fleuriste — Quartier révisé</h1><p>Rue et ruelle élargie, place basse, façades, arbres, remise, accès au sous-sol, notaire, squelette et nouveaux animaux. Les 35 images ci-dessous sont des captures du jeu Godot. Cliquez pour les agrandir.</p>
<p><a class="button" href="../../build/windows/Fleuriste-quartier-revise.exe">Lancer la nouvelle version Windows</a></p>
<nav><a href="#street">Rue</a><a href="#intersection">STOP et raccord</a><a href="#alley">Ruelle</a><a href="#plaza">Place basse</a><a href="#shop_facade">Boutique</a><a href="#shed">Remise</a><a href="#stairs_above">Escalier</a><a href="#vents">Filtres au plafond</a><a href="#notary">Notaire</a><a href="#concepts">Planches des animaux</a></nav>
<p class="stats">Vérifications : 6 507 assertions sans échec ; 56 contrôles ciblés en boutique vide et 56 en boutique meublée ; sept étapes de marche sur la ruelle ; exécutable testé depuis un autre répertoire, sans écran puis avec rendu Vulkan.</p>
<p>Les filtres à charbon se clipsent sur les deux bouches centrales du plafond. E permet d’interagir avec une bouche ; les cartouches achetées s’alignent automatiquement en mode placement. Espace : sauter. R / T : tourner un objet de 90° / 180°. La remise communique avec la boutique par une porte ; la maison d’angle partage son mur sans empiéter sur sa pièce.</p>
<p class="muted">Les anciennes silhouettes de clients sont remplacées par les personnages issus des planches ; les identités et les règles économiques sont conservées. Les surfaces de sol superposées sont retirées. Les gros plans des animaux utilisent un plateau de présentation dans le moteur, avec un agrandissement pour les petits insectes.</p>
<div class="grid">'''+cards+'''</div><div class="concepts" id="concepts"><h1>Les cinq nouvelles planches</h1><p>Références créées avec l’outil intégré image_gen, puis modèles 3D réalisés dans Blender. Chaque prompt, GLB et source Blender est accessible ci-dessous.</p><div class="grid">'''+references+'''</div></div><p><a href="../../docs/quartier_revision_v4.md">Détail des changements et des vérifications</a> · <a href="../../build/windows/quartier_revise_build_info.json">Informations de compilation</a></p></main></html>'''
(OUT/'index.html').write_text(page,encoding='utf-8')
(ROOT/'build/windows/LIRE_MOI_QUARTIER_REVISE.txt').write_text('''FLEURISTE — QUARTIER RÉVISÉ — 30 OCTOBRE 2026

Lancer Fleuriste-quartier-revise.exe. Les ressources sont intégrées.
Continuer conserve la sauvegarde ; Nouvelle partie permet de revoir le tutoriel.
La galerie est dans out/quartier_v4_review/index.html.

Commandes utiles : E interagir ; Espace sauter ; Pause > Se décoincer.
Placement : R 90°, T 180°, molette 15°, clic poser, Échap annuler.
Les filtres à charbon s’alignent sur les deux bouches du plafond du sous-sol.
Il faut ouvrir la porte de l’escalier pour descendre depuis la boutique.

Ressources et scènes testées dans l’exécutable exporté, depuis un autre répertoire.
''',encoding='utf-8')
print(json.dumps(meta,ensure_ascii=False))
