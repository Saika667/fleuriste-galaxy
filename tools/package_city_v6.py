"""Package verified captures and the Windows build; no network or user-save access."""
from pathlib import Path
import json,html,hashlib,re,shutil
ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'out/city_v6'
def log(name):return (OUT/name).read_text(encoding='utf-8',errors='replace')
core_result=re.search(r'RESULT: (\d+) passed, 0 failed',log('core_final.log'))
assert core_result
core_count=int(core_result.group(1))
core_label=f'{core_count:,}'.replace(',',' ')
assert 'SCRIPT ERROR' not in log('core_final.log')
checks=json.loads((OUT/'checks.json').read_text(encoding='utf-8'))
assert checks and all(c['passed'] for c in checks)
traversals=[]
for name in ['quartier_v4_traversal_checks.json','quartier_v4_traversal_furnished_checks.json']:
 result=json.loads((ROOT/'out'/name).read_text(encoding='utf-8'))
 assert result['passed'] and all(c['passed'] for c in result['checks'])
 traversals.extend(result['checks']);shutil.copy2(ROOT/'out'/name,OUT/name)
for name in ['export_smoke_engine.log','export_vulkan_engine.log']:
 assert 'EXPORT_SMOKE_PASSED' in log(name),name
 assert 'SCRIPT ERROR' not in log(name),name
assert 'CITY_VISUAL_COMPLETE 25' in log('visual_release.log')
assert 'SCRIPT ERROR' not in log('visual_release.log')
captures=json.loads((OUT/'review/captures.json').read_text(encoding='utf-8'))
titles=['Façade du fleuriste','Terrasse et parasol','Rue principale','Intersection et STOP','Descente vers la place','Place et jardins','Façade industrielle du sous-sol','Soupiraux côté ruelle','Ruelle piétonne','Toit terrasse ouvert','Murs de la boutique','Annexe','Serre attenante','Composteur','Érables et pieds d’arbres','Entrepôt de prêt','Ambassade galactique','Salon interstellaire','Galerie macabre','Nouvelle intersection','Voiture détaillée','Nouveaux habitants','Escalier intérieur','Sous-sol','Vue nocturne']
cards=[]
for capture,title in zip(captures,titles):
 file=OUT/'review'/capture['file'];assert file.exists() and file.stat().st_size>10000
 cards.append(f'<figure id="{html.escape(capture["id"])}"><a href="{html.escape(capture["file"])}"><img loading="lazy" src="{html.escape(capture["file"])}" alt="{html.escape(title)}"></a><figcaption>{html.escape(title)}</figcaption></figure>')
gallery='''<!doctype html><html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Fleuriste — révision du 31 octobre</title><style>body{margin:0;background:#eef0e7;color:#263c34;font:17px system-ui}header,main{max-width:1350px;margin:auto;padding:24px}h1{font-size:32px}p{max-width:850px;line-height:1.6}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(420px,1fr));gap:24px}figure{margin:0;background:white;border-radius:12px;overflow:hidden}img{width:100%;height:auto;display:block}figcaption{padding:15px}a{color:#356c58}@media(max-width:500px){main{display:block}figure{margin-bottom:20px}}</style><header><h1>Fleuriste — révision du 31 octobre 2026</h1><p>25 captures du jeu sous Vulkan. Boutique, jardins, sous-sol, ville et nouveaux habitants. Cliquez sur une image pour l’ouvrir en grand.</p><p><a href="../../../art/concepts/city_v6/composter_residents_sheet.png">Planche de référence</a> · <a href="../../../art/concepts/city_v6/prompt.txt">Prompt image_gen</a> · <a href="../../../docs/revision_ville_31_octobre.md">Rapport de validation</a></p></header><main>'''+''.join(cards)+'</main></html>'
(OUT/'review/index.html').write_text(gallery,encoding='utf-8')
exe=ROOT/'build/windows/Fleuriste-31-octobre.exe';assert exe.exists()
metrics={}
for name in ['visual_vulkan.log','visual_release.log']:
 metrics[name]={m[0]:int(float(m[1])) for m in re.findall(r'CITY_CAPTURE (\S+) draws=([\d.]+)',log(name))}
manifest={'date':'2026-10-31','file':exe.name,'bytes':exe.stat().st_size,'sha256':hashlib.sha256(exe.read_bytes()).hexdigest(),'engine':'Godot 4.7.2 stable','platform':'Windows x86_64','embedded_resources':True,'core_assertions':core_count,'city_checks':len(checks),'traversal_checks':len(traversals),'captures':len(captures),'concept_sheets':1,'new_glb_models':len(list((ROOT/'assets/models/city_v6').glob('*.glb'))),'headless_export_smoke':'passed','vulkan_export_smoke':'passed','draw_calls_by_view':metrics}
(exe.with_suffix('.json')).write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
(OUT/'validation.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
report=ROOT/'docs/revision_ville_31_octobre.md'
text=report.read_text(encoding='utf-8')
marker='Les tests utilisent `.runtime/appdata`'
text=text[:text.index(marker)]+f'''Les tests utilisent `.runtime/appdata` et des sauvegardes de contrôle sous `out/city_v6`, sans écrire dans la sauvegarde du joueur.

- **{core_label} assertions de la suite générale : 0 échec**, aucune erreur de script (`out/city_v6/core_final.log`).
- **{len(checks)} contrôles de la ville : 0 échec**, accès aux 48 maisons enregistrées, 67 points de cheminement, retours complets à domicile et marche sur la pente (`out/city_v6/checks_final.log`).
- **{len(traversals)} contrôles de parcours et d’interaction : 0 échec**, boutique vide et meublée, six étapes réelles sur l’escalier du sous-sol, saut, cartons, placement et étage (`out/city_v6/traversal3.log`, `out/city_v6/traversal_furnished.log`). Les anciennes coordonnées des outils de contrôle ont été mises à jour pour correspondre au véritable escalier et au nouveau composteur ; le verrouillage de l’étage est testé explicitement hors du mode de visite.
- **25 captures Vulkan** vérifiées dans `out/city_v6/review/index.html` ; la vue de l’escalier est recadrée depuis son axe réel.
- **Exécutable autonome testé depuis un autre répertoire**, en mode sans affichage puis avec rendu Vulkan : catalogue de 257 références, onze extensions, commandes, meubles, placement et sous-sol persistant. Journaux `out/city_v6/export_smoke_engine.log` et `out/city_v6/export_vulkan_engine.log`.
- `git diff --check` : aucune erreur d’espacement.

Sur les mêmes points de vue de cette révision, entre le premier contrôle Vulkan et le contrôle final, les appels de dessin passent de **3 150 à 2 780** devant la boutique, de **1 951 à 1 311** dans la boutique et de **3 292 à 2 721** dans le sous-sol. Il s’agit d’une comparaison entre deux étapes de cette révision, pas d’un benchmark de la version initialement testée par le joueur. La scène est plus grande et le feuillage plus dense ; les compteurs de triangles ne baissent pas partout.

Le pilote Windows signale un avertissement de lecture du magasin de certificats au démarrage ; les contrôles ci-dessus vont néanmoins à leur terme. Aucun accès réseau n’est nécessaire pour jouer.

## Version à lancer

`build/windows/Fleuriste-31-octobre.exe` — exécutable Windows autonome, ressources incorporées ({exe.stat().st_size/1024/1024:.1f} Mio). Métadonnées et empreinte SHA-256 : `build/windows/Fleuriste-31-octobre.json`.

La sauvegarde du joueur et l’ancien exécutable restent disponibles. La galerie et le rapport permettent de revoir les modifications sans lancer le jeu.
'''
report.write_text(text,encoding='utf-8')
(ROOT/'build/windows/LIRE-31-octobre.txt').write_text('Fleuriste Galaxy — révision du 31 octobre 2026\n\nLancer Fleuriste-31-octobre.exe par double-clic. Toutes les ressources sont incorporées.\n\nGalerie : ../../out/city_v6/review/index.html\nRapport : ../../docs/revision_ville_31_octobre.md\n\nLes contrôles ont utilisé un profil isolé et ne modifient pas la sauvegarde existante du joueur.\n',encoding='utf-8')
print('CITY_PACKAGE_COMPLETE',len(captures),len(checks)+len(traversals),'checks',exe.stat().st_size,'bytes')
