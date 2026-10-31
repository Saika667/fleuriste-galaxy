"""Assemble the validated Windows delivery, image gallery and measured results."""
from pathlib import Path
import json,html,hashlib,re,shutil
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'out/city_v7'
def log(name):return (OUT/name).read_text(encoding='utf-8-sig',errors='replace')
core=log('core_final.log')
assert 'RESULT: 6513 passed, 0 failed' in core and 'SCRIPT ERROR' not in core
checks=json.loads((OUT/'checks.json').read_text(encoding='utf-8-sig'))
assert checks and all(r['passed'] for r in checks)
legacy=log('legacy_city_final.log');assert '272 checks 0 failures' in legacy and 'SCRIPT ERROR' not in legacy
traversal=[]
for furnished in [False,True]:
    name='traversal_furnished.log' if furnished else 'traversal_empty.log'
    assert 'DISTRICT_PROBE_COMPLETE true' in log(name) and 'SCRIPT ERROR' not in log(name)
    data=json.loads((ROOT/('out/quartier_v4_traversal'+('_furnished' if furnished else '')+'_checks.json')).read_text(encoding='utf-8-sig'))
    assert data['passed'];traversal.extend(data['checks'])
for name in ['export_smoke_engine.log','export_vulkan_engine.log']:
    assert 'EXPORT_SMOKE_PASSED' in log(name) and 'SCRIPT ERROR' not in log(name)
    assert (OUT/name).stat().st_mtime >= (ROOT/'build/windows/Fleuriste-ville-v7.exe').stat().st_mtime
assert 'SCRIPT ERROR' not in log('review_final.log') and 'CITY_VISUAL_COMPLETE 42' in log('review_final.log')
captures=json.loads((OUT/'review/captures.json').read_text(encoding='utf-8-sig'))
assert len(captures)==42
titles=['Façade du fleuriste','Terrasse du café','Rue principale','Carrefour et haut de la pente','Ruelle en pente','Place du sous-sol','Porte métallique et façade du sous-sol','Habillage industriel jusqu’au jardin','Ruelle arrière de la place','Parapet du toit terrasse','Boutique','Pièce secondaire','Serre et mitoyenneté','Composteur du jardin','Érable et pied d’arbre','Entrepôt de prêt','Ambassade galactique','Salon interstellaire','Galerie macabre','Quartier des routes perpendiculaires','Voiture civile','Nouveaux habitants','Escalier en brique et verrière','Conduites du sous-sol','Quartier de nuit','Pièce vitrée et toit terrasse','Escalier en pierre du jardin','Nouvelle ruelle piétonne','Station-service','Police municipale','Cinéma','Casino','Parc et fontaine','Entrées des jardins','Maison longue en brique','Voiture de police','Vue d’ensemble','Portraits des habitants','Collecte des déchets','Poteaux et câbles électriques','Vanne et réseau continu','Climatiseurs industriels']
cards=[]
for item in sorted(captures,key=lambda x:x['id']):
    assert (OUT/'review'/item['file']).exists()
    title=titles[int(item['id'][:2])-1];file=html.escape(item['file'])
    cards.append(f'<figure><a href="{file}"><img src="{file}" alt="{html.escape(title)}" loading="lazy"></a><figcaption>{html.escape(title)}</figcaption></figure>')
gallery='''<!doctype html><html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Fleuriste — ville V7</title><style>body{margin:0;background:#f2efe5;color:#283f35;font:16px/1.5 system-ui}header{max-width:1250px;margin:auto;padding:35px 24px 15px}h1{font-weight:600;font-size:34px;margin:0}main{max-width:1400px;margin:auto;padding:20px;display:grid;grid-template-columns:repeat(auto-fit,minmax(350px,1fr));gap:22px}figure{margin:0;background:white;border-radius:12px;overflow:hidden;box-shadow:0 2px 9px #263b3012}img{width:100%;display:block}figcaption{padding:14px 18px}a{color:#386d54}@media(max-width:500px){main{display:block}figure{margin-bottom:20px}}</style><header><h1>Fleuriste — ville V7</h1><p>42 captures du jeu sous Vulkan. Cliquez sur une image pour l’ouvrir en grand.</p><p><a href="../../../art/concepts/city_v7/residents_sheet.png">Planche des habitants</a> · <a href="../../../art/concepts/city_v7/roof_studio_sheet.png">Planche de l’étage</a> · <a href="../../../docs/revision_ville_v7.md">Corrections et vérifications</a></p></header><main>'''+''.join(cards)+'</main></html>'
(OUT/'review/index.html').write_text(gallery,encoding='utf-8')
before=json.loads((OUT/'benchmark_without_lods.json').read_text(encoding='utf-8-sig'))
after=json.loads((OUT/'benchmark_with_lods.json').read_text(encoding='utf-8-sig'))
assert len(before['views'])==len(after['views'])==4
labels={'facade':'Devanture','extended_city':'Quartier étendu','cellar':'Sous-sol','night':'Nuit'}
table=['| Vue | Primitives avant | Primitives après | Réduction | Temps médian avant / après |','|---|---:|---:|---:|---:|']
for a,b in zip(before['views'],after['views']):
    assert a['name']==b['name']
    reduction=100*(1-b['primitives']/a['primitives'])
    table.append(f"| {labels[a['name']]} | {int(a['primitives']):,} | {int(b['primitives']):,} | {reduction:.1f} % | {a['median_ms']:.2f} / {b['median_ms']:.2f} ms |")
exe=ROOT/'build/windows/Fleuriste-ville-v7.exe';assert exe.exists()
digest=hashlib.sha256()
with exe.open('rb') as f:
    for block in iter(lambda:f.read(1024*1024),b''):digest.update(block)
manifest={'version':'ville-v7','date':'2026-10-31','engine':'Godot 4.7.2 stable','platform':'Windows x86_64','file':exe.name,'bytes':exe.stat().st_size,'sha256':digest.hexdigest(),'embedded_resources':True,'core_assertions':6513,'city_v7_checks':len(checks),'existing_city_checks':272,'traversal_checks':len(traversal),'captures':42,'concept_sheets':2,'human_models':3,'buildings_checked':109,'public_path_points':82,'usable_resident_doors':68,'waste_collection_areas':4,'headless_export_smoke':'passed','vulkan_export_smoke':'passed','benchmark_before':before,'benchmark_after':after}
(OUT/'validation.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
exe.with_suffix('.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
report=ROOT/'docs/revision_ville_v7.md';text=report.read_text(encoding='utf-8')
marker='\n## Résultats chiffrés de livraison\n'
text=text.split(marker)[0]+marker+f'''
Version autonome : **{exe.name}**, {exe.stat().st_size/1024/1024:.1f} Mio, ressources incorporées. Contrôlée depuis `C:\\Windows\\Temp`, en mode sans affichage puis avec Vulkan.

**6 513 assertions générales et {len(checks)+272+len(traversal)} contrôles ciblés réussis, zéro échec.** Les tests des mâchoires de la plante carnivore et de préservation des squelettes passent après la préparation des ressources. Aucun `SCRIPT ERROR` dans les journaux finaux. Les avertissements de certificats Windows et de libération de ressources à la fermeture sont distincts des assertions fonctionnelles.

Mesures sur {after['gpu']}, 1 440 × 900, mode équilibré :

'''+ '\n'.join(table)+f'''

Temps de préparation et des premières images mesuré dans ces exécutions : {before['startup_ms']/1000:.1f} s avant, {after['startup_ms']/1000:.1f} s avec les ressources préparées. Les caches de shaders et la charge de la machine peuvent influencer ce temps. La réduction de primitives est reproductible à vue fixe ; les variations de temps médian ne constituent pas une promesse de fluidité sur un autre ordinateur.

Journaux : `out/city_v7/core_final.log`, `checks_final.log`, `legacy_city_final.log`, `traversal_empty.log`, `traversal_furnished.log`, `export_smoke_engine.log`, `export_vulkan_engine.log`. Les captures et les deux planches sont accessibles depuis la galerie. Empreinte de l’exécutable : `build/windows/Fleuriste-ville-v7.json`.
'''
report.write_text(text,encoding='utf-8')
(ROOT/'build/windows/LIRE-V7.txt').write_text('Fleuriste Galaxy — ville V7\n\nLancer Fleuriste-ville-v7.exe par double-clic. Les ressources sont incorporées.\n\nGalerie : ../../out/city_v7/review/index.html\nRapport : ../../docs/revision_ville_v7.md\n\nLes contrôles ont utilisé un profil de test isolé. La sauvegarde du joueur n’a pas été utilisée.\n',encoding='utf-8')
print('CITY_V7_PACKAGE_COMPLETE',exe.stat().st_size,'bytes',len(checks)+272+len(traversal),'targeted checks',len(captures),'captures')
