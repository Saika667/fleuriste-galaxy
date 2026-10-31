"""Verify and package the last original shop concept sheets and optional proposals."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
from PIL import Image, ImageDraw, ImageFont
import json, html, shutil

ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'art/concepts/shop'

def main():
    manifest=ART/'items_74_89_prompts.json'
    jobs=json.loads(manifest.read_text(encoding='utf-8'))['jobs']
    results=json.loads((ART/'items_74_89_generation_results.json').read_text(encoding='utf-8'))
    assert len(jobs) in (16,20)
    assert [j['number'] for j in jobs[:16]]==list(range(74,90))
    assert len(results)==len(jobs)
    for r in results:
        shutil.copy2(r['source'], ART/r['output'])
    for j in jobs:
        with Image.open(ART/j['output']) as im: im.verify()
        with Image.open(ART/j['output']) as im: assert im.width>im.height>=1024
    notes='# Préparation des modèles 3D — fin du catalogue\n\n'
    notes+='Les références 74 à 89 sont les seize derniers éléments du catalogue existant. Les propositions éventuelles P1 à P4 sont de nouvelles variantes, et ne sont pas des éléments préexistants.\n\n'
    notes+='Les illustrations sont des concepts de production : les cotes sont indicatives et la cohérence géométrique doit être fixée lors de la modélisation.\n\n'
    notes+='- Trappe 75/76 : un seul couvercle et un seul axe de charnière ; prendre la planche 75 comme référence du couvercle. Conserver le cadenas sur le bord avant dans les deux états ; les différences dessinées de position ne définissent pas deux pièces. Adapter la profondeur et l’inclinaison de l’échelle au sous-sol réel.\n- Étagères : 2 m et 1,50 m proposés pour remplacer les anciennes rangées de 5,60 m. Un seul plateau par objet, minimum 90 cm libres au-dessus ; vases et étiquettes mobiles et séparés. La fonction de stock existante reste à conserver.\n- Textiles : dos, coutures et envers distincts ; motifs plats.\n- Cadres : images peintes planes, vitrage et encadrement séparés.\n- Livres : pages et couverture distinctes, titres à composer avec de vraies polices lors de la réalisation.\n- Néons : canaux, diffuseurs, supports et câbles séparés ; passage de porte dégagé, halo modéré.\n\n'
    for j in jobs: notes+=f'## {j.get("display_number",j["number"])} — {j["title_fr"]}\n\n{j["design_brief"]}\n\n'
    (ART/'items_74_89_modeling_notes.md').write_text(notes,encoding='utf-8')
    count=len(jobs)
    css='*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#f8f3e8;color:#183837;font:17px/1.6 system-ui}main{max-width:1600px;margin:auto;padding:30px 24px}a{color:#147775}h1,h2{line-height:1.2}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:15px}.card{padding:10px;border:1px solid #d9c8aa;border-radius:12px;background:#fffaf0;text-decoration:none;font-weight:650}.card img{width:100%;aspect-ratio:1.5;object-fit:contain}.sheet{margin:50px 0;scroll-margin-top:20px}.sheet img{width:100%;border-radius:12px;border:1px solid #deceb3}input{font:inherit;padding:10px;border:1px solid #b8a588;border-radius:9px;width:min(100%,550px);margin:12px 0 24px}.notes{padding:16px 20px;background:#e1eee5;border-radius:12px}.badge{font-size:14px;color:#884665}[hidden]{display:none!important}'
    page=f'<!doctype html><html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Shop — fin du catalogue</title><style>{css}</style><main id="top"><h1>{count} planches — fin du catalogue du shop</h1>'
    page+='<p>Les items 74 à 89 terminent le catalogue existant : tapis, trappes, signalétique, étagères, cadres, livres, rideaux et néons.</p>'
    if count==20: page+='<p class="notes">Pour compléter les 20 planches, quatre variantes supplémentaires sont proposées et repérées P1 à P4. Elles ne figuraient pas dans le catalogue d’origine.</p>'
    page+='<p>Vues complémentaires, détails de construction et palettes dans le style cartoon approuvé. Les étagères sont présentées vides et garnies d’accessoires amovibles. Cotes indicatives à confirmer lors de la modélisation.</p><p><a href="../../../out/shop_items_74_89_reference_sheets.zip">Télécharger toutes les planches et les prompts (ZIP)</a> · <a href="items_74_89_prompts.json">Prompts complets</a> · <a href="items_74_89_modeling_notes.md">Notes de modélisation</a></p><label for="search">Rechercher une planche</label><br><input id="search" type="search" placeholder="Trappe, étagère, livre…"><nav class="grid">'
    for j in jobs:
        title=html.escape(f'{j.get("display_number",j["number"])} — {j["title_fr"]}')
        badge='<br><span class="badge">Variante supplémentaire proposée</span>' if j['status']=='proposal' else ''
        page+=f'<a class="card" data-search="{title.lower()}" href="#item-{j["number"]}"><img src="{j["output"]}" loading="lazy" alt=""><span>{title}</span>{badge}</a>'
    page+='</nav>'
    for j in jobs:
        title=html.escape(f'{j.get("display_number",j["number"])} — {j["title_fr"]}')
        page+=f'<section class="sheet" data-search="{title.lower()}" id="item-{j["number"]}"><h2>{title}</h2><a href="{j["output"]}" target="_blank"><img src="{j["output"]}" loading="lazy" alt="{title}"></a><p><a href="../../../out/shop_catalog/{j["front"]}">Référence du catalogue</a> · <a href="#top">Sommaire ↑</a></p></section>'
    page+='<p>Illustrations produites avec image_gen intégré, mode génération avec références. Les modèles 3D de cette série restent à réaliser.</p></main><script>document.querySelector("#search").addEventListener("input",e=>{const q=e.target.value.toLocaleLowerCase("fr");document.querySelectorAll("[data-search]").forEach(c=>c.hidden=!c.dataset.search.includes(q));});</script></html>'
    gallery=ART/'items_74_89.html'
    gallery.write_text(page,encoding='utf-8')
    rows=(count+3)//4
    contact=Image.new('RGB',(1600,rows*290),'#f8f3e8')
    draw=ImageDraw.Draw(contact);font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',18)
    for i,j in enumerate(jobs):
        x=i%4*400;y=i//4*290
        with Image.open(ART/j['output']) as im:
            im=im.convert('RGB');im.thumbnail((396,260));contact.paste(im,(x+(400-im.width)//2,y))
        draw.text((x+5,y+265),f'{j.get("display_number",j["number"])} — {j["title_fr"]}'[:39],font=font,fill='#183837')
    contact_path=ART/'items_74_89_apercu.jpg';contact.save(contact_path,quality=93)
    archive=ROOT/'out/shop_items_74_89_reference_sheets.zip'
    with ZipFile(archive,'w',ZIP_DEFLATED) as z:
        portable=page.replace('../../../out/shop_items_74_89_reference_sheets.zip','#top').replace('../../../out/shop_catalog/','references/')
        z.writestr(gallery.name,portable)
        for p in [manifest,ART/'items_74_89_generation_results.json',ART/'items_74_89_modeling_notes.md',contact_path]+[ART/j['output'] for j in jobs]:z.write(p,p.name)
        for ref in sorted({j['front'] for j in jobs}):z.write(ROOT/'out/shop_catalog'/ref,'references/'+ref)
        z.writestr('LISEZ-MOI.txt',f'{count} planches. Ouvrir items_74_89.html.\nGénération avec références via image_gen intégré. Prompts JSON inclus.\nCotes indicatives ; modèles 3D non inclus.\n')
    with ZipFile(archive) as z: assert z.testzip() is None
    print(f'VERIFIED {count} landscape PNGs, portable gallery, prompts and ZIP CRC. Archive: {archive.stat().st_size:,} bytes.')

if __name__=='__main__':main()
