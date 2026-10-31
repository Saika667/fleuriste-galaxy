"""Editable metric cellar collection for the 44 approved concept families. Y up/+Z front."""
import os,sys,math,json,struct,random
import bpy
from mathutils import Vector
sys.path.insert(0,os.path.dirname(__file__))
exec(open(os.path.join(os.path.dirname(__file__),'shop_items_74_89.py'),encoding='utf-8').read().split('\nSPECS=')[0],globals())
OUT=os.path.join(bc.ROOT,'assets/models/cellar');BLEND=os.path.join(bc.ROOT,'art/blender/cellar')
os.makedirs(OUT,exist_ok=True);os.makedirs(BLEND,exist_ok=True)
def cn(name):
    r=new(name)
    for k,v in {'teal':'#285954','teal_light':'#4E8274','teal_dark':'#183F40','walnut':'#795136','wood':'#A5774B','wood_dark':'#503827','stone':'#4D4659','stone_dark':'#393443','steel':'#9AA7AD','steel_dark':'#54636B','purple':'#68437D','leaf':'#295F46','leaf_light':'#538965','bud':'#81508C','mint':'#91E1C1'}.items():bc.material(k,v)
    for role in ['mint','yellow']:
        b=bc._MATS[role].node_tree.nodes['Principled BSDF'];b.inputs['Emission Color'].default_value=bc._MATS[role].diffuse_color;b.inputs['Emission Strength'].default_value=.45
    return r
def cylinder(r,name,rad,h,p,role='steel',r2=None):return bc.cylinder(name,rad,rad if r2 is None else r2,h,p,role,r,seg=20,bevel=.003)
def rivets(r,w,h,z,y=0):
    for sx in [-1,1]:
        for sy in [-1,1]:screw(r,(sx*(w/2-.025),y+sy*(h/2-.025),z),.012,'steel')
def sign_part(r,body,p,w=.8,h=.25):
    box('Sign_timber',(w,h,.04),p,'wood_dark',r,.015)
    box('Sign_cream_face',(w-.03,h-.03,.006),(p[0],p[1],p[2]+.025),'cream',r,.009)
    ob=letters('Flat_sign',body,(p[0],p[1],p[2]+.030),min(.12,h*.32),'teal_dark',r)
    bpy.context.view_layer.update()
    if ob.dimensions.x>w*.9:ob.scale*=w*.9/ob.dimensions.x
    rivets(r,w,h,p[2]+.03,p[1]) if p[0]==0 else None
def board(body):
    r=cn('Plaque');has_arrow='→' in body;sign_part(r,body.replace(' →',''),(0,0,0))
    if has_arrow:
        for ob in r.children:
            if ob.name.startswith('Flat_sign'):ob.location.x-=.045;ob.scale*=.82
        mesh('Direction_arrow',[(.28,-.04,.036),(.36,0,.036),(.28,.04,.036)],[(0,1,2)],'teal_dark',r,.002)
    return r
def floor():
    r=cn('Floor24x18')
    for ix in range(24):
        for iz in range(18):box('Stone_slab',(.992,.045,.992),(-11.5+ix,-.0225,-8.5+iz),'stone' if (ix+iz)%5 else 'stone_dark',r,.008)
    for x in [-11.96,11.96]:box('Plinth',(.08,.18,18),(x,.09,0),'stone_dark',r,.01)
    for z in [-8.96,8.96]:box('Plinth',(24,.18,.08),(0,.09,z),'stone_dark',r,.01)
    return r
def ceiling():
    r=cn('CeilingBeams24x18')
    box('Ceiling_slab',(24,.08,18),(0,.04,0),'stone_dark',r)
    for z in [-7.5,-4.5,-1.5,1.5,4.5,7.5]:
        box('Timber_beam',(24,.21,.24),(0,-.105,z),'walnut',r,.018)
        for x in [-11.6,-6,0,6,11.6]:
            box('Iron_beam_strap',(.16,.24,.27),(x,-.12,z),'steel_dark',r,.009)
            for dz in [-.141,.141]:screw(r,(x,-.13,z+dz),.02,'steel')
    return r
def vent():
    r=cn('VentSocket')
    box('Upper_box',(.66,.34,.60),(0,.17,0),'steel',r,.025)
    box('Dark_open_socket',(.58,.025,.51),(0,-.015,0),'ink',r,.009)
    for x in [-.32,.32]:box('Filter_slide_rail',(.035,.20,.61),(x,-.10,0),'steel_dark',r,.006)
    for z in [-.295,.295]:box('Grille_frame',(.68,.04,.04),(0,-.03,z),'steel',r,.005)
    for i in range(10):box('Grille_louvre',(.57,.022,.035),(0,-.025,-.24+i*.053),'steel_dark',r,.004)
    for x in [-.28,.28]:
        for z in [-.245,.245]:cylinder(r,'Ceiling_bolt',.014,.045,(x,.36,z),'steel')
    return r
def filter_cartridge():
    r=cn('RemovableCharcoalCartridge');r['articulated']=True
    box('Charcoal_body',(.57,.16,.50),(0,0,0),'ink',r,.015)
    for x in [-.275,.275]:box('Metal_side',(.025,.17,.52),(x,0,0),'steel_dark',r,.004)
    for i in range(12):
        for j in range(9):box('Filter_mesh',(.035,.003,.035),(-.25+i*.045,-.083,-.20+j*.05),'gray',r,.003)
    tube('Pull_handle',[(-.10,-.01,.275),(-.10,-.07,.30),(.10,-.07,.30),(.10,-.01,.275)],.016,'steel',r)
    return r
def duct():
    r=cn('SilverDuct1m');tube('Main_duct',[(-.5,0,0),(.5,0,0)],.115,'steel',r)
    for x in [-.48,0,.48]:
        g=bc.pivot('Flange',bc.G(x,0,0),r);g.rotation_euler.y=math.pi/2
        front_loop('Flange_ring',0,0,0,.128,.128,.012,'steel_dark',g)
    tube('Hanger',[(-.02,.14,0),(-.02,.40,0)],.013,'steel_dark',r);box('Ceiling_anchor',(.12,.022,.12),(0,.40,0),'steel_dark',r)
    return r
def elbow():
    r=cn('SilverElbow');tube('Bent_duct',[(0,0,0),(.12,0,0),(.27,-.03,0),(.36,-.13,0),(.38,-.27,0)],.115,'steel',r);return r
def stairs():
    r=cn('Stairs380')
    for k in range(19):
        y=(k+1)*.20;z=-k*.28
        box('Wood_tread',(1.55,.075,.29),(0,y,z),'wood',r,.014)
        box('Step_fascia',(1.50,.17,.03),(0,y-.10,z+.14),'walnut',r,.008)
        if k%3==0:
            for x in [-.72,.72]:
                tube('Rail_post',[(x,y,z),(x,y+.9,z)],.035,'walnut',r)
    for x in [-.72,.72]:
        tube('Continuous_hand_rail',[(x,1.10,.08),(x,4.7,-5.12)],.045,'wood',r)
        tube('Structural_stringer',[(x,.09,.08),(x,3.69,-5.12)],.09,'wood_dark',r)
    return r
def lantern():
    r=cn('Lantern');cylinder(r,'Lower_cap',.16,.07,(0,.035,0),'ink');cylinder(r,'Upper_cap',.17,.06,(0,.52,0),'ink')
    for x in [-.12,.12]:
        for z in [-.12,.12]:tube('Cage',[(x,.06,z),(x,.49,z)],.018,'ink',r)
    box('Amber_diffuser',(.21,.40,.21),(0,.28,0),'yellow',r,.025)
    tube('Suspension_cable',[(0,.55,0),(0,1.10,0)],.012,'ink',r);box('Ceiling_rose',(.14,.04,.14),(0,1.10,0),'ink',r)
    return r
def bulb():
    r=cn('HangingBulb');oval('Bulb',(0,0,0),(.10,.14,.10),'yellow',r);cylinder(r,'Socket',.055,.10,(0,.16,0),'steel');tube('Cord',[(0,.21,0),(0,.65,0)],.009,'ink',r);return r
def garland():
    r=cn('Garland');pts=[(-2+i*.1,-.18*(1-((-2+i*.1)/2)**2),0) for i in range(41)];tube('Cable',pts,.01,'ink',r)
    for i in range(14):
        x=-1.9+i*.29;y=-.18*(1-(x/2)**2);cylinder(r,'Socket',.022,.05,(x,y-.02,0),'ink');oval('Small_bulb',(x,y-.08,0),(.04,.065,.04),['mint','pink','yellow','lavender'][i%4],r)
    return r
def vessel(kind='harvest',q=1):
    r=cn('Jar_'+kind);rad=.10 if kind!='tip' else .14;h=.24 if kind!='tip' else .28
    solid('Glass_jar',[(rad*.85,.008),(rad,.025),(rad,h-.03),(rad*.92,h)],'glass',r,seg=32)
    if kind!='tip':cylinder(r,'Lid',rad*1.05,.03,(0,h+.015,0),'teal')
    if kind in ['harvest','culture']:
        for i in range(13):
            a=i*2.4;rr=(i%3)*rad*.24;oval('Contents_on_bottom',(rr*math.cos(a),.03+(i//4)*.033,rr*math.sin(a)),(.025,.025,.025),['leaf','leaf_light','bud','purple'][q-1],r)
        box('Label',(.11,.11,.006),(0,.12,rad+.003),'cream',r,.008);motif(r,0,.13,rad+.008,.04,'leaf');letters('Flat_quality',str(q),(0,.083,rad+.011),.035,'teal',r)
    elif kind=='tip':
        for k in range(7):cylinder(r,'Coin',.026,.008,((k%3-1)*.04,.01+k//3*.009,(k%2)*.035),'gold')
        letters('Flat_tips','MERCI',(0,.14,rad+.003),.045,'teal',r)
    return r
def tools(kind):
    r=cn(kind)
    if kind=='bucket':
        solid('Metal_bucket',[(.13,.008),(.15,.03),(.19,.31),(.20,.32)],'steel_dark',r);ring('Rolled_lip',.20,.32,.012,'steel',r)
        tube('Swing_handle',[(-.20,.29,0),(-.20,.49,0),(0,.58,0),(.20,.49,0),(.20,.29,0)],.009,'steel',r)
    elif kind=='trowel':
        tube('Wood_handle',[(0,0,0),(0,.17,0)],.025,'olive',r);tube('Ferrule',[(0,.16,0),(0,.23,0)],.018,'steel',r)
        mesh('Concave_pointed_blade',[(0,.20,-.015),(-.06,.27,0),(-.055,.36,0),(0,.43,.01),(.055,.36,0),(.06,.27,0),(0,.31,-.025)],[(6,i,(i+1)%6) for i in range(6)],'steel',r,.008)
    elif kind=='shears':
        for s in [-1,1]:
            front_loop('Finger_loop',s*.036,.045,0,.032,.055,.009,'teal',r)
            tube('Steel_blade',[(s*.017,.09,0),(-s*.020,.15,0),(-s*.045,.23,0)],.012,'steel',r)
        oval('Pivot',(0,.12,.012),(.017,.017,.008),'gold',r)
    elif kind=='watering_can':
        solid('Can_body',[(.14,.01),(.18,.03),(.18,.25),(.15,.29)],'teal',r)
        tube('Spout',[(.14,.06,0),(.27,.14,0),(.36,.30,0)],.035,'teal',r)
        oval('Sprinkler_head',(.36,.31,0),(.065,.026,.065),'steel',r)
        tube('Handle',[(-.14,.08,0),(-.30,.10,0),(-.32,.30,0),(-.13,.30,0)],.021,'teal',r)
    elif kind=='power_strip':
        box('Strip',(.36,.045,.09),(0,.023,0),'cream',r,.015)
        for x in [-.12,-.04,.04]:
            cylinder(r,'Recessed_socket',.029,.004,(x,.047,0),'gray')
            for z in [-.01,.01]:cylinder(r,'Plug_hole',.004,.005,(x,.050,z),'ink')
        box('Switch',(.03,.006,.045),(.13,.05,0),'coral',r);tube('Wire',[(.18,.03,0),(.35,.02,.08),(.50,.01,0)],.008,'ink',r)
    elif kind=='label':sign_part(r,'',(0,.05,0),.18,.10);box('Clip',(.03,.09,.03),(0,0,-.04),'steel_dark',r)
    return r
def terminal(kind):
    r=cn('Terminal_'+kind);box('Foot',(.55,.08,.55),(0,.04,0),'ink',r,.025);box('Walnut_pedestal',(.42,.75,.43),(0,.43,0),'walnut',r,.02)
    g=bc.pivot('SlopedControlPanel',bc.G(0,.98,.02),r);g.rotation_euler.x=-.23
    box('Teal_panel',(.53,.53,.20),(0,0,0),'teal_dark',g,.035);box('Screen',(.38,.22,.015),(0,.07,.11),'ink',g,.015)
    for i in range(3):oval('Level_light',(-.10+i*.10,-.10,.115),(.025,.025,.009),'mint',g)
    box('Button',(.14,.05,.024),(0,-.19,.12),'gold',g,.01)
    letters('Flat_title',{'capacity':'ESPACE','lamp':'LAMPES','filter':'FILTRE','lock':'SERRURE'}[kind],(0,.074,.123),.07,'mint',g)
    cylinder(r,'Badge_stem',.025,.15,(0,1.38,0),'steel')
    front_loop('Badge',0,1.52,0,.12,.12,.025,'steel_dark',r)
    letters('Flat_badge',{'capacity':'+','lamp':'L','filter':'F','lock':'S'}[kind],(0,1.52,.025),.15,'mint',r)
    return r
def cabinet():
    r=cn('StockCabinet');w=1.8
    for x in [-.87,.87]:box('Side',(.06,1.8,.50),(x,.90,0),'walnut',r,.012)
    box('Rear',(1.8,1.8,.04),(0,.90,-.24),'wood_dark',r)
    for y in [.06,.55,1.17,1.79]:box('Shelf',(1.8,.04,.50),(0,y,0),'wood',r,.009)
    for x in [-.90,.90]:box('Iron_frame',(.055,1.85,.055),(x,.92,.26),'teal_dark',r,.009)
    # Upper storage stays accessible; doors are open at the sides.
    for s in [-1,1]:
        g=bc.pivot('DoorHinge_'+str(s),bc.G(s*.86,.55,.25),r);g['articulated']=True;g.rotation_euler.z=s*math.radians(105)
        box('Door',(.82,1.24,.04),(-s*.41,.62,0),'walnut',g,.01)
        for y in [.10,1.13]:box('Door_strap',(.82,.05,.02),(-s*.41,y,.03),'teal_dark',g)
    box('Lower_front',(1.70,.43,.04),(0,.29,.26),'walnut',r,.01);return r
def lock():
    r=cn('CabinetLock');box('Reinforced_lock',(.24,.22,.06),(0,0,0),'teal_dark',r,.02);front_loop('Dial',0,0,.04,.065,.065,.012,'steel',r);oval('LED',(.075,.07,.04),(.018,.018,.008),'mint',r);return r
def lock_version(level):
    r=lock()
    if level==2:
        box('Code_screen',(.12,.04,.012),(0,.055,.065),'mint',r,.005)
        for i in range(6):box('Key',(.025,.024,.015),(-.045+(i%3)*.045,-.015-(i//3)*.04,.072),'steel',r,.003)
    else:
        front_loop('Heavy_wheel',0,0,.08,.085,.085,.014,'steel',r)
        for i in range(4):a=i*math.pi/2;tube('Wheel_spoke',[(0,0,.08),(.08*math.cos(a),.08*math.sin(a),.08)],.009,'steel',r)
        box('Heavy_reinforcement',(.32,.055,.045),(0,-.10,.03),'steel_dark',r,.006)
    return r
def composter():
    r=cn('ComposterMonster');solid('Purple_staves',[(.39,.0),(.46,.08),(.48,.40),(.44,.78)],'purple',r)
    for y in [.08,.38,.70]:ring('Iron_hoop',.47 if y<.7 else .45,y,.026,'ink',r)
    lid=bc.pivot('LidHinge',bc.G(0,.79,-.43),r);lid['articulated']=True;cylinder(lid,'Round_lid',.46,.045,(0,0,.43),'purple')
    for x in [-.18,.18]:oval('Eye',(x,.60,.405),(.11,.11,.075),'cream',r);oval('Pupil',(x,.59,.47),(.042,.05,.02),'ink',r)
    oval('Mouth',(0,.29,.45),(.31,.14,.035),'ink',r)
    for i in range(7):box('Upper_tooth',(.055,.07,.04),(-.23+i*.077,.38,.49),'bone',r,.007)
    jaw=bc.pivot('Jaw',bc.G(0,.20,.46),r);jaw['articulated']=True
    box('Lower_jaw',(.57,.05,.07),(0,0,0),'bone',jaw,.008)
    for i in range(6):box('Lower_tooth',(.055,.06,.035),(-.21+i*.084,.045,0),'bone',jaw,.005)
    return r
def counter():
    r=cn('ClandestineCounter')
    box('Plinth',(2.8,.12,.85),(0,.06,0),'wood_dark',r,.02)
    for x in [-1.35,1.35]:box('Side',(.09,.96,.80),(x,.58,0),'walnut',r,.012)
    box('Front',(2.68,.88,.055),(0,.60,.38),'walnut',r,.01);moulded_panel(r,2.35,.55,0,.62,.414,'wood_dark');motif(r,0,.62,.44,.16,'gold')
    box('Top',(3,.10,1),(0,1.09,0),'purple',r,.025)
    for y in [.17,.63]:box('Rear_service_shelf',(2.65,.04,.70),(0,y,-.02),'wood',r,.008)
    for x in [-1.39,1.39]:box('Corner_guard',(.055,.97,.06),(x,.60,.42),'gold',r,.007)
    return r
def register():
    r=cn('Register');box('Drawer_case',(.46,.12,.36),(0,.06,0),'teal_dark',r,.018)
    g=bc.pivot('CashDrawer',bc.G(0,.045,.18),r);g['articulated']=True;box('Drawer_front',(.43,.065,.02),(0,0,0),'steel',g,.006)
    box('Keyboard',(.44,.10,.28),(0,.17,0),'teal',r,.018)
    for x in range(6):
        for z in range(4):box('Key',(.046,.012,.038),(-.16+x*.063,.228,-.07+z*.054),'cream' if x<5 else 'gold',r,.004)
    box('Display_support',(.08,.10,.045),(0,.28,-.10),'teal_dark',r)
    box('Screen_case',(.29,.16,.07),(0,.39,-.10),'teal_dark',r,.015);box('Display',(.25,.11,.005),(0,.40,-.062),'ink',r)
    letters('Flat_display','GALAXY',(0,.40,-.056),.046,'mint',r);return r
def seed_crate():
    r=cn('SeedCrate')
    for z in [-.25,.25]:
        for y in [.08,.20,.32]:box('Slat',(.80,.11,.035),(0,y,z),'walnut',r,.006)
    for x in [-.39,.39]:box('End',(.035,.36,.50),(x,.18,0),'wood',r,.008)
    box('Base',(.80,.04,.50),(0,.02,0),'walnut',r)
    for x in [-.20,0,.20]:box('Divider',(.018,.24,.46),(x,.15,0),'wood',r)
    for i in range(4):
        box('Seed_packet',(.15,.22,.022),(-.29+i*.19,.20,0),['sage','pink','lavender','ochre'][i],r,.008);motif(r,-.29+i*.19,.20,.017,.08,'teal')
    return r
def sewer():
    r=cn('SewerSurround');box('Stone_surround',(1.6,.06,1.6),(0,.03,0),'stone_dark',r,.05)
    cylinder(r,'Dark_well',.63,.012,(0,.066,0),'ink');ring('Iron_ring',.66,.07,.045,'steel_dark',r)
    g=bc.pivot('HatchHinge',bc.G(.65,.09,0),r);g['articulated']=True
    cylinder(g,'Grate_plate',.62,.035,(-.65,0,0),'steel_dark')
    for i in range(7):box('Grate_groove',(.98,.008,.035),(-.65,.021,-.36+i*.12),'ink',g,.003)
    return r
def pipe():
    r=cn('DecorativePipe');tube('Painted_pipe',[(0,0,0),(0,.65,0),(.08,.82,0),(.60,.82,0)],.055,'copper',r)
    for y in [.12,.55]:
        cylinder(r,'Union',.075,.055,(0,y,0),'steel_dark');box('Wall_plate',(.16,.11,.025),(0,y,-.08),'steel_dark',r)
    front_loop('Red_valve',0,.40,.085,.11,.11,.018,'coral',r)
    for i in range(4):a=i*math.pi/2;tube('Valve_spoke',[(0,.40,.085),(.10*math.cos(a),.40+.10*math.sin(a),.085)],.009,'coral',r)
    return r
def fusebox():
    r=cn('Fusebox');box('Cabinet',(.45,.65,.16),(0,0,0),'teal_dark',r,.025)
    for x in [-.13,0,.13]:box('Switch',(.08,.20,.03),(x,-.12,.10),'steel',r,.009);box('Red_lever',(.045,.06,.02),(x,-.08,.125),'coral',r)
    oval('Indicator',(0,.23,.09),(.025,.025,.012),'mint',r);letters('Flat_warning','HAUTE TENSION',(0,.11,.10),.046,'yellow',r);return r
def window():
    r=cn('BarredWindow');box('Dark_recess',(.9,.4,.10),(0,0,0),'ink',r,.01);box('Blue_pane',(.84,.34,.01),(0,0,.055),'blue',r)
    for x in [-.45,.45]:box('Side_frame',(.04,.44,.16),(x,0,0),'steel_dark',r)
    for y in [-.21,.21]:box('Frame',(.94,.04,.16),(0,y,0),'steel_dark',r)
    for x in [-.30,-.10,.10,.30]:tube('Bar',[(x,-.20,.10),(x,.20,.10)],.015,'steel_dark',r)
    return r
def shelf_model(w):
    r=cn('WallShelf');box('Walnut_plate',(w,.055,.38),(0,-.0275,0),'wood',r,.01)
    for x in [-w*.36,w*.36]:
        box('Wall_rail',(.05,.30,.04),(x,-.15,-.17),'teal_dark',r,.008)
        tube('Curved_scroll',[(x,-.05,.16),(x,-.12,.10),(x,-.27,-.12),(x,-.20,-.10),(x,-.19,-.03)],.015,'teal_dark',r)
    return r
def duck():
    r=cn('RubberDuck');oval('Body',(0,.10,0),(.15,.10,.12),'yellow',r);oval('Head',(0,.23,.055),(.095,.095,.085),'yellow',r)
    box('Bill',(.09,.035,.09),(0,.215,.15),'orange',r,.015)
    for x in [-.05,.05]:oval('Eye',(x,.25,.125),(.012,.016,.008),'ink',r)
    for s in [-1,1]:oval('Wing',(s*.13,.12,0),(.025,.06,.075),'ochre',r)
    return r
def toaster():
    r=cn('Toaster');box('Cream_body',(.32,.24,.20),(0,.12,0),'cream',r,.035)
    for x in [-.067,.067]:box('Top_slot',(.048,.008,.15),(x,.243,0),'ink',r,.009)
    box('Crumb_drawer',(.26,.025,.025),(0,.03,.11),'teal',r,.005);oval('Dial',(.07,.10,.11),(.035,.035,.015),'copper',r);box('Lever',(.04,.07,.04),(-.08,.17,.12),'teal',r)
    return r
def bomb():
    r=cn('CartoonCollectible');oval('Sphere',(0,.13,0),(.13,.13,.13),'purple',r);cylinder(r,'Neck',.027,.055,(0,.275,0),'gold');tube('Decorative_fuse',[(0,.30,0),(.02,.35,0),(.07,.35,0)],.012,'twine',r);return r
def bananas():
    r=cn('GoldenBananas')
    for i in range(3):tube('Curved_banana',[(-.17,.16,i*.045),(-.13,.08,i*.045),(0,.055,i*.045),(.13,.10,i*.045),(.18,.20,i*.045)],.034,'gold',r)
    cylinder(r,'Display_base',.22,.022,(0,.011,.04),'wood_dark');return r
def fishjar():
    r=cn('FishJar');solid('Glass_jar',[(.085,.008),(.10,.025),(.10,.21),(.092,.24)],'glass',r,seg=32)
    cylinder(r,'Cork_lid',.105,.035,(0,.26,0),'wood')
    cylinder(r,'Translucent_water',.087,.15,(0,.10,0),'cold')
    oval('Fish',(0,.12,.045),(.05,.035,.025),'yellow',r);oval('Eye',(.02,.13,.068),(.008,.01,.004),'ink',r)
    mesh('Tail',[(-.04,.12,.045),(-.075,.15,.045),(-.075,.09,.045)],[(0,1,2)],'orange',r,.006)
    for i in range(5):oval('Bottom_pebble',((i%3-1)*.035,.02,(i//3)*.04),(.025,.013,.022),'steel_dark',r)
    return r
def helmet():
    r=cn('SpaceHelmet');cylinder(r,'Display_base',.19,.035,(0,.018,0),'teal');oval('Helmet',(0,.18,0),(.13,.14,.12),'cream',r);oval('Visor',(0,.19,.09),(.10,.09,.035),'ink',r)
    for s in [-1,1]:oval('Side_hinge',(s*.13,.18,0),(.025,.05,.05),'steel_dark',r)
    solid('Display_dome',[(.18,.035),(.18,.27),(.14,.35),(.06,.39),(.001,.40)],'glass',r,seg=32);return r
def mug():
    r=cn('SkullMug');solid('Skull_ceramic',[(.07,.005),(.10,.035),(.12,.12),(.105,.20)],'bone',r)
    for s in [-1,1]:oval('Eye_socket',(s*.046,.13,.105),(.033,.040,.012),'ink',r)
    tube('Handle',[(.10,.16,0),(.20,.18,0),(.22,.08,0),(.10,.05,0)],.02,'bone',r);return r
def rocket():
    r=cn('MiniRocket');solid('Hull',[(.07,0),(.10,.07),(.085,.28),(.001,.42)],'cream',r)
    for k in range(3):
        a=k*math.tau/3;g=bc.pivot('Fin',bc.G(0,0,0),r);g.rotation_euler.z=a;mesh('Red_fin',[(0,0,.065),(0,.16,.07),(0,.06,.16),(0,0,.16)],[(0,1,2,3)],'coral',g,.015)
    oval('Porthole',(0,.23,.08),(.037,.037,.012),'teal',r);return r
def moon():
    r=cn('MiniMoon');oval('Moon',(0,.20,0),(.13,.13,.13),'lavender',r)
    for x,y,z in [(-.04,.24,.11),(.05,.17,.11),(.07,.28,.06)]:oval('Crater',(x,y,z),(.025,.027,.012),'purple',r)
    cylinder(r,'Base',.12,.025,(0,.012,0),'teal_dark');tube('Support',[(0,.02,0),(0,.18,-.12)],.018,'teal_dark',r);return r
def shipping_crate():
    r=cn('ShippingCrate')
    for z in [-.30,.30]:
        for y in [.10,.28,.46]:box('Wood_slat',(.80,.17,.04),(0,y,z),'wood',r,.006)
    for x in [-.39,.39]:box('End_panel',(.035,.55,.60),(x,.28,0),'walnut',r,.008)
    box('Lid',(.80,.04,.60),(0,.57,0),'walnut',r)
    for x in [-.34,.34]:box('Iron_strap',(.04,.60,.65),(x,.29,0),'teal_dark',r,.004)
    letters('Flat_stencil','FRAGILE',(0,.30,.325),.10,'teal_dark',r);return r
def barrel():
    r=cn('Barrel');solid('Staves',[(.25,0),(.30,.10),(.33,.40),(.30,.70),(.26,.75)],'olive',r)
    for y in [.09,.38,.68]:ring('Hoop',.30 if y!=.38 else .335,y,.023,'teal_dark',r)
    cylinder(r,'Lid',.26,.035,(0,.75,0),'olive');return r
def can(kind):
    r=cn('Jerrycan');box('Body',(.30,.43,.17),(0,.22,0),'coral' if kind==0 else 'ochre',r,.025)
    tube('Handle',[(-.10,.43,0),(-.07,.52,0),(.08,.52,0),(.10,.43,0)],.027,'steel_dark',r);cylinder(r,'Cap',.035,.025,(-.10,.45,.03),'ink');return r
def sack():
    r=cn('BurlapSack');oval('Bag',(0,.21,0),(.23,.25,.18),'kraft',r);tube('Tied_neck',[(0,.38,0),(0,.48,0)],.055,'kraft',r);ring('Cord',.06,.42,.009,'twine',r);return r
def mushroom(col='mint'):
    r=cn('Mushroom');tube('Stalk',[(0,0,0),(.03,.15,0),(0,.29,0)],.028,'cream',r)
    oval('Cap',(0,.30,0),(.15,.065,.14),col,r)
    for k in range(12):a=k*math.tau/12;tube('Gills',[(0,.25,0),(.12*math.cos(a),.275,.11*math.sin(a))],.003,'cream',r)
    return r
def moss():
    r=cn('MossPatch')
    for i in range(12):a=i*2.4;rr=.07*(i%4);oval('Moss_tuft',(rr*math.cos(a),.02,rr*math.sin(a)),(.09,.025,.075),'leaf',r)
    return r
def skeleton():
    r=cn('FormerPartner');oval('Skull',(0,1.62,0),(.15,.19,.13),'bone',r)
    for s in [-1,1]:
        oval('Socket',(s*.06,1.66,.12),(.043,.055,.025),'ink',r)
        tube('Arm',[(s*.22,1.37,0),(s*.30,1.02,.02),(s*.28,.80,.04)],.027,'bone',r)
        tube('Leg',[(s*.10,.83,0),(s*.13,.43,0),(s*.14,.10,.03)],.035,'bone',r)
        oval('Foot',(s*.14,.055,.08),(.07,.04,.13),'bone',r)
    tube('Spine',[(0,.85,0),(0,1.45,0)],.028,'bone',r)
    for y in [1.08,1.17,1.26,1.35]:front_loop('Rib',0,y,.02,.19,.065,.014,'bone',r)
    front_loop('Pelvis',0,.86,0,.16,.09,.025,'bone',r);sign_part(r,'ANCIEN ASSOCIÉ',(0,2.0,0),.95,.22);return r
def radio():
    r=cn('Radio');box('Case',(.45,.28,.18),(0,.14,0),'walnut',r,.025);box('Speaker',(.23,.20,.02),(-.07,.14,.10),'kraft',r,.02)
    for x in [-.15,-.10,-.05,0]:
        for y in [.08,.13,.18,.23]:oval('Speaker_hole',(x,y,.113),(.007,.007,.002),'wood_dark',r)
    for y in [.09,.20]:oval('Knob',(.15,y,.11),(.032,.032,.015),'cream',r)
    tube('Handle',[(-.15,.28,0),(-.15,.34,0),(.15,.34,0),(.15,.28,0)],.017,'teal_dark',r);return r
def cat():
    r=cn('SleepingCat');oval('Cushion',(0,.035,0),(.35,.035,.27),'purple',r);oval('Curled_body',(0,.16,0),(.25,.14,.19),'teal_dark',r);oval('Head',(.17,.20,.09),(.12,.10,.10),'teal_dark',r)
    for x in [.10,.24]:mesh('Ear',[(x-.035,.25,.10),(x,.35,.09),(x+.025,.25,.10)],[(0,1,2)],'teal_dark',r,.018)
    tube('Tail',[(-.22,.10,.10),(-.12,.10,.23),(.10,.10,.23),(.18,.10,.15)],.045,'teal_dark',r)
    for x in [.12,.22]:tube('Closed_eye',[(x-.02,.215,.184),(x,.207,.19),(x+.02,.216,.184)],.004,'ink',r)
    return r
def dryer():
    r=cn('DryingLine');tube('Cord',[(-1.2,.10,0),(0,-.02,0),(1.2,.10,0)],.009,'twine',r)
    for k in range(5):
        x=-.9+k*.45;box('Peg',(.025,.12,.035),(x,.0,0),'wood',r,.005)
        for j in range(4):
            dx=(j-1.5)*.04;tube('Hanging_stem',[(x,-.06,0),(x+dx,-.40,0)],.005,'leaf',r);oval('Dried_bloom',(x+dx,-.42,0),(.045,.07,.04),'purple',r)
            leaf(r,(x+dx,-.25,.02),.13,.035,yaw=j,role='leaf')
    return r
def singlepot():
    r=cn('SinglePlantPot');solid('Hollow_teal_pot',[(.17,.018),(.18,.04),(.23,.36),(.24,.42)],'teal',r)
    bc.lathe('Terracotta_rim',[(.225,.36),(.245,.36),(.245,.42),(.225,.42)],'clay',r,seg=40,subsurf=0)
    solid('Separate_saucer',[(.0,0),(.23,0),(.25,.025),(.25,.045)],'teal',r)
    cylinder(r,'Recessed_soil',.215,.025,(0,.37,0),'soil')
    for x in [-.24,.24]:box('Molded_handle',(.035,.09,.08),(x,.37,0),'teal_light',r,.007)
    box('Crop_badge',(.12,.12,.018),(0,.27,.232),'ink',r,.012);motif(r,0,.27,.247,.07,'mint');return r
def singlelamp():
    r=cn('SinglePotLamp');pts=[(.38*math.cos(a),.045,.36*math.sin(a)) for a in [math.pi*.15+i*math.pi*1.70/40 for i in range(41)]];tube('Weighted_C_base',pts,.055,'teal_dark',r)
    tube('Mast',[(0,.08,-.34),(0,1.65,-.34),(0,1.84,-.27),(0,1.88,-.12),(0,1.88,0)],.025,'teal_dark',r)
    for y in [.5,1.0,1.5]:box('Height_collar',(.08,.08,.08),(0,y,-.34),'teal',r,.009)
    g=bc.pivot('LampHead',bc.G(0,1.85,0),r);g['articulated']=True
    box('Hood',(.35,.10,.32),(0,0,0),'teal',g,.035);box('Mint_diffuser',(.30,.012,.27),(0,-.055,0),'mint',g,.025)
    tube('Clipped_cable',[(.03,.08,-.34),(.03,1.65,-.34),(.03,1.85,0)],.006,'ink',r)
    return r
def bed():
    r=cn('GrowBed');w=1.8;d=1.1
    for x in [-.82,.82]:
        for z in [-.47,.47]:box('Leg',(.11,.15,.11),(x,.075,z),'ink',r,.012)
    for z in [-.53,.53]:
        for y in [.20,.32,.44]:box('Walnut_slat',(w,.11,.045),(0,y,z),'walnut',r,.008)
    for x in [-.88,.88]:box('End',(.045,.37,d),(x,.33,0),'walnut',r,.01)
    for z in [-.53,.53]:box('Purple_rim',(1.88,.06,.09),(0,.52,z),'purple',r,.014)
    for x in [-.90,.90]:box('Purple_end_rim',(.09,.06,1.10),(x,.52,0),'purple',r,.014)
    box('Soil_insert',(1.69,.055,.94),(0,.455,0),'soil',r,.01)
    for x in [-.84,.84]:
        for z in [-.56,.56]:box('Iron_corner',(.055,.35,.025),(x,.32,z),'teal_dark',r);screw(r,(x,.39,z+.02),.014,'steel')
    return r
def bedlamp():
    r=cn('BedLamp');box('Hood',(1.6,.09,.40),(0,0,0),'teal_dark',r,.025)
    for z in [-.10,.10]:box('Diffuser',(1.47,.016,.09),(0,-.052,z),'mint',r,.012)
    for x in [-.65,.65]:tube('Hanger',[(x,.05,0),(x,1.15,0)],.008,'ink',r)
    return r
def herb(stage):
    r=cn('DarkHerb_'+stage);name='cannabis_compact'+({'seedling':'_seedling','growing':'_growing','budding':'','ripe':''}[stage])+'_toon.glb'
    before=set(bpy.data.objects);bpy.ops.import_scene.gltf(filepath=os.path.join(bc.ROOT,'assets/models/plants',name));obs=set(bpy.data.objects)-before
    for ob in list(obs):
        if any(k in ob.name.lower() for k in ['terracotta','recessed_soil','soil_clod','pot_rim']):bpy.data.objects.remove(ob,do_unlink=True);obs.discard(ob)
    for ob in obs:
        if ob.parent not in obs:ob.parent=r;ob.location.z-=.24;ob.scale*=.80 if stage=='budding' else 1.0
    for ob in obs:
        if ob.type=='MESH':
            # The approved GLBs are joined by material, including their original
            # pot and inverted-hull outline. Strip those faces before reusing the plant.
            bm=bmesh.new();bm.from_mesh(ob.data)
            removed=[]
            for face in bm.faces:
                role=ob.data.materials[face.material_index].name.lower()
                if role.startswith(('outline','pot','soil')):removed.append(face)
            bmesh.ops.delete(bm,geom=removed,context='FACES')
            bmesh.ops.delete(bm,geom=[v for v in bm.verts if not v.link_faces],context='VERTS')
            bm.to_mesh(ob.data);bm.free();ob.data.update()
            for attr in list(ob.data.color_attributes):ob.data.color_attributes.remove(attr)
            for slot in ob.material_slots:
                mat=slot.material
                if mat:
                    role=mat.name.lower()
                    replacement='leaf_light' if 'leaf_light' in role else ('leaf' if 'leaf' in role or role.startswith('green') else ('bud' if 'bud' in role else ('orange' if 'orange' in role else 'ink')))
                    slot.material=bc._MATS[replacement]
                    continue
                if mat and mat.use_nodes:
                    role=mat.name.lower();col='#294E40' if 'leaf' in role else ('#81508C' if 'bud' in role else None)
                    if col:
                        for node in mat.node_tree.nodes:
                            if node.type=='BSDF_PRINCIPLED':node.inputs['Base Color'].default_value=bc.hex_color(col)
    return r
def fantasy(kind,stage):
    r=cn(kind+'_'+stage);sc={'seedling':.28,'growing':.6,'budding':.8,'ripe':1}[stage]
    if kind=='lotus':
        leaves={'seedling':2,'growing':4,'budding':6,'ripe':7}[stage]
        for k in range(leaves):a=k*math.tau/leaves;leaf(r,(.13*sc*math.cos(a),.04,.13*sc*math.sin(a)),.50*sc,.12*sc,yaw=a,tilt=math.pi/2,role='leaf')
        for k in range({'seedling':0,'growing':1,'budding':3,'ripe':3}[stage]):
            x=(k-1)*.13*sc;h=(.35+.12*(k%2))*sc;tube('Stem',[(x,0,0),(x,h,0)],.018*sc,'leaf',r)
            if stage=='ripe':
                for j in range(5):a=j*math.tau/5;oval('Petal',(x+math.cos(a)*.105*sc,h,.105*sc*math.sin(a)),(.12*sc,.05*sc,.08*sc),'purple',r)
                oval('Core',(x,h+.015,0),(.04*sc,.025*sc,.04*sc),'mint',r)
            else:oval('Closed_bud',(x,h,0),(.045*sc,.09*sc,.045*sc),'purple',r)
    elif kind=='moss_crop':
        for k in range({'seedling':3,'growing':5,'budding':8,'ripe':10}[stage]):a=k*2.4;rr=.10*(k%3)*sc;oval('Mound',(rr*math.cos(a),.09*sc,rr*math.sin(a)),(.16*sc,.12*sc,.14*sc),'teal_dark',r)
        for k in range({'seedling':0,'growing':1,'budding':3,'ripe':5}[stage]):a=k*2.4;x=.17*math.cos(a)*sc;z=.17*math.sin(a)*sc;tube('Curved_shoot',[(x,0,z),(x,.25*sc,z),(x+.08*sc,.31*sc,z)],.028*sc,'blue',r)
    else:
        tube('Twining_stem',[(.04*sc*math.sin(k*.8),k*.045*sc,.04*sc*math.cos(k*.8)) for k in range(21)],.018*sc,'teal',r)
        for k in range({'seedling':2,'growing':5,'budding':7,'ripe':8}[stage]):
            y=(.15+k*.09)*sc;s=(-1 if k%2 else 1);leaf(r,(s*.09*sc,y,0),.20*sc,.05*sc,yaw=s*.8,role='leaf')
            if stage in ['budding','ripe']:
                star_size=.48 if stage=='budding' else 1.0
                verts=[(s*.15*sc,y,0)]+[(s*.15*sc+math.sin(j*math.pi/5)*(.09 if j%2==0 else .043)*sc*star_size,y+math.cos(j*math.pi/5)*(.09 if j%2==0 else .043)*sc*star_size,.01) for j in range(10)];mesh('Star',verts,[(0,j+1,(j+1)%10+1) for j in range(10)],'yellow',r,.008)
                oval('Berry',(-s*.07*sc,y,.03),(.025*sc,.025*sc,.025*sc),'purple',r)
    return r
def cone():
    r=cn('SafetyCone');box('Base',(.30,.035,.30),(0,.0175,0),'ink',r,.02);cylinder(r,'Cone',.018,.40,(0,.23,0),'orange',.13);cylinder(r,'White_band',.061,.06,(0,.26,0),'cream',.079);return r
def boots():
    r=cn('ForgottenBoots')
    for x in [-.13,.13]:
        g=bc.pivot('Boot',bc.G(x,0,0),r)
        box('Sole',(.18,.045,.32),(0,.023,.05),'ink',g,.025);oval('Leather_toe',(0,.11,.09),(.09,.075,.16),'wood_dark',g);solid('Boot_ankle',[(.07,.07),(.08,.27),(.075,.31)],'walnut',g)
        for y in [.13,.18,.23]:tube('Laces',[(-.04,y,.073),(.04,y+.015,.073)],.004,'twine',g)
    return r
def wilted_pot():
    r=cn('WiltedCompostPot');plain_pot(r,.17,.25,'clay')
    tube('Drooping_stem',[(0,.23,0),(0,.60,0),(.12,.69,0),(.24,.54,0)],.009,'leaf',r)
    for s in [-1,1]:leaf(r,(s*.04,.41,0),.18,.05,yaw=s,tilt=.7,role='olive')
    for k in range(7):a=k*math.tau/7;oval('Wilted_petal',(.24+.07*math.cos(a),.49,.07*math.sin(a)),(.035,.09,.035),'purple',r)
    return r
def paper_parcel():
    r=cn('PaperParcel');box('Wrapped_box',(.47,.28,.34),(0,.14,0),'kraft',r,.018)
    for x in [-.12,.12]:tube('Tied_string',[(x,0,-.18),(x,.29,-.18),(x,.29,.18),(x,0,.18)],.006,'twine',r)
    box('Paper_label',(.22,.10,.003),(0,.15,.173),'cream',r);letters('Flat_terre','TERRE',(0,.15,.177),.055,'teal_dark',r);return r
def cable_tray():
    r=cn('CableTray1m');box('Tray_bottom',(1,.025,.18),(0,0,0),'steel_dark',r)
    for z in [-.08,.08]:box('Tray_lip',(1,.08,.02),(0,.04,z),'steel_dark',r)
    for z in [-.05,0,.05]:tube('Protected_cable',[(-.5,.04,z),(.5,.04,z)],.009,'ink',r)
    return r
def door_frame():
    r=cn('VisitorDoorFrame')
    for x in [-.045,1.005]:box('Jamb',(.07,2.29,.14),(x,1.145,0),'teal_dark',r,.012)
    box('Header',(1.12,.07,.14),(.48,2.255,0),'teal_dark',r,.012)
    return r
def visitor_door():
    r=cn('VisitorDoorHinge');r['articulated']=True
    box('Teal_leaf',(.96,2.18,.05),(.48,1.09,0),'teal',r,.014)
    for y,h in [(.46,.62),(1.48,1.12)]:
        moulded_panel(r,.76,h,.48,y,.032,'teal_dark')
    for y in [.20,1.10,2.0]:cylinder(r,'Hinge',.018,.11,(0,y,0),'gold')
    for z in [-.042,.042]:
        box('Lock_plate',(.07,.18,.014),(.84,1.05,z),'gold',r,.008)
        tube('Door_handle',[(.84,1.08,z),(.74,1.08,z*2)],.016,'gold',r)
    box('Kickplate',(.87,.16,.01),(.48,.11,.034),'steel_dark',r,.005)
    return r
SPECS=[('floor',floor),('ceiling',ceiling),('vent_socket',vent),('filter_cartridge',filter_cartridge),('duct_module',duct),('duct_elbow',elbow),('stairs',stairs),('entry_sign',lambda:board('BOUTIQUE →')),('step_warning',lambda:board('ATTENTION !')),('boots',boots),('bulb',bulb),('garland',garland),('lantern',lantern),('culture_jar',lambda:vessel('culture')),('trowel',lambda:tools('trowel')),('shears',lambda:tools('shears')),('watering_can',lambda:tools('watering_can')),('bucket',lambda:tools('bucket')),('label',lambda:tools('label')),('power_strip',lambda:tools('power_strip'))]
SPECS += [('terminal_'+k,lambda k=k:terminal(k)) for k in ['capacity','lamp','filter','lock']]
SPECS += [('cabinet',cabinet),('cabinet_lock',lock),('composter',composter),('counter',counter),('register',register),('tip_jar',lambda:vessel('tip')),('desk_bell',lambda:make_bell()),('visitor_door',visitor_door),('seed_crate',seed_crate),('sewer',sewer),('sewer_sign',lambda:board('SORTIE ÉGOUT')),('cone',cone),('skeleton',skeleton),('pipes',pipe),('fusebox',fusebox),('window',window),('shelf_150',lambda:shelf_model(1.5)),('shelf_200',lambda:shelf_model(2)),('duck',duck),('toaster',toaster),('cartoon_bomb',bomb),('gold_bananas',bananas),('fish_jar',fishjar),('space_helmet',helmet),('skull_mug',mug),('mini_rocket',rocket),('mini_moon',moon),('shipping_crate',shipping_crate),('barrel',barrel),('jerrycan_red',lambda:can(0)),('jerrycan_yellow',lambda:can(1)),('sack',sack),('mushroom_mint',lambda:mushroom('mint')),('mushroom_pink',lambda:mushroom('pink')),('mushroom_lilac',lambda:mushroom('lavender')),('moss_patch',moss),('drying_line',dryer),('sleeping_cat',cat),('radio',radio),('warning_poster',lambda:board('INTERDIT AUX FLICS')),('tariffs_sign',lambda:board('TARIFS')),('payments_sign',lambda:board('PIÈCES · CRÉDITS')),('found_sign',lambda:board('OBJETS TROUVÉS')),('contraband_sign',lambda:board('ZONE DE CONTREBANDE')),('nap_sign',lambda:board('SIESTE')),('syrup_sign',lambda:board('SIROP')),('doormat',doormat),('single_pot',singlepot),('single_lamp',singlelamp),('grow_bed',bed),('bed_lamp',bedlamp),('wilted_pot',wilted_pot),('paper_parcel',paper_parcel),('cable_tray',cable_tray),('door_frame',door_frame)]
def make_bell():
    r=cn('DeskBell');cylinder(r,'Stable_base',.11,.022,(0,.011,0),'ink')
    bc.lathe('Brass_dome',[(.095,.022),(.092,.055),(.073,.080),(.035,.10),(.001,.105)],'gold',r,seg=32,subsurf=0)
    cylinder(r,'Plunger',.014,.03,(0,.12,0),'steel');cylinder(r,'Bell_button',.028,.014,(0,.138,0),'gold');return r
SPECS += [('harvest_jar_q'+str(q),lambda q=q:vessel('harvest',q)) for q in range(1,5)]
SPECS += [('herb_'+st,lambda st=st:herb(st)) for st in ['seedling','growing','budding','ripe']]
SPECS += [(k+'_'+st,lambda k=k,st=st:fantasy(k,st)) for k in ['lotus','moss_crop','star_vine'] for st in ['seedling','growing','budding','ripe']]
SPECS += [('cabinet_lock_electronic',lambda:lock_version(2)),('cabinet_lock_heavy',lambda:lock_version(3))]
selected=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
report=[]
for name,build in SPECS:
    if selected and name not in selected:continue
    root=build();root['cellar_asset']=name;bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BLEND,name+'.blend'));path=os.path.join(OUT,name+'.glb');bc.export_glb(path,root)
    raw=open(path,'rb').read();n=struct.unpack_from('<I',raw,12)[0];doc=json.loads(raw[20:20+n]);tris=sum(doc['accessors'][p['indices']]['count']//3 for m in doc['meshes'] for p in m['primitives'])
    record=dict(asset=name,triangles=tris,metres=True);report.append(record);print('CELLAR_MODEL',json.dumps(record),flush=True)
all_models=[]
for name,_ in SPECS:
    path=os.path.join(OUT,name+'.glb')
    if not os.path.exists(path):continue
    raw=open(path,'rb').read();n=struct.unpack_from('<I',raw,12)[0];doc=json.loads(raw[20:20+n])
    all_models.append(dict(asset=name,triangles=sum(doc['accessors'][p['indices']]['count']//3 for m in doc['meshes'] for p in m['primitives']),metres=True))
json.dump(all_models,open(os.path.join(OUT,'manifest.json'),'w'),indent=2)
print('CELLAR_MODELS_COMPLETE',len(report),flush=True)
