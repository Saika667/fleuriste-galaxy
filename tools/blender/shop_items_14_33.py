"""Shop concepts 14–33, native metric Blender meshes; +Z is the front in Godot."""
import os,sys,math,json,struct,random
import bpy,bmesh
from mathutils import Vector
sys.path.insert(0,os.path.dirname(__file__))
import bl_common as bc
# Reuse the established vessel/relief vocabulary without executing the previous batch.
ns={'__file__':__file__};exec(open(os.path.join(os.path.dirname(__file__),'shop_items_07_13.py'),encoding='utf-8').read().split('SPECS=')[0],ns)
box,line,ring,solid,text=[ns[k] for k in ['box','line','ring','solid_vase','text']]
OUT=os.path.join(bc.ROOT,'assets/models/shop');BLEND=os.path.join(bc.ROOT,'art/blender/shop')
PALETTE={'orange':'#E07A2F','wood':'#D9B37A','wood_dark':'#92623D','soil':'#543827','kraft':'#D2B28B','twine':'#C9A77A','lining':'#F6EED9','slime':'#B8F248','slate':'#3A4B42','bone':'#F4EBD7','copper':'#C57A6B','olive':'#858548','leaf_light':'#8CBF6A','stone':'#B7B1C7','stone_dark':'#79718B','metal':'#A9B7BA','white':'#FFFEED'}

def start(name):
    r=ns['start'](name)
    for k,v in PALETTE.items():bc.material(k,v)
    return r

def mesh(name,verts,faces,role,r,thick=0):
    me=bpy.data.meshes.new(name);me.from_pydata([tuple(bc.G(*v)) for v in verts],[],faces);me.update()
    ob=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(ob);ob.data.materials.append(bc._MATS[role]);bc._parent(ob,r)
    if thick:
        m=ob.modifiers.new('Thickness','SOLIDIFY');m.thickness=thick
    return ob

def oval(name,pos,scale,role,r):return bc.sphere(name,1,pos,role,r,scale=scale,seg=16,exact=True)

def front_loop(name,x,y,z,rx,ry,rad,role,r):
    return line(name,[(x+rx*math.cos(i*math.tau/40),y+ry*math.sin(i*math.tau/40),z) for i in range(41)],rad,role,r)

def motif(r,x,y,z,s=.07,role='gold'):
    line('Botanical_stem',[(x,y-s*.6,z),(x,y+s*.55,z)],s*.035,role,r)
    for side in [-1,1]:
        o=oval('Botanical_leaf',(x+side*s*.24,y,z),(s*.12,s*.30,s*.035),role,r);o.rotation_euler.y=side*.7
    oval('Botanical_tip',(x,y+s*.40,z),(s*.12,s*.24,s*.035),role,r)

def orange():
    r=start('OrangeVase')
    solid('Hollow_fluted_amber_body',[(.045,.003),(.050,.013),(.073,.031),(.088,.062),(.083,.095),(.060,.129),(.041,.145),(.044,.155),(.074,.185),(.075,.19)],'orange',r,mod=lambda a,t:(1+.035*math.cos(10*a),0))
    bc.lathe('Cream_flared_collar',[(.042,.145),(.047,.155),(.077,.185),(.077,.19),(.073,.19),(.070,.185),(.043,.158)],'cream',r,seg=48,subsurf=0)
    ring('Gold_neck',.043,.146,.002,'gold',r);ring('Ivory_foot',.048,.006,.005,'cream',r)
    oval('Gold_medallion',(0,.083,.085),(.023,.033,.004),'gold',r)
    oval('Teal_medallion',(0,.083,.089),(.019,.028,.002),'teal',r);motif(r,0,.081,.092,.028,'cream')
    return r

def panel(r,x,y,z,w,h,role='teal',depth=.035):
    box('Panel',(w,h,depth),(x,y,z),role,r,.009)
    for sx in [-1,1]:box('Panel_moulding',(.012,h-.02,.012),(x+sx*(w/2-.02),y,z+depth/2),'teal_light',r,.003)
    for sy in [-1,1]:box('Panel_moulding',(w-.03,.012,.012),(x,y+sy*(h/2-.02),z+depth/2),'teal_light',r,.003)

def display():
    r=start('AwningDisplay')
    box('Recessed_plinth',(1.98,.07,.93),(0,.035,0),'brown',r,.02)
    for x in [-.95,.95]:
        box('Side_panel',(.06,.51,.90),(x,.31,0),'teal',r,.025)
        for z in [-.435,.435]:
            bc.lathe('Cream_support_post',[(.026,.08),(.034,.10),(.026,.15),(.026,1.05),(.038,1.07),(.03,1.14)],'cream',r,loc=(x,0,z),seg=20,subsurf=0)
            for y in [.12,.54,.60,1.06]:bc.cylinder('Brass_post_ring',.035,.035,.016,(x,y,z),'gold',r,seg=20,bevel=.003)
            bc.sphere('Post_finial',.035,(x,1.126,z),'gold',r,seg=16)
    box('Closed_rear',(1.85,.64,.045),(0,.39,-.43),'teal',r,.016)
    for y,depth,z in [(.29,.88,0),(.73,.47,-.20)]:
        box('Wood_display_shelf',(1.85,.035,depth),(0,y,z),'wood',r,.012)
        box('Cream_shelf_lip',(1.86,.025,.022),(0,y,z+depth/2),'cream',r,.006)
    panel(r,0,.17,.446,1.82,.20)
    oval('Medallion',(0,.17,.475),(.065,.077,.008),'gold',r);motif(r,0,.17,.486,.07,'cream')
    for i in range(8):
        x=-.84+i*.24;role='pink' if i%2==0 else 'cream'
        # Roof slopes gently forward, with a connected scalloped cloth front.
        mesh('Canvas_stripe',[(x-.12,1.105,-.47),(x+.12,1.105,-.47),(x+.12,1.06,.47),(x-.12,1.06,.47)],[(0,1,2,3)],role,r,.008)
        verts=[(x-.12,1.06,.477),(x+.12,1.06,.477)]+[(x+.12*math.cos(t*math.pi/12),1.015-.045*math.sin(t*math.pi/12),.477) for t in range(13)]
        mesh('Scalloped_valance',verts,[tuple(range(len(verts)))],role,r,.006)
        line('Valance_gold_hem',verts[2:],.004,'gold',r)
    for ob in r.children_recursive:
        if ob.type!='MESH':continue
        if any(tag in ob.name for tag in ['Canvas_stripe','Scalloped_valance','Valance_gold_hem','Post_finial']): ob.location.z+=.48
        elif ob.name.startswith('Cream_support_post'):
            for v in ob.data.vertices:
                if v.co.z>.60: v.co.z+=.48
        elif ob.name.startswith('Brass_post_ring') and ob.location.z>1: ob.location.z+=.48
    return r

def pot(r,radius=.29,h=.44,band=True):
    solid('Terracotta_open_pot',[(radius*.69,.025),(radius*.72,.045),(radius*.91,h-.055),(radius,h-.05),(radius,h-.008),(radius*.93,h)],'clay',r)
    bc.lathe('Separate_saucer',[(0,0),(radius*.78,0),(radius*.84,.008),(radius*.84,.027),(radius*.79,.031),(radius*.75,.013),(0,.013)],'clay',r,seg=40,subsurf=0)
    bc.cylinder('Removable_soil',radius*.87,radius*.84,.02,(0,h-.025,0),'soil',r,seg=40,bevel=.003)
    if band:
        bc.lathe('Cream_botanical_band',[(radius*.88,h-.115),(radius*.94,h-.075),(radius*.94+.003,h-.075),(radius*.88+.003,h-.115)],'cream',r,seg=40,subsurf=0)
    return r

def import_flower(r,kind,base,top,index=0):
    before=set(bpy.data.objects);bpy.ops.import_scene.gltf(filepath=os.path.join(bc.ROOT,'assets/models/flowers',kind+'_toon.glb'))
    objects=set(bpy.data.objects)-before;g=bc.pivot('Removable_'+kind+'_'+str(index),bc.G(0,0,0),r)
    for ob in objects:
        # Round-tripping imported inverted outline shells changes their culling. Strip those
        # shells, keep the original colored petal geometry, use the game's fine overlay.
        if ob.type=='MESH':
            slots={i for i,m in enumerate(ob.data.materials) if m and m.name.startswith('OUTLINE')}
            if slots:
                bm=bmesh.new();bm.from_mesh(ob.data)
                bmesh.ops.delete(bm,geom=[f for f in bm.faces if f.material_index in slots],context='FACES')
                bm.to_mesh(ob.data);bm.free();ob.data.update()
        if ob.parent not in objects:bc._parent(ob,g)
    d=Vector(top)-Vector(base);g.location=bc.G(*base);g.rotation_mode='QUATERNION';g.rotation_quaternion=Vector((0,0,1)).rotation_difference(bc.G(*d).normalized());g.scale=(d.length/.445,)*3

def rose_pot():
    r=start('LargeRosePlanter');pot(r)
    for i in range(12):
        a=math.tau*i/12
        line('Pot_broad_flute',[(math.sin(a)*.211,.06,math.cos(a)*.211),(math.sin(a)*.25,.29,math.cos(a)*.25)],.007,'orange',r)
    for i in range(3):
        a=i*math.tau/3;import_flower(r,'rose',(math.cos(a)*.035,.405,math.sin(a)*.035),(math.cos(a)*.13,1.07+.04*(i%2),math.sin(a)*.13),i)
    return r

def rug():
    r=start('FloralRug')
    for name,size,y,role in [('Non_slip_backing',1.92,.003,'gray'),('Bound_pink_edge',1.92,.006,'ribbon'),('Teal_border',1.83,.008,'teal'),('Cream_border',1.70,.009,'cream'),('Pink_field',1.56,.010,'pink')]:
        box(name,(size,.003,size),(0,y,0),role,r,.025)
    for i in range(6):
        a=i*math.tau/6;o=oval('Flat_woven_daisy_petal',(math.sin(a)*.265,.013,math.cos(a)*.265),(.145,.0007,.235),'cream',r);o.rotation_euler.z=a
    bc.cylinder('Flat_yellow_centre',.165,.165,.0015,(0,.014,0),'yellow',r,seg=40,bevel=0)
    for sx in [-1,1]:
        for sz in [-1,1]:
            for k in range(2):
                o=oval('Corner_leaf',(sx*(.57+k*.075),.012,sz*(.65-k*.09)),(.065,.0007,.11),'teal_light',r);o.rotation_euler.z=sx*sz*.6
    for i in range(40):
        t=-.9+i*1.8/39
        for s in [-1,1]:
            line('Edge_binding_stitch',[(t,.009,s*.94),(t,.011,s*.956)],.0008,'pink',r)
            line('Edge_binding_stitch',[(s*.94,.009,t),(s*.956,.011,t)],.0008,'pink',r)
    return r

def wrap(kind):
    r=start('Bouquet_'+kind)
    if kind!='none':
        outer={'silk':'pink','paper':'kraft','black':'ink'}[kind]
        # Three overlapping double-sided thin sheets; top is open, bottom has a stem aperture.
        for k in range(3):
            phase=k*math.tau/3;cols=25;verts=[]
            for j in range(5):
                t=j/4
                for i in range(cols):
                    u=i/(cols-1);a=phase+(u-.5)*2.55
                    radius=.023+.13*t**1.3+.020*math.sin(u*math.tau)*t*t
                    y=.105+.25*t+(abs(u-.5)*.11+.045*math.sin(u*math.tau))*t**3
                    verts.append((math.sin(a)*radius,y,math.cos(a)*radius))
            faces=[(j*cols+i,j*cols+i+1,(j+1)*cols+i+1,(j+1)*cols+i) for j in range(4) for i in range(cols-1)]
            ob=mesh('Open_folded_'+kind+'_sheet',verts,faces,outer,r,.0014)
            ob.data.materials.append(bc._MATS['lining']);ob.modifiers['Thickness'].material_offset=1
            if kind!='paper':line('Fine_gold_hem',verts[-cols:],.0009,'gold',r)
            # Fold the upper edge outward, revealing the lining and a broad diagonal lapel.
            flap=verts[-cols:]+[(x*1.10,y-.025,z*1.10) for x,y,z in verts[-cols:]]
            mesh('Visible_cream_folded_lapel',flap,[(i,i+1,i+1+cols,i+cols) for i in range(cols-1)],'lining',r,.001)
            # Short flared lower skirt, still open around cut stems.
            lower=[(math.sin(phase+(u/16-.5)*2.55)*rad,yy,math.cos(phase+(u/16-.5)*2.55)*rad) for rad,yy in [(.023,.105),(.044,.035)] for u in range(17)]
            mesh('Folded_lower_skirt',lower,[(i,i+1,i+18,i+17) for i in range(16)],outer,r,.0013)
        front=[(-.012,.115,.038),(-.122,.29,.095),(-.09,.381,.119),(.083,.274,.120),(.028,.16,.060)]
        mesh('Overlapping_diagonal_front_flap',front,[(0,1,2,3,4)],outer,r,.0015)
        line('Diagonal_fold_seam',[front[2],front[3],front[4],front[0]],.001,'twine' if kind=='paper' else 'gold',r)
    role='twine' if kind in ['paper','none'] else 'ribbon'
    for y in ([] if kind=='none' else [.103,.11,.117]):ring('Binding',.024,y,.0015 if kind in ['paper','none'] else .003,role,r,seg=32)
    if kind=='none':
        for i in range(3):ring('Natural_raffia_binding',.0185,.105+i*.003,.0015,'twine',r,seg=32)
        for side in [-1,1]:
            front_loop('Raffia_loose_bow',side*.013,.111,.021,.014,.006,.0016,'twine',r)
            line('Raffia_hanging_end',[(side*.006,.108,.024),(side*.014,.090,.025),(side*.021,.074,.029)],.0015,'twine',r)
        oval('Raffia_central_knot',(0,.111,.022),(.005,.004,.003),'twine',r)
        return r
    for s in [-1,1]:
        front_loop('Bow_hollow_loop',s*.020,.111,.031,.020,.009,.0015 if kind=='paper' else .004,role,r)
        mesh('Downward_notched_ribbon',[(s*.007,.108,.034),(s*.019,.107,.035),(s*.035,.046,.043),(s*.023,.052,.044),(s*.017,.041,.043)],[(0,1,2,3,4)],role,r,.001)
    oval('Bow_knot',(0,.109,.034),(.009,.007,.004),role,r)
    return r

def shelf(width=5.6):
    r=start('BotanicalWallShelf')
    box('Warm_wood_shelf',(width,.035,.30),(0,0,0),'wood',r,.014)
    box('Cream_front_inlay',(width-.05,.007,.006),(0,0,.151),'cream',r,.002)
    box('Rear_wall_cleat',(width-.08,.050,.025),(0,-.035,-.126),'wood_dark',r,.005)
    for x in ([-width/2+.15,width/2-.15] if width<3 else [-width/2+.15,-width/6,width/6,width/2-.15]):
        box('Brass_wall_plate',(.055,.195,.012),(x,-.103,-.139),'gold',r,.009)
        for y in [-.025,-.18]:oval('Mounting_screw',(x,y,-.13),(.007,.007,.002),'ink',r)
        line('Attached_bracket',[(x,-.018,-.12),(x,-.018,.125),(x,-.05,.125),(x,-.105,.06),(x,-.185,-.12)],.012,'teal',r)
        line('Botanical_scroll',[(x,-.16,-.105),(x,-.12,-.05),(x,-.07,-.01),(x,-.06,-.045),(x,-.085,-.065)],.009,'teal',r)
    return r

def ivy_leaf(r,p,size,a=0,role='leaf'):
    # Lobed leaf silhouette, raised centre fold; actual broad leaf rather than ellipsoid blobs.
    shape=[(0,-.65),(-.34,-.28),(-.62,-.20),(-.43,.05),(-.55,.43),(-.2,.30),(0,.65),(.2,.30),(.55,.43),(.43,.05),(.62,-.2),(.34,-.28)]
    vs=[(0,0,.009)]+[(x*size,y*size,0) for x,y in shape]
    verts=[(p[0]+x*math.cos(a)-y*math.sin(a),p[1]+x*math.sin(a)+y*math.cos(a),p[2]+z) for x,y,z in vs]
    mesh('Lobed_ivy_leaf',verts,[(0,i+1,(i+1)%len(shape)+1) for i in range(len(shape))],role,r,.0007)
    line('Leaf_midvein',[(p[0]+math.sin(a)*size*.5,p[1]-math.cos(a)*size*.5,p[2]+.002),p,(p[0]-math.sin(a)*size*.5,p[1]+math.cos(a)*size*.5,p[2]+.003)],.0008,'leaf_light',r)

def ivy():
    r=start('TrailingIvy');pot(r,.115,.20,False)
    bc.lathe('Ivory_collar',[(.104,.15),(.112,.18),(.115,.18),(.107,.15)],'cream',r,seg=40,subsurf=0);ring('Teal_band',.110,.168,.006,'teal',r)
    for i in range(9):
        a=i*math.tau/9;length=.44+.14*(i%3)/2
        pts=[(math.sin(a)*.025,.20,math.cos(a)*.025),(math.sin(a)*.105,.26,math.cos(a)*.105),(math.sin(a)*.15,.17,math.cos(a)*.15),(math.sin(a)*.18,.04,math.cos(a)*.18),(math.sin(a)*.19,.20-length,math.cos(a)*.19)]
        line('Curved_branching_vine',pts,.002,'leaf',r)
        for j in range(7):
            t=j/6;idx=min(3,int(t*4));v=Vector(pts[idx]).lerp(Vector(pts[idx+1]),min(1,t*4-idx))
            for s in [-1,1]:
                p=(v.x+s*.025,v.y+.005,v.z+.009)
                line('Short_petioles',[tuple(v),p],.0011,'leaf',r);ivy_leaf(r,p,.052-.015*t,s*.55+a*.2,'leaf_light' if (i+j)%3==0 else 'leaf')
    return r

def jar(kind):
    r=start('Apothecary_'+kind)
    solid('Hollow_jar_glass',[(.059,.002),(.071,.008),(.074,.02),(.074,.195),(.065,.21),(.063,.223)],'glass',r)
    for yy in [.215,.221]:ring('Glass_thread',.064,yy,.002,'glass',r)
    lid={'eyes':'teal','bulbs':'olive','slime':'teal_dark','teeth':'copper','seeds':'olive'}[kind]
    bc.cylinder('Separate_screw_lid',.075,.075,.021,(0,.229,0),lid,r,seg=48,bevel=.003)
    for i in range(40):
        a=i*math.tau/40;line('Lid_grip_ridge',[(math.sin(a)*.075,.222,math.cos(a)*.075),(math.sin(a)*.075,.237,math.cos(a)*.075)],.0009,lid,r)
    box('Cream_paper_label',(.090,.059,.002),(0,.125,.074),'cream',r,.006)
    title={'eyes':'YEUX','bulbs':'BULBES','slime':'GEL FLUO','teeth':'DENTS','seeds':'GRAINES'}[kind]
    text('Label_'+title,title,(0,.126,.076),.016 if len(title)>5 else .021,'brown',r)
    for y in [.101,.149]:line('Label_gold_rule',[(-.037,y,.076),(.037,y,.076)],.0006,'gold',r)
    rng=random.Random(1400)
    if kind=='eyes':
        for i in range(4):
            p=(math.sin(i*2.2)*.029,.045+i*.039,math.cos(i*2.2)*.027)
            oval('Floating_cartoon_eye',p,(.026,.026,.026),'white',r)
            oval('Large_dark_pupil',(p[0],p[1],p[2]+.023),(.010,.012,.004),'ink',r)
        bc.cylinder('Pale_liquid',.067,.067,.185,(0,.104,0),'cold',r,seg=32,bevel=.002)
    elif kind=='slime':
        bc.lathe('Continuous_fluorescent_gel',[(0,.01),(.06,.01),(.068,.02),(.068,.174),(.059,.183),(.03,.185),(0,.184)],'slime',r,seg=40,subsurf=0,mod=lambda a,t:(1+.012*math.sin(5*a+t*10),0))
        for i in range(10):
            a=i*2.1;oval('Trapped_bubble',(math.sin(a)*.045,.025+i*.016,math.cos(a)*.045),(.005,.006,.005),'cream',r)
    elif kind=='bulbs':
        for i in range(5):
            p=(math.sin(i*2.4)*.029,.040+(i//2)*.059,math.cos(i*2.4)*.029)
            g=bc.pivot('Individual_planting_bulb',bc.G(*p),r)
            bc.lathe('Tapered_bulb',[(0,-.023),(.022,-.02),(.029,0),(.024,.024),(.009,.040),(.003,.051),(0,.052)],'wood',g,seg=20,subsurf=0,loc=p,mod=lambda a,t:(1+.04*math.cos(6*a),0))
            for k in range(5):
                a=k*math.tau/5;line('Dry_roots',[(p[0],p[1]-.02,p[2]),(p[0]+math.sin(a)*.012,p[1]-.029,p[2]+math.cos(a)*.012)],.0008,'brown',r)
    elif kind=='teeth':
        for i in range(8):
            p=(math.sin(i*2.4)*.039,.025+(i//3)*.027,math.cos(i*2.4)*.036)
            for s in [-1,1]:
                oval('Molar_root',(p[0]+s*.006,p[1]-.01,p[2]),(.005,.013,.005),'bone',r)
                for z in [-.005,.005]:oval('Molar_crown_cusp',(p[0]+s*.005,p[1]+.006,p[2]+z),(.008,.008,.007),'bone',r)
    else:
        oval('Seed_pile_core',(0,.018,0),(.062,.018,.062),'wood',r)
        for i in range(180):
            a=rng.random()*math.tau;ra=.058*math.sqrt(rng.random());p=(math.sin(a)*ra,.020+.031*math.sqrt(max(0,1-(ra/.065)**2))+rng.random()*.004,math.cos(a)*ra)
            o=oval('Individual_seed',p,(.006,.0035,.009),'wood' if i%4 else 'olive',r);o.rotation_euler=(rng.random(),rng.random(),rng.random())
    return r

def cactus():
    r=start('PottedCactus');pot(r,.14,.20)
    bc.lathe('Ribbed_cactus_trunk',[(0,.18),(.055,.19),(.078,.24),(.078,.47),(.066,.53),(.039,.56),(0,.566)],'leaf',r,seg=48,subsurf=0,mod=lambda a,t:(1+.055*math.cos(9*a),0))
    bc.sweep('Attached_side_arm',[(.046,.31,0),(.11,.33,0),(.13,.40,0),(.13,.46,0)],[.036,.038,.034,.012],'leaf',r,seg=24,sub=2)
    for i in range(9):
        a=i*math.tau/9
        for y in [.27,.36,.45,.51]:
            p=Vector((math.sin(a)*.079,y,math.cos(a)*.079))
            oval('Cream_areole',tuple(p),(.006,.006,.006),'cream',r)
            for s in [-1,1]:line('Chunky_spines',[tuple(p),tuple(p+Vector((math.sin(a)*.014,s*.014,math.cos(a)*.014)))],.0015,'cream',r)
    # Short crown blossom: full-sized petals directly attached, no miniature long-stem flower.
    for i in range(6):
        a=i*math.tau/6
        ob=oval('Cactus_crown_petal',(math.sin(a)*.023,.589,math.cos(a)*.023),(.019,.027,.010),'coral',r)
        ob.rotation_euler.z=-a
    oval('Cactus_flower_centre',(0,.604,0),(.013,.009,.013),'yellow',r)
    return r

def skull():
    r=start('SkullRosePlanter');pot(r,.12,.175)
    # True shallow eye recesses through boolean difference, dark interiors behind them.
    existing=set(bpy.data.objects)
    head=oval('Ivory_skull_bulb',(0,.265,0),(.094,.095,.081),'bone',r)
    for x in [-.036,.036]:
        cutter=oval('Socket_cutter',(x,.274,.070),(.027,.031,.022),'ink',r)
        bpy.context.view_layer.objects.active=head;md=head.modifiers.new('Recessed_eye_socket','BOOLEAN');md.operation='DIFFERENCE';md.object=cutter
        bpy.ops.object.modifier_apply(modifier=md.name);bpy.data.objects.remove(cutter,do_unlink=True)
        oval('Socket_dark_interior',(x,.274,.060),(.023,.027,.010),'ink',r)
    for x in [-.036,-.012,.012,.036]:box('Skull_rounded_tooth',(.024,.028,.034),(x,.197,.060),'bone',r,.009)
    mesh('Triangular_nose',[(-.011,.239,.081),(.011,.239,.081),(0,.257,.083)],[(0,1,2)],'ink',r,.001)
    import_flower(r,'rose',(0,.337,0),(0,.620,0))
    for ob in set(bpy.data.objects)-existing:
        if ob.parent==r: ob.location.z-=.070
    return r

def pegboard():
    r=start('FloristPegboard')
    box('Perforated_wood_panel',(2.6,.43,.025),(0,0,0),'wood',r,.012)
    for x in [-1.27,1.27]:box('Teal_vertical_frame',(.055,.43,.044),(x,0,0),'teal',r,.009)
    for y in [-.198,.198]:box('Ivory_horizontal_frame',(2.6,.035,.045),(0,y,0),'cream',r,.009)
    for x in [-1.27,1.27]:
        for y in [-.192,.192]:box('Brass_corner',(.06,.055,.049),(x,y,.002),'gold',r,.009)
    for i in range(25):
        for j in range(3):oval('Recessed_peg_hole',(-1.19+i*.099,-.13+j*.13,.014),(.006,.006,.001),'brown',r)
    for x in [-.90,-.45,0,.45,.90]:
        line('Removable_hook',[(x,.13,.018),(x,.13,.06),(x,.15,.06)],.004,'gold',r)
    # Scissors: hollow handles + distinct tapered blades + central pivot.
    for s in [-1,1]:
        front_loop('Pink_finger_loop',-.90+s*.025,-.103,.052,.020,.035,.006,'ribbon',r)
        line('Scissors_neck',[(-.90+s*.023,-.072,.052),(-.90,0,.052)],.007,'metal',r)
        mesh('Crossed_tapered_blade',[(-.90-s*.009,-.01,.052+s*.002),(-.90+s*.060,.152,.052+s*.002),(-.90+s*.018,.135,.052+s*.002),(-.90+s*.009,.01,.052+s*.002)],[(0,1,2,3)],'metal',r,.004)
    oval('Scissors_pivot',(-.9,0,.059),(.009,.009,.004),'gold',r)
    # Watering can, curved carry handle, spout and rose.
    bc.cylinder('Watering_can_body',.071,.062,.125,(-.47,-.045,.08),'teal',r,seg=24,bevel=.012)
    front_loop('Can_handle',-.47,.045,.08,.075,.045,.008,'gold',r)
    line('Can_spout',[(-.405,-.055,.08),(-.34,-.01,.08),(-.30,.06,.08)],.014,'teal',r)
    oval('Can_spout_rose',(-.30,.062,.08),(.025,.022,.015),'teal_light',r)
    for i in range(6):a=i*math.tau/6;oval('Rose_holes',(-.30+math.cos(a)*.015,.062+math.sin(a)*.012,.094),(.002,.002,.001),'ink',r)
    box('Trowel_wood_handle',(.035,.14,.027),(0,.07,.055),'brown',r,.012)
    mesh('Trowel_blade',[(-.048,.0,.06),(.048,.0,.06),(.041,-.09,.07),(0,-.145,.09),(-.041,-.09,.07)],[(0,1,2,3,4)],'metal',r,.008)
    box('Knife_sheath',(.07,.19,.034),(.45,-.04,.05),'ribbon',r,.012);box('Knife_handle',(.038,.10,.028),(.45,.10,.05),'ink',r,.009)
    solid('Spray_bottle',[(.043,-.15),(.05,-.14),(.048,.035),(.022,.064),(.020,.10)],'pink',r,seg=24)
    # Move only the spray bottle geometry (lathe has baked origin).
    ob=bpy.context.scene.objects.get('Spray_bottle');ob.location+=bc.G(.9,0,.065)
    box('Spray_trigger_head',(.105,.033,.041),(.91,.117,.065),'cream',r,.009)
    line('Spray_trigger',[(.94,.10,.07),(.925,.069,.07)],.007,'pink',r)
    for x in [-.8,.8]:box('Rear_wall_standoff',(.055,.22,.035),(x,0,-.025),'metal',r,.005)
    return r

def chalkboard():
    r=start('ChalkMenuBoard')
    box('Back_wood_panel',(1.10,.95,.028),(0,0,0),'brown',r,.008)
    box('Sage_slate',(.99,.84,.014),(0,0,.020),'slate',r,.004)
    for x in [-.526,.526]:box('Wood_side_frame',(.048,.95,.042),(x,0,.006),'wood_dark',r,.006)
    for y in [-.451,.451]:box('Wood_cross_frame',(1.10,.048,.042),(0,y,.006),'wood_dark',r,.006)
    for x in [-.496,.496]:box('Cream_bevel',(.009,.85,.008),(x,0,.031),'cream',r,.003)
    for y in [-.422,.422]:box('Cream_bevel',(1,.009,.008),(0,y,.031),'cream',r,.003)
    for i,(body,y,sz) in enumerate([('MENU DU JOUR',.28,.082),('Roses 2 €',.10,.07),('Lys 3 €',-.035,.07),('Tulipes -50 %',-.17,.07)]):text('Chalk_letters_'+str(i),body,(0,y,.031),sz,'cream',r)
    line('Chalk_underline',[(-.30,.20,.032),(.30,.20,.032)],.002,'cream',r)
    for s in [-1,1]:
        line('Chalk_botanical_stem',[(s*.42,-.32,.032),(s*.45,0,.032),(s*.41,.33,.032)],.002,'sage',r)
        for j in range(4):oval('Chalk_leaf',(s*(.42+(.017 if j%2 else -.017)),-.26+j*.15,.033),(.026,.010,.001),'sage',r)
        motif(r,s*.478,.405,.033,.027)
        front_loop('Rear_hanging_fitting',s*.35,.35,-.022,.015,.018,.003,'gold',r)
    box('Chalk_ledge',(1.03,.025,.055),(0,-.437,.033),'wood_dark',r,.006)
    box('Felt_eraser',(.12,.037,.025),(.30,-.405,.047),'gray',r,.006)
    box('Ivory_chalk',(.085,.012,.012),(.16,-.412,.052),'cream',r,.004)
    return r

def rip_sign():
    r=start('RipPromotionSign')
    outline=[(-.25,0),(.25,0),(.25,.43)]+[(.25*math.cos(i*math.pi/24),.43+.22*math.sin(i*math.pi/24)) for i in range(25)]
    verts=[(x,y,z) for z in [-.0175,.0175] for x,y in outline];n=len(outline)
    faces=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    ob=mesh('Beveled_wood_plaque',verts,faces,'stone',r);md=ob.modifiers.new('Rounded_plaque_edges','BEVEL');md.width=.008;md.segments=3
    for x in [-.17,.17]:
        front_loop('Brass_eyelet',x,.58,.025,.021,.026,.005,'gold',r)
        line('Suspension_cord',[(x,.58,.025),(x,.65,.025),(x,1.10,.025)],.004,'ink',r)
    text('RIP','RIP',(0,.37,.020),.12,'ink',r)
    text('Roses_hier',"Roses d’hier",(0,.232,.020),.057,'ink',r);text('Discount','-50 %',(0,.11,.020),.09,'ink',r)
    for y in [.08,.50]:box('Rear_wood_brace',(.44,.05,.018),(0,y,-.027),'stone_dark',r,.003)
    line('Wilted_rose_stem',[(-.075,.49,.023),(0,.53,.023),(.06,.49,.023)],.003,'leaf',r)
    for i in range(5):a=i*math.tau/5;oval('Wilted_rose_petal',(math.cos(a)*.022,.535+math.sin(a)*.018,.026),(.018,.016,.003),'ribbon',r)
    return r

exec(open(os.path.join(os.path.dirname(__file__),'shop_revision_details.py'),encoding='utf-8').read(),globals())

SPECS=[('vase_orange',orange),('awning_display',display),('rose_planter',rose_pot),('floral_rug',rug),('bouquet_silk',lambda:wrap('silk')),('bouquet_paper',lambda:wrap('paper')),('bouquet_none',lambda:wrap('none')),('bouquet_black',lambda:wrap('black')),('botanical_wall_shelf',shelf),('pot_ivy',ivy),('jar_eyes',lambda:jar('eyes')),('jar_bulbs',lambda:jar('bulbs')),('pot_cactus',cactus),('jar_slime',lambda:jar('slime')),('pot_skull',skull),('jar_teeth',lambda:jar('teeth')),('jar_seeds',lambda:jar('seeds')),('florist_pegboard',pegboard),('chalk_menu',chalkboard),('rip_promotion_sign',rip_sign),('botanical_shelf_medium',lambda:shelf(2.4)),('botanical_shelf_small',lambda:shelf(1.2))]
report=[]
selected=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
for index,(name,build) in enumerate(SPECS):
    if selected and name not in selected:continue
    root=build();bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BLEND,name+'.blend'))
    path=os.path.join(OUT,name+'.glb');bc.export_glb(path,root)
    raw=open(path,'rb').read();size=struct.unpack_from('<I',raw,12)[0];doc=json.loads(raw[20:20+size])
    record={'number':14+index,'asset':name,'triangles':sum(doc['accessors'][p['indices']]['count']//3 for m in doc['meshes'] for p in m['primitives']),'metres':True}
    report.append(record);print('SHOP_ASSET_COMPLETE',json.dumps(record),flush=True)
if not selected:
    with open(os.path.join(OUT,'items_14_33.json'),'w') as f:json.dump(report,f,indent=2)
print('ITEMS_14_33_COMPLETE',len(report),flush=True)

