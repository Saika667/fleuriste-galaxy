"""Review gallery for four revised native props and the real entrance-door sign."""
from pathlib import Path
from PIL import Image
from zipfile import ZipFile,ZIP_DEFLATED
import json,shutil,re

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'out/items_69_72_revisions_review'
IDS=['shelf_flowered_skull','botanical_clock','botanical_open_sign','botanical_queue_sign']

def main():
    log=(ROOT/'out/items_69_72_revisions_capture.log').read_text(encoding='utf-8-sig')
    assert 'ITEMS_69_72_REVISIONS_COMPLETE' in log and 'SCRIPT ERROR' not in log and '\nERROR:' not in log
    checks=json.loads((OUT/'checks.json').read_text(encoding='utf-8'))
    assert all(checks.values())
    # Refresh the corresponding views in the existing twenty-model gallery, too.
    old=ROOT/'out/items_54_73_review'
    for p in OUT.glob('*.png'):
        if p.name.startswith(('69_','70_','71_','72_')) and (old/p.name).exists():shutil.copy2(p,old/p.name)
    sources=[OUT/'01_enseigne_sur_porte_ouverte.png']+sorted(OUT.glob('retournement_*.png'))+[OUT/'03_enseigne_sur_porte_fermee.png']
    frames=[]
    for p in sources:
        with Image.open(p) as im:
            im=im.convert('RGB');im.thumbnail((960,540));frames.append(im.copy())
    frames[0].save(OUT/'enseigne_retournement_en_jeu.gif',save_all=True,append_images=frames[1:]+frames[-2:0:-1],duration=[700]+[100]*9+[1000]+[100]*9,loop=0,optimize=True)
    page='''<!doctype html><html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Shop — Crâne, horloge et panneaux corrigés</title><style>
*{box-sizing:border-box}body{margin:0;background:#f7f0e2;color:#193c36;font:17px/1.6 system-ui}main{max-width:1580px;margin:auto;padding:30px 24px}h1,h2{line-height:1.2}a{color:#176f68}.views{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,580px),1fr));gap:15px}figure{margin:0}figcaption{padding:8px}img{display:block;width:100%;border-radius:12px}section{margin:40px 0;scroll-margin-top:20px}p{max-width:1150px}.note{padding:18px;background:#e1eee5;border-radius:12px}.anim{max-width:960px;margin:auto}</style><main><h1>Les quatre modèles corrigés — rendus en jeu</h1>
<p>Crâne à pommettes intégrées, bouquet bas de sept petites fleurs et feuilles débordantes ; horloge dans des tons verts ; enseigne réversible à typographie épaisse et chaîne unique continue ; panneau de file au texte rose agrandi.</p>
<p><a href="../items_54_73_review/index.html">Galerie des vingt modèles</a> · <a href="../shop_items_69_72_revisions.zip">Les quatre sources Blender, GLB et rendus (ZIP)</a></p>
<section id="enseigne-porte"><h2>L’enseigne sur la porte d’entrée</h2><p class="note">Le panneau accompagne la porte quand elle s’ouvre. Une seule chaîne passe par le crochet central et reste fixe lorsque le panneau se retourne. La face OUVERT est verte, la face FERMÉ est rouge. Depuis l’intérieur du shop, interagir avec l’enseigne ouvre la journée ou ferme la boutique pour passer au bilan ; le cycle de journée existant est conservé.</p><figure class="anim"><img src="enseigne_retournement_en_jeu.gif" alt="Retournement de l’enseigne dans le jeu"><figcaption>Animation assemblée à partir des images réellement capturées dans Godot.</figcaption></figure><div class="views">'''
    for f,label in [('01_enseigne_sur_porte_ouverte','Depuis la rue — face OUVERT'),('03_enseigne_sur_porte_fermee','Depuis la rue — face FERMÉ rouge'),('02_porte_entree_enseigne','Fixation sur la porte d’entrée'),('04_interaction_depuis_shop','Côté joueur — accessible depuis le shop'),('05_porte_ouverte_enseigne_fixee','L’enseigne suit le mouvement de la porte')]:
        page+=figure(f+'.png',label)
    page+='</div></section>'
    data=[(69,IDS[0],'Crâne fleuri d’étagère','Pommettes sculptées dans la surface du crâne, sans sphères rapportées. Sept petites fleurs basses avec feuillage débordant.', [('face','Face / trois-quarts'),('dos','Dos')]),(70,IDS[1],'Horloge murale verte','Boîtier vert profond, cadran vert pâle, filets menthe et chiffres vert foncé. Les aiguilles suivent toujours l’heure du jeu.', [('face','Face'),('dos','Dos'),('14h30','Affichage à 14 h 30')]),(71,IDS[2],'Enseigne ouvert / fermé','Nouvelle police Cooper Black, faces séparées aux couleurs fixes et panneau réellement retournable sous sa suspension.', [('face','Face OUVERT'),('dos','Face FERMÉ rouge'),('ferme','Panneau retourné, chaîne fixe')]),(72,IDS[3],'Tableau de file d’attente','EN FILE et ATTENTE sont désormais tous deux roses, plus grands et en gras. Le nombre reste dynamique.', [('face','Texte rose agrandi'),('dos','Dos'),('12','Exemple avec douze clients')])]
    for n,id,title,desc,views in data:
        page+=f'<section id="item-{n}"><h2>{n} — {title}</h2><p>{desc}</p><p><a href="../../art/blender/shop/{id}.blend">Source Blender</a> · <a href="../../assets/models/shop/{id}.glb">GLB</a></p><div class="views">'
        for suffix,label in views:page+=figure(f'{n}_{id}_{suffix}.png',label)
        if n==69:
            for f,label in [('69_crane_profil.png','Profil — pommette intégrée'),('69_crane_dessus.png','Composition basse et feuillage')]:page+=figure(f,label)
        page+='</div></section>'
    page+='<p>Captures du viewport du vrai jeu. La scène utilise une partie de contrôle et ne remplace pas votre sauvegarde.</p></main></html>'
    (OUT/'index.html').write_text(page,encoding='utf-8')
    for ref in re.findall(r'(?:src|href)="([^"]+)"',page):
        if not ref.startswith('#') and not ref.endswith('.zip'):assert (OUT/ref).exists(),ref
    files=list(OUT.glob('*.png'))+[OUT/'index.html',OUT/'checks.json',OUT/'enseigne_retournement_en_jeu.gif']
    for id in IDS:files += [ROOT/'assets/models/shop'/f'{id}.glb',ROOT/'art/blender/shop'/f'{id}.blend']
    files += [ROOT/f for f in ['tools/blender/shop_items_54_73.py','src/world/shop_collection_54_73.gd','src/world/shop_room.gd','src/world/shop_world.gd','src/world/shop_items_69_72_revisions_preview.gd','scenes/shop/shot_items_69_72_revisions.tscn','tests/test_shop_collection_54_73.gd','docs/shop_items_69_72_revisions.md','tools/package_shop_items_69_72_revisions.py']]
    with ZipFile(ROOT/'out/shop_items_69_72_revisions.zip','w',ZIP_DEFLATED) as z:
        for p in files:z.write(p,p.relative_to(ROOT))
    with ZipFile(ROOT/'out/shop_items_69_72_revisions.zip') as z:assert z.testzip() is None
    print('VERIFIED: four native models, game captures, real interaction checks, animated sign preview, links and ZIP CRC.')

def figure(filename,label):return f'<figure><a href="{filename}"><img src="{filename}" loading="lazy" alt="{label}"></a><figcaption>{label}</figcaption></figure>'

if __name__=='__main__':main()
