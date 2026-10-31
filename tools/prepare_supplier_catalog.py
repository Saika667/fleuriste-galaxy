from pathlib import Path
import json,math
r=Path.cwd();labels={};dims={}
for p in sorted((r/'out').glob('*/inventory.json')):
 try: records=json.loads(p.read_text(encoding='utf-8')).get('entries',[])
 except: continue
 for m in records:
  k=m.get('id','');labels[k]=m.get('title',k);dims[k]=m.get('size_m',[1,1,1])
cat={}
def add(id,name,category,price,model='',role='',level=1,family='shop',kind='asset',size=None):
 cat[id]=dict(name=name,kind=kind,category=category,price=price,level=level,family=family,model=model,role=role,size=size or dims.get(model.split('/')[-1].removesuffix('.glb'),[1,1,1]))
for id,name,price,model,role,size in [('counter','Comptoir de fleuriste',50,'counter_cabinet','counter',[3,.98,1]),('register','Caisse enregistreuse',25,'cash_register','register',[.65,.42,.5]),('workbench','Établi et outils',60,'workbench','workbench',[3,.97,1]),('stock_shelf','Étagère de stockage',28,'stock_shelf_botanical','stock_shelf',[2,.15,.45]),('bouquet_stand','Présentoir de bouquets',35,'stand_classic','bouquet_stand',[.9,1,.65])]:
 add(id,name,'furniture',price,'res://assets/models/shop/'+model+'.glb',role,size=size)
for species in ['rose','tulip','daisy']:
 add('flower_pot:'+species,'Pot de stockage — '+{'rose':'roses','tulip':'tulipes','daisy':'marguerites'}[species],'plants',6,'res://assets/models/shop/vase_lily.glb','flower_pot',size=[.18,.26,.18]);cat['flower_pot:'+species]['variety']=species
for id,name,price,size in [('grow_bed','Bac de culture à quatre pieds',40,[1.89,.55,1.16]),('single_pot','Pot individuel de culture',15,[.82,.45,.76])]:add(id,name,'plants',price,'res://assets/models/cellar/'+id+'.glb',id,2,'darknet',size=size)
add('nursery_pot','Pot pour semis de fleurs','plants',5,'res://assets/models/surface/nursery_pot.glb','flower_grow_pot',size=[.36,.32,.36])
exclude={'floor','ceiling','stairs','visitor_door','door_frame','window','greenhouse_shell','shed_shell','spiral_stair','shop_floor_botanical','shop_ceiling_botanical','cellar_hatch_closed','cellar_hatch_open','hatch_rug_botanical','greenhouse_door','shed_door'};aliases={v['model'] for v in cat.values()}
for lib in ['shop','surface','cellar','completion']:
 for p in sorted((r/'assets/models'/lib).glob('*.glb')):
  path='res://'+p.relative_to(r).as_posix()
  if path in aliases or p.stem in exclude or p.stem.startswith(('herb_','lotus_','moss_crop_','star_vine_','harvest_jar_q')):continue
  group='plants' if any(s in p.stem for s in ['pot','vase','seed','lamp','bucket','watering','soil','shears']) else 'furniture' if any(s in p.stem for s in ['shelf','stand','counter','desk','chair','table','bench','cabinet','fridge','display']) else 'decoration'
  add(lib+':'+p.stem,labels.get(p.stem,p.stem.replace('_',' ').capitalize()),group,12 if group=='decoration' else 30,path,('fridge' if 'fridge' in p.stem else p.stem if p.stem in ['composter','bed_lamp','single_lamp'] or p.stem.startswith('terminal_') else ''),2 if lib!='cellar' else 3,'darknet' if lib=='cellar' else 'shop')
for id,d in json.loads((r/'data/flowers.json').read_text(encoding='utf-8'))['flowers'].items():
 level=1 if id in ['rose','tulip','daisy'] else 2 if id in ['lily','sunflower','lavender','poppy'] else 5
 add('flower:'+id,d['name']+' — tige','flowers',math.ceil(d['cost']*1.25),'res://assets/models/flowers/'+id+'_toon.glb',id,level,kind='flower',size=[.2,.45,.2])
 add('seed:'+id,'Graines — '+d['name'],'flowers',d['cost'],role=id,level=level,kind='flower_seed')
for id,d in json.loads((r/'data/balance.json').read_text(encoding='utf-8'))['crops'].items():add('dark_seed:'+id,'Graines — '+d.get('name',id),'flowers',int(d.get('seed_cost',5)),role=id,level=2,family='darknet',kind='crop_seed')
(r/'data/supplier_catalog.json').write_text(json.dumps({'items':cat},ensure_ascii=False,indent=2),encoding='utf-8');print('CATALOG_ITEMS',len(cat))

