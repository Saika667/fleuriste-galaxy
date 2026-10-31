"""Package the verified V5 build and native engine captures."""
from pathlib import Path
import datetime, hashlib, html, json
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'out/district_v5_review'
def log(name):
    return (ROOT / 'out' / name).read_text(encoding='utf-8', errors='replace')
assert 'RESULT: 6507 passed, 0 failed' in log('district_v5_core.log')
result = json.loads((ROOT/'out/district_v5_checks.json').read_text(encoding='utf-8'))
assert result['passed'] and all(c['passed'] for c in result['checks'])
for name in ['district_v5_windows_smoke_engine.log', 'district_v5_windows_graphics_engine.log']:
    assert 'EXPORT_SMOKE_PASSED' in log(name), name
    assert 'SCRIPT ERROR' not in log(name), name
assert 'DISTRICT_VISUAL_COMPLETE 38' in log('district_v5_visual.log')
assert 'SCRIPT ERROR' not in log('district_v5_visual.log')
assert 'SCRIPT ERROR' not in log('district_v5_probe.log')
captures = json.loads((OUT/'captures.json').read_text(encoding='utf-8'))
assert len(captures) == 38
for c in captures:
    assert (OUT/c['file']).stat().st_size > 10000, c
exe = ROOT/'build/windows/Fleuriste-zones-ouvertes.exe'
meta = dict(file=exe.name, built_at=datetime.datetime.fromtimestamp(exe.stat().st_mtime).isoformat(), bytes=exe.stat().st_size, sha256=hashlib.sha256(exe.read_bytes()).hexdigest(), engine='Godot 4.7.2 stable', embedded_resources=True, temporary_zone_access=True, core_checks=6507, targeted_checks=len(result['checks']), native_captures=38, concept_sheets=2, headless_export_smoke='passed', vulkan_export_smoke='passed')
(ROOT/'build/windows/zones_ouvertes_build_info.json').write_text(json.dumps(meta, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
cards = ''.join(f'<article id="{c["id"]}"><h2>{html.escape(c["title"])}</h2><a href="{c["file"]}"><img loading="lazy" src="{c["file"]}" alt="{html.escape(c["title"])}"></a></article>' for c in captures)
refs = ''.join(f'<article><h2>{title}</h2><a href="../../art/concepts/district_v5/{key}_sheet.png"><img loading="lazy" src="../../art/concepts/district_v5/{key}_sheet.png" alt="{title}"></a><p><a href="../../art/concepts/district_v5/{key}_prompt.txt">Prompt exact</a> · <a href="../../assets/models/street/{model}.glb">Modèle GLB</a> · <a href="../../art/blender/street/{model}.blend">Source Blender</a></p></article>' for key,title,model in [('apartment','Nouvel immeuble R+5','apartment_five'),('bakery','Vitrine de boulangerie garnie','bakery_display')])
page = '''<!doctype html><html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Fleuriste — Quartier V5</title><style>
:root{color-scheme:dark}*{box-sizing:border-box}body{margin:0;background:#14241f;color:#eee8d7;font:17px/1.55 system-ui,sans-serif}main{max-width:1560px;margin:auto;padding:32px}h1{font-size:36px}h2{font-size:19px}a{color:#c4dfbd}nav{display:flex;flex-wrap:wrap;gap:16px;margin:24px 0}.button{display:inline-block;padding:14px 22px;background:#cad9b8;color:#20342a;border-radius:12px;font-weight:700;text-decoration:none}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(520px,1fr));gap:24px}article{background:#243b32;padding:16px;border-radius:14px}img{display:block;width:100%;border-radius:8px}p{max-width:1150px}.stats{padding:18px;background:#304337;border-radius:12px}@media(max-width:650px){main{padding:16px}.grid{grid-template-columns:1fr}}</style><main>
<h1>Fleuriste — Quartier V5</h1><p>Animaux repris, ruelle à double sens, raccords au sol, nouvel escalier contre le mur droit, étage au-dessus du shop, immeubles, façades, jardins et boulangerie. Les 38 vues sont des captures réelles du moteur Godot ; les insectes sont agrandis sur un plateau de présentation.</p>
<p><a class="button" href="../../build/windows/Fleuriste-zones-ouvertes.exe">Version Windows — zones ouvertes</a></p><p>Toutes les zones sont temporairement accessibles pour les essais. Les extensions ne sont pas ajoutées aux achats de la sauvegarde. L'option de lancement <code>--story-locks</code> rétablit les restrictions de progression.</p>
<nav><a href="#alley">Ruelle</a><a href="#intersection">Intersection</a><a href="#plaza">Place</a><a href="#stairs_above">Nouvel escalier</a><a href="#upstairs_actual">Étage</a><a href="#shop_rear">Façade arrière</a><a href="#bakery">Boulangerie</a><a href="#animal_pigeon">Animaux</a><a href="#concepts">Nouvelles planches</a></nav>
'''+f'<p class="stats">6 507 assertions sans échec · {len(result["checks"])} contrôles ciblés réussis, dont 49 points de support au sol · exécutable testé sans écran et avec rendu Vulkan depuis un autre répertoire.</p>'+'''
<p>E : interagir. Espace : sauter. Pause → Se décoincer. Placement : R / T pour tourner, molette pour affiner, clic pour poser. Pour descendre, ouvrir la porte au fond à droite de la boutique.</p><div class="grid">'''+cards+'''</div><h1 id="concepts">Nouvelles références</h1><div class="grid">'''+refs+'''</div><p><a href="../../docs/district_revision_v5.md">Détail des changements</a> · <a href="../../build/windows/zones_ouvertes_build_info.json">Compilation et empreinte du fichier</a></p></main></html>'''
(OUT/'index.html').write_text(page, encoding='utf-8')
(ROOT/'build/windows/LIRE_MOI_ZONES_OUVERTES.txt').write_text('FLEURISTE — QUARTIER V5\n\nLancer Fleuriste-zones-ouvertes.exe. Ressources intégrées.\nToutes les zones sont ouvertes pour les essais, sans achat automatique des extensions.\nOption --story-locks pour rétablir les restrictions de progression.\nE interagir ; Espace sauter ; Pause > Se décoincer.\nR / T tourner les meubles ; molette affiner ; clic poser.\nGalerie : out/district_v5_review/index.html.\n', encoding='utf-8')
print(json.dumps(meta, ensure_ascii=False))
