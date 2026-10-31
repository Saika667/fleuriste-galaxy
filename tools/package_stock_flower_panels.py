"""Package actual in-game stock-panel review captures."""
from pathlib import Path
from PIL import Image
import json
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'out/stock_flower_panels_review'
SHOTS=[('01_deux_etageres','Les deux étagères — panneaux réduits'),('02_logos_rangee_1','Rose, tulipe, lys et tournesol'),('03_logos_rangee_2','Lavande, marguerite, coquelicot et fleur xéno'),('04_variantes_rangee_1','Rose ivoire, tulipe violette et lys rose — une seule palette par pot'),('05_variante_xeno_cyan','Fleur xéno cyan et son logo assorti'),('06_pots_vides_zero','Pots vides — affichage 0')]
assert all(json.loads((OUT/'checks.json').read_text()).values())
page='''<!doctype html><html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Étagères — logos et quantités</title><style>body{margin:0;background:#f7f0e2;color:#193c36;font:18px/1.6 system-ui}main{max-width:1550px;margin:auto;padding:30px}a{color:#176f68}img{display:block;width:100%;border-radius:12px}section{margin:40px 0}h1,h2{line-height:1.25}.note{background:#e1eee5;padding:18px;border-radius:12px}</style><main><h1>Étagères de stock — nouveaux panneaux</h1><p class="note">Panneaux de 19 × 10,5 cm, logos simplifiés propres à chaque variété, sans nom ni point de couleur. Le logo reprend la couleur des pétales du pot ; toutes les tiges d’un même pot partagent une seule palette. La quantité apparaît en chiffres, avec <b>0</b> lorsque le pot est vide.</p><p>Captures réelles du jeu. Les vues de variantes montrent différentes palettes disponibles pour vérifier la synchronisation entre les fleurs et les logos.</p>'''
for filename,title in SHOTS:
    p=OUT/(filename+'.png')
    with Image.open(p) as im:assert im.width>=1600 and im.height>=900
    page+=f'<section><h2>{title}</h2><a href="{filename}.png"><img src="{filename}.png" loading="lazy" alt="{title}"></a></section>'
page+='</main></html>'
(OUT/'index.html').write_text(page,encoding='utf-8')
old=ROOT/'out/items_74_89_review/index.html'
s=old.read_text(encoding='utf-8')
link='<p class="notes"><b>Étagères de stock mises à jour :</b> <a href="../stock_flower_panels_review/index.html">voir les petits panneaux avec logos assortis et quantité à zéro →</a></p>'
if 'stock_flower_panels_review' not in s:s=s.replace('<h2>Éléments installés',link+'<h2>Éléments installés',1)
old.write_text(s,encoding='utf-8')
print('Verified six actual game captures and review gallery.')
