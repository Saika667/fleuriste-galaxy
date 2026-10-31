"""Metric articulated fauna and planted urban trees; reference sheets in art/concepts/animals."""
import os,sys,math,random,bpy
sys.path.insert(0,os.path.dirname(__file__))
exec(open(os.path.join(os.path.dirname(__file__),'cellar_collection.py'),encoding='utf-8').read().split('\nSPECS=')[0],globals())
OUT=os.path.join(bc.ROOT,'assets/models/animals');SOURCE=os.path.join(bc.ROOT,'art/blender/animals')
os.makedirs(OUT,exist_ok=True);os.makedirs(SOURCE,exist_ok=True)
def pivot(name,pos,parent):
 p=bc.pivot(name,bc.G(*pos),parent);p['articulated']=True;return p
def cat(sleep=False):
 r=cn('SleepingCat' if sleep else 'StreetCat');rig=pivot('rig',(0,0,0),r)
 bc.material('fur','#514D57');bc.material('fur_dark','#36333D');bc.material('white_fur','#D9D9CF');bc.material('eye_green','#A2B872');bc.material('nose','#B77E80')
 oval('Torso',(0,.23,-.015),(.115,.13,.245),'fur',rig)
 oval('Chest',(0,.25,.12),(.10,.13,.09),'white_fur',rig)
 head=pivot('head',(0,.34,.19),rig)
 oval('Head',(0,0,0),(.115,.10,.10),'fur',head)
 for s in [-1,1]:
  mesh('Pointed_ear',[(s*.04,.055,0),(s*.10,.16,-.02),(s*.115,.045,-.01),(s*.075,.07,.025)],[(0,1,2),(0,3,1),(1,3,2)],'fur_dark',head,.005)
  mesh('Ear_inner',[(s*.06,.07,.019),(s*.097,.135,-.003),(s*.10,.06,.018)],[(0,1,2)],'nose',head,.002)
  oval('Muzzle',(s*.027,-.035,.092),(.04,.03,.024),'white_fur',head)
  if sleep:tube('Closed_eye',[(s*.075,.015,.08),(s*.05,.005,.094),(s*.03,.014,.09)],.004,'ink',head)
  else:
   oval('Eye',(s*.051,.018,.083),(.029,.033,.013),'eye_green',head);oval('Vertical_pupil',(s*.051,.018,.096),(.006,.025,.004),'ink',head)
  for j in range(3):tube('Whisker',[(s*.04,-.03,.108),(s*.155,-.015+j*.014,.125)],.0016,'white_fur',head)
 oval('Nose',(0,-.02,.116),(.015,.009,.008),'nose',head)
 for j,(x,z) in enumerate([(-.085,.14),(.085,.14),(-.085,-.17),(.085,-.17)]):
  leg=pivot('leg_'+str(j),(x,.20,z),rig)
  oval('Upper_leg',(0,-.045,0),(.038,.083,.043),'fur',leg);oval('Sock',(0,-.13,.008),(.032,.05,.035),'white_fur',leg);oval('Paw',(0,-.177,.028),(.042,.024,.06),'white_fur',leg)
  for dx in [-.014,.014]:tube('Toe_line',[(dx,-.172,.072),(dx,-.182,.075)],.0015,'fur_dark',leg)
 tail=pivot('tail',(0,.24,-.235),rig);tube('Curved_tail',[(0,0,0),(0,.08,-.12),(.045,.20,-.18),(.065,.29,-.12),(.04,.31,-.08)],.025,'fur',tail)
 oval('White_tail_tip',(.04,.31,-.08),(.025,.025,.030),'white_fur',tail)
 if sleep:rig.rotation_euler.z=.7;rig.location.z=-.07
 return r
def pigeon():
 r=cn('CityPigeon');rig=pivot('rig',(0,0,0),r)
 for k,c in {'feather':'#788590','feather_dark':'#3D4B58','neck':'#4E807B','neck_purple':'#725E7B','feet':'#BE7E72','eye':'#C89B54'}.items():bc.material(k,c)
 oval('Body',(0,.18,0),(.115,.14,.19),'feather',rig)
 oval('Neck',(0,.30,.11),(.073,.11,.075),'neck',rig)
 for j in range(5):oval('Iridescent_neck_feather',((j-2)*.025,.28,.17),(.023,.045,.009),'neck_purple' if j%2 else 'neck',rig)
 head=pivot('head',(0,.37,.13),rig);oval('Skull',(0,0,0),(.067,.071,.067),'feather',head)
 for s in [-1,1]:oval('Orange_eye',(s*.055,.013,.028),(.012,.015,.011),'eye',head);oval('Pupil',(s*.062,.014,.031),(.006,.009,.006),'ink',head)
 oval('Beak',(0,-.018,.078),(.022,.016,.042),'feather_dark',head);oval('Cere',(0,-.003,.063),(.019,.01,.016),'cream',head)
 for s in [-1,1]:
  wing=pivot('wing_'+str(s),(s*.102,.24,.025),rig)
  oval('Folded_wing',(s*.015,-.035,-.025),(.035,.095,.135),'feather',wing)
  for j in range(7):oval('Layered_flight_feather',(s*.025,-.047-j*.006,-.015-j*.022),(.020,.048,.064),'feather_dark' if j%3==0 else 'feather',wing)
  for z in [-.02,.045]:tube('Wing_black_bar',[(s*.033,.02,z),(s*.048,-.065,z-.03)],.008,'feather_dark',wing)
  tube('Red_leg',[(s*.045,.105,0),(s*.05,.045,.015)],.009,'feet',rig)
  for k in [-1,0,1]:tube('Articulated_toe',[(s*.05,.045,.015),(s*.05+k*.018,.012,.058),(s*.05+k*.025,.008,.083)],.004,'feet',rig)
  tube('Hind_toe',[(s*.05,.025,.02),(s*.05,.009,-.025)],.004,'feet',rig)
 for i in range(7):oval('Tail_feather',((i-3)*.018,.16,-.20),(.016,.016,.10),'feather_dark',rig)
 return r
def spider():
 r=cn('CellarSpider');rig=pivot('rig',(0,0,0),r);bc.material('spider_leg','#655D60')
 oval('Abdomen',(0,.055,-.06),(.06,.05,.085),'purple',rig);oval('Cephalothorax',(0,.055,.035),(.043,.037,.042),'ink',rig)
 for j in range(4):
  for s in [-1,1]:
   leg=pivot('leg_'+str(j*2+(s+1)//2),(s*.026,.055,.055-j*.026),rig)
   tube('Eight_jointed_legs',[(0,0,0),(s*.075,.045,.025-j*.017),(s*.135,-.045,.05-j*.027)],.005,'spider_leg',leg)
 for x in [-.021,.021]:oval('Large_eye',(x,.069,.068),(.018,.020,.012),'cream',rig);oval('Pupil',(x,.071,.080),(.007,.009,.004),'ink',rig)
 for i in range(6):oval('Small_eye',((i-2.5)*.012,.085,.053),(.0045,.005,.004),'cream',rig)
 for s in [-1,1]:tube('Pedipalp',[(s*.012,.035,.067),(s*.015,.023,.083)],.005,'steel_dark',rig)
 return r
def butterfly():
 r=cn('GardenButterfly');rig=pivot('rig',(0,0,0),r)
 oval('Segmented_body',(0,0,0),(.010,.012,.058),'wood_dark',rig)
 oval('Head',(0,.005,.051),(.014,.014,.012),'wood_dark',rig)
 for s in [-1,1]:
  oval('Large_eye',(s*.009,.012,.059),(.007,.009,.004),'cream',rig);oval('Pupil',(s*.009,.012,.063),(.003,.005,.002),'ink',rig)
 for j in range(5):oval('Abdominal_segment',(0,.001,-.049+j*.016),(.010,.013,.009),'wood',rig)
 for s in [-1,1]:
  wing=pivot('wing_'+str(s),(0,0,0),rig)
  for name,x,z,rx,rz in [('Forewing',.075,.025,.075,.072),('Hindwing',.052,-.060,.053,.055)]:
   oval(name,(s*x,0,z),(rx,.004,rz),'ink',wing)
   oval(name+'_orange',(s*x,.004,z),(rx*.87,.003,rz*.86),'orange' if name=='Forewing' else 'cream',wing)
   for j in range(5):a=j*.6;oval('Cream_wing_dot',(s*(x+rx*.66*math.cos(a)),.008,z+rz*.72*math.sin(a)),(.005,.002,.005),'cream',wing)
   for j in [-1,0,1]:tube('Wing_vein',[(s*.012,.009,-.012),(s*x,.009,z),(s*(x+rx*.6),.009,z+j*rz*.55)],.0015,'wood_dark',wing)
  tube('Clubbed_antenna',[(s*.005,0,.05),(s*.025,.025,.09),(s*.035,.026,.092)],.0018,'wood_dark',rig)
  oval('Antenna_tip',(s*.035,.026,.092),(.004,.003,.005),'wood_dark',rig)
  for j in range(3):tube('Six_legs',[(s*.006,-.005,.025-j*.02),(s*.025,-.018,.032-j*.025)],.0015,'wood_dark',rig)
 return r
def firefly():
 r=cn('Firefly');rig=pivot('rig',(0,0,0),r)
 oval('Luminous_abdomen',(0,0,-.016),(.009,.008,.016),'mint',rig)
 for j in range(4):oval('Glowing_abdominal_segment',(0,-.001,-.025+j*.007),(.008,.008,.0045),'mint',rig)
 for s in [-1,1]:
  wing=pivot('wing_'+str(s),(s*.003,.007,.003),rig);oval('Olive_elytron',(s*.003,0,-.009),(.006,.004,.019),'leaf',wing)
  for j in range(3):tube('Six_legs',[(s*.006,0,.013-j*.01),(s*.016,-.007,.015-j*.012)],.001,'wood_dark',rig)
  tube('Antenna',[(s*.004,.003,.02),(s*.009,.009,.034),(s*.012,.010,.041)],.0006,'wood_dark',rig)
  oval('Large_eye',(s*.005,.006,.027),(.0038,.0048,.0023),'cream',rig);oval('Pupil',(s*.005,.006,.029),(.002,.003,.001),'ink',rig)
  oval('Membranous_flight_wing',(s*.016,.007,-.004),(.013,.0008,.018),'cream',wing)
 oval('Amber_pronotum',(0,.002,.014),(.009,.007,.008),'ochre',rig);oval('Head',(0,.003,.023),(.006,.005,.006),'ink',rig)
 return r
def tree(variant):
 r=cn('UrbanTree'+str(variant));rng=random.Random(444+variant)
 bc.material('bark','#74634D');bc.material('soil','#564735');bc.material('curb','#A89E89');bc.material('leaves','#627A45');bc.material('leaves_light','#7E9255');bc.material('litter','#B69258')
 # A hollow raised stone border with actual soil inside, never a solid slab under the trunk.
 for x in [-.68,.68]:box('Tree_pit_edge',(.13,.14,1.40),(x,.07,0),'curb',r,.025)
 for z in [-.68,.68]:box('Tree_pit_edge',(1.23,.14,.13),(0,.07,z),'curb',r,.025)
 box('Dark_soil',(1.22,.035,1.22),(0,.035,0),'soil',r,.02)
 height=[3.5,4.0,3.4][variant]
 tube('Tapered_trunk',[(0,.03,0),(.015,1.2,.03),(-.04,2.1,.04),(.10,height-.4,-.04)],.105,'bark',r)
 for i in range(9):
  a=i*2.39996;rr=rng.uniform(.5,.95);y=2.5+rng.uniform(0,height-2.1)
  tip=(math.cos(a)*rr,y,math.sin(a)*rr)
  tube('Branch_forks',[(-.01,1.7,.02),(tip[0]*.55,tip[1]-.35,tip[2]*.55),tip],.035,'bark',r)
  # Small layered sprays give an irregular crown with visible leaf edges.
  oval('Foliage_core',tip,(.32,.29 if variant!=1 else .45,.30),'leaves',r)
  for j in range(48):
   theta=rng.random()*math.tau;rad=rng.uniform(.25,.6);p=(tip[0]+math.cos(theta)*rad,tip[1]+rng.uniform(-.3,.4),tip[2]+math.sin(theta)*rad)
   leaf=oval('Leaf_spray',p,(.16,.022,.085),'leaves_light' if j%3 else 'leaves',r);leaf.rotation_euler.z=rng.uniform(-.8,.8)
 for i in range(30):
  x=rng.uniform(-.56,.56);z=rng.uniform(-.56,.56)
  if x*x+z*z<.035:continue
  oval('Fallen_leaf',(x,.065,z),(.035,.004,.018),'litter',r)
 for i in range(8):
  a=i*2.4;x=.46*math.cos(a);z=.46*math.sin(a)
  tube('Flower_stem',[(x,.05,z),(x,.18,z)],.006,'leaf',r)
  for j in range(5):aa=j*math.tau/5;oval('Small_flower_petal',(x+.025*math.cos(aa),.19,z+.025*math.sin(aa)),(.024,.008,.015),'cream' if i%2 else 'ochre',r)
 for i in range(12):
  a=i*2.4;radius=rng.uniform(.8,1.12);oval('Pavement_leaf',(math.cos(a)*radius,.027,math.sin(a)*radius),(.04,.004,.023),'litter',r)
 return r
SPECS=[('cat',lambda:cat(False)),('cat_sleeping',lambda:cat(True)),('pigeon',pigeon),('spider',spider),('butterfly',butterfly),('firefly',firefly)]
for i in range(3):SPECS.append(('tree_'+str(i),lambda i=i:tree(i)))
selected=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
for name,fn in SPECS:
 if selected and name not in selected:continue
 ob=fn();bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SOURCE,name+'.blend'));bc.export_glb(os.path.join(OUT,name+'.glb'),ob);print('FAUNA_TREE_MODEL',name,flush=True)
