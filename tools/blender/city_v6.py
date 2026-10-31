"""Models based on art/concepts/city_v6/composter_residents_sheet.png. Y-up metres."""
import os, sys, math, bpy
sys.path.insert(0,os.path.dirname(__file__))
exec(open(os.path.join(os.path.dirname(__file__),'surface_collection.py'),encoding='utf-8').read().split('\nSPECS=')[0],globals())
OUT=os.path.join(bc.ROOT,'assets/models/city_v6'); SOURCE=os.path.join(bc.ROOT,'art/blender/city_v6')
os.makedirs(OUT,exist_ok=True);os.makedirs(SOURCE,exist_ok=True)

def compost():
 r=root('GoofyComposter')
 for role,col in {'cedar':'#62745A','rust':'#805138','ivory':'#EFE4CB','soil':'#342D24'}.items():bc.material(role,col)
 box('Dark_interior',(.91,.96,.82),(0,.53,0),'soil',r,.025)
 for i in range(8):
  y=.13+i*.115
  for z in [-.44,.44]:
   if z>0 and i in [3,4]:continue
   box('Weathered_slat',(.96,.09,.065),(0,y,z),'cedar',r,.006)
   for x in [-.40,.40]:oval('Rusty_nail',(x,y,z+math.copysign(.035,z)),(.013,.013,.007),'rust',r)
  for x in [-.47,.47]:box('Side_slat',(.06,.09,.85),(x,y,0),'cedar',r,.005)
 for x in [-.47,.47]:
  for z in [-.45,.45]:box('Iron_corner',(.07,1.08,.07),(x,.55,z),'rust',r,.008)
 lid=bc.pivot('LidHinge',bc.G(0,1.08,-.45),r);lid['articulated']=True
 for i in range(6):box('Lid_plank',(.174,.06,1.02),(-.435+i*.174,0,.45),'cedar',lid,.006)
 for x in [-.29,.29]:
  box('Hinge',(.09,.035,.18),(x,1.12,-.43),'rust',r,.008)
  oval('Eye_white',(x,.88,.50),(.155,.18,.095),'ivory',r)
  oval('Pupil',(x+.025,.87,.585),(.064,.077,.022),'ink',r)
  oval('Eye_glint',(x+.005,.90,.605),(.018,.023,.009),'cream',r)
  b=box('Goofy_eyebrow',(.32,.065,.09),(x,1.065,.51),'walnut',r,.01);b.rotation_euler.y=x*.6
 for x,y in [(-.20,.59),(.18,.60)]:box('Uneven_tooth',(.11,.145,.055),(x,y,.49),'ivory',r,.018)
 tube('Hatch_handle',[(-.13,.18,.49),(-.13,.18,.56),(.13,.18,.56),(.13,.18,.49)],.018,'rust',r)
 return r

def resident(index):
 r=root('Resident_'+str(index))
 palettes=[('#E6B38E','#A45E40','#303F54','#352C29'),('#875A41','#3D6E67','#373D3D','#282622'),('#E5BBA1','#715365','#616449','#C8C9C0')]
 for role,col in zip(['skin','coat','pants','hair'],palettes[index]):bc.material(role,col)
 bc.material('ivory','#E8DEC8')
 # Rigid articulated limbs keep this modest mesh animation inexpensive.
 for side in [-1,1]:
  leg=bc.pivot('Leg_'+str(0 if side<0 else 1),bc.G(side*.115,.82,0),r);leg['articulated']=True
  box('Trouser_leg',(.17,.66,.20),(0,-.34,0),'pants',leg,.045)
  box('Leather_shoe',(.20,.12,.32),(0,-.76,.05),'walnut',leg,.035)
  box('Sole',(.205,.025,.33),(0,-.815,.05),'wood_dark',leg,.006)
  arm=bc.pivot('Arm_'+str(0 if side<0 else 1),bc.G(side*.30,1.40,0),r);arm['articulated']=True
  box('Jacket_sleeve',(.17,.43,.20),(side*.025,-.20,0),'coat',arm,.06)
  oval('Hand',(side*.04,-.50,.01),(.075,.13,.065),'skin',arm)
  for j in range(4):box('Finger',(.020,.065,.035),(side*.04-.030+j*.02,-.59,.035),'skin',arm,.008)
 box('Jacket_body',(.52,.57,.29),(0,1.15,0),'coat',r,.075)
 box('Shirt_front',(.19,.47,.025),(0,1.18,.155),'ivory',r,.01)
 for side in [-1,1]:
  lapel=box('Lapel',(.10,.25,.025),(side*.12,1.33,.18),'coat',r,.009);lapel.rotation_euler.y=side*.2
  box('Patch_pocket',(.13,.14,.025),(side*.18,1.02,.165),'coat',r,.012)
 for i in range(4):oval('Button',(.045,1.02+i*.085,.178),(.012,.012,.008),'walnut',r)
 cylinder(r,'Neck',.075,.16,(0,1.49,0),'skin')
 head=bc.pivot('Head',bc.G(0,1.72,0),r);head['articulated']=True
 oval('Face',(0,0,0),(.205,.255,.19),'skin',head)
 oval('Hair_cap',(0,.14,-.025),(.212,.135,.185),'hair',head)
 if index==0:
  for side in [-1,1]:oval('Bob_side',(side*.18,-.015,-.025),(.07,.19,.16),'hair',head)
 elif index==1:
  for j in range(16):
   a=j*2.4;oval('Curl',(.16*math.cos(a),.18+(j%3)*.025,.12*math.sin(a)),(.055,.055,.05),'hair',head)
 else:oval('Silver_bun',(0,.12,-.21),(.115,.115,.10),'hair',head)
 for side in [-1,1]:
  oval('Ear',(side*.205,-.01,0),(.043,.065,.035),'skin',head)
  oval('Eye',(side*.078,.025,.17),(.048,.037,.018),'cream',head)
  oval('Iris',(side*.078,.025,.185),(.021,.027,.009),'walnut',head)
  oval('Pupil',(side*.078,.026,.193),(.011,.018,.005),'ink',head)
  oval('Glint',(side*.078-.006,.037,.198),(.005,.006,.003),'cream',head)
  tube('Eyebrow',[(side*.045,.087,.18),(side*.08,.095,.18),(side*.115,.085,.17)],.009,'hair',head)
 oval('Nose',(0,-.025,.195),(.033,.05,.043),'skin',head)
 tube('Smile',[(-.055,-.115,.17),(0,-.13,.18),(.055,-.115,.17)],.008,'walnut',head)
 if index==2:
  bc.lathe('Long_skirt',[(.28,.34),(.29,.4),(.22,.86),(.20,.95)],'pants',r,seg=20,subsurf=0)
 return r

def umbrella():
 r=root('TailoredBistroParasol')
 cylinder(r,'Weighted_base',.29,.09,(0,.045,0),'teal_dark')
 cylinder(r,'Mast',.025,2.55,(0,1.32,0),'walnut')
 cylinder(r,'Sliding_collar',.045,.18,(0,2.05,0),'gold')
 for k in range(10):
  a=k*math.tau/10;b=(k+1)*math.tau/10;verts=[]
  for row in range(6):
   rr=row/5*1.18
   for j in range(5):
    q=a+(b-a)*j/4;yy=2.73-.43*(rr/1.18)**1.35-.035*math.sin(math.pi*j/4)*(rr/1.18)
    verts.append((rr*math.cos(q),yy,rr*math.sin(q)))
  faces=[(i*5+j,i*5+j+1,(i+1)*5+j+1,(i+1)*5+j) for i in range(5) for j in range(4)]
  mesh('Sewn_canvas_panel',verts,faces,'cream' if k%2 else 'teal_light',r,.002)
  points=[(rr*math.cos(a),2.71-.43*(rr/1.18)**1.35,rr*math.sin(a)) for rr in [0,.3,.6,.9,1.18]]
  tube('Curved_rib',points,.009,'steel_dark',r)
  tube('Seam_piping',[(x,y+.025,z) for x,y,z in points],.004,'gold',r)
  tube('Spreader',[(0,2.10,0),(.6*math.cos(a),2.48,.6*math.sin(a))],.008,'steel_dark',r)
  mesh('Hem_valance',[(1.18*math.cos(q),y,1.18*math.sin(q)) for q,y in [(a,2.30),(b,2.30),(b,2.18),((a+b)/2,2.14),(a,2.18)]],[(0,1,2,3,4)],'cream' if k%2 else 'teal_light',r,.002)
 oval('Finial',(0,2.77,0),(.035,.065,.035),'gold',r)
 return r

for name,fn in [('composter',compost),('resident_0',lambda:resident(0)),('resident_1',lambda:resident(1)),('resident_2',lambda:resident(2)),('parasol',umbrella)]:
 bc.reset_scene();ob=fn()
 # Low resolution primitives and planar canvas; no subdivision modifier at export.
 for m in bpy.data.objects:
  if m.type=='MESH':
   for mod in list(m.modifiers):
    if mod.type=='SUBSURF':m.modifiers.remove(mod)
 bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SOURCE,name+'.blend'))
 bc.export_glb(os.path.join(OUT,name+'.glb'),ob)
 print('CITY_MODEL',name,flush=True)
