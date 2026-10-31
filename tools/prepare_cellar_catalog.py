"""Instrument copies of actual cellar builders; never change the playable scene."""
from pathlib import Path
import re,json
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'src/cellar_view/catalog_generated'
OUT.mkdir(exist_ok=True)
TRACE='preload("res://src/cellar_view/catalog_trace.gd")'

def instrument_sections(text,funcs,parent,category,source):
    """Record exactly the nodes created in each source-level construction section."""
    parts=re.split(r'(?=^(?:static )?func )',text,flags=re.M)
    for i,part in enumerate(parts):
        m=re.match(r'(?:static )?func (\w+)\(',part)
        if not m or m[1] not in funcs:continue
        name=m[1];lines=part.splitlines();body=[];section=0;active=False
        def finish():
            nonlocal section
            title=funcs[name] if section==0 else f'{funcs[name]} — détail {section+1}'
            body.append(f'\t{TRACE}.record({parent},_catalog_start,"{Path(source).stem}_{name}_{section}",{json.dumps(title,ensure_ascii=False)},{json.dumps(category,ensure_ascii=False)},{json.dumps(source)})')
        body.append(f'\tvar _catalog_start={parent}.get_child_count()')
        for line in lines[1:]:
            if line.startswith('\t# ') and active:
                finish();section+=1;body.append(f'\t_catalog_start={parent}.get_child_count()');active=False
            if line.strip() and not line.lstrip().startswith('#'):active=True
            body.append(line)
        while body and not body[-1].strip():body.pop()
        finish();parts[i]=lines[0]+'\n'+'\n'.join(body)+'\n\n\n'
    return ''.join(parts)

def helper(text,name,parent,title,source,category='Accessoires et décorations'):
    pattern=rf'(^static func {name}\([^\n]+\n)(.*?)(?=^static func |\Z)'
    def repl(m):
        body=m[2].rstrip();marker=f'\t{TRACE}.record({parent},_catalog_start,"{name}",{json.dumps(title,ensure_ascii=False)},{json.dumps(category,ensure_ascii=False)},{json.dumps(source)})\n'
        if re.search(r'^\treturn ',body,re.M):body=re.sub(r'(?=^\treturn )',marker,body, count=1,flags=re.M)
        else:body+='\n'+marker
        return m[1]+f'\tvar _catalog_start={parent}.get_child_count()\n'+body+'\n\n\n'
    return re.sub(pattern,repl,text,flags=re.M|re.S)

source='src/cellar_view/dressing.gd'
s=(ROOT/source).read_text(encoding='utf-8')
for fn,title in {'crate':'Caisse de contrebande','barrel':'Tonneau cerclé','mushroom':'Champignon lumineux','shelf':'Étagère murale','duck':'Canard décoratif','toaster':'Grille-pain','bomb':'Bombe cartoon décorative','bananas':'Bananes dorées','fish_jar':'Bocal à poisson','helmet':'Casque spatial sous cloche','skull_mug':'Tasse crâne','rocket':'Mini-fusée','moon':'Mini-lune','lantern':'Lanterne suspendue'}.items():
    s=helper(s,fn,'p' if fn in ['duck','toaster','bomb','bananas','fish_jar','helmet','skull_mug','rocket','moon'] else 'v',title,source)
s=instrument_sections(s,{'stairs':'Habillage de l’escalier','pipes':'Conduites et vannes','shelves':'Étagères et signalétique de contrebande','crates':'Caisses, bidons et sacs','mushrooms':'Champignons et mousse lumineuse','dryer':'Séchoir à bouquets','nap_corner':'Coin sieste — chat et radio','counter':'Accessoires du comptoir','floor_clutter':'Paillasson, colis et pot à compost'},'v','Décor et mobilier',source)
(OUT/'dressing.gd').write_text(s,encoding='utf-8')
source='src/cellar_view/scenery.gd';s=(ROOT/source).read_text(encoding='utf-8')
s=s.replace('class_name CellarScenery\n','').replace('res://src/cellar_view/dressing.gd','res://src/cellar_view/catalog_generated/dressing.gd')
s=instrument_sections(s,{'_props':'Guirlande, étagère de bocaux et électricité'},'v','Éclairage et accessoires',source)
(OUT/'scenery.gd').write_text(s,encoding='utf-8')
source='src/cellar_view/planter_view.gd';s=(ROOT/source).read_text(encoding='utf-8').replace('class_name PlanterView\n','')
s=instrument_sections(s,{'_build_props':'Accessoires de culture'},'_bin','Outils et culture',source)
(OUT/'planter_view.gd').write_text(s,encoding='utf-8')
source='src/cellar_view/cellar_view.gd';s=(ROOT/source).read_text(encoding='utf-8').replace('class_name CellarView\n','')
s=s.replace('CellarScenery.build(self)','preload("res://src/cellar_view/catalog_generated/scenery.gd").build(self)')
s=s.replace('PlanterView.new()','preload("res://src/cellar_view/catalog_generated/planter_view.gd").new()')
s=instrument_sections(s,{'_build_room':'Sol, murs et plafond','_build_lighting':'Ampoules et câbles suspendus','_build_stairs':'Escalier et accès boutique','_build_consoles':'Consoles d’amélioration','_build_cabinet':'Armoire à produits','_build_composter':'Composteur animé','_build_counter':'Comptoir clandestin et porte','_build_seed_crate':'Caisse de graines','_build_hatch':'Bouche d’égout et décor','_build_decor':'Décor permanent'},'self','Aménagement du sous-sol',source)
(OUT/'cellar_view.gd').write_text(s,encoding='utf-8')
print('Generated four instrumented copies of actual cellar builders; playable source unchanged.')
