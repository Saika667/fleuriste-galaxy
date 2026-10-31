"""Model refinements, executed in the main builder namespace."""
from mathutils.bvhtree import BVHTree
def text(name,body,pos,size,role,r):
    font='Inkfree.ttf' if name.startswith('Chalk_letters') or name in ['Roses_hier','Discount'] else ('georgiab.ttf' if name=='RIP' else None)
    cu=bpy.data.curves.new(name,'FONT');cu.body=body;cu.size=size;cu.align_x='CENTER';cu.align_y='CENTER';cu.extrude=.00025
    if font:cu.font=bpy.data.fonts.load('C:/Windows/Fonts/'+font)
    ob=bpy.data.objects.new(name,cu);bpy.context.collection.objects.link(ob);ob.location=bc.G(*pos);ob.rotation_euler=(math.pi/2,0,0);cu.materials.append(bc._MATS[role]);bc._parent(ob,r)
    bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob;bpy.ops.object.convert(target='MESH');ob['no_outline']=True
    if name.startswith('Chalk_letters'):
        bpy.context.view_layer.update();tree=BVHTree.FromObject(ob,bpy.context.evaluated_depsgraph_get());rng=random.Random(name)
        bb=[Vector(v) for v in ob.bound_box];dots=[];faces=[]
        for i in range(2600):
            x=rng.uniform(min(v.x for v in bb),max(v.x for v in bb));y=rng.uniform(min(v.y for v in bb),max(v.y for v in bb))
            hit,normal,idx,dist=tree.ray_cast(Vector((x,y,.02)),Vector((0,0,-1)),.05)
            if hit is None:continue
            w=ob.matrix_world@hit;p=(w.x,w.z,-w.y+.0005);a=.0004+rng.random()*.0007;n=len(dots)
            dots.extend([(p[0]-a,p[1],p[2]),(p[0]+a,p[1],p[2]),(p[0],p[1]+a,p[2])]);faces.append((n,n+1,n+2))
        if dots:mesh('Chalk_grain_speckles',dots,faces,'slate',r)
    return ob

def ivy_leaf(r,p,size,a=0,role='leaf'):
    shape=[(0,-.62),(-.20,-.34),(-.46,-.19),(-.59,.01),(-.55,.20),(-.39,.24),(-.23,.13),(-.19,.40),(0,.62),(.19,.40),(.23,.13),(.39,.24),(.55,.20),(.59,.01),(.46,-.19),(.20,-.34)]
    perimeter=[]
    for i in range(len(shape)):
        p0,p1,p2,p3=[Vector(shape[k%len(shape)]) for k in [i-1,i,i+1,i+2]]
        for j in range(3):
            t=j/3;v=.5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t*t+(-p0+3*p1-3*p2+p3)*t*t*t);perimeter.append(tuple(v))
    raw=[(0,0,.0014)]+[(x*size,y*size,0) for x,y in perimeter]
    verts=[(p[0]+x*math.cos(a)-y*math.sin(a),p[1]+x*math.sin(a)+y*math.cos(a),p[2]+z) for x,y,z in raw]
    ob=mesh('Rounded_ivy_leaf',verts,[(0,i+1,(i+1)%len(perimeter)+1) for i in range(len(perimeter))],role,r,.0005)
    for f in ob.data.polygons:f.use_smooth=True
    line('Leaf_midvein',[(p[0]+math.sin(a)*size*.47,p[1]-math.cos(a)*size*.47,p[2]+.002),p,(p[0]-math.sin(a)*size*.47,p[1]+math.cos(a)*size*.47,p[2]+.002)],.0006,'leaf_light',r)

def ivy():
    r=start('ReferenceTrailingIvy');pot(r,.115,.20,False)
    bc.lathe('Cream_rim_band',[(.114,.144),(.117,.144),(.117,.184),(.114,.184)],'cream',r,seg=40,subsurf=0)
    ring('Teal_glaze_band',.118,.163,.004,'teal',r)
    rng=random.Random(231)
    def leaf_at(p,size,angle,yaw,tilt,role):
        g=bc.pivot('Individual_ivy_leaf',bc.G(0,0,0),r)
        ivy_leaf(g,(0,0,0),size,angle,role)
        g.location=bc.G(*p);g.rotation_euler=(tilt,0,yaw)
    # A low, spreading crown; no uniform vertical cylinder of leaves.
    for i in range(34):
        a=i*2.39996;rad=.025+.095*math.sqrt(i/33)
        p=(math.sin(a)*rad,.205+.024*math.sin(i*1.73),math.cos(a)*rad)
        line('Crown_branch',[(0,.175,0),p],.0013,'leaf',r)
        leaf_at(p,.05+rng.random()*.022,(rng.random()-.5)*1.3,a,-.55 if i%3 else -.85,'leaf_light' if i%4==0 else 'leaf')
    # Six independently curved trails. The open front keeps the pot visible.
    trails=[
        [(-.035,.18,.035),(-.10,.225,.09),(-.145,.10,.12),(-.17,-.05,.14),(-.19,-.20,.15),(-.22,-.34,.12)],
        [(.04,.18,.025),(.10,.22,.08),(.14,.09,.10),(.165,-.06,.12),(.17,-.20,.11)],
        [(-.03,.18,-.025),(-.105,.21,-.07),(-.16,.08,-.10),(-.18,-.07,-.11)],
        [(.03,.18,-.02),(.10,.225,-.08),(.15,.09,-.10),(.17,-.08,-.11),(.19,-.26,-.08)],
        [(-.02,.18,.05),(-.07,.21,.13),(-.09,.10,.155),(-.08,.015,.16)],
        [(.04,.18,.04),(.07,.21,.12),(.10,.11,.15),(.12,.03,.175),(.16,-.10,.18)]
    ]
    for i,pts in enumerate(trails):
        bc.sweep('Distinct_curved_ivy_vine',pts,[.0018]*len(pts),'leaf',r,seg=6,sub=4)
        for j in range(2,12):
            t=j/11;u=t*(len(pts)-1);idx=min(len(pts)-2,int(u));v=Vector(pts[idx]).lerp(Vector(pts[idx+1]),min(1,u-idx))
            sides=[-1,1] if j%3 else [1]
            for side in sides:
                dx=side*(.019+rng.random()*.006)
                p=(v.x+dx,v.y-.008,v.z+.008)
                line('Ivy_petioles',[tuple(v),(p[0],p[1]+.025,p[2])],.0009,'leaf',r)
                radial=math.atan2(v.x,v.z)
                facing=0 if v.z>=0 else (math.pi if v.x>=0 else -math.pi)
                yaw=facing+(radial-facing)*(.35 if j%3 else .85)+(rng.random()-.5)*.85
                leaf_at(p,.055-.014*t+rng.random()*.008,side*.45+rng.random()*.25,yaw,(rng.random()-.5)*.25,'leaf_light' if (i+j)%4==0 else 'leaf')
    return r

_old_pegboard=pegboard
def pegboard():
    r=_old_pegboard()
    prefixes=['Pink_finger_loop','Scissors_neck','Crossed_tapered_blade','Scissors_pivot','Watering_can_body','Can_handle','Can_spout','Rose_holes']
    for ob in list(r.children_recursive):
        if any(ob.name.startswith(p) for p in prefixes):bpy.data.objects.remove(ob,do_unlink=True)
    for side in [-1,1]:
        front_loop('Scissor_oval_grip',-.90+side*.033,-.095,.058,.026,.037,.008,'ribbon',r)
        line('Scissor_grip_neck',[(-.90+side*.033,-.06,.058),(-.90+side*.012,-.015,.058),(-.90,.010,.058)],.008,'metal',r)
        mesh('Sharp_scissor_blade',[(-.90-side*.010,-.004,.058+side*.003),(-.90+side*.066,.156,.058+side*.003),(-.90+side*.033,.145,.058+side*.003),(-.90+side*.008,.016,.058+side*.003)],[(0,1,2,3)],'metal',r,.004)
    oval('Scissor_brass_pivot',(-.90,.01,.065),(.012,.012,.004),'gold',r);line('Scissor_screw_slot',[(-.906,.010,.070),(-.894,.010,.070)],.001,'ink',r)
    can=bc.pivot('Detailed_watering_can',bc.G(0,0,0),r)
    solid('Hollow_can_body',[(.048,-.11),(.065,-.105),(.070,-.085),(.070,.030),(.065,.041)],'teal',can,seg=32)
    ring('Rolled_can_rim',.066,.040,.004,'teal_light',can);ring('Can_bottom_seam',.060,-.10,.003,'teal_light',can)
    line('Curved_can_spout',[(.05,-.07,0),(.095,-.04,0),(.13,.015,0),(.155,.058,0)],.012,'teal',can)
    oval('Shower_rose',(.158,.064,0),(.026,.022,.022),'teal_light',can)
    for i in range(7):
        a=i*math.tau/7;oval('Shower_hole',(.158+math.sin(a)*.015,.065+math.cos(a)*.012,.022),(.002,.002,.001),'ink',can)
    front_loop('Open_can_side_handle',-.079,-.026,0,.028,.063,.007,'gold',can);front_loop('Carry_can_handle',0,.063,0,.055,.028,.006,'gold',can)
    can.location=bc.G(-.47,-.01,.082)
    return r

_old_rip=rip_sign
def rip_sign():
    r=_old_rip();bc.material('wilted','#AC6F81');bc.material('wilted_dark','#804E65');bc.material('wilted_leaf','#788C7A')
    for ob in list(r.children_recursive):
        if ob.name.startswith('Wilted_rose'):bpy.data.objects.remove(ob,do_unlink=True)
    edge=[(-.227,.025,.021),(.227,.025,.021),(.227,.43,.021)]+[(.227*math.cos(i*math.pi/24),.43+.192*math.sin(i*math.pi/24),.021) for i in range(25)]
    line('Inset_beveled_border',edge+[edge[0]],.0025,'stone_dark',r)
    for side in [-1,1]:
        for y in [.115,.366]:
            pts=[(side*(.172+.013*math.cos(i*math.tau/28)),y+.012*math.sin(i*math.tau/28),.021) for i in range(29)]
            line('Engraved_flourish',pts,.0015,'stone_dark',r);oval('Flourish_dot',(side*.172,y,.022),(.003,.003,.001),'stone_dark',r)
    for x,y in [(-.243,.06),(-.19,.57),(.18,.60),(.24,.045),(.07,.006)]:
        line('Paint_crack',[(x,y,.021),(x-.008,y+.013,.021),(x+.004,y+.028,.021)],.0011,'stone_dark',r)
    for y in [.08,.50]:
        for x in [-.19,.19]:
            oval('Rear_brass_screw',(x,y,-.039),(.008,.008,.002),'gold',r);line('Rear_screw_slot',[(x-.004,y-.004,-.041),(x+.004,y+.004,-.041)],.0007,'brown',r)
    for x in [-.12,0,.12]:line('Rear_wood_joint',[(x,.014,-.018),(x,.53,-.018)],.0008,'stone_dark',r)
    line('Wilted_bent_stem',[(0,.475,.023),(0,.520,.024),(-.013,.555,.026),(-.023,.551,.028),(-.024,.531,.030)],.002,'wilted_leaf',r)
    for side in [-1,1]:
        line('Drooping_leaf_branch',[(0,.49,.024),(side*.052,.52,.023),(side*.092,.49,.023)],.002,'wilted_leaf',r)
        o=oval('Wilted_sagging_leaf',(side*.068,.499,.025),(.028,.009,.002),'wilted_leaf',r);o.rotation_euler.y=side*.4
    for layer in range(2):
        for i in range(5):
            a=i*math.tau/5+layer*.4;p=(-.024+math.cos(a)*(.015-layer*.007),.531+math.sin(a)*.009,.031+layer*.004)
            o=oval('Hanging_wilted_rose_petal',p,(.010,.021,.004),'wilted' if i%2 else 'wilted_dark',r);o.rotation_euler.y=math.sin(a)*.2
            line('Withered_petal_fold',[(p[0],p[1]+.012,p[2]+.004),(p[0]-.002,p[1],p[2]+.004),(p[0],p[1]-.015,p[2]+.003)],.0007,'wilted_dark',r)
    return r

