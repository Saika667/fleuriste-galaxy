"""Refined fauna, organic foliage, a five-storey block and real bakery glazing."""
import os,sys,math,random,bpy
sys.path.insert(0,os.path.dirname(__file__))
exec(open(os.path.join(os.path.dirname(__file__),'animals_and_trees_v4.py'),encoding='utf-8').read().split('\nSPECS=')[0],globals())
from mathutils import Vector

def pointed(name,p,length,width,role,parent,yaw=0,bend=.025):
    # A folded leaf with a pointed tip, shoulder lobes, and an actual central ridge.
    x,y,z=p;c=math.cos(yaw);s=math.sin(yaw)
    def q(a,b,h=0):return (x+a*c+b*s,y+h,z-a*s+b*c)
    verts=[q(0,-length*.5),q(-width*.5,-length*.10),q(-width*.42,length*.24),q(0,length*.5,bend),q(width*.42,length*.24),q(width*.5,-length*.10),q(0,0,bend*.45)]
    mesh(name,verts,[(6,i,(i+1)%6) for i in range(6)],role,parent,.0006)
    if 'live_leaf' not in name:tube(name+'_midrib',[q(0,-length*.5,.001),q(0,0,bend*.45+.001),q(0,length*.5,bend+.001)],max(.0005,width*.012),'wood',parent)

def cat5(sleep=False):
    r=cat(sleep);rig=next(c for c in r.children if c.name=='rig');head=next(c for c in rig.children if c.name=='head');head.scale*=.9
    rig.rotation_euler.z=0;rig.location.z=-.10 if sleep else 0
    for leg in [c for c in rig.children if c.name.startswith('leg_')]:
        if sleep:leg.rotation_euler.x=1.4 if int(leg.name.split('_')[-1])<2 else -1.2
    tail=next(c for c in rig.children if c.name=='tail')
    for c in list(tail.children):bpy.data.objects.remove(c,do_unlink=True)
    pts=[(0,0,0),(.025,.035,-.10),(.085,.11,-.15),(.12,.18,-.11),(.12,.22,-.065)]
    for i in range(4):tube('Tapered_tail_segment',pts[i:i+2],.022-i*.004,'white_fur' if i==3 else 'fur',tail)
    oval('Neck_transition',(0,.285,.145),(.075,.075,.07),'fur',rig)
    for s in [-1,1]:
        mesh('Cheek_fur',[(s*.07,-.02,.05),(s*.115,-.025,.075),(s*.09,-.045,.05),(s*.112,-.055,.05),(s*.06,-.05,.07)],[(0,1,2),(2,3,4)],'fur',head,.002)
        for j in range(3):tube('Subtle_fur_mark',[(s*.101,.25,-.03+j*.055),(s*.114,.24,.0+j*.055)],.002,'fur_dark',rig)
    return r

def spider5():
    r=cn('CellarSpider');rig=pivot('rig',(0,0,0),r)
    for k,c in {'spider':'#62505D','spider_dark':'#413C42','leg':'#6E6264','pattern':'#A08C8F'}.items():bc.material(k,c)
    oval('Ovoid_abdomen',(0,.057,-.05),(.048,.043,.069),'spider',rig)
    oval('Cephalothorax',(0,.05,.035),(.032,.026,.038),'spider_dark',rig)
    for j in range(4):
        for s in [-1,1]:
            anchor=(s*.024,.052,.057-j*.022);leg=pivot('leg_'+str(j*2+(s+1)//2),anchor,rig)
            a=(0,0,0);b=(s*.036,.018,.019-j*.012);c=(s*.075,.030,.040-j*.025);d=(s*.125,-.046,.066-j*.042)
            tube('Femur',[a,b,c],.0033,'leg',leg);tube('Tibia_tarsus',[c,((c[0]+d[0])*.55,-.018,(c[2]+d[2])*.5),d],.0021,'leg',leg)
            oval('Knee',c,(.004,.004,.004),'spider_dark',leg)
    for s in [-1,1]:
        oval('Principal_eye',(s*.012,.060,.065),(.009,.010,.006),'ink',rig)
        oval('Eye_glint',(s*.012-.002,.064,.071),(.002,.002,.001),'cream',rig)
        tube('Chelicera',[(s*.008,.037,.065),(s*.010,.030,.075),(s*.004,.026,.079)],.003,'spider_dark',rig)
        tube('Pedipalp',[(s*.022,.039,.059),(s*.029,.027,.079)],.002,'leg',rig)
    for j in range(6):oval('Secondary_eye',((j-2.5)*.007,.070-abs(j-2.5)*.002,.054),(.0025,.003,.0025),'ink',rig)
    for j in range(5):
        zz=-.08+j*.014;y=.057+.043*math.sqrt(max(.1,1-((zz+.05)/.069)**2))+.001
        tube('Dorsal_chevron',[(-.012,y-.002,zz-.004),(0,y,zz+.005),(.012,y-.002,zz-.004)],.001,'pattern',rig)
    return r

def wing5(parent,s,fore):
    z=.018 if fore else -.042
    outline=[(.008,z-.018),(.032,z-.044),(.078,z-.049),(.112,z-.025),(.145,z+.035),(.143,z+.078),(.123,z+.092),(.085,z+.079),(.041,z+.041)] if fore else [(.007,z+.012),(.039,z-.055),(.074,z-.067),(.104,z-.048),(.113,z-.013),(.086,z+.018),(.041,z+.032)]
    smooth=[]
    for i in range(len(outline)):
        p0=outline[(i-1)%len(outline)];p1=outline[i];p2=outline[(i+1)%len(outline)];p3=outline[(i+2)%len(outline)]
        for k in range(6):
            t=k/6
            smooth.append(tuple(.5*((2*p1[j])+(-p0[j]+p2[j])*t+(2*p0[j]-5*p1[j]+4*p2[j]-p3[j])*t*t+(-p0[j]+3*p1[j]-3*p2[j]+p3[j])*t*t*t) for j in range(2)))
    outline=smooth
    center=(sum(p[0] for p in outline)/len(outline),sum(p[1] for p in outline)/len(outline))
    vs=[(s*x,0,zz) for x,zz in outline]+[(s*center[0],.003,center[1])]
    mesh('Black_wing_margin',vs,[(len(outline),i,(i+1)%len(outline)) for i in range(len(outline))],'ink',parent,.0007)
    inner=[(s*(center[0]+(x-center[0])*.86),.0015,center[1]+(zz-center[1])*.86) for x,zz in outline]+[(s*center[0],.004,center[1])]
    mesh('Forewing_orange' if fore else 'Hindwing_ochre',inner,[(len(outline),i,(i+1)%len(outline)) for i in range(len(outline))],'orange' if fore else 'ochre',parent,.0003)
    for x,zz in outline[12:-6:6]:
        tube('Fine_wing_vein',[(s*.013,.004,z),(s*center[0],.004,center[1]),(s*(center[0]+(x-center[0])*.86),.004,center[1]+(zz-center[1])*.86)],.00065,'wood_dark',parent)
        oval('Margin_cream_spot',(s*(center[0]+(x-center[0])*.92),.003,center[1]+(zz-center[1])*.92),(.0023,.0008,.0028),'cream',parent)

def butterfly5():
    r=cn('GardenButterfly');rig=pivot('rig',(0,0,0),r)
    oval('Thorax',(0,.003,.017),(.009,.010,.016),'wood_dark',rig)
    for j in range(7):oval('Tapered_abdominal_segment',(0,-j*.0003,-.005-j*.008),(.008-j*.0006,.008-j*.0006,.006),'wood',rig)
    oval('Head',(0,.007,.038),(.011,.011,.010),'wood_dark',rig)
    for s in [-1,1]:
        oval('Compound_eye',(s*.009,.009,.043),(.005,.006,.005),'ink',rig)
        oval('Eye_reflection',(s*.010,.012,.047),(.0015,.0015,.001),'cream',rig)
        wing=pivot('wing_'+str(s),(0,0,0),rig);wing5(wing,s,True);wing5(wing,s,False)
        tube('Clubbed_antenna',[(s*.004,.014,.043),(s*.014,.031,.065),(s*.027,.038,.076)],.0008,'wood_dark',rig)
        oval('Antenna_club',(s*.027,.038,.076),(.002,.0015,.003),'ink',rig)
        for j in range(3):tube('Jointed_leg',[(s*.006,0,.026-j*.012),(s*.017,-.010,.032-j*.014),(s*.028,-.018,.044-j*.019)],.0008,'wood_dark',rig)
    return r

def firefly5():
    r=cn('Firefly');rig=pivot('rig',(0,0,0),r)
    for role,col in {'elytron':'#555D3A','elytron_edge':'#8B9460','amber':'#AD8045','insect_leg':'#534A35','light_segment':'#B4D765','firefly_glow':'#CDEB62'}.items():bc.material(role,col)
    glow=bc._MATS['firefly_glow'].node_tree.nodes['Principled BSDF'];glow.inputs['Emission Color'].default_value=(.64,.95,.15,1);glow.inputs['Emission Strength'].default_value=1.2
    for j in range(5):
        rad=.0075-j*.0006;oval('Abdominal_segment',(0,0,-.004-j*.0055),(rad,.0048,.0042),'firefly_glow' if j>1 else 'light_segment',rig)
    oval('Pronotum',(0,.003,.010),(.0085,.005,.009),'amber',rig)
    oval('Head',(0,.002,.021),(.0055,.0045,.005),'insect_leg',rig)
    for s in [-1,1]:
        oval('Compound_eye',(s*.0048,.004,.023),(.0032,.0038,.0028),'ink',rig)
        oval('Eye_glint',(s*.005,.0053,.025),(.0007,.0008,.0005),'cream',rig)
        wing=pivot('wing_'+str(s),(s*.001,.005,.010),rig)
        oval('Protective_elytron',(s*.0032,0,-.015),(.0046,.0025,.019),'elytron',wing)
        tube('Elytron_seam',[(s*.0004,.002,0),(s*.0007,.002,-.029)],.00035,'elytron_edge',wing)
        for j in range(3):
            zz=.01-j*.011;tube('Jointed_six_legs',[(s*.005,-.001,zz),(s*.011,-.003,zz-.002),(s*.014,-.010,zz+.003),(s*.018,-.011,zz+.005)],.00055,'insect_leg',rig)
        tube('Segmented_antenna',[(s*.003,.004,.023),(s*.005,.009,.030),(s*.009,.010,.036)],.0005,'insect_leg',rig)
    return r

def pigeon5():
    r=cn('CityPigeon');rig=pivot('rig',(0,0,0),r)
    for role,col in {'plume':'#87929A','plume_dark':'#44515C','neck5':'#547C7A','neck_iris':'#675C7A','pigeon_feet':'#B37E78'}.items():bc.material(role,col)
    oval('Pear_shaped_body',(0,.165,-.015),(.105,.125,.17),'plume',rig)
    oval('Breast',(0,.215,.085),(.085,.105,.09),'plume',rig)
    oval('Tapered_neck',(0,.295,.085),(.052,.09,.053),'neck5',rig)
    for i in range(16):
        a=i*math.tau/16;oval('Iridescent_neck_scale',(.047*math.cos(a),.287+(i%3)*.012,.085+.046*math.sin(a)),(.015,.022,.008),'neck_iris' if i%3==0 else 'neck5',rig)
    head=pivot('head',(0,.367,.112),rig);oval('Rounded_head',(0,0,0),(.057,.061,.062),'plume',head)
    for s in [-1,1]:
        oval('Orange_iris',(s*.049,.010,.025),(.009,.011,.007),'ochre',head);oval('Round_pupil',(s*.055,.011,.028),(.0045,.006,.003),'ink',head)
        oval('White_eye_glint',(s*.056,.013,.031),(.0015,.0015,.001),'cream',head)
        wing=pivot('wing_'+str(s),(s*.095,.215,.025),rig)
        oval('Wing_coverts',(s*.003,-.005,-.035),(.027,.073,.122),'plume',wing)
        for j in range(9):oval('Overlapping_primary_feather',(s*(.018+j*.001),-.032-j*.004,-.043-j*.016),(.016,.043,.064),'plume_dark' if j>5 else 'plume',wing)
        for z in [-.012,-.055]:tube('Two_wing_bars',[(s*.026,.034,z),(s*.035,-.055,z-.030)],.005,'plume_dark',wing)
        tube('Scaly_leg',[(s*.040,.10,0),(s*.045,.035,.013)],.006,'pigeon_feet',rig)
        for k in [-1,0,1]:
            end=(s*.045+k*.025,.007,.074-abs(k)*.012)
            tube('Toe_phalanges',[(s*.045,.035,.013),(s*.045+k*.013,.012,.045),end],.003,'pigeon_feet',rig)
            tube('Claw',[end,(end[0],.003,end[2]+.009)],.0013,'ink',rig)
        tube('Rear_toe',[(s*.045,.025,.014),(s*.055,.005,-.020)],.0025,'pigeon_feet',rig)
    for j in range(8):oval('Tail_rectrix',((j-3.5)*.015,.14,-.19),(.012,.010,.083),'plume_dark',rig)
    oval('Upper_beak',(0,-.011,.071),(.017,.010,.035),'plume_dark',head)
    oval('Nasal_cere',(0,.001,.056),(.015,.007,.013),'cream',head)
    return r

def tree5(v,hedge=False):
    r=cn('HedgeSegment' if hedge else 'UrbanTree'+str(v));rng=random.Random(981+v)
    for role,col in {'bark5':'#6D604B','foliage5':'#4D7146','foliage_light5':'#71905C','soil5':'#574935','leaf_dead':'#A3844D','leaf_dead2':'#957445','pit_stone':'#A99E89'}.items():bc.material(role,col)
    if hedge:
        centers=[(-.3,1,0),(0,.9,.1),(.3,1.1,-.1)]
    else:
        for x in [-.68,.68]:box('Hollow_pit_border',(.12,.13,1.42),(x,.065,0),'pit_stone',r,.015)
        for z in [-.68,.68]:box('Hollow_pit_border',(1.24,.13,.12),(0,.065,z),'pit_stone',r,.015)
        box('Soil',(1.24,.04,1.24),(0,.04,0),'soil5',r,.008)
        tube('Trunk',[(0,.06,0),(.025,1.1,0),(-.025,2.2,.035),(.05,3.5,0)],.095,'bark5',r)
        centers=[]
        for i in range(12):
            a=i*2.4;rad=rng.uniform(.45,1.05);y=2.6+rng.random()*1.4
            p=(math.cos(a)*rad,y,math.sin(a)*rad);centers.append(p)
            tube('Tapered_branch',[(0,1.6+i*.07,0),(p[0]*.5,p[1]-.32,p[2]*.5),p],.024 if i<8 else .018,'bark5',r)
        for i in range(110):
            x=rng.uniform(-.55,.55);z=rng.uniform(-.55,.55)
            if x*x+z*z<.04:continue
            h=rng.uniform(.07,.18);mesh('Grass_blade',[(x-.006,.061,z),(x+.006,.061,z),(x+rng.uniform(-.03,.03),h+.061,z+.025)],[(0,1,2)],'foliage5',r,.0008)
        for i in range(28):
            a=rng.random()*math.tau;rad=rng.uniform(.20,.60) if i<18 else rng.uniform(.80,1.15)
            pointed('Fallen_pointed_leaf',(math.cos(a)*rad,.066 if i<18 else .027,math.sin(a)*rad),rng.uniform(.07,.11),rng.uniform(.035,.05),'leaf_dead' if i%2 else 'leaf_dead2',r,a,.006)
        for i in range(6):
            a=i*2.4;x=.45*math.cos(a);z=.45*math.sin(a)
            tube('Flower_stem',[(x,.06,z),(x,.16,z)],.003,'leaf',r)
            for j in range(5):aa=j*math.tau/5;oval('Small_petals',(x+.02*math.cos(aa),.17,z+.02*math.sin(aa)),(.018,.004,.010),'cream',r)
    for ci,p in enumerate(centers):
        for j in range(45 if not hedge else 70):
            a=rng.random()*math.tau;rr=rng.uniform(.05,.65 if not hedge else .43);pos=(p[0]+math.cos(a)*rr,p[1]+rng.uniform(-.4,.45),p[2]+math.sin(a)*rr)
            pointed('Folded_live_leaf',pos,.18 if not hedge else .15,.075,'foliage5' if j%3 else 'foliage_light5',r,a,rng.uniform(.01,.05))
    return r

def bakery5():
    r=cn('BakeryGlazedDisplay')
    for role,col in {'frame5':'#345348','oak5':'#A67C4D','crust5':'#BB7C38','bread_light5':'#DCAF66','chocolate5':'#523B2A','glass':'#D5E4DF'}.items():bc.material(role,col)
    b=bc._MATS['glass'];b.node_tree.nodes['Principled BSDF'].inputs['Alpha'].default_value=.10;b.surface_render_method='DITHERED'
    for x in [-1.54,1.54]:box('Timber_pilaster',(.15,2.7,.65),(x,1.35,0),'frame5',r,.012)
    for y in [.14,2.2,2.62]:box('Frame_rail',(3.1,.12,.66),(0,y,0),'frame5',r,.012)
    box('Paneled_base',(3.05,.44,.10),(0,.35,.28),'frame5',r,.012)
    box('Interior_back',(3.0,2.12,.04),(0,1.14,-.31),'oak5',r,.005)
    for yy in [.60,1.12,1.64]:
        box('Oak_display_shelf',(2.98,.04,.55),(0,yy,-.02),'oak5',r,.007)
        for i in range(7):
            x=-1.24+i*.41
            if yy<.8:
                oval('Round_loaf',(x,yy+.105,0),(.16,.10,.13),'crust5',r)
                for k in [-1,0,1]:tube('Scored_crust',[(x-.11,yy+.165,-.06+k*.047),(x,yy+.205,-.04+k*.047),(x+.11,yy+.165,-.02+k*.047)],.008,'bread_light5',r)
            elif yy<1.4:
                # A crescent, with nested laminated lobes instead of a yellow oval.
                for j in range(7):
                    a=-1.2+j*.4;oval('Croissant_lamination',(x+.11*math.sin(a),yy+.06,0+.085*math.cos(a)),(.045-j*.002,.050-abs(j-3)*.006,.040),'bread_light5' if j%2 else 'crust5',r)
            else:
                ob=oval('Baguette',(x,yy+.13,-.04),(.046,.065,.24),'crust5',r);ob.rotation_euler.z=.18
                for j in range(4):tube('Baguette_score',[(x-.025,yy+.18,-.20+j*.10),(x+.025,yy+.20,-.17+j*.10)],.006,'bread_light5',r)
    # Glazing stays transparent in Godot; bread is actual geometry behind it.
    box('Glass_front',(2.94,1.60,.008),(0,1.39,.327),'glass',r,0)
    box('Framed_sign',(3.05,.37,.10),(0,2.43,.34),'frame5',r,.015)
    for y in [2.25,2.61]:box('Gold_sign_border',(2.96,.018,.014),(0,y,.397),'gold',r,.002)
    letters('Bakery_title','BOULANGERIE',(0,2.35,.401),.23,'cream',r,font='georgia.ttf')
    return r

if __name__=='__main__':
    jobs=[('cat',lambda:cat5(False)),('cat_sleeping',lambda:cat5(True)),('pigeon',pigeon5),('spider',spider5),('butterfly',butterfly5),('firefly',firefly5),('hedge_v5',lambda:tree5(2,True))]+[('tree_'+str(v),lambda v=v:tree5(v)) for v in range(3)]
    selected=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
    for name,fn in jobs:
        if selected and name not in selected:continue
        ob=fn();bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SOURCE,name+'.blend'));bc.export_glb(os.path.join(OUT,name+'.glb'),ob);print('V5_ASSET',name,flush=True)
    if selected:sys.exit(0)
    ob=bakery5();bc.export_glb(os.path.join(bc.ROOT,'assets/models/street/bakery_display.glb'),ob);bpy.ops.wm.save_as_mainfile(filepath=os.path.join(bc.ROOT,'art/blender/street/bakery_display.blend'))
    # Reuse coherent architecture, then deepen the party-wall building to the reference dimensions.
    exec(open(os.path.join(os.path.dirname(__file__),'street_architecture_v2.py'),encoding='utf-8').read().split('\nfor spec in ')[0],globals())
    building('apartment_five',12,6,'#B5B7A4','house')
    r=bpy.data.objects.get('apartment_five')
    if r:
        r.scale.y=9/7
        for c in list(r.children):
            if c.name.startswith('Side_joinery'):bpy.data.objects.remove(c,do_unlink=True)
        for child in r.children_recursive:
            for modifier in child.modifiers:
                if modifier.type=='BEVEL':modifier.segments=1
        bc.export_glb(os.path.join(bc.ROOT,'assets/models/street/apartment_five.glb'),r);bpy.ops.wm.save_as_mainfile(filepath=os.path.join(bc.ROOT,'art/blender/street/apartment_five.blend'))
