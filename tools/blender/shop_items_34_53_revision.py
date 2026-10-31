"""Detailed geometry revisions, executed in the 34–53 builder namespace."""
import bmesh

_previous_poster=poster
def poster(kind):
    r=_previous_poster(kind)
    for ob in list(r.children_recursive):
        if ob.name.startswith('Flat_'):bpy.data.objects.remove(ob,do_unlink=True)
    w,h=(.61,.86) if kind=='flower' else (.46,.61)
    filename='poster_bouquet_painting_v2.png' if kind=='flower' else 'poster_warning_art_v2.png'
    material=bpy.data.materials.new('Printed_painting_'+kind);material.use_nodes=True
    bsdf=material.node_tree.nodes.get('Principled BSDF');bsdf.inputs['Roughness'].default_value=.88;bsdf.inputs['Specular IOR Level'].default_value=.15
    tex=material.node_tree.nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(os.path.join(bc.ROOT,'assets/textures/shop',filename));tex.image.pack()
    material.node_tree.links.new(tex.outputs['Color'],bsdf.inputs['Base Color'])
    verts=[(-w/2+.028,-h/2+.028,.021),(w/2-.028,-h/2+.028,.021),(w/2-.028,h/2-.028,.021),(-w/2+.028,h/2-.028,.021)]
    me=bpy.data.meshes.new('Printed_canvas');me.from_pydata([bc.G(*p) for p in verts],[],[(0,1,2,3)]);me.update()
    uv=me.uv_layers.new(name='ArtworkUV')
    for i,coord in enumerate([(0,0),(1,0),(1,1),(0,1)]):uv.data[i].uv=coord
    ob=bpy.data.objects.new('Flat_framed_artwork',me);bpy.context.collection.objects.link(ob);me.materials.append(material);bc._parent(ob,r);ob['no_outline']=True
    return r

def side_extrusion(name,outline,x,width,role,r):
    count=len(outline)
    verts=[(xx,y,z) for xx in [x-width/2,x+width/2] for y,z in outline]
    faces=[tuple(range(count-1,-1,-1)),tuple(range(count,2*count))]+[(i,(i+1)%count,(i+1)%count+count,i+count) for i in range(count)]
    ob=mesh(name,verts,faces,role,r)
    bm=bmesh.new();bm.from_mesh(ob.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(ob.data);bm.free()
    return ob

def stand(k):
    r=begin('SteppedStand_'+str(k))
    for level in range(3):
        y=.30+level*.32;z=.19-level*.19
        box('Flat_display_tray',(.90,.035,.22),(0,y,z),'wood' if k==1 else 'teal',r,.009)
        box('Cream_tray_edge',(.90,.025,.015),(0,y+.002,z+.11),'cream',r,.006)
        for side in [-1,1]:screw(r,(side*.425,y,z+.119),.008)
    profile=[(.025,.30),(.025,.235),(.15,.16),(.28,.08),(.31,-.06),(.16,-.20),(.025,-.235),(.025,-.29),(1.03,-.29),(1.04,-.23),(1.025,-.19),(.94,-.16),(.78,-.08),(.64,.015),(.48,.13),(.34,.245),(.30,.29)]
    for side in [-1,1]:
        x=side*.433
        panel_ob=side_extrusion('Solid_sculpted_side_panel' if k==1 else 'Pierced_botanical_side_panel',profile,x,.042,'teal' if k==1 else 'wood',r)
        if k==3:
            for j,(y,z,angle) in enumerate([(.36,-.08,-.5),(.54,-.15,.45),(.75,-.215,-.20)]):
                outline=[]
                for i in range(32):
                    a=i*math.tau/32;yy=.075*math.cos(a);zz=.027*math.sin(a)*abs(math.sin(a))**.35
                    outline.append((y+yy*math.cos(angle)-zz*math.sin(angle),z+yy*math.sin(angle)+zz*math.cos(angle)))
                cutter=side_extrusion('Leaf_aperture_tool',outline,x,.13,'wood',r)
                md=panel_ob.modifiers.new('Real_leaf_shaped_aperture_'+str(j),'BOOLEAN');md.operation='DIFFERENCE';md.solver='EXACT';md.object=cutter
                bpy.context.view_layer.objects.active=panel_ob;bpy.ops.object.modifier_apply(modifier=md.name);bpy.data.objects.remove(cutter,do_unlink=True)
        bevel=panel_ob.modifiers.new('Soft_side_edges','BEVEL');bevel.width=.006;bevel.segments=3
        g=bc.pivot('Outer_side_ornaments',bc.G(0,0,0),r)
        for y,z in [(.30,.23),(.62,.035),(.94,-.17)]:screw(g,(-side*z,y,.003),.014)
        if k==1:motif(g,-side*.025,.43,.005,.070)
        g.location=bc.G(side*.458,0,0);g.rotation_euler.z=side*math.pi/2
        for z in [-.26,.265]:box('Brass_capped_foot',(.054,.043,.060),(x,.025,z),'gold',r,.006)
    if k==3:
        for side in [-1,1]:tube('Rear_cross_brace',[(-.41,.12 if side<0 else .89,-.29),(.41,.89 if side<0 else .12,-.29)],.012,'wood_dark',r)
    else:box('Rear_stability_brace',(.85,.045,.025),(0,.18,-.27),'wood_dark',r,.004)
    return r

_previous_crate=crate
def crate(content):
    r=_previous_crate(content)
    if content!='bulbs':return r
    for ob in list(r.children_recursive):
        if ob.name.startswith(('Papery_bulb','Bulb_roots','Tiny_bulb_sprout')):bpy.data.objects.remove(ob,do_unlink=True)
    for i in range(6):
        x=-.19+(i%3)*.19;z=-.095+(i//3)*.19;scale=.93+.065*(i%3)
        profile=[(0,.115),(.033,.119),(.051,.142),(.058,.177),(.053,.206),(.036,.241),(.018,.274),(.010,.304),(.005,.322),(0,.328)]
        bc.lathe('Teardrop_flower_bulb',[(ra*scale,.115+(y-.115)*scale) for ra,y in profile],'root' if i%2 else 'kraft',r,loc=(x,0,z),seg=32,subsurf=0,mod=lambda a,t:(1+.025*math.cos(7*a),0))
        for j in range(6):
            a=j*math.tau/6+.3
            pts=[(x+rad*scale*math.cos(a),.115+(y-.115)*scale,z+rad*scale*math.sin(a)) for rad,y in [(.034,.12),(.052,.145),(.059,.178),(.054,.207),(.037,.243),(.019,.276),(.011,.306)]]
            tube('Fine_papery_bulb_seam',pts,.0008,'wood_dark',r)
            tube('Settled_root_tuft',[(x+.025*math.cos(a),.119,z+.025*math.sin(a)),(x+.043*math.cos(a),.112,z+.042*math.sin(a))],.0013,'twine',r)
        tube('Small_green_shoot',[(x,.115+.213*scale,z),(x+.006,.355+(scale-.95)*.08,z)],.003,'leaf',r)
    return r

_previous_flytrap=flytrap
def flytrap():
    r=_previous_flytrap();jaw=next(ob for ob in r.children_recursive if ob.name=='jaw_dn')
    # Construct at the origin then parent in local jaw coordinates, so it follows the jaw.
    tongue=oval('Tongue_pink',(0,-.006,.092),(.035,.009,.051),'pink',r)
    tongue.parent=jaw;tongue.matrix_parent_inverse=__import__('mathutils').Matrix.Identity(4);tongue.location=bc.G(0,-.005,.092)
    crease=line('Tongue_center_groove',[(0,.005,.065),(0,.005,.120)],.001,'ribbon',r)
    crease.parent=jaw;crease.matrix_parent_inverse=__import__('mathutils').Matrix.Identity(4)
    return r

def coffin():
    r=begin('DetailedCoffinPlanter')
    outline=[(-.60,-.15),(-.30,-.325),(.32,-.325),(.60,-.15),(.60,.15),(.32,.325),(-.30,.325),(-.60,.15)]
    mesh('Coffin_floor',[(x,.055,z) for x,z in outline],[tuple(range(8))],'walnut',r,.022)
    mesh('Recessed_waterproof_soil',[(x*.91,.335,z*.86) for x,z in outline],[tuple(range(8))],'soil',r,.012)
    for i in range(8):
        a=Vector(outline[i]);b=Vector(outline[(i+1)%8]);mid=(a+b)/2;length=(b-a).length;angle=math.atan2(b.y-a.y,b.x-a.x)
        g=bc.pivot('Detailed_side_segment_'+str(i),bc.G(0,0,0),r)
        box('Walnut_carved_side',(length+.008,.30,.030),(0,.215,0),'walnut',g,.008)
        box('Inset_teal_panel',(length-.055,.185,.008),(0,.22,.019),'teal',g,.006)
        for s in [-1,1]:
            box('Brass_panel_vertical',(.006,.17,.004),(s*(length/2-.038),.22,.025),'gold',g,.001)
            box('Brass_panel_horizontal',(length-.075,.006,.004),(0,.22+s*.085,.025),'gold',g,.001)
        motif(g,0,.22,.028,min(.060,length*.17))
        if length>.5:
            for s in [-1,1]:
                motif(g,s*length*.32,.22,.027,.025)
                box('Handle_mount',(.038,.044,.014),(s*.18,.245,.028),'gold',g,.005)
                front_loop('Brass_drop_handle',s*.18,.212,.043,.026,.025,.005,'gold',g)
                for dx in [-.010,.010]:screw(g,(s*.18+dx,.25,.038),.003)
        g.location=bc.G(mid.x,0,mid.y);g.rotation_euler.z=math.pi-angle
        for y,rad,role in [(.075,.009,'gold'),(.355,.005,'gold'),(.377,.020,'cream')]:line('Continuous_moulded_edge',[(a.x,y,a.y),(b.x,y,b.y)],rad,role,r)
        box('Brass_corner_strap',(.025,.30,.025),(a.x,.216,a.y),'gold',r,.005)
        for y in [.075,.37]:box('Decorated_corner_cap',(.044,.035,.044),(a.x,y,a.y),'gold',r,.006)
    for x in [-.43,.43]:
        for z in [-.19,.19]:box('Carved_walnut_foot',(.065,.065,.06),(x,.0325,z),'wood_dark',r,.008)
    rng=random.Random(520)
    for i in range(56):
        x=rng.uniform(-.47,.47);z=rng.uniform(-.23,.23);y=.355+rng.random()*.055
        a=rng.uniform(-math.pi,math.pi);leaf(r,(x,y,z),rng.uniform(.085,.145),rng.uniform(.035,.060),a,-.35-rng.random()*.8,'leaf_dark' if i%3 else 'grass',angle=(rng.random()-.5)*1.2)
    for side in [-1,1]:
        for x in [-.38,0,.38]:
            pts=[(x,.36,side*.23),(x+.025,.37,side*.35),(x+.05,.25,side*.39),(x+.09,.12,side*.40)]
            tube('Overflowing_leafy_trail',pts,.0025,'leaf_dark',r)
            for j in range(6):
                t=j/5
                leaf(r,(x+.09*t,.35-.23*t,side*(.32+.08*t)),.075-.022*t,.034,0 if side>0 else math.pi,-.1,'leaf',angle=(j%2-.5)*.8)
    return r

_previous_hanging=hanging
def hanging():
    r=_previous_hanging();g=bc.pivot('Small_branch_ramifications',bc.G(0,0,0),r);rng=random.Random(530)
    for i in range(8):
        a=i*math.tau/8+.15;length=.24+.065*(i%4)
        for j in [2,4]:
            t=j/7;p=Vector((math.sin(a)*(.135+.075*t),.10-(length+.10)*t,math.cos(a)*(.135+.075*t)))
            for side in [-1,1]:
                q=p+Vector((math.cos(a)*side*.045,-.025-rng.random()*.025,-math.sin(a)*side*.045))
                tube('Tiny_side_branch',[tuple(p),tuple((p+q)/2+Vector((0,.012,0))),tuple(q)],.0013,'leaf_dark',g)
                for k in range(2):
                    point=p.lerp(q,.55+k*.45)
                    leaf(g,tuple(point),rng.uniform(.040,.073),rng.uniform(.021,.038),a+rng.uniform(-1.2,1.2),rng.uniform(-.55,.4),'grass' if (i+j+k)%4==0 else 'leaf',angle=rng.uniform(-.8,.8))
    for i in range(14):
        a=i*2.39996;rr=.045+.08*(i%3)/2
        leaf(g,(math.sin(a)*rr,.20+rng.random()*.07,math.cos(a)*rr),rng.uniform(.06,.10),.038,a+rng.uniform(-.6,.6),-.6,'leaf')
    g.location=bc.G(0,-.73,0)
    return r
