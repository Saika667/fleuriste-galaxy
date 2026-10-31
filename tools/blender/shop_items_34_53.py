"""Native metric meshes for shop sheets 34–53. Godot +Z is front, Y is up."""
import os, sys, math, json, struct, random
import bpy
from mathutils import Vector
sys.path.insert(0, os.path.dirname(__file__))
exec(open(os.path.join(os.path.dirname(__file__),'shop_items_14_33.py'),encoding='utf-8').read().split('\nSPECS=')[0],globals())

def begin(name):
    r=start(name)
    for role,color in {'steel':'#8CAEC7','steel_dark':'#607C99','steel_teal':'#78B2BA','walnut':'#795137','grass':'#8EBF69','leaf_dark':'#34724B','paper_yellow':'#F7E1A0','poster_red':'#E66F79','root':'#CEAD7D'}.items():bc.material(role,color)
    return r

def letters(name,body,pos,size,role,r,font='Inkfree.ttf'):
    cu=bpy.data.curves.new(name,'FONT');cu.body=body;cu.size=size;cu.align_x='CENTER';cu.align_y='CENTER';cu.extrude=.0002
    cu.font=bpy.data.fonts.load('C:/Windows/Fonts/'+font)
    ob=bpy.data.objects.new(name,cu);bpy.context.collection.objects.link(ob);ob.location=bc.G(*pos);ob.rotation_euler=(math.pi/2,0,0);cu.materials.append(bc._MATS[role]);bc._parent(ob,r)
    bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob;bpy.ops.object.convert(target='MESH');ob['no_outline']=True
    return ob

def tube(name,pts,rad,role,r):return bc.sweep(name,pts,[rad]*len(pts),role,r,seg=8,sub=3,extras={'no_outline':True})

def screw(r,p,rad=.005,role='gold'):
    oval('Brass_screw',p,(rad,rad,rad*.35),role,r)
    line('Screw_slot',[(p[0]-rad*.5,p[1],p[2]+rad*.36),(p[0]+rad*.5,p[1],p[2]+rad*.36)],rad*.09,'brown',r)

def leaf(r,p,length=.12,width=.045,yaw=0,tilt=0,role='leaf',split=False,angle=0):
    # Shaped, curved leaves with real silhouette notches; no intersecting ellipsoid proxies.
    shape=[(0,-.55),(-.30,-.27),(-.50,.02),(-.52,.27),(-.35,.43),(-.15,.40),(0,.20),(.15,.40),(.35,.43),(.52,.27),(.50,.02),(.30,-.27)]
    if split:
        shape=[(0,-.54),(-.22,-.42),(-.43,-.22),(-.12,-.10),(-.51,-.12),(-.60,.07),(-.18,.13),(-.57,.20),(-.51,.38),(-.18,.27),(-.34,.48),(-.10,.53),(0,.35),(.10,.53),(.34,.48),(.18,.27),(.51,.38),(.57,.20),(.18,.13),(.60,.07),(.51,-.12),(.12,-.10),(.43,-.22),(.22,-.42)]
    rounded=[]
    for i in range(len(shape)):
        p0,p1,p2,p3=[Vector(shape[k%len(shape)]) for k in [i-1,i,i+1,i+2]]
        for j in range(4):
            t=j/4;v=.5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t*t+(-p0+3*p1-3*p2+p3)*t*t*t);rounded.append(tuple(v))
    shape=rounded
    g=bc.pivot('Leaf_attachment',bc.G(0,0,0),r)
    verts=[(0,0,.006)]+[(x*width*1.5,y*length,0) for x,y in shape]
    ob=mesh('Split_monstera_leaf' if split else 'Broad_shaped_leaf',verts,[(0,i+1,(i+1)%len(shape)+1) for i in range(len(shape))],role,g,.0015)
    line('Leaf_midvein',[(0,-length*.48,.001),(0,0,.007),(0,length*.38,.001)],.0012 if length<.15 else .002,'grass',g)
    for side in [-1,1]:
        for k in range(3):line('Leaf_secondary_vein',[(0,-length*.28+k*length*.19,.006),(side*width*.48,-length*.20+k*length*.19,.002)],.00065,'grass',g)
    g.location=bc.G(*p);g.rotation_euler=(tilt,angle,yaw)
    return g

def plain_pot(r,radius=.13,h=.22,role='violet'):
    solid('Hollow_ceramic_pot',[(radius*.70,.015),(radius*.73,.028),(radius*.96,h-.035),(radius,h-.03),(radius,h)],role,r,seg=40)
    bc.lathe('Cream_pot_collar',[(radius*.96,h-.045),(radius+.002,h-.045),(radius+.002,h),(radius*.96,h)],'cream',r,seg=40,subsurf=0)
    ring('Teal_collar_inlay',radius+.003,h-.039,.003,'teal',r)
    bc.lathe('Saucer',[(0,0),(radius*.88,0),(radius*.93,.01),(radius*.92,.023),(radius*.83,.025),(radius*.80,.012),(0,.012)],'teal',r,seg=40,subsurf=0)
    bc.cylinder('Soil_insert',radius*.91,radius*.91,.015,(0,h-.022,0),'soil',r,seg=32,bevel=.002)

def poster(kind):
    r=begin('BotanicalPoster' if kind=='flower' else 'WarningPoster');w,h=(.61,.86) if kind=='flower' else (.46,.61)
    box('Wood_backing',(w,h,.024),(0,0,0),'walnut',r,.008)
    box('Flat_printed_background',(w-.055,h-.055,.003),(0,0,.016),'paper_yellow' if kind=='flower' else 'poster_red',r,.008)
    for s in [-1,1]:
        box('Teal_vertical_frame',(.026,h,.032),(s*(w/2-.013),0,.008),'teal',r,.006)
        box('Teal_horizontal_frame',(w,.026,.032),(0,s*(h/2-.013),.008),'teal',r,.006)
        box('Cream_inner_vertical',(.006,h-.046,.005),(s*(w/2-.028),0,.024),'cream',r,.002)
        box('Cream_inner_horizontal',(w-.046,.006,.005),(0,s*(h/2-.028),.024),'cream',r,.002)
        for sy in [-1,1]:
            if kind=='skull':box('Brass_corner',(.044,.044,.008),(s*(w/2-.022),sy*(h/2-.022),.027),'gold',r,.009)
            else:motif(r,s*(w/2-.032),sy*(h/2-.032),.026,.02)
            box('Rear_backing_clip',(.018,.032,.004),(s*(w/2-.04),sy*h*.30,-.015),'metal',r,.002)
        front_loop('Rear_triangle_hanger',s*w*.29,h*.33,-.022,.018,.022,.003,'gold',r)
        screw(r,(s*w*.29,h*.30,-.026))
    tube('Rear_hanging_wire',[(-w*.29,h*.33,-.028),(0,h*.24,-.032),(w*.29,h*.33,-.028)],.002,'ink',r)
    if kind=='flower':
        letters('Flat_title','COURS DE\nBOUQUET',(0,h*.29,.020),.065,'teal_dark',r)
        line('Flat_flower_stem',[(0,-h*.31,.020),(0,h*.04,.020)],.005,'leaf',r)
        for i in range(5):
            a=i*math.tau/5;oval('Flat_illustrated_petal',(math.sin(a)*.066,h*.02+math.cos(a)*.066,.020),(.046,.049,.0006),'pink',r)
        oval('Flat_flower_center',(0,h*.02,.022),(.039,.039,.0007),'yellow',r)
        for side in [-1,1]:
            tube('Flat_botanical_border',[(side*w*.31,-h*.33,.020),(side*w*.36,-h*.07,.020),(side*w*.31,h*.26,.020)],.0025,'leaf',r)
            for k in range(6):
                o=oval('Flat_border_leaf',(side*w*(.31+(.025 if k%2 else -.025)),-h*.26+k*h*.082,.021),(.014,.028,.0006),'leaf',r);o.rotation_euler.y=side*.5
    else:
        letters('Flat_warning','NE PAS\nNOURRIR',(0,h*.22,.020),.066,'cream',r,'georgiab.ttf')
        oval('Flat_skull_illustration',(0,-h*.10,.020),(.083,.077,.0006),'bone',r)
        box('Flat_skull_teeth',(.099,.036,.001),(0,-h*.207,.021),'bone',r,.007)
        for side in [-1,1]:oval('Flat_eye_socket',(side*.033,-h*.10,.022),(.019,.025,.0007),'ink',r)
        for x in [-.026,0,.026]:line('Flat_skull_tooth_line',[(x,-h*.22,.022),(x,-h*.192,.022)],.001,'walnut',r)
        motif(r,0,-h*.34,.021,.032)
    return r

BUCKETS=[('bucket_roses','steel',.40,.18,'ROSES'),('bucket_lilies','steel_dark',.44,.175,'LYS\nDE DEUIL'),('bucket_tulips','steel_teal',.38,.18,'TULIPES'),('bucket_poppies','steel_dark',.40,.18,'PAVOTS'),('bucket_daisies','steel_teal',.38,.175,'MARGUERITES'),('bucket_widow','stone_dark',.42,.18,'SPÉCIAL\nVEUVE')]

def bucket(k):
    name,role,h,rad,tag=BUCKETS[k];r=begin(name)
    solid('Open_metal_reservoir',[(rad*.69,.008),(rad*.73,.026),(rad*.93,h-.025),(rad,h)],role,r,seg=48)
    ring('Rolled_cream_lip',rad,h,.007,'cream' if k>0 else 'steel',r)
    ring('Reinforced_base',rad*.74,.018,.009,'cream' if k in [2,4] else role,r)
    for y in [.12,h-.10]:ring('Pressed_bucket_rib',rad*(.70+.30*y/h)+.002,y,.005,role,r)
    for side in [-1,1]:
        oval('Handle_rivet',(side*rad*.95,h-.07,0),(.011,.011,.012),'gold',r)
        if k in [1,3,4,5]:
            pts=[(side*(rad*.96+.014*math.sin(i*math.pi/20)),h-.073-.053*math.sin(i*math.pi/20),.045*math.cos(i*math.pi/20)) for i in range(41)]
            line('Side_ring_handle',pts,.004,'gold' if k in [4,5] else 'metal',r)
    if k in [0,2]:
        line('Fold_down_wire_handle',[(rad*math.cos(i*math.pi/40),h-.07-.12*math.sin(i*math.pi/40),rad*.87*math.sin(i*math.pi/40)) for i in range(41)],.004,'metal',r)
        bc.cylinder('Wood_handle_grip',.009,.009,.09,(0,h-.19,rad*.87),'wood_dark',r,seg=16,bevel=.003,rot=(0,math.pi/2,0))
    z=rad*.91;y=.20 if k!=2 else .25
    w=.235 if k in [3,4,5] else .18;hh=.075 if k not in [1,2,3] else .115
    box('Removable_price_plaque',(w,hh,.008),(0,y,z),'cream' if k!=1 else 'slate',r,.012)
    letters('Label_bold_species',tag,(0,y,z+.005),min(.040,(w-.024)/(max(len(t) for t in tag.split('\n'))*.70)),'ink' if k!=1 else 'cream',r,'arialbd.ttf')
    for x in [-w*.43,w*.43]:
        screw(r,(x,y+hh*.33,z+.006),.003)
        line('Price_tag_wire',[(x,y+hh/2,z),(x,y+hh/2+.025,z-.007)],.0016,'gold',r)
    if k in [1,2,4,5]:
        oval('Botanical_enamel_crest',(0,.10,rad*.80),(.026,.034,.003),'gold',r);motif(r,0,.10,rad*.80+.004,.025,'cream')
    return r

def wall_shelf(width):
    # Four / three supports retain identical dimensions, unlike stretching a longer model.
    r=begin('WallShelf_'+str(width));depth=.34
    box('Wood_shelf_plank',(width,.035,depth),(0,0,0),'wood',r,.009)
    box('Cream_front_lip',(width,.025,.018),(0,.003,depth/2),'cream',r,.006)
    box('Fine_brass_inlay',(width-.02,.003,.003),(0,-.008,depth/2+.010),'gold',r,.001)
    n=2 if width<2.5 else (4 if width>4 else 3)
    for i in range(n):
        x=-width/2+.15+i*(width-.30)/(n-1)
        box('Bracket_wall_plate',(.055,.235,.02),(x,-.12,-.151),'teal',r,.009)
        tube('Curved_botanical_bracket',[(x,-.22,-.135),(x,-.14,-.085),(x,-.08,.005),(x,-.035,.115)],.017,'teal',r)
        for y in [-.05,-.205]:screw(r,(x,y,-.134),.009)
        motif(r,x,-.10,-.124,.035)
    return r

def bigplant():
    r=begin('LargeMonstera');plain_pot(r,.215,.45)
    for i in range(20):
        a=i*2.39996;h=.76+(i%5)*.265;rad=.28+(i%3)*.085
        tip=(math.sin(a)*rad,h,math.cos(a)*rad)
        tube('Branching_monstera_stem',[(0,.39,0),(math.sin(a)*.10,h*.63,math.cos(a)*.10),tip],.008 if i<12 else .006,'leaf_dark',r)
        leaf(r,(tip[0],tip[1]+.13,tip[2]),.48 if i<12 else .34,.30 if i<12 else .23,a,-.28-(i%3)*.20,['leaf','grass','leaf_dark'][i%3],True,angle=(i%3-1)*.18)
    return r

def crate(content):
    r=begin('Crate_'+content);w=.60 if content=='seedlings' else .64;d=.45 if content=='seedlings' else .46;h=.30 if content=='seedlings' else .32
    dark=content=='skulls';woodrole='walnut' if dark else 'wood';corner='cream' if content in ['bulbs','skulls'] else 'teal'
    for i in range(5):box('Drainage_bottom_slat',((w-.04)/5-.006,.02,d-.03),(-w/2+.02+(i+.5)*(w-.04)/5,.015,0),woodrole,r,.002)
    for side in [-1,1]:
        for i in range(3):box('Front_rear_slat',(w,.075,.023),(0,.055+i*.10,side*(d/2-.012)),woodrole,r,.004)
        # Genuine handle aperture in upper side slat, constructed around the opening.
        x=side*(w/2-.013)
        for i in range(2):box('Side_lower_slat',(.026,.075,d),(x,.055+i*.10,0),woodrole,r,.004)
        for z in [-1,1]:box('Side_handle_cheek',(.026,.075,(d-.16)/2),(x,h-.065,z*(d/2-(d-.16)/4)),woodrole,r,.004)
        for y in [h-.093,h-.034]:box('Handle_top_bottom',(.026,.019,.16),(x,y,0),woodrole,r,.004)
        for sz in [-1,1]:
            box('Corner_upright',(.04,h,.04),(side*(w/2-.019),h/2,sz*(d/2-.019)),corner,r,.004)
            for y in [.045,h-.045]:screw(r,(side*(w/2-.019),y,sz*(d/2+.004)),.006)
    names={'flowers':'FLEURS','bulbs':'BULBES','skulls':'CRÂNES','seedlings':'JEUNES PLANTS'}
    box('Removable_inventory_label',(.25,.055,.009),(0,.16,d/2+.008),'teal' if content=='bulbs' else 'cream',r,.005)
    letters('Crate_handwriting',names[content],(0,.16,d/2+.014),.033 if content!='seedlings' else .027,'cream' if content=='bulbs' else 'ink',r)
    if content in ['skulls','bulbs']:
        box('Removable_straw_liner',(w-.075,.025,d-.075),(0,.10,0),'twine',r,.015)
        rng=random.Random(42)
        for i in range(70):
            x=rng.uniform(-w*.40,w*.40);z=rng.uniform(-d*.38,d*.38);line('Straw_fibres',[(x,.115,z),(x+.025,.12,z+.008)],.001,'root',r)
    if content=='bulbs':
        for i in range(8):
            x=-.225+(i%4)*.15;z=-.10+(i//4)*.20
            bc.lathe('Papery_bulb',[(0,.105),(.035,.108),(.051,.135),(.055,.175),(.033,.208),(.012,.235),(.006,.26),(0,.265)],'root' if i%2 else 'cream',r,loc=(x,0,z),seg=24,subsurf=0,mod=lambda a,t:(1+.04*math.cos(7*a),0))
            for k in range(4):
                a=k*math.tau/4;tube('Bulb_roots',[(x,.112,z),(x+.015*math.cos(a),.106,z+.015*math.sin(a))],.001,'twine',r)
            tube('Tiny_bulb_sprout',[(x,.25,z),(x+.005,.28,z)],.003,'leaf',r)
    elif content=='skulls':
        for i in range(3):
            x=-.19+i*.19;z=.025 if i%2 else -.02;y=.197
            oval('Resting_ivory_skull',(x,y,z),(.075,.077,.067),'bone',r)
            box('Rounded_skull_jaw',(.083,.035,.065),(x,y-.054,z+.025),'bone',r,.012)
            for side in [-1,1]:oval('Skull_eye_socket',(x+side*.028,y+.003,z+.058),(.019,.024,.008),'ink',r)
            mesh('Skull_nose',[(x-.008,y-.026,z+.066),(x+.008,y-.026,z+.066),(x,y-.013,z+.066)],[(0,1,2)],'ink',r)
            for dx in [-.02,0,.02]:line('Skull_tooth_division',[(x+dx,y-.071,z+.059),(x+dx,y-.055,z+.059)],.001,'brown',r)
    elif content in ['seedlings','flowers']:
        for i in range(8 if content=='seedlings' else 6):
            cols=4 if content=='seedlings' else 3;x=-(cols-1)*.07+(i%cols)*.14;z=-.10+(i//cols)*.20
            if content=='seedlings':
                box('Removable_seedling_cell',(.125,.075,.16),(x,.105,z),'slate',r,.008)
                box('Soil_cell_fill',(.113,.009,.148),(x,.145,z),'soil',r,.003)
                for side in [-1,1]:
                    tube('Seedling_petioles',[(x,.15,z),(x+side*.025,.205,z)],.002,'leaf',r)
                    leaf(r,(x+side*.027,.22,z),.065,.035,side*.3,-.15,'grass',angle=side*.4)
                leaf(r,(x,.245,z-.015),.055,.025,.3,-.4,'leaf')
            else:
                solid('Removable_water_cup',[(.045,.035),(.049,.05),(.057,.25)],'slate',r,seg=24)
                # Shift the cup to its cell while retaining independent removable geometry.
                bpy.context.scene.objects['Removable_water_cup' if i==0 else 'Removable_water_cup.%03d'%i].location+=bc.G(x,0,z)
    return r

def stand(k):
    r=begin('SteppedStand_'+str(k));w=.90
    for level in range(3):
        y=.30+level*.32;z=.19-level*.19
        box('Flat_display_tray',(w,.035,.22),(0,y,z),'wood' if k==1 else 'teal',r,.008)
        box('Cream_tray_edge',(w,.025,.015),(0,y+.002,z+.11),'cream',r,.006)
        for side in [-1,1]:screw(r,(side*.425,y,z+.118),.008)
    for side in [-1,1]:
        x=side*.433
        pts=[(x,.025,.29),(x,.30,.22),(x,.62,.035),(x,.94,-.17),(x,1.025,-.21)]
        tube('Swept_side_rail',pts,.028,'teal' if k==1 else 'wood_dark',r)
        box('Rear_leg',(.05,1.00,.05),(x,.51,-.27),'wood_dark',r,.006)
        for z in [-.27,.29]:box('Brass_foot_cap',(.057,.04,.06),(x,.025,z),'gold',r,.006)
        if k==3:
            # Open botanical ornament rather than a solid sideboard hiding the pots.
            tube('Leaf_cutout_rail',[(x,.11,.20),(x,.30,-.10),(x,.65,-.20)],.016,'wood',r)
            for j in range(2):
                line('Open_leaf_side_ornament',[(x,.23+j*.18,-.17),(x,.29+j*.18,-.02),(x,.38+j*.18,-.16),(x,.23+j*.18,-.17)],.009,'wood',r)
        else:motif(r,x,.34,.244,.045)
    if k==3:
        for side in [-1,1]:line('Rear_cross_brace',[(-.41,.12 if side<0 else .89,-.28),(.41,.89 if side<0 else .12,-.28)],.012,'wood_dark',r)
    else:box('Rear_stability_brace',(.85,.045,.025),(0,.18,-.27),'wood_dark',r,.004)
    return r

def flytrap():
    r=begin('CarnivorousPlant');plain_pot(r,.08,.15,'violet_dark')
    tube('Flexible_curved_stem',[(0,.13,0),(.018,.23,0),(-.012,.32,-.025),(0,.405,-.055)],.012,'leaf',r)
    for i in range(5):
        a=i*math.tau/5;leaf(r,(math.sin(a)*.045,.17,math.cos(a)*.045),.09,.045,a,-.65,'leaf')
    head=bc.pivot('head',bc.G(0,0,0),r)
    oval('Rear_mouth_throat',(0,0,-.02),(.032,.035,.014),'ink',head)
    for sign in [1,-1]:
        jaw=bc.pivot('jaw_up' if sign>0 else 'jaw_dn',bc.G(0,0,0),head)
        verts=[];faces=[];rings=9;seg=40
        for j in range(rings):
            t=j*math.pi/2/(rings-1)
            for i in range(seg):
                a=i*math.tau/seg;verts.append((math.sin(a)*.124*math.cos(t),sign*(.014+.050*math.sin(t)),.052+math.cos(a)*.104*math.cos(t)))
        for j in range(rings-1):
            for i in range(seg):
                q=(j*seg+i,j*seg+(i+1)%seg,(j+1)*seg+(i+1)%seg,(j+1)*seg+i);faces.append(q if sign>0 else tuple(reversed(q)))
        faces.append(tuple(range(seg-1,-1,-1)) if sign>0 else tuple(range(seg)))
        ob=mesh('Fleshy_upper_jaw' if sign>0 else 'Fleshy_lower_jaw',verts,faces,'ribbon' if sign>0 else 'coral',jaw)
        for f in ob.data.polygons:f.use_smooth=True
        oval('Dark_mouth_interior',(0,sign*.012,.052),(.116,.002,.097),'ink',jaw)
        # Upper and lower teeth alternate around the lip, rooted in their OWN jaw.
        count=7 if sign>0 else 6
        for i in range(count):
            a=-1.35+(i+(0 if sign>0 else .5))*2.7/6;x=.116*math.sin(a);z=.052+.098*math.cos(a)
            bc.cylinder('Triangular_cream_tooth',.009 if sign>0 else .001,.001 if sign>0 else .009,.027,(x,0,z),'cream',jaw,seg=3,bevel=.002)
        if sign>0:
            for side in [-1,1]:
                tube('Eye_stalk',[(side*.05,.047,.015),(side*.064,.094,.012)],.006,'leaf',jaw)
                oval('Eye_white',(side*.064,.104,.015),(.022,.023,.022),'white',jaw)
                oval('Eye_pupil',(side*.064,.107,.035),(.010,.011,.004),'ink',jaw)
    head.location=bc.G(0,.416,0)
    return r

def coffin():
    r=begin('CoffinPlanter');outline=[(-.60,-.22),(-.42,-.325),(.42,-.325),(.60,-.20),(.60,.20),(.42,.325),(-.42,.325),(-.60,.22)]
    # In plan the long axis is X; the open soil liner is genuinely below the rim.
    mesh('Coffin_floor',[(x,.045,z) for x,z in outline],[tuple(range(8))],'walnut',r,.025)
    mesh('Recessed_soil_insert',[(x*.94,.335,z*.88) for x,z in outline],[tuple(range(8))],'soil',r,.012)
    for i in range(8):
        a=Vector(outline[i]);b=Vector(outline[(i+1)%8]);mid=(a+b)/2;length=(b-a).length;angle=math.atan2(b.y-a.y,b.x-a.x)
        box('Coffin_side_panel',(length+.012,.31,.03),(mid.x,.21,mid.y),'walnut',r,.006,rot=(0,0,-angle))
        line('Cream_open_rim',[(a.x,.375,a.y),(b.x,.375,b.y)],.018,'cream',r)
        line('Brass_bottom_moulding',[(a.x,.075,a.y),(b.x,.075,b.y)],.008,'gold',r)
    for side in [-1,1]:
        panel(r,0,.225,side*.34,.72,.17,'teal',.012)
        if side>0:motif(r,0,.225,.351,.064)
        for x in [-.39,.39]:
            box('Handle_mount',(.055,.055,.018),(x,.235,side*.34),'gold',r,.006)
            front_loop('Brass_drop_handle',x,.205,side*.36,.036,.032,.006,'gold',r)
    for x in [-.50,.50]:
        for z in [-.20,.20]:box('Carved_foot',(.07,.055,.065),(x,.0275,z),'wood_dark',r,.008)
    return r

def bell(r,p,size=.026):
    x,y,z=p
    bc.lathe('Pink_hanging_bell',[(0,y+.025),(size*.3,y+.022),(size*.55,y+.008),(size,y-.016),(size*.90,y-.021),(size*.70,y-.012),(0,y+.015)],'pink',r,loc=(x,0,z),seg=16,subsurf=0,mod=lambda a,t:(1+.08*math.cos(5*a),0))
    oval('Bell_stamen',(x,y-.017,z),(.003,.008,.003),'yellow',r)

def hanging():
    r=begin('FloweredHangingPlant');g=bc.pivot('Potted_trailing_plant',bc.G(0,0,0),r);plain_pot(g,.11,.19,'cream')
    rng=random.Random(53)
    for i in range(32):
        a=i*2.39996;rr=.025+.10*math.sqrt(i/31);p=(math.sin(a)*rr,.225+(1-i/31)*.07,math.cos(a)*rr)
        tube('Crown_branch',[(0,.16,0),p],.002,'leaf_dark',g);leaf(g,p,.075,.036,a,-.5,'grass' if i%4==0 else 'leaf')
    for i in range(8):
        a=i*math.tau/8+.15;length=.24+.065*(i%4)
        pts=[(0,.16,0),(.10*math.sin(a),.23,.10*math.cos(a)),(.15*math.sin(a),.08,.15*math.cos(a)),(.18*math.sin(a),-length*.5,.18*math.cos(a)),(.21*math.sin(a),-length,.21*math.cos(a))]
        tube('Distinct_flowering_trail',pts,.0025,'leaf_dark',g)
        for j in range(8):
            t=j/7;p=(math.sin(a)*(.135+.075*t),.10-(length+.10)*t,math.cos(a)*(.135+.075*t))
            for s in [-1,1]:leaf(g,(p[0]+s*.018,p[1],p[2]+.01),.070-.015*t,.034,a+(rng.random()-.5)*1.4,-.10,'leaf' if j%3 else 'grass',angle=s*.4)
            if j%3==1:bell(g,(p[0]+.02,p[1]-.02,p[2]+.02),.018)
    g.location=bc.G(0,-.73,0)
    for i in range(3):
        a=i*math.tau/3+.3;x=.105*math.sin(a);z=.105*math.cos(a)
        tube('Macrame_suspension_cord',[(0,-.035,0),(x,-.53,z),(x,-.66,z),(x*.65,-.73,z*.65),(0,-.75,0)],.003,'twine',r)
        for y in [-.54,-.65]:oval('Macrame_knots',(x,y,z),(.008,.009,.008),'twine',r)
    front_loop('Top_hanging_ring',0,-.012,0,.017,.021,.004,'gold',r)
    return r

exec(open(os.path.join(os.path.dirname(__file__),'shop_items_34_53_revision.py'),encoding='utf-8').read(),globals())

SPECS=[('poster_flower',lambda:poster('flower'))]+[(row[0],lambda k=k:bucket(k)) for k,row in enumerate(BUCKETS[:4])]+[
 ('shelf_wide',lambda:wall_shelf(1.5)),('big_plant',bigplant),('crate_flowers',lambda:crate('flowers')),('crate_bulbs',lambda:crate('bulbs')),('crate_skulls',lambda:crate('skulls')),('crate_seedlings',lambda:crate('seedlings')),('stand_classic',lambda:stand(1)),('flytrap',flytrap),('poster_skull',lambda:poster('skull')),('stand_botanical',lambda:stand(3)),('bucket_daisies',lambda:bucket(4)),('bucket_widow',lambda:bucket(5)),('shelf_medium_wide',lambda:wall_shelf(2.0)),('coffin_planter',coffin),('hanging_flowered',hanging)]
selected=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
report=[]
for index,(name,build) in enumerate(SPECS):
    if selected and name not in selected:continue
    r=build();bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BLEND,name+'.blend'));path=os.path.join(OUT,name+'.glb');bc.export_glb(path,r)
    raw=open(path,'rb').read();n=struct.unpack_from('<I',raw,12)[0];doc=json.loads(raw[20:20+n]);tris=sum(doc['accessors'][p['indices']]['count']//3 for m in doc['meshes'] for p in m['primitives'])
    record=dict(number=34+index,asset=name,triangles=tris,metres=True);report.append(record);print('SHOP_ASSET_COMPLETE',json.dumps(record),flush=True)
if not selected:
    with open(os.path.join(OUT,'items_34_53.json'),'w') as f:json.dump(report,f,indent=2)
print('ITEMS_34_53_COMPLETE',len(report),flush=True)
