"""Editable cartoon street props, anatomical skeleton and notary; metric Y-up."""
import os,sys,math,bpy
sys.path.insert(0,os.path.dirname(__file__))
exec(open(os.path.join(os.path.dirname(__file__),'cellar_collection.py'),encoding='utf-8').read().split('\nSPECS=')[0],globals())
OUT=os.path.join(bc.ROOT,'assets/models/district');BLEND=os.path.join(bc.ROOT,'art/blender/district')
os.makedirs(OUT,exist_ok=True);os.makedirs(BLEND,exist_ok=True)

def lamp():
 r=cn('FlutedStreetLamp')
 for radius,h,y in [(.22,.12,.06),(.16,.16,.20),(.12,.50,.52),(.075,2.65,2.05),(.12,.08,3.40)]:cylinder(r,'Cast_iron',radius,h,(0,y,0),'teal_dark')
 for i in range(12):
  a=i*math.tau/12;tube('Fluted_rib',[(.079*math.cos(a),.78,.079*math.sin(a)),(.079*math.cos(a),3.32,.079*math.sin(a))],.009,'steel_dark',r)
 tube('Swan_neck',[(0,3.38,0),(0,3.66,0),(.12,3.80,0),(.40,3.80,0),(.57,3.65,0)],.06,'teal_dark',r)
 cylinder(r,'Lantern_roof',.27,.09,(.57,3.57,0),'teal_dark',.16)
 cylinder(r,'Warm_lantern',.15,.32,(.57,3.36,0),'yellow')
 for dx in [-.17,.17]:
  for dz in [-.12,.12]:tube('Lantern_cage',[(.57+dx,3.17,dz),(.57+dx,3.52,dz)],.014,'teal_dark',r)
 cylinder(r,'Lantern_bottom',.21,.06,(.57,3.16,0),'teal_dark');return r

def bin_model(big=False):
 r=cn('MunicipalRecycling' if big else 'StreetRecycling')
 w,d,h=(1.65,.90,1.22) if big else (.62,.60,.97)
 box('Tapered_body',(w,h-.14,d),(0,h/2+.04,0),'teal',r,.085)
 for x in [-w*.43,w*.43]:
  for z in [-d*.36,d*.36]:
   o=cylinder(r,'Rubber_wheel',.09,.055,(x,.09,z),'ink');o.rotation_euler.x=math.pi/2
 for i in range(7):box('Reinforcing_rib',(.025,h*.67,.025),(-w*.4+i*w*.8/6,h*.51,d/2+.008),'teal_light',r,.008)
 box('Hinged_lid',(w+.09,.10,d+.10),(0,h+.02,0),'teal_dark',r,.05)
 tube('Lid_handle',[(-.10,h+.06,d*.18),(-.10,h+.13,d*.18),(.10,h+.13,d*.18),(.10,h+.06,d*.18)],.022,'steel_dark',r)
 box('Recycling_badge',(.35,.38,.018),(0,h*.62,d/2+.03),'cream',r,.035)
 letters('Recycling_symbol','♻',(0,h*.53,d/2+.047),.29,'teal',r,font='seguisym.ttf')
 for x in [-w*.50,w*.50]:tube('Side_lifting_handle',[(x,.85,-.15),(x*1.08,.85,-.15),(x*1.08,.85,.15),(x,.85,.15)],.025,'steel_dark',r)
 return r

def manhole():
 r=cn('CastIronManhole');cylinder(r,'Stone_ring',.56,.045,(0,.012,0),'stone')
 cylinder(r,'Iron_rim',.49,.035,(0,.037,0),'steel_dark');cylinder(r,'Recessed_lid',.455,.014,(0,.055,0),'ink')
 for x in range(-5,6):
  for z in range(-5,6):
   if x*x+z*z<27:box('Raised_tread',(.045,.009,.024),(x*.075,.068,z*.075),'steel',r,.004)
 for x in [-.30,.30]:box('Lifting_slot',(.065,.008,.12),(x,.071,0),'ink',r,.015)
 return r

def mushroom_v3():
 r=cn('LuminousGilledMushrooms')
 for i,(x,z,h) in enumerate([(-.13,.03,.17),(.09,0,.25),(.19,-.10,.12),(-.05,-.12,.09)]):
  rad=h*.44
  tube('Curved_stem',[(x,0,z),(x-.025,h*.25,z),(x+.015,h*.55,z),(x,h*.78,z)],h*.065,'cream',r)
  # Solid cap with a flared rim and convex crown, modelled as a revolved profile.
  cap=solid('Convex_cap',[(rad*.08,h),(rad*.40,h*.98),(rad*.77,h*.90),(rad,h*.77),(rad*.96,h*.71),(rad*.70,h*.73),(0,h*.75)],'mint',r,seg=32)
  cap.location.x= x;cap.location.y=-z
  for k in range(18):
   a=k*math.tau/18;tube('Radial_gill',[(x+math.cos(a)*rad*.13,h*.75,z+math.sin(a)*rad*.13),(x+math.cos(a)*rad*.90,h*.72,z+math.sin(a)*rad*.90)],.003,'cream',r)
  for k in range(6):
   a=k*2.4;oval('Cap_speckle',(x+math.cos(a)*rad*.45,h*.94,z+math.sin(a)*rad*.45),(.008,.003,.006),'cream',r)
 return r

def skeleton_v3():
 r=cn('AnatomicalCartoonSkeleton');bc.material('bone','#D8D0AF')
 def bone(a,b,rad=.032):
  tube('Bone_shaft',[a,b],rad,'bone',r)
  for p in [a,b]:oval('Bone_epiphysis',p,(rad*1.3,rad*1.3,rad*1.3),'bone',r)
 # Vertebrae, sacrum and tapered coccyx, not a solid torso.
 for i in range(14):
  y=.92+i*.047;oval('Vertebra',(0,y,-.025),(.044,.021,.042),'bone',r)
 mesh('Triangular_sacrum',[(-.058,.97,-.065),(.058,.97,-.065),(0,.855,-.085),(-.045,.97,-.025),(.045,.97,-.025),(0,.855,-.065)],[(0,1,2),(5,4,3),(0,3,4,1),(1,4,5,2),(2,5,3,0)],'bone',r)
 for j in range(4):oval('Coccygeal_vertebra',(0,.849-j*.015,-.083+j*.004),(.015-j*.0027,.010-j*.001,.010-j*.0015),'bone',r)
 for s in [-1,1]:
  tube('Iliac_crest',[(s*.02,1.01,0),(s*.16,1.04,-.02),(s*.20,.96,.015),(s*.13,.87,.055),(s*.04,.85,.035)],.035,'bone',r)
  tube('Pubic_arch',[(s*.13,.90,.06),(s*.09,.84,.09),(0,.85,.08)],.022,'bone',r)
  bone((s*.09,.89,0),(s*.13,.53,.015),.041);bone((s*.13,.50,.015),(s*.115,.12,.015),.027)
  bone((s*.16,.50,0),(s*.15,.13,-.015),.017)
  oval('Patella',(s*.13,.51,.055),(.035,.035,.021),'bone',r)
  bone((s*.02,1.48,0),(s*.23,1.47,0),.023)
  bone((s*.24,1.44,0),(s*.30,1.15,0),.030)
  bone((s*.30,1.12,0),(s*.30,.86,.025),.020);bone((s*.34,1.12,0),(s*.34,.86,.025),.015)
  for j in range(2):
   for k in range(3):oval('Carpal',(s*(.291+k*.014),.854-j*.015,.03),(.009,.009,.008),'bone',r)
  for k,length in enumerate([.090,.107,.100,.077]):
   x=s*(.284+k*.021);tip=s*(.275+k*.029)
   bone((s*.315,.825,.03),(x,.786,.039),.0075)
   bone((x,.786,.039),(tip,.786-length*.48,.048),.0065)
   bone((tip,.786-length*.48,.048),(tip,.786-length*.79,.056),.0057)
   bone((tip,.786-length*.79,.056),(tip,.786-length,.063),.005)
  bone((s*.293,.827,.04),(s*.252,.797,.055),.008)
  bone((s*.252,.797,.055),(s*.239,.767,.074),.007)
  bone((s*.239,.767,.074),(s*.244,.745,.087),.006)
  for k in range(5):bone((s*(.08+k*.018),.09,.025),(s*(.08+k*.018),.055,.16-k*.012),.012)
  for i in range(7):
   y=1.43-i*.052;ww=.20-i*.012
   tube('Curved_rib',[(s*.03,y,-.025),(s*ww,y-.01,-.06),(s*(ww+.025),y-.025,.03),(s*ww*.75,y-.055,.115),(s*.03,y-.055,.13)],.014,'bone',r)
 bone((0,1.13,.12),(0,1.44,.12),.020)
 skull=oval('Cranium',(0,1.72,0),(.125,.165,.108),'bone',r)
 # True recessed orbital cavities via booleans; eyeballs are absent.
 for x in [-.052,.052]:
  cutter=oval('Socket_cutter',(x,1.75,.095),(.044,.049,.065),'ink',r)
  bpy.context.view_layer.objects.active=skull;mod=skull.modifiers.new('Orbital_cavity','BOOLEAN');mod.operation='DIFFERENCE';mod.object=cutter
  bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(cutter,do_unlink=True)
  oval('Dark_orbit',(x,1.75,.065),(.035,.039,.019),'ink',r)
 mesh('Nasal_cavity',[(-.019,1.69,.108),(.019,1.69,.108),(0,1.73,.113)],[(0,1,2)],'ink',r)
 tube('Mandible',[(-.10,1.65,.02),(-.078,1.60,.09),(0,1.59,.115),(.078,1.60,.09),(.10,1.65,.02)],.022,'bone',r)
 for i in range(8):box('Tooth',(.015,.027,.017),(-.061+i*.0175,1.637,.111),'cream',r,.003)
 return r

def garden_composter():
 r=cn('GardenComposter')
 for x in [-.44,.44]:
  for z in [-.39,.39]:box('Corner_post',(.085,.98,.085),(x,.49,z),'teal_dark',r,.015)
 for i in range(7):
  y=.10+i*.115
  for z in [-.42,.42]:box('Ventilated_cedar_slat',(.90,.09,.055),(0,y,z),'wood' if i%2 else 'walnut',r,.009)
  for x in [-.44,.44]:box('Side_slat',(.055,.09,.82),(x,y,0),'wood',r,.009)
 lid=bc.pivot('LidHinge',bc.G(0,.96,-.40),r);lid['articulated']=True
 box('Green_lid',(.99,.075,.94),(0,0,.40),'teal',lid,.03)
 tube('Top_handle',[(-.12,.05,.58),(-.12,.12,.58),(.12,.12,.58),(.12,.05,.58)],.020,'steel_dark',lid)
 for x in [-.31,.31]:box('Hinge',(.075,.025,.12),(x,.995,-.39),'steel',r,.006)
 box('Lower_access_hatch',(.68,.24,.025),(0,.19,.465),'teal_dark',r,.015)
 tube('Hatch_handle',[(-.10,.22,.49),(-.10,.22,.53),(.10,.22,.53),(.10,.22,.49)],.012,'steel',r)
 box('Organic_badge',(.24,.22,.014),(0,.66,.47),'cream',r,.02)
 letters('Recycle','♻',(0,.59,.49),.19,'teal',r,font='seguisym.ttf')
 return r

def notary():
 r=cn('Notary');bc.material('suit','#26384D');bc.material('skin','#E8B98F');bc.material('silver','#BFC6CB');bc.material('tie','#833D4C')
 for s in [-1,1]:
  box('Formal_shoe',(.17,.11,.30),(s*.13,.07,.055),'wood_dark',r,.04)
  tube('Suit_trouser',[(s*.13,.15,0),(s*.12,.56,0),(s*.13,.92,0)],.083,'suit',r)
 oval('Suit_torso',(0,1.18,0),(.25,.34,.13),'suit',r)
 mesh('White_shirt',[(-.13,1.46,.124),(.13,1.46,.124),(0,1.13,.15)],[(0,1,2)],'cream',r)
 mesh('Silk_tie',[(-.026,1.40,.145),(.026,1.40,.145),(.035,1.22,.155),(0,1.17,.16),(-.035,1.22,.155)],[(0,1,2,3,4)],'tie',r)
 for s in [-1,1]:
  mesh('Notched_lapel',[(s*.12,1.47,.14),(s*.21,1.35,.14),(s*.14,1.33,.16),(s*.16,1.28,.16),(0,1.12,.16)],[(0,1,2,3,4)],'suit',r)
  mesh('Folded_shirt_collar',[(s*.015,1.48,.139),(s*.10,1.49,.127),(s*.072,1.389,.155),(s*.025,1.426,.160)],[(0,1,2,3)],'cream',r)
  tube('Lapel_pickstitch',[(s*.115,1.455,.146),(s*.194,1.352,.15),(s*.135,1.327,.166),(s*.151,1.283,.166),(s*.012,1.14,.165)],.0025,'steel',r)
  box('Pocket_welt',(.10,.012,.016),(s*.14,1.11,.128),'ink',r,.002)
  tube('Sleeve',[(s*.22,1.39,0),(s*.31,1.13,0),(s*.30,.98,.035)],.063,'suit',r)
  oval('Cuff',(s*.30,.97,.035),(.056,.035,.05),'cream',r);oval('Hand',(s*.30,.88,.05),(.060,.08,.045),'skin',r)
  for k in range(4):tube('Finger',[(s*(.265+k*.019),.88,.075),(s*(.265+k*.019),.80,.08)],.010,'skin',r)
 oval('Tie_knot',(0,1.433,.16),(.029,.027,.015),'tie',r)
 cylinder(r,'Neck',.07,.16,(0,1.54,0),'skin')
 oval('Head',(0,1.78,0),(.155,.23,.14),'skin',r)
 oval('Chin',(0,1.61,.07),(.092,.07,.08),'skin',r)
 for s in [-1,1]:
  for j in range(7):
   oval('Layered_silver_lock',(s*(.136+j*.0018),1.91-j*.023,-.04-j*.006),(.022,.044,.073),'silver',r)
  tube('Spectacle_temple',[(s*.137,1.82,.177),(s*.157,1.82,.08),(s*.164,1.80,-.015),(s*.16,1.765,-.025)],.005,'ink',r)
  oval('Ear',(s*.16,1.75,0),(.043,.064,.030),'skin',r)
  oval('Eye',(s*.067,1.82,.132),(.065,.072,.043),'cream',r);oval('Pupil',(s*.067,1.82,.174),(.011,.014,.007),'ink',r)
  front_loop('Spectacles',s*.067,1.82,.177,.070,.077,.006,'ink',r)
  tube('Eyebrow',[(s*.12,1.91,.13),(s*.065,1.92,.151),(s*.025,1.91,.14)],.012,'silver',r)
 tube('Glasses_bridge',[(-.009,1.83,.176),(.009,1.83,.176)],.006,'ink',r)
 oval('Long_nose',(0,1.75,.17),(.030,.075,.059),'skin',r)
 tube('Smile',[(-.05,1.67,.129),(0,1.66,.144),(.05,1.67,.129)],.005,'wood_dark',r)
 for i in range(4):tube('Combed_silver_hair',[(-.13,1.94,-.03),(-.05,2.015,-.03+i*.028),(.08,1.98,-.02+i*.025)],.012,'silver',r)
 for y in [1.04,1.14,1.24]:oval('Suit_button',(0,y,.138),(.012,.012,.006),'ink',r)
 for y in [1.945,1.965]:tube('Forehead_wrinkle',[(-.065,y,.100),(0,y+.006,.118),(.065,y,.100)],.0025,'wood',r)
 box('Legal_folder',(.29,.37,.035),(-.30,1.01,.11),'wood',r,.009)
 letters('Legal_title','ACTE',(-.30,1.07,.132),.042,'cream',r,font='georgia.ttf')
 return r

for name,fn in [('street_lamp',lamp),('recycling_bin',bin_model),('municipal_bin',lambda:bin_model(True)),('manhole',manhole),('mushroom',mushroom_v3),('skeleton',skeleton_v3),('notary',notary),('composter',garden_composter)]:
 ob=fn();bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BLEND,name+'.blend'));bc.export_glb(os.path.join(OUT,name+'.glb'),ob);print('DETAIL_MODEL',name,flush=True)
