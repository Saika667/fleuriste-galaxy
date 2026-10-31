"""Native metric game props for the approved catalogue sheets 54–73.
Godot coordinates: Y up, front +Z; all generated objects have editable Blender sources.
"""
import os,sys,math,json,struct,random
import bpy,bmesh
from mathutils import Vector
sys.path.insert(0,os.path.dirname(__file__))
exec(open(os.path.join(os.path.dirname(__file__),'shop_items_34_53.py'),encoding='utf-8').read().split('\nSPECS=')[0],globals())
from mathutils import Matrix,Quaternion

# This collection specifies geometry in the parent's LOCAL coordinates. The older
# helpers preserve world transforms by default, which buries details in translated
# pivots. Override only in this generator process, never in the shared helper file.
def local_parent(obj,parent):
    obj.parent=parent
    obj.matrix_parent_inverse=Matrix.Identity(4)
bc._parent=local_parent

def fresh(name):
    r=begin(name)
    for role,col in {'mint':'#8FCEB8','rose_glass':'#C76B91','ivory_tile':'#F8F4E6','grain':'#B28A60','honey':'#C8A882','plum':'#5E3A86','coral_enamel':'#E05B5B','sage_pot':'#8FB68F','lilac_pot':'#CDBDDC','xeno_teal':'#0E6F73','xeno_purple':'#7B3F8E','lime':'#B7F25E','socket':'#D8BD7F'}.items():bc.material(role,col)
    return r

def front_ring(r,name,rx,ry,z,rad,role='gold',x=0,y=0):
    return front_loop(name,x,y,z,rx,ry,rad,role,r)

def moulded_panel(r,w,h,x,y,z,role):
    box('Recessed_panel',(w,h,.012),(x,y,z),role,r,.01)
    for s in [-1,1]:
        box('Inset_vertical_bead',(.009,h,.009),(x+s*w/2,y,z+.008),'gold',r,.003)
        box('Inset_horizontal_bead',(w,.009,.009),(x,y+s*h/2,z+.008),'cream',r,.003)

def bunting_new():
    r=fresh('Bunting960cm')
    pts=[(-4.8+i*.16,-.32*(1-((-4.8+i*.16)/4.8)**2),0) for i in range(61)]
    tube('Continuous_braided_cord',pts,.006,'ink',r)
    cols=['pink','ochre','mint','lavender','cream']
    for i in range(30):
        x=-4.64+i*.32;y=-.32*(1-(x/4.8)**2)
        mesh('Cloth_flag',[(x-.125,y-.012,.0),(x+.125,y-.012,0),(x,y-.325,.015)],[(0,1,2)],cols[i%5],r,.003)
        line('Flag_double_hem',[(x-.117,y-.02,.003),(x,y-.31,.018),(x+.117,y-.02,.003)],.0015,'cream',r)
        tube('Folded_sleeve',[(x-.125,y,0),(x+.125,y,0)],.009,cols[i%5],r)
        if i%2==0:
            motif(r,x,y-.13,.008,.045,'cream')
            back=bc.pivot('Reverse_flag_pattern',bc.G(x,y-.13,-.004),r);back.rotation_euler.z=math.pi;motif(back,0,0,0,.045,'cream')
    for x in [-4.8,4.8]:
        front_loop('Brass_end_hook',x,.018,0,.035,.04,.008,'gold',r)
        for k in range(3):oval('End_cord_knot',(x+(k-1)*.015,0,0),(.012,.012,.012),'ink',r)
    return r

def floor_new():
    r=fresh('ShopFloor10x8')
    rng=random.Random(55)
    # Origin at room centre. Exclude the existing hatch at world (0..1,1..2).
    for row in range(25):
        z=-4+(row+.5)*.2
        for col in range(10):
            x=-4.5+col
            if col==0 and -3<=z<-2:continue
            role='honey' if rng.random()<.8 else 'sage'
            box('Timber_plank',(.996,.012,.196),(x,0,z),role,r,.001)
            if col%2==0:
                line('Broad_cartoon_grain',[(x-.39,.0065,z-.03),(x-.08,.0065,z-.022),(x+.34,.0065,z-.035)],.0013,'grain',r)
    for row in range(6):
        for col in range(20):
            box('Checker_tile',(.496,.012,.496),(-4.75+col*.5,0,1.25+row*.5),'teal_light' if (row+col)%2 else 'ivory_tile',r,.001)
    box('Flush_brass_transition',(10,.014,.035),(0,0,1),'gold',r,.001)
    for w,d,y,role in [(4.2,1.9,.007,'pink'),(4.06,1.76,.008,'cream'),(3.93,1.63,.009,'teal')]:box('Inset_woven_rug',(w,.002,d),(0,y,2.55),role,r,.015)
    for ix in range(10):
        for iz in range(4):
            g=bc.pivot('Flat_woven_botanical',bc.G(-1.76+ix*.39,.011,1.96+iz*.39),r)
            motif(g,0,0,0,.09);g.rotation_euler.x=math.pi/2
    return r

def ceiling_new():
    r=fresh('CeilingAndFourBeams')
    box('Cream_ceiling_slab',(10,.08,8),(0,.04,0),'cream',r,.005)
    for x in [-4.93,4.93]:
        box('Perimeter_long_cornice',(.14,.095,8),(x,-.047,0),'cream',r,.016)
        box('Cornice_gold_bead',(.012,.012,8),(x-.04*(1 if x>0 else -1),-.091,0),'gold',r,.004)
    for z in [-3.93,3.93]:box('End_cornice',(10,.095,.14),(0,-.047,z),'cream',r,.016)
    for z in [-3,-1,1,3]:
        box('Transverse_walnut_beam',(9.95,.24,.14),(0,-.12,z),'walnut',r,.014)
        for x in [-4.82,4.82]:
            box('Teal_end_bracket',(.24,.26,.20),(x,-.16,z),'teal_dark',r,.02)
            box('Brass_end_strap',(.045,.27,.205),(x,-.16,z),'gold',r,.006)
            for s in [-1,1]:motif(r,x,-.16,z+s*.105,.08)
    for x in [-2.5,2.5]:
        for z in [-1.5,2]:
            bc.cylinder('Suspension_attachment',.095,.095,.015,(x,-.008,z),'gold',r,seg=32,bevel=.003)
    return r

def door_new(service=False):
    r=fresh('ServiceDoor' if service else 'EntranceDoor')
    # Origin on the moving hinge, all leaf geometry to +X. Runtime places fixed frame separately.
    g=bc.pivot('DoorLeaf',bc.G(0,0,0),r);g['articulated']=True;col='plum' if service else 'teal'
    if service:box('Solid_leaf',(.96,2.2,.05),(.48,1.1,0),col,g,.01)
    else:
        box('Lower_leaf',(.96,1.02,.05),(.48,.51,0),col,g,.01)
        box('Top_rail',(.96,.19,.05),(.48,2.105,0),col,g,.008)
        for x in [.085,.875]:box('Glazed_side_stile',(.17,1.0,.05),(x,1.52,0),col,g,.008)
        box('Window_glass',(.62,1.0,.008),(.48,1.52,0),'cold',g,.002)
    for sd in [-1,1]:
        side=bc.pivot('Interior' if sd<0 else 'Exterior',bc.G(.48,0,sd*.025),g)
        if sd<0:side.rotation_euler.z=math.pi
        moulded_panel(side,.68,.56,0,.46,.008,col)
        if service:moulded_panel(side,.68,.76,0,1.63,.008,col)
        else:
            for s in [-1,1]:
                box('Window_moulding',(.018,1.04,.012),(s*.32,1.52,.005),'cream',side,.004)
                box('Window_moulding',(.66,.018,.012),(0,1.52+s*.52,.005),'cream',side,.004)
            box('Brass_kickplate',(.82,.14,.012),(0,.11,.007),'gold',side,.004)
        motif(side,0,2.10,.007,.07)
        hx=.365 if sd>0 else -.365
        oval('Handle_rosette',(hx,1.02,.020),(.027,.038,.008),'gold',side)
        if service:tube('Brass_lever',[(hx,1.02,.022),(hx,1.02,.06),(hx-.08*sd,1.02,.065)],.009,'gold',side)
        else:oval('Brass_knob',(hx,1.02,.05),(.027,.027,.025),'gold',side)
        oval('Key_escutcheon',(hx,.93,.013),(.018,.026,.004),'gold',side)
        oval('Keyhole',(hx,.935,.018),(.004,.007,.001),'ink',side)
    for y in [.28,1.1,1.94]:
        bc.cylinder('Hinge_barrel',.014,.014,.10,(0,y,0),'gold',g,seg=20,bevel=.003)
        box('Hinge_plate',(.045,.095,.005),(.023,y,.030),'gold',g,.003)
    box('Latch_plate',(.005,.12,.032),(.961,1.02,0),'gold',g,.002)
    frame=bc.pivot('FixedFrame',bc.G(0,0,0),r)
    frame['articulated']=True
    for x in [-.045,1.005]:
        box('Cream_door_jamb',(.085,2.30,.10),(x,1.15,0),'cream',frame,.008)
        box('Teal_frame_liner',(.015,2.22,.065),(x+(.044 if x<0 else -.044),1.11,0),'teal_dark',frame,.003)
    box('Cream_door_header',(1.14,.10,.12),(.48,2.25,0),'cream',frame,.012)
    return r

def pendant_new(yellow=False):
    r=fresh('YellowCorollaPendant' if yellow else 'PinkPetalPendant')
    tube('Adjustable_textile_cable',[(0,0,0),(0,-.37,0)],.006,'ink',r)
    bc.cylinder('Ceiling_rose',.055,.055,.022,(0,-.011,0),'gold' if not yellow else 'ink',r,seg=32,bevel=.003)
    bc.lathe('Six_lobe_enamel_shade',[(.035,-.37),(.052,-.39),(.11,-.44),(.21,-.54),(.30,-.62),(.297,-.635),(.285,-.627),(.20,-.545),(.10,-.445),(.045,-.40),(.030,-.385)],'yellow' if yellow else 'pink',r,seg=72,subsurf=0,mod=lambda a,t:(1+.12*math.cos(6*a),.014*math.cos(6*a)))
    bc.lathe('Ivory_reflective_lining',[(.038,-.405),(.10,-.451),(.20,-.55),(.286,-.629)],'cream',r,seg=72,subsurf=0,mod=lambda a,t:(1+.12*math.cos(6*a),.014*math.cos(6*a)))
    for i in range(6):
        a=(i+.5)*math.tau/6
        line('Petal_join_seam',[(rr*.88*math.sin(a),y-.014,rr*.88*math.cos(a)) for rr,y in [(.052,-.39),(.11,-.44),(.21,-.54),(.30,-.62)]],.0018,'ochre' if yellow else 'ribbon',r)
    ring('Brass_socket_collar',.043,-.38,.006,'gold',r)
    bc.cylinder('Teal_top_cap',.020,.046,.075,(0,-.36,0),'teal' if yellow else 'gold',r,seg=32,bevel=.004)
    bc.cylinder('Replaceable_socket',.022,.022,.045,(0,-.43,0),'socket',r,seg=24,bevel=.003)
    oval('Warm_bulb',(0,-.49,0),(.040,.060,.040),'yellow',r)
    return r

VASE_IDS=['rose','tulip','lily','sunflower','lavender','daisy','poppy','xeno_bloom']
def vase_new(kind):
    r=fresh('CollectionVase_'+kind)
    profiles={
    'rose':[(.073,.004),(.077,.02),(.11,.07),(.12,.14),(.104,.23),(.066,.278),(.069,.30),(.088,.334),(.088,.34)],
    'tulip':[(.055,.004),(.072,.018),(.047,.04),(.067,.08),(.095,.20),(.112,.31),(.12,.34)],
    'lily':[(.075,.004),(.082,.018),(.043,.045),(.035,.068),(.075,.09),(.112,.17),(.113,.25),(.093,.28),(.125,.335),(.125,.34)],
    'sunflower':[(.075,.004),(.09,.016),(.122,.07),(.13,.14),(.112,.24),(.076,.29),(.076,.32),(.094,.335),(.094,.34)],
    'lavender':[(.074,.004),(.079,.02),(.083,.09),(.10,.28),(.09,.32),(.09,.34)],
    'daisy':[(.075,.004),(.085,.015),(.11,.05),(.135,.12),(.127,.20),(.087,.25),(.12,.294),(.12,.30)],
    'poppy':[(.082,.004),(.095,.024),(.104,.08),(.11,.24),(.096,.29),(.073,.31),(.073,.34)],
    'xeno_bloom':[(.055,.025),(.088,.04),(.112,.10),(.117,.15),(.09,.24),(.067,.27),(.106,.325),(.12,.34)]}
    col={'rose':'rose_glass','tulip':'mint','lily':'cream','sunflower':'orange','lavender':'lilac_pot','daisy':'sage_pot','poppy':'coral','xeno_bloom':'xeno_teal'}[kind]
    def modulation(a,t):
        if kind in ['lavender','poppy']:
            n=4;return ((abs(math.cos(a))**4+abs(math.sin(a))**4)**(-.25)*.90,0)
        if kind=='tulip':return (1+.022*math.cos(12*a),.004*math.cos(8*a)*max(0,(t-.85)/.15))
        if kind in ['daisy','xeno_bloom']:return (1+.05*math.cos(6*a),.008*math.cos(6*a)*max(0,(t-.85)/.15))
        return (1+.015*math.cos(10*a),0)
    solid('Continuous_hollow_vessel',profiles[kind],col,r,seg=64,mod=modulation)
    rad,h=profiles[kind][-1];ring('Rolled_open_lip',rad,h-.004,.005,'cream' if kind not in ['rose','poppy','xeno_bloom'] else ('xeno_purple' if kind=='xeno_bloom' else col),r)
    ring('Base_ring',profiles[kind][0][0],.009,.004,'cream' if kind!='xeno_bloom' else 'gold',r)
    if kind=='tulip':bc.lathe('Cream_pedestal',[(rr+.0015,y) for rr,y in profiles[kind][:3]],'cream',r,seg=64,subsurf=0)
    if kind=='rose':
        ring('Ivory_neck_cord',.068,.282,.003,'cream',r)
        oval('Brass_medallion',(0,.262,.080),(.018,.025,.004),'gold',r);motif(r,0,.262,.086,.024,'cream')
    if kind=='lily':
        bc.lathe('Teal_shoulder_band',[(.113,.224),(.114,.224),(.114,.263),(.105,.271)],'teal',r,seg=64,subsurf=0)
        for a in range(8):
            g=bc.pivot('Shoulder_relief',bc.G(0,0,0),r);g.rotation_euler.z=a*math.tau/8;motif(g,0,.246,.115,.022)
    elif kind in ['tulip','daisy']:
        if kind=='tulip':motif(r,0,.195,.099,.04)
        else:
            for i in range(6):
                a=i*math.tau/6;oval('Daisy_relief_petal',(.018*math.sin(a),.13+.018*math.cos(a),.137),(.009,.014,.003),'cream',r)
            oval('Daisy_relief_center',(0,.13,.141),(.008,.008,.003),'gold',r)
    elif kind in ['lavender','poppy']:
        for sd in [-1,1]:
            g=bc.pivot('Ceramic_botanical_relief',bc.G(0,0,0),r);g.rotation_euler.z=math.pi if sd<0 else 0
            line('Etched_sprig',[(0,.045,.085),(.018,.12,.096),(0,.24,.093)],.0017,'cream' if kind=='poppy' else 'leaf',g)
            for k in range(4):
                motif(g,(k%2-.5)*.025,.085+k*.034,.095,.022,'cream' if kind=='poppy' else 'violet')
    elif kind=='sunflower':
        ring('Gold_leaf_band_lower',.12,.085,.002,'gold',r);ring('Gold_leaf_band_upper',.131,.14,.002,'gold',r)
        for i in range(10):
            g=bc.pivot('Terracotta_leaf_relief',bc.G(0,0,0),r);g.rotation_euler.z=i*math.tau/10;motif(g,0,.11,.129,.025,'leaf')
        oval('Teal_medallion',(0,.11,.135),(.017,.023,.005),'teal',r)
    elif kind=='xeno_bloom':
        for i in range(3):
            a=i*math.tau/3;oval('Three_stable_feet',(.087*math.sin(a),.019,.087*math.cos(a)),(.025,.019,.025),'xeno_purple',r)
        for i in range(8):
            g=bc.pivot('Xeno_relief',bc.G(0,0,0),r);g.rotation_euler.z=i*math.tau/8;motif(g,0,.12,.118,.044,'xeno_purple');oval('Lime_inset',(0,.23,.091),(.007,.007,.003),'lime',g)
        oval('Gold_window_frame',(0,.155,.122),(.027,.044,.005),'gold',r);oval('Blue_window',(0,.155,.128),(.022,.038,.003),'blue',r)
    return r

def skull_new():
    r=fresh('FloweredShelfSkull')
    head=oval('Hollow_cranium',(0,.12,-.012),(.10,.10,.10),'bone',r)
    # Sculpt shallow zygomatic ridges directly into a continuous subdivided cranium.
    subdivision=head.modifiers.new('Continuous_cranial_surface','SUBSURF');subdivision.levels=1
    bpy.context.view_layer.objects.active=head;bpy.ops.object.modifier_apply(modifier=subdivision.name)
    for v in head.data.vertices:
        y=v.co.z+.12
        ridge=math.exp(-((y-.086)/.024)**2)*min(1,abs(v.co.x)/.05)
        v.co.x*=1+.055*ridge
        if v.co.y<0:v.co.y-=.006*ridge
        if .04<y<.075:v.co.x*=.94
    # Apply actual socket and crown aperture differences; dark recessed interior, no protruding eyes.
    for x in [-.041,.041]:
        cutter=oval('Socket_cutter',(x,.136,.074),(.032,.035,.044),'ink',r)
        mod=head.modifiers.new('Recessed_orbit','BOOLEAN');mod.operation='DIFFERENCE';mod.object=cutter
        bpy.context.view_layer.objects.active=head
        bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(cutter,do_unlink=True)
        oval('Socket_dark_depth',(x,.136,.045),(.026,.029,.004),'ink',r)
    cutter=bc.cylinder('Crown_aperture_cutter',.025,.025,.18,(0,.22,0),'ink',r,seg=32,bevel=0)
    mod=head.modifiers.new('Open_crown_for_stems','BOOLEAN');mod.operation='DIFFERENCE';mod.object=cutter;bpy.context.view_layer.objects.active=head;bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(cutter,do_unlink=True)
    oval('Crown_inner_depth',(0,.143,0),(.025,.002,.025),'soil',r)
    box('Flat_stable_jaw',(.112,.028,.086),(0,.014,.025),'bone',r,.012)
    for i in range(8):box('Individual_tooth',(.011,.026,.014),(-.044+i*.0125,.039,.080),'cream',r,.003)
    mesh('Recessed_nasal_cavity',[(-.011,.094,.085),(.011,.094,.085),(0,.115,.088)],[(0,1,2)],'ink',r,.002)
    line('Fine_crown_crack',[(.019,.20,.026),(.029,.185,.057),(.023,.17,.071)],.0007,'stone_dark',r)
    for i in range(12):
        a=i*math.tau/12;rr=.055+.035*(i%3)/2
        p=(math.sin(a)*rr,.205+.01*(i%3),math.cos(a)*rr)
        tip=(math.sin(a)*(rr+.025),p[1]-.014,math.cos(a)*(rr+.025))
        tube('Crown_leaf_petiole',[(0,.185,0),p,tip],.0015,'leaf_dark',r)
        leaf(r,tip,.055+.010*(i%3),.026,a,-.7 if i%2 else -.2,'leaf' if i%3 else 'grass',angle=.45)
    return r

def clock_new():
    r=fresh('BotanicalClock')
    bc.material('clock_green','#28755D');bc.material('clock_dial','#E2EDD8');bc.material('clock_mint','#91BFA1');bc.material('clock_dark','#193E33')
    for name,rad,depth,z,role in [('Rear_case',.329,.07,-.025,'clock_dark'),('Green_rim',.34,.058,0,'clock_green'),('Sage_dial',.307,.008,.033,'clock_dial')]:
        ob=bc.cylinder(name,rad,rad,depth,(0,0,z),role,r,seg=80,bevel=.003);ob.rotation_euler.x=math.pi/2
    front_ring(r,'Outer_mint_bead',.334,.334,.032,.003,'clock_mint');front_ring(r,'Inner_green_bead',.309,.309,.038,.002,'clock_green')
    for i in range(60):
        a=i*math.tau/60;dist=.287
        line('Minute_tick',[(math.sin(a)*dist,math.cos(a)*dist,.039),(math.sin(a)*(dist-.012),math.cos(a)*(dist-.012),.039)],.0012,'clock_dark',r)
    for n in range(1,13):
        a=n*math.tau/12;letters('Dial_number_'+str(n),str(n),(.25*math.sin(a),.25*math.cos(a),.041),.047,'clock_dark',r,'comicbd.ttf')
    motif(r,0,-.115,.041,.045,'leaf')
    for name,length,width,z,role in [('HourHand',.17,.016,.047,'clock_dark'),('MinuteHand',.235,.010,.053,'clock_dark'),('SecondHand',.25,.003,.060,'clock_green')]:
        g=bc.pivot(name,bc.G(0,0,z),r);g['articulated']=True
        mesh('Separate_clock_hand',[(-width,-.018,0),(width,-.018,0),(width*.55,length-.015,0),(0,length,0),(-width*.55,length-.015,0)],[(0,1,2,3,4)],role,g,.003)
    oval('Central_brass_pin',(0,0,.064),(.014,.014,.006),'gold',r)
    box('Battery_cover',(.12,.10,.006),(0,-.14,-.064),'gray',r,.006)
    front_loop('Rear_hanging_keyhole',0,.23,-.064,.009,.015,.003,'gold',r)
    return r

def sign_new(queue=False):
    r=fresh('QueueIndicator' if queue else 'OpenClosedSign');w,h=(1.30,.60) if queue else (.58,.38)
    if not queue:
        bc.material('open_green','#8EEB8B');bc.material('closed_red','#F23535')
    panel=r if queue else bc.pivot('TurnablePanel',bc.G(0,0,0),r)
    if not queue:panel['articulated']=True
    box('Solid_rounded_case',(w,h,.05 if not queue else .07),(0,0,0),'ink',panel,.025)
    # Recessed faces and connected molded frame; front +Z.
    for sd in ([1] if queue else [-1,1]):
        g=bc.pivot('SignFace' if sd>0 else 'SignBack',bc.G(0,0,sd*.026),panel)
        if sd<0:g.rotation_euler.z=math.pi
        for s in [-1,1]:
            box('Teal_horizontal_frame',(w,.025,.012),(0,s*(h/2-.0125),0),'teal',g,.008)
            box('Teal_vertical_frame',(.025,h-.025,.012),(s*(w/2-.0125),0,0),'teal',g,.008)
            line('Gold_frame_bead',[(s*(w/2-.03),-h/2+.03,.008),(s*(w/2-.03),h/2-.03,.008)],.002,'gold',g)
            line('Gold_frame_bead',[(-w/2+.03,s*(h/2-.03),.008),(w/2-.03,s*(h/2-.03),.008)],.002,'gold',g)
            for sy in [-1,1]:motif(g,s*(w/2-.045),sy*(h/2-.045),.010,.026,'cream')
        if queue:
            box('Number_display_recess',(.49,.44,.008),(-.33,0,.003),'violet_dark',g,.017)
            letters('Fixed_queue_title','EN FILE',(.23,.09,.014),.137,'pink',g,'arialbd.ttf')
            letters('Fixed_queue_subtitle','ATTENTE',(.23,-.095,.014),.108,'pink',g,'arialbd.ttf')
            anchor=bc.pivot('DigitsAnchor',bc.G(-.33,0,.016),g);anchor['articulated']=True
        else:
            anchor=bc.pivot('OpenTextAnchor' if sd>0 else 'ClosedTextAnchor',bc.G(0,0,.012),g);anchor['articulated']=True
            lettering=letters('Printed_open_text' if sd>0 else 'Printed_closed_text','OUVERT' if sd>0 else 'FERMÉ',(0,0,.012),.095,'open_green' if sd>0 else 'closed_red',g,'COOPBL.TTF')
            bpy.context.view_layer.update()
            if lettering.dimensions.x>0:lettering.scale*=.46/lettering.dimensions.x
    if queue:
        box('Rear_wall_bracket',(.40,.20,.006),(0,0,-.039),'gray',r,.005)
        tube('Cable_outlet',[(0,-.20,-.03),(0,-.36,-.03)],.006,'ink',r)
        oval('Status_light',(.664,.20,.0),(.015,.023,.015),'pink',r)
        oval('Side_button',(.663,-.10,0),(.012,.018,.013),'gold',r)
    else:
        chain=bc.pivot('SingleContinuousChain',bc.G(0,0,0),r)
        chain['articulated']=True
        for x in [-.18,.18]:
            front_loop('Suspension_eyelet',x,.205,0,.012,.017,.003,'gold',panel)
        # One connected chain runs left eyelet -> central door hook -> right eyelet.
        pts=[Vector((-.18,.225,0)),Vector((0,.435,0)),Vector((.18,.225,0))]
        for side in range(2):
            d=pts[side+1]-pts[side];angle=math.atan2(-d.x,d.y)
            for i in range(15):
                p=pts[side].lerp(pts[side+1],i/14)
                link=bc.pivot('Interlocked_chain_link',bc.G(*p),chain)
                front_loop('Chain_link',0,0,0,.006,.012,.0018,'gold',link)
                link.rotation_mode='QUATERNION'
                link.rotation_quaternion=Vector((0,0,1)).rotation_difference(bc.G(*d).normalized()) @ Quaternion(Vector((0,0,1)),math.pi/2 if i%2 else 0)
        front_loop('Single_door_hook',0,.444,-.004,.010,.016,.003,'gold',chain)
        oval('Glass_suction_mount',(0,.444,.070),(.019,.019,.004),'cold',chain)
        tube('Hook_to_glass_stem',[(0,.444,.068),(0,.444,.015),(0,.434,0)],.0025,'gold',chain)
    return r

def hanging_new():
    r=fresh('SimpleHangingPlant');g=bc.pivot('PotAndFoliage',bc.G(0,-.75,0),r)
    pot(g,.15,.24,False)
    bc.lathe('Cream_botanical_collar',[(.14,.18),(.153,.19),(.153,.24),(.147,.245)],'cream',g,seg=48,subsurf=0)
    for i in range(12):
        q=bc.pivot('Pot_leaf_relief',bc.G(0,0,0),g);q.rotation_euler.z=i*math.tau/12;motif(q,0,.21,.154,.024,'teal')
    rng=random.Random(73)
    for i in range(26):
        a=i*2.39996;rr=.03+.13*math.sqrt(i/25);p=(math.sin(a)*rr,.24+rng.random()*.07,math.cos(a)*rr)
        tube('Crown_leaf_stem',[(0,.20,0),p],.002,'leaf_dark',g);leaf(g,p,.07+rng.random()*.035,.035,a,-.7,'leaf' if i%3 else 'grass')
    for i in range(8):
        a=i*math.tau/8;length=.28+.04*(i%4)
        pts=[(0,.20,0),(.12*math.sin(a),.29,.12*math.cos(a)),(.18*math.sin(a),.12,.18*math.cos(a)),(.22*math.sin(a),-length,.22*math.cos(a))]
        tube('Main_trailing_stem',pts,.0028,'leaf_dark',g)
        for k in range(8):
            t=k/7;p=(math.sin(a)*(.15+.07*t),.18-(length+.18)*t,math.cos(a)*(.15+.07*t))
            for sd in [-1,1]:
                q=(p[0]+sd*.035*math.cos(a),p[1]-.015,p[2]-sd*.035*math.sin(a))
                tube('Forked_leaf_branch',[p,q],.0014,'leaf_dark',g)
                leaf(g,q,.05+rng.random()*.04,.025+rng.random()*.012,a+sd*.75+rng.uniform(-.4,.4),rng.uniform(-.6,.3),'grass' if k%3 else 'leaf',angle=sd*.4)
    for i in range(3):
        a=i*math.tau/3
        x=.15*math.sin(a);z=.15*math.cos(a)
        tube('Braided_suspension',[(0,-.04,0),(x,-.51,z),(x,-.68,z),(0,-.75,0)],.004,'twine',r)
        for y in [-.51,-.65]:oval('Cord_attachment_knot',(x,y,z),(.009,.011,.009),'twine',r)
    front_loop('Top_hanging_ring',0,-.015,0,.018,.024,.004,'gold',r)
    return r

SPECS=[('bunting_botanical',bunting_new),('shop_floor_botanical',floor_new),('shop_ceiling_botanical',ceiling_new),('entrance_door',lambda:door_new(False)),('service_door',lambda:door_new(True)),('pendant_pink',lambda:pendant_new(False)),('pendant_yellow',lambda:pendant_new(True))]+[('stock_vase_'+k,lambda k=k:vase_new(k)) for k in VASE_IDS]+[('shelf_flowered_skull',skull_new),('botanical_clock',clock_new),('botanical_open_sign',lambda:sign_new(False)),('botanical_queue_sign',lambda:sign_new(True)),('hanging_simple_botanical',hanging_new)]
selected=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
report=[]
for index,(name,build) in enumerate(SPECS):
    if selected and name not in selected:continue
    r=build();bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BLEND,name+'.blend'));path=os.path.join(OUT,name+'.glb');bc.export_glb(path,r)
    raw=open(path,'rb').read();n=struct.unpack_from('<I',raw,12)[0];doc=json.loads(raw[20:20+n]);tris=sum(doc['accessors'][p['indices']]['count']//3 for m in doc['meshes'] for p in m['primitives'])
    record=dict(number=54+index,asset=name,triangles=tris,metres=True);report.append(record);print('SHOP_ASSET_COMPLETE',json.dumps(record),flush=True)
if not selected:
    with open(os.path.join(OUT,'items_54_73.json'),'w') as f:json.dump(report,f,indent=2)
print('ITEMS_54_73_COMPLETE',len(report),flush=True)
