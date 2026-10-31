"""Measured diagram and review gallery from actual map code and Godot captures."""
from pathlib import Path
from html import escape
import json,zipfile,shutil
from PIL import Image,ImageDraw,ImageFont

ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'out/map_design'
W,H=1600,1120;PAPER='#FFF9EF';INK='#30283E'
im=Image.new('RGB',(W,H),PAPER);draw=ImageDraw.Draw(im)
svg=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}"><rect width="100%" height="100%" fill="{PAPER}"/>']
def font(size,bold=False):return ImageFont.truetype('C:/Windows/Fonts/arial'+('bd' if bold else '')+'.ttf',size)
def rect(box,fill,stroke=INK,width=2):
    draw.rectangle(box,fill=fill,outline=stroke,width=width)
    x,y,x1,y1=box;svg.append(f'<rect x="{x}" y="{y}" width="{x1-x}" height="{y1-y}" fill="{fill}" stroke="{stroke}" stroke-width="{width}"/>')
def line(points,color=INK,width=2,dash=False):
    draw.line(points,fill=color,width=width)
    d=' stroke-dasharray="8 6"' if dash else ''
    svg.append(f'<polyline points="'+ ' '.join(f'{x},{y}' for x,y in points)+f'" fill="none" stroke="{color}" stroke-width="{width}"{d}/>')
def text(x,y,value,size=20,bold=False,color=INK):
    draw.text((x,y),value,font=font(size,bold),fill=color)
    svg.append(f'<text x="{x}" y="{y+size*.87}" font-family="Arial,sans-serif" font-size="{size}" font-weight="{700 if bold else 400}" fill="{color}">{escape(value)}</text>')
def xy(x,z):return (250+x*34,365+z*34)
def area(x,z,w,h,color):
    a=xy(x,z);b=xy(x+w,z+h);rect((*a,*b),color,width=3)
def label(x,z,lines):
    px,py=xy(x,z)
    for i,s in enumerate(lines):text(px,py+i*25,s,20 if i==0 else 17,i==0)

text(42,25,'FLEURISTE GALAXY — CROQUIS DE L’EXISTANT',34,True)
text(44,72,'Relevé du code et des scènes du jeu • plan au sol simplifié • repère X / Z du moteur',21)
text(44,103,'Extensions affichées pour l’étude ; mobilier initial. Le croquis ne propose pas encore de nouveau design.',19)
# World footprints: actual rendered extents, not the furniture placement grids.
area(10.1,.2,4.8,7.8,'#E8DDD2')
area(-5,0,5,6,'#E4E2F0');label(-4.65,1.1,['ANNEXE','5 × 6 m','Étage au-dessus'])
area(0,0,10,8,'#F4CFDA');label(2.5,2.2,['SHOP / BOUTIQUE','10 × 8 m','Comptoir · établi · frigo'])
area(5.3,-4.6,4,4.25,'#D7EEF1');label(5.55,-3.5,['SERRE','4 × 4,25 m','2 tables / allée'])
area(9.4,-6.8,5.2,7,'#D7E8BD');label(9.7,-5.9,['JARDIN','≈ 5,2 × 7 m','Massifs / dalles'])
area(-3.2,8.25,8.3,3.25,'#EDD1A9');label(-2.9,8.7,['TERRASSE','Plateforme ≈ 8,3 × 3,25 m'])
area(10.26,4.85,1.14,2.7,'#BFD7CC')
line([xy(11.4,6.2),xy(16,5.0)])
label(16.2,4.5,['REMISE','≈ 1,14 × 2,70 m','Volume fermé : pas d’intérieur jouable'])
label(11,.8,['COUR','Passage de service'])
# Openings and connections are schematic marks, not new doors.
line([xy(5.02,8),xy(6.02,8)],'#FFF9EF',8)
text(*xy(5.4,8.5),'A',21,True)
line([xy(10,3.02),xy(10,4.02)],'#FFF9EF',8)
text(*xy(10.4,3.0),'B',21,True)
line([xy(0,2.5),xy(0,3.6)],'#FFF9EF',8)
area(.05,1.05,.9,.9,'#B9A2D5');text(*xy(.25,1.1),'C',22,True)
line([xy(9.3,-4.5),xy(9.3,-3.0)],'#FFF9EF',8)
line([xy(10.7,3.5),xy(12.5,3.5),xy(12.5,-.4),xy(12.5,-3.8)],'#76806F',3,True)
label(-5,-2.5,['OUEST ←  repère  → EST'])
line([xy(-5.2,-4.8),xy(-5.2,-6.2)],INK,4)
line([xy(-5.45,-5.9),xy(-5.2,-6.2),xy(-4.95,-5.9)],INK,3)
text(*xy(-5.55,-7.0),'ARRIÈRE / −Z',17,True)
area(-5.5,12,37.8,2.0,'#E0DEE7');label(-4.7,12.4,['RUE / +Z — devanture, trottoirs et accès public'])
for name,x in [('Galerie',17.4),('Entrepôt',21.7),('Salon',26.0),('Ambassade',30.3)]:
    # Facade modules are context only: no fabricated interior floor plan.
    px,py=xy(x-1.65,8.25);qx,qy=xy(x+1.65,9.15)
    rect((px,py,qx,qy),'#E3DAEA',width=1);text(px+4,py+6,name,15,True)
text(*xy(16,10.0),'Façades de fin de partie — contexte uniquement',17)

# Separate instance: do not pretend its coordinates are physically below the shop.
rect((905,150,1530,470),'#F0E8FA',width=2)
text(925,165,'SOUS-SOL — scène distincte (encart)',24,True)
text(925,199,'Volume rendu 10 × 8 m ; grille de placement 8 × 6 cases',18)
bx,by,scale=960,235,24
def cp(x,z):return (bx+(x+5)*scale,by+(z+4)*scale)
rect((*cp(-5,-4),*cp(5,4)),'#D9CBE7',width=3)
rect((*cp(-4.25,-3.6),*cp(-2.95,-.4)),'#BC9A79')
text(1217,242,'Escalier / retour au shop [C]',18)
for x,z in [(.4,-3.1),(3,-3.1),(.4,-1.2),(3,-1.2)]:
    rect((*cp(x-.9,z-.35),*cp(x+.9,z+.35)),'#BAD3B4',width=1)
text(1217,273,'4 emplacements de bacs',18)
rect((*cp(-1.8,2.3),*cp(.6,3.2)),'#D4B997',width=1)
rect((*cp(-4.2,2.0),*cp(-2.8,3.5)),'#BFCB8B',width=1)
text(1217,304,'Comptoir / composteur',18)
text(1217,335,'Consoles / rangement',18)
text(925,440,'L’encart montre l’organisation locale, pas sa projection sous le bâtiment.',16)

text(45,925,'ACCÈS ET LECTURE DU PLAN',23,True)
text(45,961,'A  Entrée publique depuis la rue     B  Porte de service vers la cour     C  Trappe du shop → sous-sol',20)
text(45,997,'Serre accessible côté jardin. Annexe reliée au shop ; escalier vers l’étage à +3,4 m.',20)
line([(1140,1014),(1310,1014)],INK,5)
line([(1140,1005),(1140,1023)],INK,2);line([(1310,1005),(1310,1023)],INK,2)
text(1188,1028,'5 mètres',18)
text(45,1067,'Les dimensions décrivent les volumes construits ; elles peuvent différer des grilles de placement du mobilier.',17)
im.save(OUT/'plan_existant.png');svg.append('</svg>');(OUT/'plan_existant.svg').write_text(''.join(svg),encoding='utf-8')

groups=[('shop','Shop / boutique'),('terrasse','Terrasse'),('sous_sol','Sous-sol'),('remise','Remise'),('jardin','Jardin'),('serre','Serre')]
manifest=json.loads((OUT/'captures.json').read_text(encoding='utf-8'))
titles={s['id']:s['label'] for s in manifest['shots']}
page=['<!doctype html><html lang="fr"><meta charset="utf-8"><title>Map — dossier de design</title><style>body{margin:35px auto;max-width:1480px;padding:0 24px;background:#fff9ef;color:#30283e;font:18px system-ui}h1{font-size:38px}p{line-height:1.6}nav{display:flex;gap:18px;flex-wrap:wrap}a{color:inherit}img{max-width:100%;height:auto;border-radius:8px}section{margin:50px 0}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(420px,1fr));gap:20px}figure{margin:0}figcaption{padding:10px 0}</style><h1>Fleuriste Galaxy — état des lieux de la map</h1><p>Captures réelles dans Godot, en 1600 × 1000. Session de référence : extensions affichées et mobilier initial. Aucune sauvegarde joueur modifiée. Le croquis restitue l’existant pour préparer une refonte.</p><nav><a href="#plan">Croquis</a><a href="#ensemble">Ensemble</a>']
page.extend(f'<a href="#{id}">{name}</a>' for id,name in groups)
page.append('</nav><section id="plan"><h2>Croquis du plan existant</h2><a href="plan_existant.png"><img src="plan_existant.png" alt="Plan coté de la map et encart du sous-sol"></a><p><a href="plan_existant.svg">Version vectorielle SVG</a> · <a href="notes_design.md">Relevé et notes pour la refonte</a></p></section>')
def figures(ids):
    return '<div class="grid">'+''.join(f'<figure><a href="{id}.png"><img loading="lazy" src="{id}.png" alt="{escape(titles[id])}"></a><figcaption>{escape(titles[id])}</figcaption></figure>' for id in ids)+'</div>'
page.append('<section id="ensemble"><h2>La map dans son ensemble</h2>'+figures(['00_ensemble_coupe','01_ensemble_exterieur','02_ensemble_arriere'])+'</section>')
contact=Image.new('RGB',(1232,1325),PAPER);dc=ImageDraw.Draw(contact)
for index,(id,name) in enumerate(groups):
    page.append(f'<section id="{id}"><h2>{name}</h2>')
    if id=='remise':page.append('<p>La remise est un volume fermé et collidable, sans intérieur jouable. Ces vues montrent son enveloppe et son implantation dans la cour.</p>')
    if id=='sous_sol':page.append('<p>Scène intérieure distincte chargée par la trappe. État initial : emplacements de bacs visibles au sol.</p>')
    page.append(figures([id+'_01',id+'_02'])+'</section>')
    x=8+(index%2)*616;y=12+(index//2)*438
    dc.text((x+4,y),name,font=font(27,True),fill=INK)
    source=Image.open(OUT/(id+'_01.png'));assert source.size==(1600,1000)
    contact.paste(source.resize((608,380),Image.Resampling.LANCZOS),(x,y+42))
page.append('<section><h2>Contexte supplémentaire : annexe et étage</h2>'+figures(['annexe_bonus'])+'<p>L’étage existe au-dessus de l’annexe. Galerie, entrepôt, salon et ambassade sont représentés en façade sur la vue d’ensemble ; aucun intérieur n’est inventé sur le croquis.</p></section></html>')
contact.save(OUT/'zones_apercu.jpg',quality=95)
(OUT/'index.html').write_text(''.join(page),encoding='utf-8')
shutil.copy2(ROOT/'docs/map_design_audit.md',OUT/'notes_design.md')
with zipfile.ZipFile(ROOT/'out/map_design_reference.zip','w',zipfile.ZIP_DEFLATED) as archive:
    for path in OUT.iterdir():archive.write(path,path.name)
print('Created measured PNG/SVG plan, six-zone overview, 16-capture gallery and ZIP.')
