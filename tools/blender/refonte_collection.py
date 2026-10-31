"""Reworked cellar equipment and detailed cartoon street vehicles, metres/Y-up."""
import os,sys,json,struct,math
import bpy
sys.path.insert(0,os.path.dirname(__file__))
exec(open(os.path.join(os.path.dirname(__file__),'surface_collection.py'),encoding='utf-8').read().split('\nSPECS=')[0],globals())
REV=os.path.join(bc.ROOT,'assets/models/street');RB=os.path.join(bc.ROOT,'art/blender/street');os.makedirs(REV,exist_ok=True);os.makedirs(RB,exist_ok=True)
def palette():
 for k,c in {'teal':'#53796B','teal_light':'#85A18C','teal_dark':'#2F4842','cream':'#E1DCC7','steel':'#98A39E','steel_dark':'#55625F','purple':'#668373','walnut':'#725B45','wood':'#AC9672','gold':'#B5A06C'}.items():
  m=bc._MATS[k];m.diffuse_color=bc.hex_color(c);m.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=bc.hex_color(c)
def revised_bed():
 r=root('ModularHorticultureBed');w=1.89;d=1.16
 for x in [-.86,.86]:
  for z in [-.48,.48]:box('Adjustable_foot',(.10,.10,.10),(x,.05,z),'steel_dark',r,.012);cylinder(r,'Levelling_bolt',.019,.07,(x,.12,z),'steel')
 for z in [-.54,.54]:
  for y in [.22,.36]:box('Timber_front',(w-.12,.125,.06),(0,y,z),'wood',r,.008)
  box('Reinforced_top_rail',(w,.065,.075),(0,.515,z),'steel',r,.01)
 for x in [-.90,.90]:
  box('End_plate',(.055,.35,d),(x,.335,0),'teal',r,.012)
  for z in [-.55,.55]:box('Metal_corner',(.07,.41,.07),(x,.31,z),'teal_dark',r,.008)
 box('Soil',(1.72,.045,.99),(0,.46,0),'soil',r,.008)
 tube('Drain_pipe',[(.80,.26,-.59),(.80,.10,-.59),(.94,.10,-.59)],.021,'steel_dark',r)
 for i in range(6):tube('Welded_crossbrace',[(-.80+i*.32,.145,-.48),(-.80+i*.32,.145,.48)],.012,'steel_dark',r)
 for x in [-.83,.83]:
  for y in [.22,.37]:screw(r,(x,y,.578),.009,'steel_dark')
 sign_part(r,'CULTURE',(0,.32,.578),.33,.12)
 return r
def revised_composter():
 r=root('SealedComposter');solid('Ribbed_vessel',[(.36,0),(.43,.05),(.46,.68),(.42,.77)],'teal',r)
 for y in [.08,.67]:ring('Steel_hoop',.455,y,.025,'steel_dark',r)
 for i in range(12):
  a=i*math.tau/12;tube('Moulded_rib',[(.45*math.cos(a),.13,.45*math.sin(a)),(.45*math.cos(a),.64,.45*math.sin(a))],.009,'teal_dark',r)
 lid=bc.pivot('LidHinge',bc.G(0,.79,-.43),r);lid['articulated']=True;cylinder(lid,'Cream_lid',.46,.045,(0,0,.43),'cream');tube('Lid_handle',[(-.09,.03,.43),(-.09,.08,.43),(.09,.08,.43),(.09,.03,.43)],.016,'steel_dark',lid)
 box('Intake',(.50,.18,.035),(0,.37,.45),'ink',r,.025)
 jaw=bc.pivot('Jaw',bc.G(0,.28,.46),r);jaw['articulated']=True;box('Feed_hatch',(.52,.17,.035),(0,.09,.012),'cream',jaw,.02);tube('Feed_grip',[(-.11,.12,.04),(.11,.12,.04)],.014,'steel_dark',jaw)
 sign_part(r,'COMPOST',(0,.59,.44),.38,.10)
 return r
def revised_counter():
 r=counter()
 for x in [-1.34,1.34]:box('Reinforced_corner',(.045,1.02,.045),(x,.51,.40),'steel',r,.006)
 for x in [-.86,0,.86]:
  box('Drawer_recess',(.69,.27,.025),(x,.75,.455),'teal_dark',r,.012)
  box('Drawer_face',(.65,.23,.026),(x,.75,.474),'cream',r,.012)
  tube('Drawer_handle',[(x-.08,.78,.495),(x-.08,.78,.52),(x+.08,.78,.52),(x+.08,.78,.495)],.011,'steel_dark',r)
 return r
def revised_cabinet():
 r=cabinet()
 for x in [-.86,.86]:
  box('Steel_corner',(.04,1.82,.035),(x,.91,-.27),'steel',r,.006)
 for y in [.57,1.19,1.81]:box('Shelf_edge',(1.76,.025,.025),(0,y,.263),'teal_dark',r,.005)
 return r
def revised_terminal(kind):
 r=terminal(kind)
 for i in range(3):
  x=-.13+i*.13;box('Service_switch',(.06,.03,.035),(x,.83,.25),'steel',r,.005)
 for y in [.20,.29,.38]:box('Pedestal_vent',(.28,.012,.012),(0,y,.224),'steel_dark',r,.002)
 for x in [-.20,.20]:screw(r,(x,.58,.226),.009,'steel')
 return r
def vehicle(van=False):
 r=root('DeliveryVan' if van else 'CartoonCompactCar');bc.material('paint','#568C87' if van else '#BD6E69');bc.material('windshield','#7C9FA5');bc.material('rubber','#292D31');bc.material('chrome','#B2B6A8')
 box('Rounded_body',(4.18,.65,1.72),(0,.72,0),'paint',r,.14)
 box('Sill',(3.9,.17,1.76),(0,.40,0),'steel_dark',r,.045)
 if van:
  box('Cargo_box',(2.6,1.3,1.7),(-.62,1.53,0),'cream',r,.10)
  mesh('Cab_roof',[(-.15,1.06,-.75),(-.10,2.10,-.68),(1.05,2.04,-.65),(1.75,1.12,-.74),(-.15,1.06,.75),(-.10,2.10,.68),(1.05,2.04,.65),(1.75,1.12,.74)],[(0,1,2,3),(4,7,6,5),(1,5,6,2),(0,4,5,1),(3,2,6,7)],'paint',r,.045)
  for z in [-.764,.764]:
   mesh('Driver_window',[(.02,1.24,z),(.02,1.90,z),(.94,1.87,z),(1.39,1.24,z)],[(0,1,2,3)],'windshield',r,.007)
   box('Door_handle',(.22,.045,.025),(.07,1.13,z*1.01),'chrome',r,.008)
   box('Cargo_lower_rail',(2.4,.045,.025),(-.62,1.18,z*1.13),'steel_dark',r,.006)
 else:
  mesh('Sculpted_cabin',[(-1.52,1.02,-.76),(-.92,1.73,-.64),(.56,1.76,-.64),(1.30,1.02,-.76),(-1.52,1.02,.76),(-.92,1.73,.64),(.56,1.76,.64),(1.30,1.02,.76)],[(0,1,2,3),(4,7,6,5),(1,5,6,2),(0,4,5,1),(3,2,6,7)],'paint',r,.06)
  for z in [-.754,.754]:
   mesh('Side_windows',[(-1.22,1.13,z),(-.82,1.60,z*.88),(.47,1.63,z*.88),(1.03,1.13,z)],[(0,1,2,3)],'windshield',r,.008)
   tube('Window_pillar',[(-.18,1.12,z),(-.18,1.65,z*.87)],.026,'steel_dark',r)
   box('Door_handle',(.19,.045,.025),(-.48,1.01,z*1.15),'chrome',r,.009)
  mesh('Windscreen',[(.62,1.65,-.56),(.62,1.65,.56),(1.18,1.09,.69),(1.18,1.09,-.69)],[(0,1,2,3)],'windshield',r,.008)
 for x in [-1.30,1.30]:
  for z in [-.86,.86]:
   wh=bc.cylinder('Tire',.36,.36,.19,(x,.36,z),'rubber',r,seg=24,bevel=.022);wh.rotation_euler.x=math.pi/2
   hub=bc.cylinder('Hubcap',.20,.20,.205,(x,.36,z),'chrome',r,seg=20,bevel=.008);hub.rotation_euler.x=math.pi/2
   small=bc.cylinder('Hub',.065,.065,.215,(x,.36,z),'steel_dark',r,seg=12,bevel=.004);small.rotation_euler.x=math.pi/2
 for x in [-2.10,2.10]:
  box('Bumper',(.10,.12,1.51),(x,.47,0),'chrome',r,.035)
  for z in [-.57,.57]:box('Headlight',(.035,.18,.26),(x,.79,z),'cream' if x>0 else 'coral',r,.028)
  box('License_plate',(.021,.11,.40),(x,.57,0),'cream',r,.005)
 for z in [-.91,.91]:
  tube('Mirror_arm',[(.55,1.19,z),(.55,1.22,z*1.08)],.018,'steel_dark',r);box('Rearview_mirror',(.20,.13,.10),(.55,1.23,z*1.10),'paint',r,.028)
 return r
spec=[('grow_bed',revised_bed),('composter',revised_composter),('counter',revised_counter),('cabinet',revised_cabinet),('single_pot',singlepot),('single_lamp',singlelamp),('bed_lamp',bedlamp)]+[('terminal_'+k,lambda k=k:revised_terminal(k)) for k in ['capacity','lamp','filter','lock']]
report=[]
for name,build in spec:
 r=build();palette();out=os.path.join(bc.ROOT,'assets/models/cellar',name+'.glb');bpy.ops.wm.save_as_mainfile(filepath=os.path.join(bc.ROOT,'art/blender/cellar',name+'.blend'));bc.export_glb(out,r);report.append(name)
for name,build in [('compact_car',lambda:vehicle(False)),('delivery_van',lambda:vehicle(True))]:
 r=build();bpy.ops.wm.save_as_mainfile(filepath=os.path.join(RB,name+'.blend'));bc.export_glb(os.path.join(REV,name+'.glb'),r);report.append(name)
json.dump({'assets':report},open(os.path.join(bc.ROOT,'out/refonte_model_manifest.json'),'w'),indent=2);print('REFONTE_MODELS_COMPLETE',len(report),flush=True)
