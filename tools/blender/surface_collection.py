"""All remaining florist zones: metric, editable, independent functional parts."""
import os,sys,math,json,struct
import bpy
sys.path.insert(0,os.path.dirname(__file__))
exec(open(os.path.join(os.path.dirname(__file__),'cellar_collection.py'),encoding='utf-8').read().split('\nSPECS=')[0],globals())
OUT=os.path.join(bc.ROOT,'assets/models/surface');BLEND=os.path.join(bc.ROOT,'art/blender/surface')
os.makedirs(OUT,exist_ok=True);os.makedirs(BLEND,exist_ok=True)

def root(name):
    r=cn(name);bc.material('red','#B95450')
    for role,color in {'teal':'#3D786A','teal_light':'#639886','teal_dark':'#254D45','walnut':'#795136','wood':'#A5774B','wood_dark':'#503827','leaf':'#35654B','leaf_light':'#64915B','steel':'#9AA7AD','steel_dark':'#54636B','purple':'#68437D','gold':'#C6A455'}.items():
        mat=bc._MATS[role];mat.diffuse_color=bc.hex_color(color);mat.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=bc.hex_color(color)
    return r
def plank(r,p,size,role='wood'):
    box('Bevelled_timber',size,p,role,r,.009)
    x,y,z=p;w,h,d=size
    if w>.3:
        for zz in [-d*.23,d*.23]:tube('Fine_wood_grain',[(x-w*.42,y+h/2+.001,z+zz),(x,y+h/2+.001,z+zz+.004),(x+w*.42,y+h/2+.001,z+zz-.002)],.001,'wood_dark',r)
def legs(r,w,d,h,role='teal_dark'):
    for x in [-w/2+.055,w/2-.055]:
        for z in [-d/2+.055,d/2-.055]:box('Leg',(.065,h,.065),(x,h/2,z),role,r,.009)
    for x in [-w/2+.055,w/2-.055]:tube('Side_brace',[(x,.17,-d/2+.06),(x,.17,d/2-.06)],.021,role,r)
def top_surface(r,w,d,y,role='wood'):
    for i in range(max(1,int(d/.12))):
        n=max(1,int(d/.12));plank(r,(0,y,-d/2+(i+.5)*d/n),(w,.055,d/n-.008),role)
def leaf_emblem(r,p,rad=.075,role='gold'):
    motif(r,p[0],p[1],p[2],rad,role)
def table():
    r=root('BistroTable');cylinder(r,'Ivory_top',.40,.045,(0,.725,0),'cream');ring('Walnut_edge',.395,.725,.018,'walnut',r)
    cylinder(r,'Pedestal',.036,.62,(0,.39,0),'ink');cylinder(r,'Brass_collar',.052,.065,(0,.19,0),'gold')
    for k in range(3):
        a=k*math.tau/3;tube('Swept_foot',[(0,.20,0),(.18*math.cos(a),.04,.18*math.sin(a)),(.30*math.cos(a),.025,.30*math.sin(a))],.024,'ink',r)
    g=bc.pivot('Inlay',bc.G(0,.75,0),r);g.rotation_euler.x=-math.pi/2
    front_loop('Fine_inlay_ring',0,0,0,.31,.31,.0016,'gold',g)
    for k in range(8):leaf_emblem(g,(math.sin(k*math.tau/8)*.265,math.cos(k*math.tau/8)*.265,0),.045,'teal')
    return r
def chair(role='teal_light',office=False):
    r=root('OfficeChair' if office else 'BistroChair')
    if office:
        cylinder(r,'Lift',.035,.40,(0,.24,0),'steel');cylinder(r,'Seat',.235,.08,(0,.48,0),'teal')
        for k in range(5):
            a=k*math.tau/5;x=.27*math.cos(a);z=.27*math.sin(a);tube('Caster_arm',[(0,.12,0),(x,.06,z)],.021,'steel_dark',r);oval('Caster',(x,.045,z),(.04,.045,.025),'rubber',r)
        box('Curved_back',(.43,.38,.085),(0,.76,-.20),'teal',r,.07)
        for x in [-.12,.12]:tube('Back_support',[(x,.49,-.16),(x,.61,-.24),(x,.76,-.24)],.018,'steel_dark',r)
    else:
        legs(r,.43,.43,.43,'ink');top_surface(r,.43,.42,.435,'walnut')
        for x in [-.205,.205]:tube('Back_upright',[(x,.38,-.17),(x,.88,-.19),(x*.8,.96,-.18)],.018,'ink',r)
        for y in [.65,.77,.89]:box('Rounded_back_slat',(.40,.065,.03),(0,y,-.18),role,r,.025)
        leaf_emblem(r,(0,.77,-.158),.04,'cream')
    return r
def parasol():
    r=root('PetalParasol');cylinder(r,'Base',.31,.075,(0,.0375,0),'teal_dark');cylinder(r,'Pole',.028,2.55,(0,1.31,0),'walnut')
    for k in range(8):
        a=k*math.tau/8;b=(k+1)*math.tau/8;pts=[(0,2.66,0)]
        for j in range(7):
            q=a+(b-a)*j/6;pts.append((1.05*math.cos(q),2.10,1.05*math.sin(q)))
        mesh('Canvas_panel',pts,[(0,j,j+1) for j in range(1,7)],'pink' if k%2 else 'cream',r,.008)
        tube('Under_rib',[(0,2.64,0),(.55*math.cos(a),2.39,.55*math.sin(a)),(1.05*math.cos(a),2.09,1.05*math.sin(a))],.009,'steel_dark',r)
        mesh('Scalloped_valance',[(1.05*math.cos(a),2.1,1.05*math.sin(a)),(1.05*math.cos(b),2.1,1.05*math.sin(b)),(1.05*math.cos(b),2.00,1.05*math.sin(b)),(1.05*math.cos((a+b)/2),1.95,1.05*math.sin((a+b)/2)),(1.05*math.cos(a),2,1.05*math.sin(a))],[(0,1,2,3,4)],'pink' if k%2 else 'cream',r,.006)
    oval('Finial',(0,2.70,0),(.045,.075,.045),'gold',r);return r
def deck():
    r=root('Deck1m')
    for k in range(6):plank(r,(0,.03,-.5+(k+.5)/6),(.996,.06,1/6-.008),'walnut')
    for x in [-.4,.4]:
        for z in [-.46,.46]:cylinder(r,'Recessed_bolt',.006,.002,(x,.061,z),'steel_dark')
    return r
def railing(balcony=False):
    r=root('BalconyRailing' if balcony else 'TerraceRailing')
    for x in [-.48,.48]:
        box('Capped_post',(.07,1,.07),(x,.5,0),'teal_dark',r,.01);oval('Brass_post_cap',(x,1.025,0),(.05,.025,.05),'gold',r)
    for y in [.12,.88]:box('Continuous_rail',(1,.04,.04),(0,y,0),'teal',r,.009)
    for x in [-.32,-.16,0,.16,.32]:
        tube('Curving_spindle',[(x,.12,0),(x+.025,.4,0),(x-.025,.65,0),(x,.88,0)],.012,'teal_dark',r)
    front_loop('Oval_medallion',0,.50,.02,.13,.19,.014,'teal',r);leaf_emblem(r,(0,.5,.032),.09,'gold');return r
def planter():
    r=root('RailPlanter')
    box('Bottom',(.78,.035,.25),(0,.018,0),'teal_dark',r,.008)
    for z in [-.135,.135]:box('Moulded_side',(.82,.20,.025),(0,.13,z),'teal',r,.012)
    for x in [-.4,.4]:box('End',(.025,.20,.27),(x,.13,0),'teal',r,.008)
    box('Soil',(.76,.035,.23),(0,.19,0),'soil',r,.005)
    for z in [-.15,.15]:box('Top_lip',(.86,.035,.035),(0,.235,z),'teal_light',r,.008)
    leaf_emblem(r,(0,.13,.151),.06,'cream')
    for x in [-.27,.27]:tube('Rear_bracket',[(x,.15,-.14),(x,.27,-.19),(x,.27,-.26),(x,.18,-.27)],.012,'ink',r)
    return r
def border():
    r=root('BorderBed');box('Soil',(1,.13,.43),(0,.09,0),'soil',r,.015)
    for z in [-.24,.24]:
        for k in range(4):box('Terracotta_brick',(.245,.15,.07),(-.375+k*.25,.09,z),'clay',r,.009)
    for x in [-.47,.47]:box('End_brick',(.07,.15,.44),(x,.09,0),'clay',r,.009)
    return r
def pathstone():
    r=root('PathStone');pts=[(-.37,0,-.28),(.21,0,-.32),(.40,0,-.12),(.36,0,.25),(-.22,0,.32),(-.40,0,.12)]
    mesh('Irregular_stone',[(x,y+.045,z) for x,y,z in pts],[(0,1,2,3,4,5)],'cream',r,.04)
    tube('Inset_crack',[(-.32,.047,-.12),(-.14,.047,-.03),(-.11,.047,.11)],.002,'wood_dark',r);return r
def hedge():
    r=root('Hedge');groups={'leaf':[[],[]],'leaf_light':[[],[]]}
    for k in range(13):
        x=-.45+(k%5)*.22;y=.23+(k//5)*.19;z=.06*math.sin(k*3)
        oval('Foliage_core',(x,y,z),(.19,.18,.16),'leaf',r)
        for j in range(24):
            a=j*2.39996;yy=1-2*(j+.5)/24;rr=math.sqrt(max(0,1-yy*yy));normal=Vector((rr*math.cos(a),yy,rr*math.sin(a)))
            center=Vector((x+.19*normal.x,y+.18*normal.y,z+.17*normal.z));side=normal.cross(Vector((0,1,0))).normalized();up=side.cross(normal).normalized()
            verts,faces=groups['leaf_light' if j%3 else 'leaf'];base=len(verts);length=.16+.018*(j%3);width=.085
            verts.append(tuple(center+normal*.015))
            for xx,yy2 in [(0,-.55),(-.52,-.12),(-.45,.24),(0,.55),(.45,.24),(.52,-.12)]:verts.append(tuple(center+side*xx*width+up*yy2*length))
            faces.extend([(base,base+i+1,base+(i+1)%6+1) for i in range(6)])
    for role,(verts,faces) in groups.items():mesh('Lightweight_shaped_leaves',verts,faces,role,r,.001)
    return r
def arch():
    r=root('TrellisArch')
    for x in [-.72,.72]:
        box('Timber_post',(.09,2.05,.09),(x,1.025,0),'teal_dark',r,.01)
        tube('Climbing_vine',[(x+.04*math.sin(k),k*.12,.08*math.cos(k)) for k in range(18)],.012,'leaf',r)
        for k in range(9):leaf(r,(x+.07*math.sin(k),.25+k*.20,.06),.17,.055,yaw=k,role='leaf_light')
    tube('Arched_top',[(.72*math.cos(math.pi*k/24),2.03+.42*math.sin(math.pi*k/24),0) for k in range(25)],.045,'teal',r)
    for z in [-.15,.15]:tube('Arch_depth',[(.72*math.cos(math.pi*k/16),2.03+.42*math.sin(math.pi*k/16),z) for k in range(17)],.02,'teal_light',r)
    return r
def tap():
    r=root('TapPost');box('Stone_base',(.35,.08,.35),(0,.04,0),'stone',r,.025);box('Post',(.17,.85,.17),(0,.49,0),'teal',r,.025)
    tube('Brass_tap',[(0,.86,.10),(0,.86,.23),(0,.80,.26)],.023,'gold',r)
    cylinder(r,'Valve_stem',.015,.10,(0,.92,.14),'gold')
    for k in range(4):a=k*math.pi/2;tube('Star_handle',[(0,.98,.14),(.07*math.cos(a),.98,.14+.07*math.sin(a))],.009,'gold',r)
    return r
def hose():
    r=root('HoseReel');legs(r,.42,.32,.40,'steel_dark')
    for x in [-.20,.20]:
        g=bc.pivot('Spool_side',bc.G(x,.40,0),r);g.rotation_euler.z=math.pi/2;front_loop('Circular_flange',0,0,0,.24,.24,.018,'teal',g)
    for k in range(10):
        x=-.15+k*.033;tube('Coiled_hose',[(x,.40+.18*math.cos(j*math.tau/32),.18*math.sin(j*math.tau/32)) for j in range(33)],.014,'leaf',r)
    tube('Loose_nozzle',[(.15,.43,.19),(.28,.23,.20),(.28,.12,.31)],.018,'gold',r);return r
def barrow():
    r=root('Wheelbarrow')
    # Open basin, thick walls, no fake solid block.
    box('Basin_floor',(.55,.035,.58),(0,.40,0),'teal_dark',r,.02)
    for x in [-.31,.31]:box('Basin_side',(.035,.26,.65),(x,.54,0),'teal',r,.03)
    for z in [-.32,.32]:box('Basin_end',(.65,.26,.035),(0,.54,z),'teal',r,.03)
    for x in [-.23,.23]:
        tube('Handle_frame',[(x,.25,-.40),(x,.39,.12),(x,.65,.82)],.025,'steel_dark',r);tube('Hand_grip',[(x,.65,.72),(x,.65,.91)],.032,'walnut',r);tube('Standing_leg',[(x,.40,.22),(x,.02,.29)],.022,'steel_dark',r)
    g=bc.pivot('Wheel_axle',bc.G(0,.19,-.43),r);g.rotation_euler.z=math.pi/2;front_loop('Rubber_tyre',0,0,0,.155,.155,.035,'rubber',g);front_loop('Spoked_rim',0,0,0,.10,.10,.01,'steel',g)
    for k in range(8):a=k*math.tau/8;tube('Spoke',[(0,0,0),(.11*math.cos(a),.11*math.sin(a),0)],.008,'steel',g)
    return r
def garden_tool(kind):
    r=root(kind);cylinder(r,'Wood_handle',.018,1.25,(0,.74,0),'walnut')
    if kind=='spade':
        front_loop('D_grip',0,1.40,0,.09,.075,.017,'teal',r)
        mesh('Steel_shovel',[(-.13,.34,.03),(.13,.34,.03),(.14,.10,.07),(0,.015,.08),(-.14,.10,.07)],[(0,1,2,3,4)],'steel',r,.018);tube('Blade_ridge',[(0,.09,.085),(0,.33,.045)],.009,'steel_dark',r)
    else:
        box('Rake_crossbar',(.46,.04,.05),(0,.12,0),'steel_dark',r,.008)
        for k in range(9):tube('Separate_tine',[(-.2+k*.05,.12,0),(-.2+k*.05,.02,.08)],.009,'steel',r)
    return r
def greenhouse():
    r=root('Greenhouse4x425');w=4;d=4.25
    box('Foundation',(4.10,.10,4.35),(0,-.05,0),'cream',r,.015)
    # East doorway at z=-.90, from -1.525 to -.275. Separate glass panels don't cover doorway.
    for x in [-2,2]:
        intervals=[(-2.125,2.125)] if x<0 else [(-2.125,-1.525),(-.275,2.125)]
        for za,zb in intervals:
            box('Brick_base',(.10,.36,zb-za),(x,.18,(za+zb)/2),'teal',r,.008)
            box('Glass_side',(.008,1.93,zb-za-.04),(x,1.345,(za+zb)/2),'glass',r)
        for z in [-2.125,-1.525,-.275,.65,2.125]:box('Side_post',(.065,2.35,.065),(x,1.175,z),'cream',r,.007)
        box('Eave_beam',(.08,.08,d+.1),(x,2.35,0),'teal_dark',r,.008)
    for z in [-d/2,d/2]:
        box('End_base',(w,.36,.10),(0,.18,z),'teal',r,.009);box('End_glass',(w-.08,1.93,.008),(0,1.345,z),'glass',r)
        for x in [-2,-1,0,1,2]:box('End_post',(.06,2.35,.06),(x,1.175,z),'cream',r,.006)
        mesh('Glass_gable',[(-2,2.35,z),(2,2.35,z),(0,3.12,z)],[(0,1,2)],'glass',r,.003)
    box('Ridge',(.09,.09,d+.2),(0,3.12,0),'teal_dark',r,.008)
    for side in [-1,1]:
        mesh('Glass_roof',[(0,3.12,-d/2),(side*2,2.35,-d/2),(side*2,2.35,d/2),(0,3.12,d/2)],[(0,1,2,3)],'glass',r,.004)
        for z in [-d/2,-1.05,0,1.05,d/2]:tube('Roof_rafter',[(0,3.12,z),(side*2,2.35,z)],.026,'cream',r)
    for x in [-2.06,2.06]:
        tube('Gutter',[(x,2.29,-2.2),(x,2.29,2.2)],.035,'teal',r);tube('Downpipe',[(x,2.29,2.14),(x,.15,2.14),(x,.12,2.3)],.026,'teal_dark',r)
    return r
def glassdoor():
    r=root('GreenhouseDoor');r['articulated']=True
    for x in [0,1.18]:box('Stile',(.055,2.12,.065),(x,1.06,0),'cream',r,.006)
    for y in [.04,.4,2.09]:box('Rail',(1.18,.055,.065),(.59,y,0),'teal',r,.006)
    box('Glass',(1.12,1.61,.008),(.59,1.245,0),'glass',r)
    for z in [-.06,.06]:tube('Brass_pull',[(1.04,.96,z),(1.04,1.13,z)],.013,'gold',r)
    for y in [.18,1.85]:cylinder(r,'Hinge',.018,.11,(0,y,0),'gold')
    return r
def bench():
    r=root('NurseryBench');legs(r,.65,2.8,.75);top_surface(r,.65,2.8,.775);top_surface(r,.59,2.65,.245,'teal');return r
def pot_nursery():
    r=root('NurseryPot');plain_pot(r,.14,.21,'clay');ring('Thick_rim',.143,.205,.014,'clay',r);cylinder(r,'Saucer',.17,.018,(0,.009,0),'clay');return r
def tray():
    r=root('PropagationTray');box('Drip_tray',(.46,.025,.32),(0,.0125,0),'teal_dark',r,.015)
    for i in range(4):
        for j in range(3):
            x=-.165+i*.11;z=-.10+j*.10;cylinder(r,'Soil_cell',.039,.055,(x,.052,z),'soil')
            ringg=bc.pivot('Cell_rim',bc.G(x,.08,z),r);ring('Rim',.044,0,.005,'teal',ringg)
            tube('Sprout_stem',[(x,.08,z),(x,.16+(i%2)*.02,z)],.003,'leaf',r)
            for s in [-1,1]:leaf(r,(x+s*.018,.15,z),.048,.017,yaw=s,role='leaf_light')
    return r
def fan():
    r=root('ClimateFan');box('Mount',(.46,.46,.04),(0,0,-.055),'teal',r,.035)
    for rad in [.13,.18,.22]:front_loop('Guard',0,0,.06,rad,rad,.006,'steel',r)
    for k in range(12):a=k*math.tau/12;tube('Guard_spoke',[(0,0,.07),(.22*math.cos(a),.22*math.sin(a),.04)],.004,'steel',r)
    for k in range(3):a=k*math.tau/3;oval('Fan_blade',(.10*math.cos(a),.10*math.sin(a),0),(.075,.10,.015),'teal_light',r)
    oval('Hub',(0,0,.075),(.035,.035,.018),'steel_dark',r);return r
def thermometer():
    r=root('Thermometer');box('Ivory_board',(.16,.47,.025),(0,0,0),'cream',r,.035);tube('Glass_stem',[(0,-.16,.019),(0,.17,.019)],.009,'steel',r);tube('Red_mercury',[(0,-.16,.032),(0,.07,.032)],.004,'red',r);oval('Bulb',(0,-.17,.025),(.025,.025,.012),'red',r)
    for k in range(11):box('Tick',(.025 if k%5 else .04,.004,.004),(.04,-.15+k*.03,.018),'teal_dark',r)
    return r
def irrigation():
    r=root('IrrigationBar');tube('Metal_pipe',[(-1.4,0,0),(1.4,0,0)],.014,'steel',r)
    for x in [-1,0,1]:cylinder(r,'Nozzle',.022,.04,(x,-.025,0),'gold');tube('Clamp',[(x,0,0),(x,.12,0)],.008,'steel_dark',r)
    return r
def shed():
    r=root('AccessibleShed');w=1.14;d=2.7
    box('Floor',(w,.07,d),(0,.035,0),'walnut',r,.008)
    for x in [-w/2,w/2]:
        intervals=[(-d/2,d/2)] if x<0 else [(-d/2,-.8),(.8,d/2)]
        for za,zb in intervals:
            n=max(1,int((zb-za)/.15))
            for k in range(n):box('Vertical_sage_board',(.06,2.12,(zb-za)/n-.007),(x,1.06,za+(k+.5)*(zb-za)/n),'teal_light',r,.005)
        box('Header',(.09,.13,d),(x,2.12,0),'teal_dark',r,.008)
    for z in [-d/2,d/2]:
        for k in range(7):box('End_plank',(w/7-.007,2.12,.06),(-w/2+(k+.5)*w/7,1.06,z),'teal_light',r,.005)
        for y in [.12,1.9]:box('End_trim',(w+.05,.07,.08),(0,y,z),'teal_dark',r,.008)
    ob=box('Sloping_roof',(1.45,.08,3.0),(0,2.26,0),'purple',r,.018);ob.rotation_euler.y=.12
    for k in range(10):tube('Roof_seam',[(-.72,2.35,-1.4+k*.31),(.72,2.18,-1.4+k*.31)],.009,'lavender',r)
    # Door is separate, opening entirely empty.
    return r
def sheddoor():
    r=root('ShedDoor');r['articulated']=True
    for k in range(5):box('Sage_plank',(.16-.006,2.0,.045),((k+.5)*.16,1,0),'teal_light',r,.004)
    for y in [.30,1.65]:box('Iron_strap',(.72,.055,.018),(.4,y,.035),'ink',r,.008)
    tube('Diagonal_brace',[(.08,.35,-.035),(.72,1.65,-.035)],.028,'teal_dark',r)
    box('Latch',(.07,.16,.018),(.70,.95,.04),'gold',r,.008);tube('Handle',[(.70,.92,.09),(.70,1.05,.09)],.012,'gold',r);return r
def shelf_shed():
    r=root('ShedShelf');legs(r,.90,.38,1.70)
    for y in [.12,.67,1.22,1.72]:top_surface(r,.9,.38,y)
    tube('Rear_cross',[(-.39,.12,-.15),(.39,1.65,-.15)],.018,'steel_dark',r);return r
def potstack():
    r=root('NestedPots')
    for k in range(3):g=bc.pivot('Separate_pot',bc.G(0,k*.095,0),r);plain_pot(g,.14,.21,'clay')
    return r
def soilbag():
    r=root('SoilBag');o=bc.lathe('Soft_fabric_body',[(.13,0),(.22,.05),(.25,.18),(.23,.36),(.13,.47),(.06,.50),(.075,.54),(.015,.56)],'kraft',r,seg=24,subsurf=1);o.scale.y=.76
    front_loop('Tied_neck',0,.50,0,.065,.018,.006,'twine',r)
    for side in [-1,1]:tube('Fabric_fold',[(side*.12,.04,.13),(side*.19,.16,.14),(side*.16,.35,.13),(side*.05,.50,.04)],.005,'wood',r)
    box('Cream_label',(.22,.16,.006),(0,.27,.177),'cream',r,.018);letters('Flat_label','TERRE',(0,.28,.183),.055,'teal_dark',r);leaf_emblem(r,(0,.22,.185),.032,'leaf');return r
def seedorganizer():
    r=root('SeedOrganizer');box('Base',(.55,.025,.30),(0,.0125,0),'walnut',r,.006)
    for x in [-.275,-.09,.09,.275]:box('Divider',(.015,.15,.30),(x,.075,0),'wood',r,.004)
    for z in [-.15,0,.15]:box('Divider',(.55,.15,.015),(0,.075,z),'wood',r,.004)
    for k in range(6):box('Seed_packet',(.12,.16,.02),(-.18+(k%3)*.18,.12,-.075+(k//3)*.15),'cream',r,.006);leaf_emblem(r,(-.18+(k%3)*.18,.16,-.061+(k//3)*.15),.025,'leaf')
    return r
def wrapping():
    r=root('WrappingStation');legs(r,1.5,.65,.85);top_surface(r,1.5,.65,.875);top_surface(r,1.40,.55,.22,'teal')
    for x in [-.69,.69]:box('Roll_upright',(.04,.40,.04),(x,1.08,-.26),'teal_dark',r,.007)
    g=bc.pivot('Paper_roll',bc.G(0,1.20,-.26),r);g.rotation_euler.y=math.pi/2;cylinder(g,'Kraft_roll',.09,1.25,(0,0,0),'kraft');cylinder(g,'Spindle',.015,1.5,(0,0,0),'steel')
    box('Loose_paper',(.65,.005,.34),(0,.907,.03),'cream',r,.005)
    for x in [.49,.63]:cylinder(r,'Ribbon_spool',.05,.08,(x,.95,.19),'pink' if x<.6 else 'teal')
    for x in [-.62,.62]:leaf_emblem(r,(x,.78,.335),.05,'gold')
    return r
def trolley():
    r=root('ServiceTrolley')
    for x in [-.32,.32]:
        for z in [-.17,.17]:box('Raised_caster_leg',(.055,.66,.055),(x,.43,z),'teal_dark',r,.008)
    for y in [.18,.73]:
        top_surface(r,.75,.45,y)
        for z in [-.22,.22]:box('Shelf_lip',(.75,.06,.025),(0,y+.04,z),'teal',r,.008)
    for x in [-.32,.32]:
        for z in [-.17,.17]:oval('Caster',(x,.055,z),(.045,.055,.022),'rubber',r)
    for x in [-.36,.36]:tube('Brass_push_handle',[(x,.72,-.18),(x,.85,-.18),(x,.85,.18),(x,.72,.18)],.014,'gold',r)
    return r
def paperrack():
    r=root('PaperRack');box('Wall_back',(1.2,.80,.04),(0,0,0),'teal_dark',r,.02)
    for k in range(3):
        y=-.27+k*.27
        for x in [-.54,.54]:box('Spindle_bracket',(.035,.08,.20),(x,y,.11),'gold',r,.006)
        g=bc.pivot('Roll',bc.G(0,y,.16),r);g.rotation_euler.y=math.pi/2;cylinder(g,'Paper',.09,1.05,(0,0,0),['kraft','cream','pink'][k]);cylinder(g,'Axle',.014,1.2,(0,0,0),'steel')
    return r
def notice():
    r=root('NoticeBoard');moulded_panel(r,1.0,.75,0,0,0,'walnut');box('Cork',(.90,.65,.016),(0,0,.025),'coir',r,.008)
    for k in range(5):
        x=-.30+(k%3)*.29;y=.17-(k//3)*.33;box('Pinned_note',(.22,.23,.004),(x,y,.041),'cream' if k%2 else 'pink',r,.005);oval('Pin',(x,y+.09,.048),(.01,.01,.005),'gold',r)
        for j in range(3):box('Handwritten_line',(.15-j*.02,.003,.002),(x,y+.035-j*.035,.045),'teal_dark',r)
    return r
def desk():
    r=root('EmployeeDesk');legs(r,.9,1.9,.72);top_surface(r,.9,1.9,.745)
    box('Drawer_case',(.58,.59,.55),(-.09,.405,.60),'teal',r,.02)
    for y in [.25,.44,.63]:box('Drawer',(.59,.17,.028),(-.09,y,.89),'teal_light',r,.009);tube('Brass_pull',[(-.20,y,.92),(.02,y,.92)],.009,'gold',r)
    top_surface(r,.8,1.72,.17,'walnut');return r
def tasklamp():
    r=root('TaskLamp');cylinder(r,'Base',.10,.025,(0,.013,0),'gold');tube('Articulated_arm',[(0,.025,0),(.04,.25,0),(.16,.44,0)],.012,'gold',r)
    oval('Joint',(.04,.25,0),(.025,.025,.025),'steel_dark',r);g=bc.pivot('Shade_mount',bc.G(.16,.40,0),r);bc.lathe('Sage_shade',[(.09,-.09),(.10,-.07),(.045,.03),(.025,.04)],'teal',g,seg=24,subsurf=0);oval('Warm_bulb',(0,-.07,0),(.045,.02,.045),'yellow',g);return r
def filing():
    r=root('FilingCabinet');box('Case',(.8,.98,.43),(0,.49,0),'teal_dark',r,.025)
    for y in [.20,.50,.80]:
        box('Drawer',(.73,.27,.03),(0,y,.235),'teal',r,.012);front_loop('Pull',0,y,.27,.07,.025,.009,'gold',r);box('Label_slot',(.16,.045,.006),(0,y+.075,.257),'cream',r,.004)
    return r
def spiral():
    r=root('SpiralStair');cylinder(r,'Central_column',.06,4.4,(0,2.2,0),'teal_dark')
    pts=[]
    for k in range(17):
        a=math.pi/2+k*math.radians(25);g=bc.pivot('Tread',bc.G(0,(k+1)*.2,0),r);g.rotation_euler.z=-a
        mesh('Wedge_tread',[(.08,0,-.07),(.68,0,-.16),(.68,0,.16),(.08,0,.07)],[(0,1,2,3)],'walnut',g,.06)
        x=.64*math.cos(a);z=.64*math.sin(a);tube('Baluster',[(x,(k+1)*.2,z),(x,(k+1)*.2+.9,z)],.016,'teal_dark',r);pts.append((x,(k+1)*.2+.9,z))
    tube('Continuous_rail',pts,.028,'gold',r);return r
def frame(r,w,h,role='gold',p=(0,0,0)):
    x,y,z=p
    for xx in [-w/2,w/2]:box('Carved_frame_stile',(.08,h+.12,.08),(x+xx,y,z),role,r,.014)
    for yy in [-h/2,h/2]:box('Carved_frame_rail',(w+.12,.08,.08),(x,y+yy,z),role,r,.014)
    for xx in [-w*.38,w*.38]:leaf_emblem(r,(x+xx,y+h/2,z+.045),.047,'teal')
def easel():
    r=root('GalleryEasel')
    for x in [-.25,.25]:tube('Leg',[(x,0,0),(x*.5,1.3,-.05)],.018,'walnut',r)
    tube('Rear_leg',[(0,1.2,-.05),(0,0,-.45)],.02,'walnut',r);box('Canvas',(.52,.68,.04),(0,.87,0),'purple',r,.012);frame(r,.52,.68,p=(0,.87,.03));leaf_emblem(r,(0,.87,.06),.18,'gold');return r
def gallery():
    r=root('MacabreGallery');facade(r,'GALERIE MACABRE','purple')
    for k in range(3):
        x=(k-1)*.93;box('Canvas',(.72,.96,.035),(x,1.18,.08),'velvet_dark',r,.01);frame(r,.74,.98,p=(x,1.18,.12))
        if k==0:
            oval('Skull',(x,1.25,.17),(.17,.20,.045),'cream',r)
            for s in [-1,1]:oval('Eye_socket',(x+s*.07,1.29,.21),(.045,.06,.012),'ink',r)
            box('Jaw',(.18,.10,.04),(x,1.06,.18),'cream',r,.015)
            for j in range(4):box('Teeth_line',(.004,.045,.004),(x-.06+j*.04,1.04,.206),'ink',r)
        elif k==1:
            tube('Drooping_rose_stem',[(x-.08,.85,.17),(x-.04,1.47,.17),(x+.10,1.49,.17),(x+.15,1.35,.17)],.009,'leaf_light',r)
            for j in range(6):a=j*math.tau/6;oval('Rose_petal',(x+.15+.055*math.cos(a),1.35+.055*math.sin(a),.20),(.04,.045,.012),'pink',r)
            leaf_emblem(r,(x-.09,1.06,.19),.07,'leaf_light')
        else:
            mesh('Coffin_relief',[(x-.10,.80,.18),(x+.10,.80,.18),(x+.16,1.39,.18),(x+.11,1.55,.18),(x-.11,1.55,.18),(x-.16,1.39,.18)],[(0,1,2,3,4,5)],'walnut',r,.04);leaf_emblem(r,(x,1.20,.19),.09,'gold')
        tube('Picture_light_arm',[(x,1.83,.04),(x,1.83,.20)],.009,'gold',r);box('Picture_light',(.26,.035,.07),(x,1.80,.20),'yellow',r,.01)
    return r
def facade(r,text,role='teal'):
    box('Shadow_back',(3.26,2.5,.08),(0,1.25,0),'ink',r,.02)
    frame(r,3.1,2.25,role,(0,1.20,.07));box('Sign_face',(3.30,.38,.12),(0,2.48,.10),role,r,.025)
    ob=letters('Flat_name',text,(0,2.48,.168),.14,'cream',r,'georgiab.ttf');bpy.context.view_layer.update()
    if ob.dimensions.x>3.12:ob.scale*=3.12/ob.dimensions.x
def warehouse():
    r=root('FreightBay');facade(r,'ENTREPÔT DE FRET','teal_dark')
    for k in range(5):box('Shutter_slat',(2.97,.09,.08),(0,2.20-k*.095,.11),'steel',r,.01)
    for k in range(14):box('Safety_stripe',(.21,.08,.05),(-1.4+k*.215,.08,.16),'yellow' if k%2 else 'ink',r,.004)
    for k in range(5):
        x=-.95+(k%3)*.9;y=.05+(k//3)*.64;g=bc.pivot('Shipping_crate',bc.G(x,y,.30),r)
        box('Crate_body',(.72,.59,.48),(0,.295,0),'wood',g,.02)
        for yy in [.09,.50]:box('Strap',(.75,.04,.51),(0,yy,0),'wood_dark',g,.005)
        for xx in [-.28,.28]:box('Vertical_strap',(.04,.60,.51),(xx,.30,0),'teal_dark',g,.004)
    return r
def pallet():
    r=root('Pallet')
    for x in [-.4,0,.4]:box('Runner',(.12,.10,.8),(x,.05,0),'wood_dark',r,.008)
    for z in [-.34,-.17,0,.17,.34]:plank(r,(0,.12,z),(1.1,.04,.13))
    return r
def handtruck():
    r=root('Handtruck')
    for x in [-.17,.17]:tube('Red_frame',[(x,.13,0),(x,1.1,-.12),(x,1.22,-.03)],.02,'red',r);tube('Rubber_grip',[(x,1.22,-.03),(x,1.22,.10)],.027,'rubber',r)
    for y in [.30,.65,1.0]:tube('Crossbar',[(-.17,y,-.07),(.17,y,-.07)],.016,'red',r)
    box('Toe_plate',(.44,.035,.30),(0,.10,.13),'steel',r,.012)
    for x in [-.23,.23]:g=bc.pivot('Wheel',bc.G(x,.13,0),r);g.rotation_euler.z=math.pi/2;front_loop('Tyre',0,0,0,.095,.095,.03,'rubber',g);oval('Hub',(0,0,0),(.055,.055,.02),'steel',g)
    return r
def sofa():
    r=root('SalonSofa');box('Upholstered_base',(1.70,.24,.59),(0,.35,0),'teal_dark',r,.09)
    for x in [-.42,.42]:box('Seat_cushion',(.80,.15,.50),(x,.53,.03),'teal_light',r,.06)
    box('Sculpted_back',(1.7,.50,.16),(0,.79,-.26),'teal',r,.075)
    for x in [-.81,.81]:box('Rolled_arm',(.16,.28,.6),(x,.64,0),'teal',r,.07)
    for x in [-.68,.68]:
        for z in [-.20,.20]:cylinder(r,'Brass_foot',.025,.21,(x,.105,z),'gold')
    for x in [-.52,0,.52]:oval('Tuft_button',(x,.80,-.167),(.018,.018,.009),'gold',r)
    return r
def orbtable():
    r=root('OrbTable');cylinder(r,'Base',.19,.025,(0,.013,0),'gold');cylinder(r,'Stem',.025,.49,(0,.27,0),'gold');cylinder(r,'Top',.25,.035,(0,.53,0),'cream');oval('Orb',(0,.6675,0),(.105,.12,.105),'mint',r);return r
def salon():
    r=root('SalonDisplay');facade(r,'SALON INTERSTELLAIRE','purple')
    for k in range(18):
        x=-1.35+(k%6)*.54;y=.45+(k//6)*.53;oval('Star',(x,y,.065),(.012,.012,.008),'mint',r)
        if k%6<5:tube('Constellation',[(x,y,.06),(x+.54,y+.07*math.sin(k),.06)],.003,'lavender',r)
    return r
def embassy():
    r=root('EmbassyFront');facade(r,'AMBASSADE GALACTIQUE','teal_dark')
    for x in [-1.22,1.22]:
        cylinder(r,'Column',.11,1.95,(x,1.23,.22),'cream');box('Capital',(.35,.12,.35),(x,2.24,.22),'cream',r,.012);box('Column_base',(.34,.12,.35),(x,.27,.22),'cream',r,.012)
        for k in range(10):a=k*math.tau/10;tube('Fluting',[(x+.108*math.cos(a),.38,.22+.108*math.sin(a)),(x+.108*math.cos(a),2.10,.22+.108*math.sin(a))],.004,'gold',r)
    for x in [-.38,.38]:
        box('Blue_door',(.73,1.9,.05),(x,1.15,.15),'velvet_dark',r,.02);moulded_panel(r,.57,1.55,x,1.18,.185,'teal_dark');oval('Golden_handle',(x*.35,1.14,.23),(.025,.025,.018),'gold',r)
    for k in range(3):box('Step',(3.1-k*.18,.08,.75-k*.18),(0,.04+k*.08,.30),'cream',r,.012)
    mesh('Pediment',[(-1.65,2.68,.08),(1.65,2.68,.08),(0,3.08,.08)],[(0,1,2)],'cream',r,.10);front_loop('Planet_ring',0,2.80,.20,.15,.055,.013,'gold',r);oval('Planet',(0,2.80,.19),(.075,.075,.025),'gold',r);return r
def flag():
    r=root('GalacticFlag');cylinder(r,'Foot',.19,.04,(0,.02,0),'teal_dark');cylinder(r,'Pole',.018,3.3,(0,1.69,0),'gold');oval('Finial',(0,3.38,0),(.04,.06,.04),'gold',r)
    verts=[(.03+i*.10,3.22-j*.13,.035*math.sin(i*.9)) for j in range(6) for i in range(11)]
    mesh('Waved_flag',verts,[(j*11+i,j*11+i+1,(j+1)*11+i+1,(j+1)*11+i) for j in range(5) for i in range(10)],'velvet_dark',r,.006);front_loop('Ringed_planet',.54,2.90,.06,.21,.065,.013,'gold',r);oval('Planet',(.54,2.90,.06),(.11,.11,.02),'orange',r);return r
def walllantern():
    r=root('WallLantern');box('Wall_plate',(.13,.27,.025),(0,.32,-.12),'teal_dark',r,.012);tube('Curved_bracket',[(0,.40,-.12),(0,.58,.03),(0,.50,.13)],.018,'teal_dark',r)
    for y in [.04,.40]:box('Cap',(.24,.05,.23),(0,y,.13),'teal_dark',r,.02)
    box('Amber_glass',(.17,.29,.16),(0,.22,.13),'yellow',r,.02)
    for x in [-.10,.10]:
        for z in [.035,.225]:tube('Cage',[(x,.05,z),(x,.42,z)],.01,'teal_dark',r)
    return r
def bins():
    r=root('SortingBins')
    for x,role in [(-.26,'teal'),(.26,'purple')]:
        box('Bin_body',(.44,.65,.43),(x,.325,0),role,r,.04);g=bc.pivot('Hinged_lid',bc.G(x,.68,-.21),r);box('Lid',(.46,.05,.46),(0,0,.21),role,g,.025);box('Handle',(.15,.025,.04),(0,.04,.37),'ink',g,.008);leaf_emblem(r,(x,.36,.222),.10,'cream')
    return r
def delivery():
    r=root('DeliveryBell');box('Enamel_plate',(.24,.34,.025),(0,0,0),'cream',r,.035);oval('Round_button',(0,-.07,.04),(.036,.036,.016),'gold',r);box('Parcel_icon',(.09,.07,.01),(0,.07,.022),'teal',r,.005)
    for size in [(.012,.07,.004),(.09,.009,.004)]:box('Parcel_ribbon',size,(0,.07,.030),'gold',r,.002)
    return r
def directions(text):
    r=root('DirectionBoard');box('Carved_timber',(.76,.24,.045),(0,0,0),'walnut',r,.035);box('Ivory_inset',(.70,.18,.01),(0,0,.029),'cream',r,.025);letters('Flat_direction',text,(.025,0,.036),.085,'teal_dark',r,'georgiab.ttf');leaf_emblem(r,(-.27,0,.038),.043,'leaf');return r
def drain():
    r=root('DrainGrate');box('Recess',(.38,.035,.38),(0,-.018,0),'ink',r,.015)
    for x in [-.19,.19]:box('Frame',(.025,.025,.4),(x,.002,0),'steel',r,.004)
    for z in [-.19,.19]:box('Frame',(.4,.025,.025),(0,.002,z),'steel',r,.004)
    for k in range(8):box('Grate_bar',(.016,.02,.36),(-.15+k*.043,.0,0),'steel_dark',r,.003)
    return r

SPECS=[('bistro_table',table),('chair_mint',lambda:chair()),('chair_rose',lambda:chair('pink')),('parasol',parasol),('deck_tile',deck),('railing',railing),('rail_planter',planter),('border_bed',border),('path_stone',pathstone),('hedge',hedge),('garden_arch',arch),('tap_post',tap),('hose_reel',hose),('wheelbarrow',barrow),('spade',lambda:garden_tool('spade')),('rake',lambda:garden_tool('rake')),('greenhouse_shell',greenhouse),('greenhouse_door',glassdoor),('nursery_bench',bench),('nursery_pot',pot_nursery),('seed_tray',tray),('vent_fan',fan),('thermometer',thermometer),('irrigation_bar',irrigation),('shed_shell',shed),('shed_door',sheddoor),('shed_shelf',shelf_shed),('pot_stack',potstack),('soil_bag',soilbag),('seed_organizer',seedorganizer),('wrapping_station',wrapping),('service_trolley',trolley),('paper_rack',paperrack),('notice_board',notice),('employee_desk',desk),('office_chair',lambda:chair(office=True)),('task_lamp',tasklamp),('filing_cabinet',filing),('balcony_rail',lambda:railing(True)),('spiral_stair',spiral),('gallery_display',gallery),('gallery_easel',easel),('warehouse_bay',warehouse),('handtruck',handtruck),('pallet',pallet),('salon_display',salon),('salon_sofa',sofa),('orb_table',orbtable),('embassy_front',embassy),('galactic_flag',flag),('wall_lantern',walllantern),('outdoor_garland',garland),('sorting_bins',bins),('delivery_bell',delivery),('sign_garden',lambda:directions('JARDIN')),('sign_greenhouse',lambda:directions('SERRE')),('sign_workshop',lambda:directions('ATELIER')),('sign_shed',lambda:directions('REMISE')),('drain_grate',drain)]
selected=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
for name,build in SPECS:
    if selected and name not in selected:continue
    node=build();node['surface_asset']=name;bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BLEND,name+'.blend'));bc.export_glb(os.path.join(OUT,name+'.glb'),node);print('SURFACE_MODEL',name,flush=True)
report=[]
for name,_ in SPECS:
    path=os.path.join(OUT,name+'.glb')
    if not os.path.exists(path):continue
    raw=open(path,'rb').read();n=struct.unpack_from('<I',raw,12)[0];doc=json.loads(raw[20:20+n]);report.append(dict(asset=name,triangles=sum(doc['accessors'][p['indices']]['count']//3 for m in doc['meshes'] for p in m['primitives']),metres=True))
json.dump(report,open(os.path.join(OUT,'manifest.json'),'w'),indent=2);print('SURFACE_MODELS_COMPLETE',len(report),flush=True)
