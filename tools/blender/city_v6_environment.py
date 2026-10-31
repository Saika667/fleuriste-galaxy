"""Dense two-sided maple canopies, detailed cast iron lamps and optimized street meshes."""
import os,sys,math,random,bpy,bmesh
sys.path.insert(0,os.path.dirname(__file__))
exec(open(os.path.join(os.path.dirname(__file__),'district_detail_v3.py'),encoding='utf-8').read().split("\nfor name,fn in [('street_lamp'")[0],globals())
OUT=os.path.join(bc.ROOT,'assets/models/city_v6');SOURCE=os.path.join(bc.ROOT,'art/blender/city_v6')
os.makedirs(OUT,exist_ok=True);os.makedirs(SOURCE,exist_ok=True)

def maple(r,pos,size,role,angle=0,tilt=0):
 x,y,z=pos;c=math.cos(angle);s=math.sin(angle)
 outline=[(0,-.5),(-.12,-.20),(-.40,-.28),(-.31,-.04),(-.53,.10),(-.27,.17),(-.32,.40),(-.10,.30),(0,.64),(.10,.30),(.32,.40),(.27,.17),(.53,.10),(.31,-.04),(.40,-.28),(.12,-.20)]
 verts=[(x,y+.03*size,z)]
 for xx,zz in outline:
  xx*=size;zz*=size;verts.append((x+xx*c+zz*s,y+zz*tilt,z-xx*s+zz*c))
 mesh('Maple_leaf',verts,[(0,j+1,(j+1)%len(outline)+1) for j in range(len(outline))],role,r,0)

def tree(v,hedge=False):
 r=cn('DenseMaple' if not hedge else 'DenseHedge');rng=random.Random(855+v)
 for role,col in {'leaf_green':'#568146','leaf_lime':'#80984A','leaf_ochre':'#C5A14D','leaf_orange':'#B8783E','leaf_red':'#A54E3D','leaf_brown':'#826146','soil':'#61543E','moss':'#657A42'}.items():bc.material(role,col)
 for role in [k for k in bc._MATS if 'leaf_' in k]:bc._MATS[role].use_backface_culling=False
 if not hedge:
  for x in [-.68,.68]:box('Pit_border',(.12,.13,1.42),(x,.065,0),'stone',r,.008)
  for z in [-.68,.68]:box('Pit_border',(1.24,.13,.12),(0,.065,z),'stone',r,.008)
  box('Textured_soil',(1.23,.04,1.23),(0,.04,0),'soil',r,0)
  for i in range(18):
   x=rng.uniform(-.53,.53);z=rng.uniform(-.53,.53);oval('Moss_patch',(x,.067,z),(.09,.008,.055),'moss',r)
  tube('Trunk',[(0,.06,0),(.025,1.3,0),(-.025,2.4,.035),(.05,3.6,0)],.095,'wood_dark',r)
  for i in range(12):
   a=i*2.4;p=(math.cos(a)*.9,2.7+(i%4)*.3,math.sin(a)*.9)
   tube('Branch',[(0,1.6+i*.08,0),(p[0]*.5,p[1]-.3,p[2]*.5),p],.023,'wood_dark',r)
  for i in range(90):
   x=rng.uniform(-.57,.57);z=rng.uniform(-.57,.57);h=rng.uniform(.08,.19)
   mesh('Bent_grass',[(x-.008,.06,z),(x+.008,.06,z),(x+.018,h*.7,z+.015),(x+.032,h,z+.04)],[(0,1,2),(0,2,3)],'leaf_green',r,0)
  for i in range(34):
   a=rng.random()*math.tau;rad=rng.uniform(.22,1.0);maple(r,(math.cos(a)*rad,.071 if rad<.6 else .017,math.sin(a)*rad),rng.uniform(.08,.15),['leaf_ochre','leaf_orange','leaf_red','leaf_green','leaf_brown'][i%5],a,.04)
  for i in range(6):
   a=i*2.4;x=.48*math.cos(a);z=.48*math.sin(a);tube('Stem',[(x,.06,z),(x,.23,z)],.003,'leaf_green',r)
   for j in range(6):
    q=j*math.tau/6;oval('Daisy_petal',(x+.026*math.cos(q),.23,z+.026*math.sin(q)),(.025,.006,.011),'cream',r)
   oval('Flower_center',(x,.237,z),(.015,.008,.015),'yellow',r)
 for i in range(1150 if not hedge else 350):
  a=rng.random()*math.tau;rr=math.sqrt(rng.random())*(1.35 if not hedge else .52)
  yy=(3.15 if not hedge else .85)+rng.uniform(-.70,.75)*(1 if not hedge else .7)
  xx=math.cos(a)*rr;zz=math.sin(a)*rr
  maple(r,(xx,yy,zz),rng.uniform(.22,.36),['leaf_green','leaf_green','leaf_lime','leaf_ochre'][i%4],a,rng.uniform(-.7,.7))
 return r

def lamp6():
 r=lamp()
 for yy,rad in [(.15,.195),(.40,.145),(.72,.12),(3.33,.13)]:
  cylinder(r,'Cast_collar',rad,.045,(0,yy,0),'steel_dark')
 for side in [-1,1]:
  tube('Scroll_bracket',[(0,3.12,side*.025),(.18,3.25,side*.025),(.27,3.52,side*.025),(.15,3.62,side*.025),(.10,3.52,side*.025)],.014,'teal_dark',r)
 oval('Lantern_finial',(.57,3.68,0),(.045,.10,.045),'gold',r)
 for side in [-1,1]:
  for z in [-.12,.12]:tube('Pane_diagonal',[(.57+side*.17,3.17,z),(.57-side*.17,3.52,z)],.006,'teal_dark',r)
 return r

for name,fn in [('tree_0',lambda:tree(0)),('tree_1',lambda:tree(1)),('tree_2',lambda:tree(2)),('hedge_v5',lambda:tree(3,True)),('street_lamp',lamp6)]:
 if os.path.exists(os.path.join(OUT,name+'.glb')):continue
 bc.reset_scene();ob=fn();bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SOURCE,name+'.blend'));bc.export_glb(os.path.join(OUT,name+'.glb'),ob);print('CITY_ENVIRONMENT',name,flush=True)

# Reduce dense bevel geometry on static architecture, retaining material roles and named parts.
for name in ['sage_townhouse','corner_apartments','blue_workshop','brick_bakery']:
 bc.reset_scene();bpy.ops.import_scene.gltf(filepath=os.path.join(bc.ROOT,'assets/models/street',name+'.glb'))
 root_obj=next(o for o in bpy.context.scene.objects if o.parent is None)
 before=after=0
 for ob in list(bpy.context.scene.objects):
  if ob.type!='MESH':continue
  before+=sum(len(p.vertices)-2 for p in ob.data.polygons)
  if len(ob.data.polygons)>80:
   bm=bmesh.new();bm.from_mesh(ob.data)
   bmesh.ops.dissolve_limit(bm,angle_limit=.085,verts=list(bm.verts),edges=list(bm.edges),delimit={'MATERIAL','SHARP'})
   bm.to_mesh(ob.data);bm.free();ob.data.update()
  after+=sum(len(p.vertices)-2 for p in ob.data.polygons)
 bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SOURCE,name+'.blend'));bc.export_glb(os.path.join(OUT,name+'.glb'),root_obj)
 print('CITY_OPTIMIZED',name,before,after,flush=True)
