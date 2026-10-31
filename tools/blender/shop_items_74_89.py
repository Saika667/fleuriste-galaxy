"""Last sixteen shop props. Metric editable Blender sources, Godot Y up and +Z front."""
import os,sys,math,json,struct
import bpy
from mathutils import Vector,Matrix
sys.path.insert(0,os.path.dirname(__file__))
exec(open(os.path.join(os.path.dirname(__file__),'shop_items_54_73.py'),encoding='utf-8').read().split('\nSPECS=')[0],globals())

def new(name):
    r=fresh(name)
    for k,c in {'rug_plum':'#A67B99','burgundy':'#7A1E36','coir':'#C9904E','book_rose':'#D9798F','book_blue':'#233B50','book_ochre':'#E1B64A','page':'#F5ECD6','neon_green':'#64ED81','neon_lilac':'#D5B4FA','neon_mint':'#A6E7D4','velvet':'#5B2D82','velvet_dark':'#422063','velvet_light':'#75419A'}.items():bc.material(k,c)
    for k in ['neon_green','neon_lilac','neon_mint']:
        bs=bc._MATS[k].node_tree.nodes['Principled BSDF']
        bs.inputs['Emission Color'].default_value=bc.hex_color({'neon_green':'#64ED81','neon_lilac':'#D5B4FA','neon_mint':'#A6E7D4'}[k]);bs.inputs['Emission Strength'].default_value=.9
    return r

def artwork(r,name,file,w,h,pos,top=False):
    mat=bpy.data.materials.new('Printed_'+name);mat.use_nodes=True
    bs=mat.node_tree.nodes['Principled BSDF'];bs.inputs['Roughness'].default_value=.94;bs.inputs['Specular IOR Level'].default_value=.10
    tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(os.path.join(bc.ROOT,'assets/textures/shop',file+'.png'));tex.image.pack()
    mat.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color'])
    g=bc.pivot('Artwork_mount',bc.G(*pos),r)
    if top:g.rotation_euler.x=-math.pi/2
    me=bpy.data.meshes.new(name);me.from_pydata([bc.G(*p) for p in [(-w/2,-h/2,0),(w/2,-h/2,0),(w/2,h/2,0),(-w/2,h/2,0)]],[],[(0,1,2,3)]);me.update()
    uv=me.uv_layers.new(name='ArtworkUV')
    for i,xy in enumerate([(0,0),(1,0),(1,1),(0,1)]):uv.data[i].uv=xy
    ob=bpy.data.objects.new('Flat_'+name,me);bpy.context.collection.objects.link(ob);me.materials.append(mat);bc._parent(ob,g);ob['no_outline']=True

def edge_rect(r,w,h,z,role,rad=.003,x=0,y=0):
    line('Fine_edge',[(x-w/2,y-h/2,z),(x+w/2,y-h/2,z),(x+w/2,y+h/2,z),(x-w/2,y+h/2,z),(x-w/2,y-h/2,z)],rad,role,r)

def rug():
    r=new('HatchRug');box('Anti_slip_rubber',(1.1,.009,1.1),(0,.0045,0),'rubber',r,.009)
    box('Bound_woven_body',(1.098,.006,1.098),(0,.010,0),'rug_plum',r,.006)
    artwork(r,'woven_botanical_motif','hatch_rug_weave',1.08,1.08,(0,.0131,0),True)
    for x in [-.541,.541]:line('Double_stitched_edge',[(x,.014,-.54),(x,.014,.54)],.0015,'cream',r)
    for z in [-.541,.541]:line('Double_stitched_edge',[(-.54,.014,z),(.54,.014,z)],.0015,'cream',r)
    return r

def hatch_lid(r,opened):
    hinge=bc.pivot('LidHinge',bc.G(-.46,.018,0),r);hinge['articulated']=True
    # Moving lid: four identical planks, same fittings in both states.
    for x in [0,.92]:box('Lid_side_stile',(.055,.06,.94),(x,0,0),'wood_dark',hinge,.006)
    for z in [-.4425,.4425]:box('Lid_end_rail',(.92,.06,.055),(.46,0,z),'wood_dark',hinge,.006)
    for k in range(4):
        z=-.33+k*.22
        box('Walnut_lid_plank',(.86,.055,.215),(.46,0,z),'walnut',hinge,.004)
        for d in [-.05,.035]:line('Stylized_woodgrain',[(.08,.029,z+d),(.32,.029,z+d+.004),(.68,.029,z+d-.002),(.85,.029,z+d+.002)],.0009,'wood_dark',hinge)
    for x in [.17,.75]:box('Underside_reinforcement',(.065,.024,.84),(x,-.042,0),'wood_dark',hinge,.004)
    for x in [.02,.90]:
        for z in [-.42,.42]:
            box('Brass_corner_strap',(.080,.006,.080),(x,.033,z),'gold',hinge,.008)
            for dx,dz in [(-.022,0),(.022,0),(0,.022)]:oval('Corner_rivet',(x+dx,.037,z+dz),(.004,.002,.004),'gold',hinge)
    box('Flush_ring_recess',(.12,.005,.12),(.79,.031,0),'ink',hinge,.01)
    ring_g=bc.pivot('Flush_pull_mount',bc.G(.79,.037,0),hinge);ring_g.rotation_euler.x=-math.pi/2
    front_loop('Brass_pull_ring',0,0,0,.037,.037,.005,'gold',ring_g)
    for z in [-.33,.33]:
        bc.cylinder('Hinge_barrel',.014,.014,.13,(0,.0,z),'gold',hinge,seg=16,rot=(math.pi/2,0,0))
        box('Hinge_strap',(.12,.009,.06),(.035,.036,z),'gold',hinge,.004)
    box('Latch_hasp',(.08,.008,.10),(.46,.036,.44),'gold',hinge,.004)
    if not opened:
        lock=bc.pivot('RemovablePadlock',bc.G(.46,.08,.48),r);lock['articulated']=True
        box('Padlock_body',(.072,.068,.035),(0,0,0),'gold',lock,.008)
        front_loop('Padlock_shackle',0,.043,0,.023,.026,.005,'metal',lock)
        oval('Keyhole',(0,0,.020),(.007,.010,.002),'ink',lock)
    else:hinge.rotation_euler.y=-math.radians(80) # Keep the complete lid inside the adjacent west wall.

def hatch(opened=False):
    r=new('OpenCellarHatch' if opened else 'ClosedCellarHatch')
    for x in [-.475,.475]:box('Fixed_frame_side',(.05,.055,1),(x,-.015,0),'wood_dark',r,.004)
    for z in [-.475,.475]:box('Fixed_frame_end',(1,.055,.05),(0,-.015,z),'wood_dark',r,.004)
    hatch_lid(r,opened)
    if opened:
        shaft=bc.pivot('ShaftInterior',bc.G(0,0,0),r)
        for x in [-.45,.45]:box('Dark_shaft_wall',(.04,2,.90),(x,-1.02,0),'soil',shaft,.005)
        for z in [-.45,.45]:box('Dark_shaft_end',(.86,2,.04),(0,-1.02,z),'wood_dark',shaft,.005)
        box('Cellar_landing',(.88,.06,.88),(0,-2.04,0),'soil',shaft,.003)
        ladder=bc.pivot('DescendingLadder',bc.G(0,0,0),r)
        for x in [-.24,.24]:tube('Ladder_side_rail',[(x,-.04,-.32),(x,-2,.22)],.027,'wood',ladder)
        for i in range(8):
            y=-.18-i*.24;z=-.32+(-y-.04)/1.96*.54
            tube('Ladder_rung',[(-.24,y,z),(.24,y,z)],.023,'wood',ladder)
        for x in [-.24,.24]:box('Ladder_top_hook',(.06,.11,.06),(x,-.03,-.32),'gold',ladder,.009)
    return r

def doormat():
    r=new('WelcomeDoormat');box('Rubber_backing',(.90,.012,.55),(0,.006,0),'rubber',r,.022)
    box('Honey_coir_insert',(.85,.010,.50),(0,.014,0),'coir',r,.016)
    g=bc.pivot('Printed_top',bc.G(0,.0195,0),r);g.rotation_euler.x=-math.pi/2
    lettering=letters('Flat_welcome','BIENVENUE',(0,0,0),.095,'teal_dark',g,'georgiab.ttf')
    for sd in [-1,1]:motif(g,sd*.345,-sd*.15,0,.075,'cream')
    return r

def plaque():
    r=new('PrivatePlaque');box('Burgundy_molded_frame',(.38,.16,.018),(0,0,0),'burgundy',r,.025)
    box('Ivory_enamel',(.35,.13,.006),(0,0,.011),'cream',r,.018)
    edge_rect(r,.352,.132,.016,'gold',.002)
    letters('Flat_private','PRIVÉ',(0,0,.017),.065,'burgundy',r,'georgiab.ttf')
    for x in [-.161,.161]:
        for y in [-.05,.05]:screw(r,(x,y,.017),.005)
    for sd in [-1,1]:motif(r,sd*.137,0,.017,.027,'gold')
    return r

def shelf(k):
    r=new('StockShelf'+str(k));w=[2,1.5][k];role='teal' if k==0 else 'cream'
    box('Clear_walnut_plate',(w,.055,.38),(0,-.0275,0),'walnut' if k==0 else 'wood',r,.012)
    box('Molded_front_fascia',(w-.025,.048,.022),(0,-.059,.182),role,r,.007)
    box('Thin_brass_fascia_bead',(w-.05,.006,.007),(0,-.079,.196),'gold',r,.002)
    box('Rear_wall_rail',(w-.18,.06,.015),(0,-.08,-.183),'teal_dark',r,.006)
    for sd in [-1,1]:
        x=sd*(w/2-.13)
        box('Wall_bracket_anchor',(.055,.25,.025),(x,-.145,-.18),'gold' if k==0 else 'plum',r,.008)
        tube('Curved_support_scroll',[(x,-.06,.14),(x,-.11,.10),(x,-.23,-.13),(x,-.25,-.15),(x,-.19,-.14),(x,-.17,-.11)],.014,'gold' if k==0 else 'plum',r)
        tube('Bracket_diagonal',[(x,-.235,-.17),(x,-.08,.14)],.012,'gold' if k==0 else 'plum',r)
        side=bc.pivot('Bracket_leaf_relief',bc.G(x,-.15,-.04),r);side.rotation_euler.z=sd*math.pi/2
        motif(side,0,0,.017,.075,'gold')
        for y in [-.07,-.23]:oval('Wall_fixing_bolt',(x,y,-.159),(.006,.006,.004),'gold',r)
    return r

def picture(k):
    r=new('FramedBotanical'+str(k));role=['walnut','teal','cream'][k];inner=['teal','cream','lilac_pot'][k]
    box('Sealed_backboard',(.59,.79,.018),(0,0,-.016),'wood_dark',r,.005)
    for sd in [-1,1]:
        box('Stepped_frame_vertical',(.058,.80,.052),(sd*.271,0,0),role,r,.008)
        box('Stepped_frame_horizontal',(.55,.058,.052),(0,sd*.371,0),role,r,.008)
        box('Inner_vertical_bead',(.012,.70,.012),(sd*.235,0,.029),inner,r,.003)
        box('Inner_horizontal_bead',(.48,.012,.012),(0,sd*.345,.029),inner,r,.003)
        for sy in [-1,1]:motif(r,sd*.266,sy*.365,.028,.035,'gold')
        screw(r,(sd*.20,.23,-.027),.008)
        for yy in [-.31,.31]:box('Rear_backing_clip',(.016,.025,.004),(sd*.24,yy,-.028),'gold',r,.002)
    box('Linen_mat',(.46,.69,.008),(0,0,.020),'cream',r,.001)
    file=['framed_rose_painting','framed_sunflower_painting','framed_xeno_painting'][k]
    artwork(r,'botanical_painting',file,.382,.535,(0,0,.025))
    edge_rect(r,.388,.541,.026,'gold',.0018)
    tube('Rear_hanging_wire',[(-.20,.23,-.035),(0,.30,-.04),(.20,.23,-.035)],.002,'gold',r)
    return r

def book(k):
    r=new('BotanicalBook'+str(k));w,d,h=[(.32,.22,.05),(.30,.23,.045),(.28,.21,.055)][k];role=['book_rose','teal','book_ochre'][k];spine=['burgundy','book_blue','burgundy'][k]
    for y in [.003,h-.003]:box('Hardbound_cover',(w,.006,d),(0,y,0),role,r,.004)
    box('Ivory_pageblock',(w-.022,h-.014,d-.018),(.005,h/2,0),'page',r,.002)
    box('Rounded_bound_spine',(.023,h,d),(-w/2+.009,h/2,0),spine,r,.009)
    for i in range(1,9):line('Fore_edge_page_line',[(-w/2+.022,.008+i*(h-.016)/9,d/2-.008),(w/2-.01,.008+i*(h-.016)/9,d/2-.008)],.00025,'honey',r)
    for zz in [-d*.35,-d*.1,d*.16,d*.36]:box('Raised_binding_rib',(.026,h+.002,.006),(-w/2+.009,h/2,zz),'gold' if k==1 else spine,r,.002)
    artwork(r,'book_cover',['botany_cover','flowers_guide_cover','strange_plants_cover'][k],w-.032,d-.014,(.010,h+.0003,0),True)
    tube('Ribbon_bookmark',[(w*.22,.009,d*.1),(w*.22,.008,d*.51),(w*.24,.004,d*.64)],.004,'teal' if k!=1 else 'burgundy',r)
    for zz in [-d*.44,d*.44]:
        for i in range(8):oval('Stitched_headband',(-w/2+.021,.01+i*(h-.02)/8,zz),(.003,.0015,.002),'teal' if i%2 else 'cream',r)
    return r

def curtains():
    r=new('PurpleCurtains');tube('Continuous_brass_rod',[(-1.65,2.48,0),(1.65,2.48,0)],.014,'gold',r)
    for sd in [-1,1]:
        oval('Leaf_bud_finial',(sd*1.68,2.48,0),(.065,.027,.027),'gold',r)
        tube('Rod_wall_bracket',[(sd*1.46,2.48,0),(sd*1.46,2.48,-.10),(sd*1.46,2.42,-.12)],.011,'gold',r)
        for i in range(9):
            g=bc.pivot('Ring_orientation',bc.G(sd*(.85+i*.075),2.47,0),r);g.rotation_euler.z=math.pi/2
            front_loop('Curtain_rod_ring',0,0,0,.023,.031,.004,'gold',g)
        nx,ny=64,40;verts=[];faces=[]
        for iy in range(ny+1):
            t=iy/ny;y=.04+2.36*t
            gather=math.exp(-((t-.43)/.15)**2);width=.73-.25*gather;center=sd*(1.15+.10*gather)
            for ix in range(nx+1):
                u=ix/nx;x=center+(u-.5)*width;z=.07*math.cos(u*math.tau*6)*(1-.3*gather)
                verts.append((x,y,z))
        for iy in range(ny):
            for ix in range(nx):
                a=iy*(nx+1)+ix;faces.append((a,a+1,a+nx+2,a+nx+1))
        ob=mesh('Folded_velvet_cloth',verts,faces,'velvet',r,.003)
        for role in ['velvet_dark','velvet_light','cream']:ob.data.materials.append(bc._MATS[role])
        for i,p in enumerate(ob.data.polygons):
            iy=i//nx;ix=i%nx;p.material_index=3 if iy<3 else (1 if ix%11>6 else (2 if ix%11<2 else 0));p.use_smooth=True
        # Continuous tie wraps physically around the gathered cloth.
        tube('Teal_tieback',[(sd*1.51,1.08,-.10),(sd*1.53,1.07,.08),(sd*1.23,1.03,.10),(sd*1.02,1.04,0),(sd*1.08,1.08,-.10)],.018,'teal',r)
        oval('Wall_tieback_hook',(sd*1.55,1.08,-.11),(.023,.06,.015),'gold',r)
        for i in range(6):
            x=sd*(.85+i*.10);g=bc.pivot('Hem_embroidery',bc.G(x,.13,.076),r);motif(g,0,0,0,.040,'teal')
    return r

def neon_portal():
    r=new('BackRoomNeon');w=1.25
    for sd in [-1,1]:box('Portal_protected_upright',(.065,2.55,.065),(sd*(w/2-.0325),1.275,0),'ink',r,.012)
    box('Header_case',(1.25,.27,.09),(0,2.685,0),'ink',r,.018)
    edge_rect(r,1.18,.205,.049,'plum',.004,y=2.685)
    ob=letters('Flat_backroom_title','ARRIÈRE-BOUTIQUE',(0,2.685,.051),.12,'cream',r,'framd.ttf')
    bpy.context.view_layer.update()
    if ob.dimensions.x>1.08:ob.scale*=1.08/ob.dimensions.x
    tube('Green_neon_continuous_U',[(-.59,.04,.045),(-.59,2.45,.045),(-.57,2.49,.045),(-.53,2.51,.045),(.53,2.51,.045),(.57,2.49,.045),(.59,2.45,.045),(.59,.04,.045)],.014,'neon_green',r)
    for sd in [-1,1]:
        for y in [.3,.75,1.2,1.65,2.1,2.43]:box('Brass_tube_clamp',(.041,.024,.038),(sd*.59,y,.039),'gold',r,.006)
    box('Rear_transformer',(.20,.12,.045),(.35,2.685,-.067),'gray',r,.01)
    tube('Protected_power_cable',[(.35,2.63,-.092),(.35,2.53,-.09),(.58,2.50,-.06)],.006,'rubber',r)
    return r

def strip_module(r,start,end,role='neon_lilac'):
    a,b=Vector(start),Vector(end);d=b-a;length=d.length
    g=bc.pivot('NeonModule',bc.G(*((a+b)/2)),r)
    # Module length is local X; rotate in floor plane if needed.
    g.rotation_euler.z=-math.atan2(d.z,d.x)
    box('Protected_wall_channel',(length,.045,.025),(0,0,0),'ink',g,.005)
    tube('Continuous_diffuser',[(-length/2+.012,0,.023),(length/2-.012,0,.023)],.016,role,g)
    for x in [-length/2+.014,length/2-.014]:box('Brass_endcap',(.023,.046,.036),(x,0,.006),'gold',g,.005)
    for i in range(max(2,int(length/.5))):
        x=-length/2+.08+i*(length-.16)/(max(2,int(length/.5))-1)
        box('Brass_mounting_clip',(.014,.052,.03),(x,0,.011),'gold',g,.003)
    return g

def strips():
    r=new('ShopNeonStrips')
    strip_module(r,(-4.92,0,-3.92),(.9,0,-3.92))
    strip_module(r,(.92,0,-3.92),(4.92,0,-3.92),'neon_mint')
    strip_module(r,(-4.92,0,3.92),(-4.92,0,-3.92))
    strip_module(r,(4.92,0,-3.92),(4.92,0,3.92))
    return r

SPECS=[('hatch_rug_botanical',rug),('cellar_hatch_closed',lambda:hatch(False)),('cellar_hatch_open',lambda:hatch(True)),('welcome_doormat',doormat),('service_private_plaque',plaque),('stock_shelf_botanical',lambda:shelf(0)),('stock_shelf_ivory',lambda:shelf(1))]+[('framed_botanical_'+k,lambda i=i:picture(i)) for i,k in enumerate(['rose','sunflower','xeno'])]+[('botanical_book_'+k,lambda i=i:book(i)) for i,k in enumerate(['rose','teal','ochre'])]+[('purple_curtains',curtains),('backroom_neon_portal',neon_portal),('shop_neon_strips',strips)]
selected=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
report=[]
for index,(name,build) in enumerate(SPECS):
    if selected and name not in selected:continue
    root=build();bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BLEND,name+'.blend'));path=os.path.join(OUT,name+'.glb');bc.export_glb(path,root)
    raw=open(path,'rb').read();n=struct.unpack_from('<I',raw,12)[0];doc=json.loads(raw[20:20+n]);tris=sum(doc['accessors'][p['indices']]['count']//3 for m in doc['meshes'] for p in m['primitives'])
    record=dict(number=74+index,asset=name,triangles=tris,metres=True);report.append(record);print('SHOP_ASSET_COMPLETE',json.dumps(record),flush=True)
if not selected:
    with open(os.path.join(OUT,'items_74_89.json'),'w') as f:json.dump(report,f,indent=2)
print('ITEMS_74_89_COMPLETE',len(report),flush=True)
