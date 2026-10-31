"""Nine cartoon cut flowers from the approved reference sheets.
Run with Blender --background --python tools/blender/flowers.py [-- ids...].
Positions in metres, Y up, front +Z; flower head centre is Y=.445.
"""
import os, sys, math, json, struct
import bpy, bmesh
from mathutils import Vector
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
import bl_common as bc
from bl_common import G
TAU=math.tau
IDS=['tulip','lily','sunflower','lavender','daisy','poppy','xeno_bloom','snap_orchid','pleurelune']

class Flower:
    def __init__(self,ident,colors):
        bc.reset_scene();self.id=ident;self.root=bc.pivot(ident,G(0,0,0))
        self.features={}
        self.asset_group='flowers';self.height_range=(.48,.60);self.head_height=.445
        self.reference='art/concepts/flowers/'+ident+'_cartoon.png';self.outline_width=.0007
        palette={'green':'#638D3D','leaf':'#477332','ink':'#201A20','ivory':'#FFF7DC','gold':'#EAB629'}
        palette.update(colors)
        for role,col in palette.items():bc.material(role,col)
    def ball(self,name,p,s,role,seg=20):
        return bc.sphere(name,1,p,role,self.root,scale=s,seg=seg,exact=True)
    def tube(self,name,pts,r,role='green',seg=10,sub=3):
        return bc.sweep(name,pts,r,role,self.root,seg=seg,sub=sub,cap_len=.4,extras={'no_outline':role=='ink'})
    def surface(self,name,verts,faces,role,thick=.0012,inside=None):
        me=bpy.data.meshes.new(name);me.from_pydata([G(*v) for v in verts],[],faces);me.update()
        obj=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(obj);bc._parent(obj,self.root)
        me.materials.append(bc._MATS[role])
        for p in me.polygons:p.use_smooth=True
        md=obj.modifiers.new('Thickness','SOLIDIFY');md.thickness=thick;md.offset=-1
        if inside:
            me.materials.append(bc._MATS[inside]);md.material_offset=1;md.material_offset_rim=1
        return obj
    def stem(self,points=None,r=.004):
        points=points or [(0,0,0),(.006,.13,0),(-.006,.28,0),(0,.445,-.014)]
        self.tube('Stem',points,[r]*len(points))
    def leaf(self,name,p,d,length,width,role='leaf',serrate=0,droop=0):
        o=Vector(p);d=Vector(d).normalized();side=Vector((-d.y,d.x,0)).normalized()
        verts=[];faces=[];vein=[]
        for i in range(17):
            t=i/16;c=o+d*length*t+Vector((0,-droop*t*t,.007*math.sin(math.pi*t)))
            w=width*math.sin(math.pi*t)**.8
            if serrate:w*=1 if i%2 else 1-serrate
            verts.extend([tuple(c-side*w),tuple(c+Vector((0,0,.0025*math.sin(math.pi*t)))),tuple(c+side*w)])
            vein.append(tuple(c+Vector((0,0,.003))))
            if i:
                n=(i-1)*3;faces.extend([(n,n+3,n+4,n+1),(n+1,n+4,n+5,n+2)])
        self.surface(name,verts,faces,role)
        self.tube(name+'_vein',vein,[.0005]*len(vein),'ink',seg=6,sub=0)
    def leaves(self,wide=.025,serrate=0):
        self.leaf('Leaf_left',(-.002,.235,0),(-.78,.63,.08),.126,wide,serrate=serrate)
        self.leaf('Leaf_right',(.002,.145,0),(.80,.60,.1),.135,wide,serrate=serrate)
    def disk(self,name,p,r,depth,role,normal=(0,.28,.96),seg=28):
        obj=self.ball(name,p,(r,r,depth),role,seg)
        # Local Blender -Y is Godot +Z, the normal of the flattened disk.
        obj.rotation_mode='QUATERNION';obj.rotation_quaternion=Vector((0,-1,0)).rotation_difference(G(*normal).normalized())
        return obj
    def petal(self,name,center,angle,start,length,width,role='petal',normal=(0,.28,.96),curl=.012,pointed=False,ruffle=0):
        n=Vector(normal).normalized();ex=Vector((1,0,0));ey=n.cross(ex).normalized()
        radial=ex*math.cos(angle)+ey*math.sin(angle);side=-ex*math.sin(angle)+ey*math.cos(angle)
        c=Vector(center);verts=[];faces=[]
        for i in range(13):
            t=i/12
            shape=math.sin(math.pi*t)**(.85 if pointed else .48)
            w=max(.0002,width*shape)
            for j in range(9):
                s=j/8*2-1
                v=c+radial*(start+length*t)+side*w*s+n*(curl*math.sin(t*math.pi)-.010*t*t+.005*s*s*math.sin(math.pi*t))
                v+=n*(ruffle*math.sin(s*math.pi*3)*t*t)
                verts.append(tuple(v))
        for i in range(12):
            for j in range(8):
                a=i*9+j;faces.append((a,a+1,a+10,a+9))
        return self.surface(name,verts,faces,role)
    def calyx(self,center=(0,.445,-.018),r=.027,count=6,normal=(0,.28,.96)):
        self.disk('Green_receptacle',center,r,.009,'green',normal)
        for k in range(count):self.petal('Sepal_'+str(k),center,k*TAU/count,r*.30,r*.95,r*.25,'green',normal,curl=-.005,pointed=True)
    def finish(self):
        out=os.path.join(bc.ROOT,'art','blender',self.asset_group);os.makedirs(out,exist_ok=True)
        assets=os.path.join(bc.ROOT,'assets','models',self.asset_group);os.makedirs(assets,exist_ok=True)
        bpy.context.view_layer.update()
        coords=[obj.matrix_world@Vector(v) for obj in self.root.children_recursive if obj.type=='MESH' for v in obj.bound_box]
        bounds={'min':[min(v[k] for v in coords) for k in range(3)],'max':[max(v[k] for v in coords) for k in range(3)]}
        assert bounds['min'][2] > -.006, 'Geometry below cut stem; check coordinate conversion'
        assert self.height_range[0] < bounds['max'][2] < self.height_range[1], 'Unexpected asset height'
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out,self.id+'.blend'))
        colors={role:list(mat.diffuse_color) for role,mat in bc._MATS.items()};colors['OUTLINE']=list(bc.hex_color('#201A20'))
        bc.preview_toon(width=self.outline_width,min_size=.002,cel=0,color='#201A20')
        # Consolidate by shared material to keep a single mesh and few surfaces per stem.
        objects=[o for o in self.root.children_recursive if o.type=='MESH']
        for obj in objects:
            bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
            for mod in list(obj.modifiers):bpy.ops.object.modifier_apply(modifier=mod.name)
        bpy.ops.object.select_all(action='DESELECT')
        for obj in objects:obj.select_set(True)
        bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();bpy.context.object.name=self.id+'_Geometry'
        bpy.context.view_layer.update()
        merged=bpy.context.object
        for axis in range(3):
            values=[(merged.matrix_world@v.co)[axis] for v in merged.data.vertices]
            assert abs(min(values)-bounds['min'][axis]) < .003
            assert abs(max(values)-bounds['max'][axis]) < .003
        path=os.path.join(assets,self.id+'_toon.glb');bc.export_glb(path,self.root)
        raw=open(path,'rb').read();length,kind=struct.unpack_from('<I4s',raw,12);doc=json.loads(raw[20:20+length])
        for mat in doc.get('materials',[]):
            if mat.get('name') in colors:mat['pbrMetallicRoughness']={'baseColorFactor':colors[mat['name']],'metallicFactor':0,'roughnessFactor':1}
            mat['extensions']={'KHR_materials_unlit':{}};mat.pop('emissiveFactor',None)
        doc['extensionsUsed']=['KHR_materials_unlit'];doc.pop('extensionsRequired',None)
        encoded=json.dumps(doc,separators=(',',':')).encode();encoded+=b' '*((-len(encoded))%4);binary=raw[20+length:]
        with open(path,'wb') as f:f.write(struct.pack('<4sII',b'glTF',2,20+len(encoded)+len(binary))+struct.pack('<I4s',len(encoded),b'JSON')+encoded+binary)
        tris=sum(doc['accessors'][p['indices']]['count']//3 for m in doc['meshes'] for p in m['primitives'])
        report={'id':self.id,'source':self.reference,'triangles_with_outlines':tris,'meshes':len(doc['meshes']),'surfaces':sum(len(m['primitives']) for m in doc['meshes']),'height_m':bounds['max'][2],'features':self.features,'head_height_m':self.head_height,'shading':'unlit; inverted hull contours'}
        with open(os.path.join(assets,self.id+'_toon.json'),'w') as f:json.dump(report,f,indent=2)
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out,self.id+'_toon.blend'))
        print('FLOWER_ASSET',json.dumps(report))

def tulip():
    f=Flower('tulip',{'petal':'#E36B95','petal_dark':'#C54F7C'})
    f.stem([(0,0,0),(0,.20,0),(0,.39,0)])
    f.leaf('Long_leaf_left',(0,.035,0),(-.35,.94,.08),.31,.030)
    f.leaf('Long_leaf_right',(0,.075,-.008),(.30,.95,-.12),.30,.032)
    for k in range(6):
        a=k*TAU/6;verts=[];faces=[]
        for i in range(15):
            t=i/14
            for j in range(13):
                s=j/12*2-1;r=.009+.041*math.sin(t*math.pi*.72)
                r+=.0015*s*t;angle=a+s*.64
                y=.385+.109*t+.018*(1-s*s)*t**5
                verts.append((r*math.cos(angle),y,r*math.sin(angle)))
        for i in range(14):
            for j in range(12):
                n=i*13+j;faces.append((n,n+1,n+14,n+13))
        f.surface('Cup_petal_'+str(k+1),verts,faces,'petal_dark' if k%2 else 'petal')
    f.ball('Cup_base',(0,.393,0),(.020,.015,.020),'petal_dark')
    for k in range(6):
        a=k*TAU/6;p=(.012*math.cos(a),.443,.012*math.sin(a))
        f.tube('Stamen',[(p[0],.405,p[2]),p],[.001,.001],'gold',seg=6,sub=0)
        f.ball('Anther',p,(.002,.006,.002),'gold',12)
    f.features={'petals':6,'long_leaves':2,'cup':'hollow'};return f

def lily():
    f=Flower('lily',{'petal':'#FFF7DF','petal_dark':'#EDE3CB','pistil':'#A7AF43','anther':'#E5A324'})
    f.stem()
    for k in range(5):
        s=-1 if k%2==0 else 1
        f.leaf('Lance_leaf_'+str(k),(0,.10+k*.048,0),(s*.65,.76,.05),.115,.013)
    n=(0,.32,.948);f.calyx(r=.026,normal=n)
    f.disk('Throat',(0,.445,.003),.018,.012,'petal_dark',n)
    for k in range(6):f.petal('Recurved_tepal_'+str(k),(0,.445,0),math.pi/2+k*TAU/6,.009,.098,.030,'petal' if k%2 else 'petal_dark',n,curl=.030,pointed=True)
    for k in range(6):
        a=k*TAU/6;p=(.029*math.cos(a),.449+.030*math.sin(a),.063)
        f.tube('Filament_'+str(k),[(0,.445,.009),p],[.001,.0011],'pistil',seg=6,sub=0)
        f.ball('Golden_anther_'+str(k),p,(.003,.009,.003),'anther',14)
    f.tube('Pistil',[(0,.445,.005),(0,.464,.075)],[.0016,.0018],'pistil',seg=8,sub=0)
    f.ball('Stigma',(0,.464,.075),(.004,.003,.004),'pistil',12)
    f.features={'tepals':6,'stamens':6,'pistil':1,'leaves':5};return f

def radial_flower(ident):
    sunflower=ident=='sunflower';poppy=ident=='poppy'
    col='#F8C82B' if sunflower else ('#E83B2D' if poppy else '#FFFAE8')
    f=Flower(ident,{'petal':col,'heart':'#654128' if sunflower else ('#25272A' if poppy else '#EDC128'),'seed':'#352B20','capsule':'#687338'})
    f.stem(r=.005 if sunflower else .0037)
    f.leaves(.038 if sunflower else .020,serrate=.20 if sunflower else (.40 if poppy else .38))
    n=(0,.32,.948);count=4 if poppy else 12;r=.020 if poppy else (.041 if sunflower else .022)
    f.calyx(r=r*.85,count=8 if sunflower else 6,normal=n)
    for k in range(count):
        f.petal('Petal_'+str(k+1),(0,.445,0),math.pi/2+k*TAU/count,r*.70,.064 if sunflower else (.067 if poppy else .061),.018 if sunflower else (.050 if poppy else .013),'petal',n,curl=.018 if poppy else .010,pointed=sunflower,ruffle=.004 if poppy else 0)
    f.disk('Central_disk',(0,.445,.010),r,.012 if sunflower else .008,'heart',n)
    if sunflower:
        for k in range(44):
            a=k*2.399963;r0=.035*math.sqrt((k+.5)/44);x=r0*math.cos(a);y=r0*math.sin(a)
            f.ball('Seed_'+str(k),(x,.445+y*.948,.021-y*.32),(.0011,.0020,.0008),'seed',8)
    if poppy:
        for k in range(16):
            a=k*TAU/16;p=(.027*math.cos(a),.445+.026*math.sin(a),.024)
            f.tube('Black_stamen',[(0,.445,.012),p],[.0006,.0007],'heart',seg=6,sub=0)
            f.ball('Black_anther',p,(.002,.003,.002),'heart',10)
        f.disk('Capsule',(0,.445,.026),.010,.007,'capsule',n,20)
    f.features={'petals':count,'heart':'large brown disk' if sunflower else ('black stamens and capsule' if poppy else 'small golden disk'),'leaves':2};return f

def lavender():
    f=Flower('lavender',{'petal':'#A67ACC','bud':'#70448F','leaf':'#7B9982'})
    f.stem([(0,0,0),(0,.26,0),(0,.52,0)],r=.0028)
    for level in range(3):
        for sx in (-1,1):f.leaf('Narrow_leaf',(0,.075+level*.052,0),(sx*.65,.76,.08),.082,.007)
    for level in range(6):
        y=.287+level*.037
        for k in range(4):
            a=k*TAU/4+.16*(level%2);x=.012*math.cos(a);z=.012*math.sin(a)
            f.ball('Floret_tube',(x,y,z),(.007,.014,.007),'bud',12)
            c=Vector((x,y+.013,z))+Vector((math.cos(a),.2,math.sin(a)))*.007
            for l in range(3):
                da=l*TAU/3;f.ball('Floret_lobe',tuple(c+Vector((.005*math.cos(da),.005*math.sin(da),0))),(.005,.005,.004),'petal',10)
    for k in range(3):f.ball('Tip_bud',((k-1)*.005,.518-abs(k-1)*.004,0),(.005,.012,.005),'bud',12)
    f.features={'floret_tiers':6,'florets_per_tier':4,'narrow_leaves':6};return f

def xeno():
    f=Flower('xeno_bloom',{'petal':'#BEF12C','eye':'#FFFAE8','pupil':'#101014','bead':'#DAFF28'})
    f.stem();f.leaves(.024)
    f.calyx(r=.035,count=5,normal=(0,0,1))
    for k in range(3):
        a=math.pi/2+k*TAU/3
        f.ball('Fleshy_lobe_'+str(k),(.046*math.cos(a),.445+.046*math.sin(a),0),(.040,.044,.016),'petal',28)
    f.ball('Single_eye',(0,.445,.023),(.033,.035,.021),'eye',32)
    f.ball('Large_pupil',(0,.445,.043),(.016,.019,.003),'pupil',24)
    f.ball('Eye_highlight',(-.006,.454,.046),(.003,.004,.0012),'ivory',12)
    f.tube('Antenna',[(0,.472,.011),(.010,.520,.008),(.004,.553,.003)],[.0025,.0022,.002],'green',seg=10)
    f.ball('Antenna_bead',(.004,.553,.003),(.010,.010,.010),'bead',20)
    f.features={'fleshy_lobes':3,'eyes':1,'antennae':1,'leaves':2};return f

def orchid():
    f=Flower('snap_orchid',{'petal':'#D970A8','lip':'#B9487C','mouth':'#3D203D','tooth':'#FFF1CF'})
    f.stem();f.leaves(.030)
    f.calyx(r=.043,count=5,normal=(0,0,1))
    for k in range(5):f.petal('Orchid_petal_'+str(k),(0,.445,-.017),math.pi/2+k*TAU/5,.017,.077,.030,'petal',(0,0,1),curl=.007,pointed=True)
    f.disk('Mouth_cavity',(0,.445,.006),.047,.017,'mouth',(0,0,1))
    for sy in (-1,1):
        pts=[]
        for k in range(17):
            a=math.pi*k/16;pts.append((.047*math.cos(a),.445+sy*.039*math.sin(a),.028+.008*math.sin(a)))
        f.tube('Upper_lip' if sy==1 else 'Lower_lip',pts,[(.008,.012)]*len(pts),'lip',seg=12,sub=0)
        for k in range(5):
            x=(k-2)*.015;y=.445+sy*.033*math.sqrt(max(.05,1-(x/.047)**2))
            f.tube('Tooth_'+str(sy)+'_'+str(k),[(x,y,.034),(x,y-sy*.014,.039)],[.005,.00015],'tooth',seg=10,sub=0)
    f.ball('Golden_pollen',(0,.520,-.009),(.006,.009,.003),'gold',14)
    f.features={'orchid_petals':5,'lips':2,'teeth_per_lip':5,'mouth':'open, static','leaves':2};return f

def pleurelune():
    f=Flower('pleurelune',{'petal':'#A07ACA','inside':'#54346F','drop':'#B9EDFA','leaf':'#719665'})
    f.stem([(0,0,0),(0,.30,0),(-.015,.49,-.017),(0,.537,-.009),(.018,.512,.018)],r=.004)
    f.leaf('Drooping_left',(0,.29,0),(-.65,.3,.1),.17,.024,droop=.17)
    f.leaf('Drooping_right',(0,.29,-.008),(.65,.30,-.08),.17,.024,droop=.18)
    verts=[];faces=[];rings=14;seg=60
    for i in range(rings+1):
        t=i/rings
        for j in range(seg):
            a=j*TAU/seg;r=.010+.023*t+.040*t**4
            r*=1+.075*math.cos(5*a)*t*t
            y=.510-.110*t+.008*math.cos(5*a)*t**5
            verts.append((.018+r*math.cos(a),y,.018+r*math.sin(a)))
    for i in range(rings):
        for j in range(seg):
                a=i*seg+j;b=i*seg+(j+1)%seg;faces.append((a,b,b+seg,a+seg))
    f.surface('Hollow_bell',verts,faces,'petal',.0018,inside='inside')
    f.ball('Bell_cap',(.018,.507,.018),(.014,.010,.014),'green',18)
    for k in range(5):
        a=k*TAU/5;f.leaf('Cap_sepal',(.018,.511,.018),(math.cos(a),-.5,math.sin(a)),.028,.006,'green')
    # Opaque stylized tear, visible beneath the open rim from the front.
    f.tube('Single_tear',[(.018,.410,.049),(.018,.386,.049),(.018,.372,.049),(.018,.366,.049)],[.0004,.007,.010,.0008],'drop',seg=18,sub=4)
    f.features={'bell_lobes':5,'hollow_interior':True,'tears':1,'drooping_leaves':2};return f

builders={'tulip':tulip,'lily':lily,'sunflower':lambda:radial_flower('sunflower'),'daisy':lambda:radial_flower('daisy'),'poppy':lambda:radial_flower('poppy'),'lavender':lavender,'xeno_bloom':xeno,'snap_orchid':orchid,'pleurelune':pleurelune}
if __name__=='__main__':
    args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else IDS
    for ident in args:builders[ident]().finish()
