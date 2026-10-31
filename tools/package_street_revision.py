"""Review only verified Godot output; assemble the recorded traffic frames."""
from pathlib import Path
import hashlib, html, json, re, struct
from PIL import Image, ImageDraw, ImageFont

root=Path(__file__).resolve().parents[1]
out=root/'out/street_garden_revision_review'
data=json.loads((out/'checks.json').read_text(encoding='utf-8'))
walk=json.loads((out/'walk_checks.json').read_text(encoding='utf-8'))
assert data['passed'] and walk['passed']
log=(root/'out/street_v2_tests.log').read_text(encoding='utf-8')
result=re.search(r'RESULT: (\d+) passed, (\d+) failed',log)
assert result and int(result[2])==0
count=int(result[1])
frames=[Image.open(p).convert('RGB') for p in sorted((out/'traffic_frames').glob('*.png'))]
assert len(frames)==40
frames[0].save(out/'traffic.gif',save_all=True,append_images=frames[1:],duration=150,loop=0,optimize=True)
shots=[{'title':'Circulation dans les deux sens — capture animée du jeu','file':'traffic.gif'}]+data['captures']
cards=''.join('<a class="card" href="'+html.escape(s['file'])+'"><img loading="lazy" src="'+html.escape(s['file'])+'"><p>'+html.escape(s['title'])+'</p></a>' for s in shots)
page='''<!doctype html><html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Fleuriste Galaxy — quartier et jardin</title><style>
body{font:18px/1.5 system-ui;background:#142b29;color:#ede5d3;margin:0}main{max-width:1500px;margin:auto;padding:38px}
h1{color:#bde1c0}a{color:#d0e7be}.intro{max-width:1000px}.button{display:inline-block;background:#aee1bf;color:#183d34;padding:12px 22px;border-radius:30px;text-decoration:none;font-weight:700}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,440px),1fr));gap:22px}.card{display:block;background:#25443d;color:inherit;border-radius:16px;padding:12px;text-decoration:none;overflow:hidden}.card img{width:100%;display:block;border-radius:10px}.card p{margin:10px 5px}.reference{width:100%;border-radius:14px}h2{margin-top:42px}
</style><main><h1>Un nouveau quartier, un grand jardin et des commandes corrigées</h1>
<p class="intro">Quatre bâtiments natifs, trafic irrégulier dans les deux sens et patrouilles liées aux indices de suspicion. Jardin et serre visibles avant déblocage ; production et aménagement réservés aux zones achetées.</p>
<p><a class="button" href="../../build/windows/Fleuriste-Quartier.exe">Lancer la nouvelle version Windows</a></p>
<p>LOGIC tests de logique réussis · CHECKS contrôles en jeu réussis · descente et remontée réelles du personnage validées sur WALK étapes.</p>
<p><a href="../../docs/quartier_jardin_2026_10_29.md">Modifications, contrôles et fichiers sources</a></p>
<h2>Planche d’architecture</h2><p>Concept créé avec imagegen ; les captures suivantes proviennent du moteur du jeu.</p>
<a href="../../art/concepts/street/opposite_buildings_sheet.png"><img class="reference" src="../../art/concepts/street/opposite_buildings_sheet.png"></a>
<h2>Captures en jeu</h2><div class="grid">'''.replace('LOGIC',str(count)).replace('CHECKS',str(len(data['checks']))).replace('WALK',str(len(walk['steps'])))+cards+'</div></main></html>'
(out/'index.html').write_text(page,encoding='utf-8')
selected=[s for s in data['captures'] if s['id'] in ['street','garden_locked','greenhouse','ramp','police','phone_1280']]
contact=Image.new('RGB',(1440,3*450),'#e5e1d7');draw=ImageDraw.Draw(contact);font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',22)
for i,s in enumerate(selected):
    image=Image.open(out/s['file']).convert('RGB');image.thumbnail((710,405))
    x=(i%2)*720;y=(i//2)*450;contact.paste(image,(x+(710-image.width)//2,y));draw.text((x+12,y+414),s['title'][:48],font=font,fill='#24463c')
contact.save(out/'apercu.jpg',quality=92)
models=[]
for name in ['corner_apartments','sage_townhouse','brick_bakery','blue_workshop']:
    p=root/'assets/models/street'/f'{name}.glb';b=p.read_bytes();length=struct.unpack_from('<I',b,12)[0];gltf=json.loads(b[20:20+length])
    triangles=sum(gltf['accessors'][p['indices']]['count']//3 for m in gltf['meshes'] for p in m['primitives'] if 'indices' in p)
    models.append({'id':name,'triangles':triangles,'metres':True,'source':'art/blender/street/'+name+'.blend','reference':'art/concepts/street/opposite_buildings_sheet.png'})
(root/'assets/models/street/architecture_manifest.json').write_text(json.dumps(models,ensure_ascii=False,indent=2),encoding='utf-8')
exe=root/'build/windows/Fleuriste-Quartier.exe'
if exe.exists():
    info={'build_date':'2026-10-29','file':exe.name,'engine':'Godot 4.7.2 stable','target':'Windows x86_64','configuration':'release','embedded_resources':True,'bytes':exe.stat().st_size,'sha256':hashlib.sha256(exe.read_bytes()).hexdigest(),'logic_assertions_passed':count,'playthrough_checks_passed':len(data['checks']),'walk_steps_passed':len(walk['steps']),'validation_log':'out/windows_quartier_smoke.log'}
    (exe.parent/'build_info_quartier.json').write_text(json.dumps(info,ensure_ascii=False,indent=2),encoding='utf-8')
print('STREET_REVIEW_PACKAGED',count,'tests /',len(data['checks']),'checks /',len(walk['steps']),'walk points')
