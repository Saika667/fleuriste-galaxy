"""Validate and package the 54–73 concept sheets, without changing game assets."""
from pathlib import Path
from zipfile import ZipFile,ZIP_DEFLATED
from PIL import Image,ImageDraw,ImageFont
import json,html,shutil,re

ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'art/concepts/shop'

def main():
    manifest=ART/'items_54_73_prompts.json'
    jobs=json.loads(manifest.read_text(encoding='utf-8'))['jobs']
    results=json.loads((ART/'items_54_73_generation_results.json').read_text(encoding='utf-8'))
    assert len(jobs)==20 and [j['number'] for j in jobs]==list(range(54,74))
    for result in results:
        target=ART/result['output']
        if not target.exists():shutil.copy2(result['source'],target)
    for job in jobs:
        with Image.open(ART/job['output']) as im:
            im.verify()
        with Image.open(ART/job['output']) as im:
            assert min(im.size)>=1024 and im.width>im.height
    page='''<!doctype html><html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Shop — Planches 54 à 73</title><style>
*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#f8f3e8;color:#183837;font:17px/1.6 system-ui}main{max-width:1600px;margin:auto;padding:30px 24px}a{color:#147775}h1,h2{line-height:1.2}p{max-width:1150px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:15px}.card{padding:9px;border:1px solid #d9c8aa;border-radius:12px;background:#fffaf0;text-decoration:none;font-weight:650}.card img{width:100%;aspect-ratio:1.5;object-fit:contain}.sheet{margin:50px 0;scroll-margin-top:20px}.sheet img{width:100%;height:auto;border-radius:12px;border:1px solid #deceb3}.back{float:right;font-size:15px}input{font:inherit;padding:10px;border:1px solid #b8a588;border-radius:9px;width:min(100%,550px);margin:12px 0 24px}.notes{padding:16px 20px;background:#e1eee5;border-radius:12px}.muted{color:#62736b}[hidden]{display:none!important}</style><main id="top"><h1>Les 20 prochaines planches — items 54 à 73</h1>
<p>Designs cartoon pour préparer la modélisation 3D du shop. Chaque élément possède sa propre planche : vues complémentaires, détails de construction et palette. Les éléments d’architecture comprennent aussi des plans, coupes et modules.</p>
<p class="notes">Les vases sont montrés <b>vides et garnis à titre d’exemple</b> : le joueur pourra choisir les fleurs. Les fleurs, l’eau et les contenants sont des composants distincts. Les mesures sont des objectifs de conception à confirmer dans Blender ; les dessins ne sont pas des plans CAO à mesurer au pixel. Le sol conserve les accès existants, notamment la trappe ; la hauteur du plafond sera conservée à l’intégration.</p>
<p><a href="../../../out/shop_items_54_73_reference_sheets.zip">Télécharger les 20 planches + prompts (ZIP)</a> · <a href="items_54_73_prompts.json">Prompts complets</a> · <a href="items_54_73_modeling_notes.md">Notes pour la modélisation</a> · <a href="items_34_53.html">Planches 34–53</a> · <a href="../../../out/shop_catalog/index.html">Catalogue du jeu</a></p>
<label for="search">Rechercher un élément</label><br><input id="search" type="search" placeholder="Numéro, porte, vase, horloge…"><nav class="grid">
'''
    for j in jobs:
        title=html.escape(f'{j["number"]} — {j["title_fr"]}')
        page+=f'<a class="card" data-search="{title.lower()}" href="#item-{j["number"]}"><img src="{j["output"]}" loading="lazy" alt=""><span>{title}</span></a>'
    page+='</nav>'
    for j in jobs:
        title=html.escape(f'{j["number"]} — {j["title_fr"]}')
        page+=f'<section class="sheet" data-search="{title.lower()}" id="item-{j["number"]}"><h2>{title}<a class="back" href="#top">Sommaire ↑</a></h2><a href="{j["output"]}" target="_blank"><img src="{j["output"]}" alt="{title} — planche pour modélisation 3D" loading="lazy"></a><p><a href="../../../out/shop_catalog/{j["front"]}">Ancien modèle — référence du catalogue</a></p></section>'
    page+='''<p class="muted">20 illustrations générées avec l’outil intégré image_gen, à partir des références du catalogue et de la planche de style approuvée. Les modèles 3D de cette série restent à réaliser.</p></main><script>document.querySelector('#search').addEventListener('input',e=>{const q=e.target.value.toLocaleLowerCase('fr');document.querySelectorAll('[data-search]').forEach(c=>c.hidden=!c.dataset.search.includes(q));});</script></html>'''
    gallery=ART/'items_54_73.html'
    gallery.write_text(page,encoding='utf-8')
    for ref in re.findall(r'(?:src|href)="([^"]+)"',page):
        if not ref.startswith(('#','http')) and not ref.endswith('.zip'):
            assert (ART/ref).exists(),ref
    contact=Image.new('RGB',(1600,5*290),'#f8f3e8')
    draw=ImageDraw.Draw(contact)
    font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',18)
    for i,j in enumerate(jobs):
        x=i%4*400;y=i//4*290
        with Image.open(ART/j['output']) as im:
            im=im.convert('RGB');im.thumbnail((396,260))
            contact.paste(im,(x+(400-im.width)//2,y))
        draw.text((x+5,y+265),f'{j["number"]} — {j["title_fr"]}'[:38],font=font,fill='#183837')
    contact_path=ART/'items_54_73_apercu.jpg'
    contact.save(contact_path,quality=93)
    archive=ROOT/'out/shop_items_54_73_reference_sheets.zip'
    with ZipFile(archive,'w',ZIP_DEFLATED) as z:
        for p in [gallery,manifest,ART/'items_54_73_generation_results.json',ART/'items_54_73_modeling_notes.md',contact_path]+[ART/j['output'] for j in jobs]:
            z.write(p,p.name)
        z.writestr('LISEZ-MOI.txt','20 planches cartoon, items 54 à 73.\nOuvrir items_54_73.html. Génération : outil intégré image_gen.\nVues et cotes indicatives pour préparer la 3D. Composants mobiles et fleurs séparés.\nLes modèles 3D ne sont pas inclus.\n')
    with ZipFile(archive) as z:assert z.testzip() is None
    print(f'VERIFIED:20 PNG sheets, gallery links, ZIP CRC; archive {archive.stat().st_size:,} bytes.')

if __name__=='__main__':main()
