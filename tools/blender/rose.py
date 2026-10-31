"""Editable cartoon rose from art/concepts/flowers/rose_cartoon.png.
Blender background: --python tools/blender/rose.py
Units: metres, Godot Y up, front +Z. Six outer petals, three inner petals.
"""
import os, sys, math, json, struct
import bpy, bmesh
from mathutils import Vector
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bl_common as bc
from bl_common import G

bc.reset_scene()
root=bc.pivot('Rose',G(0,0,0))
for role,col in {'red':'#D92C36','red_dark':'#AE202B','green':'#638E37','leaf':'#3D702B','ink':'#201A20'}.items():
    bc.material(role,col)

def surface(name,verts,faces,role,thick=.0015):
    me=bpy.data.meshes.new(name);me.from_pydata([G(*p) for p in verts],[],faces);me.update()
    obj=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(obj);bc._parent(obj,root)
    me.materials.append(bc._MATS[role])
    bm=bmesh.new();bm.from_mesh(me);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free()
    for p in me.polygons:p.use_smooth=True
    md=obj.modifiers.new('Petal_thickness','SOLIDIFY');md.thickness=thick
    return obj

axis=Vector((0,.90,.436));axis.normalize()
across=Vector((0,-axis.z,axis.y));center=Vector((0,.445,0))
def head(r,a,h):
    return tuple(center+Vector((1,0,0))*r*math.cos(a)+across*r*math.sin(a)+axis*h)

# A real bowl of overlapping curved surfaces, with a scalloped rounded rim.
for layer,count,radius,height,base in [(0,6,.073,.068,-.043),(1,3,.041,.051,-.018)]:
    for k in range(count):
        a=2*math.pi*k/count+(.38 if layer else .18)
        verts=[];faces=[];nt=12;ns=16
        for i in range(nt+1):
            t=i/nt
            for j in range(ns+1):
                s=j/ns*2-1
                angle=a+s*(.77 if layer==0 else 1.16)
                r=.012+(radius-.012)*math.sin(t*math.pi*.5)
                r+=.006*math.sin(t*math.pi)*math.cos(s*math.pi/2)
                r+=.003*s*t  # curl the overlapping edges off the shared bowl surface
                h=base+height*t+.018*(1-s*s)*t**4
                verts.append(head(r,angle,h))
        for i in range(nt):
            for j in range(ns):
                n=i*(ns+1)+j;faces.append((n,n+1,n+ns+2,n+ns+1))
        surface(('Outer' if layer==0 else 'Inner')+'_petal_'+str(k+1),verts,faces,'red_dark' if (k+layer)%3==0 else 'red')

# Small curled central petal and the readable ink spiral from the drawing.
surface('Closed_corolla_base',[head(0,0,-.014)]+[head(.063,k*math.tau/48,-.014) for k in range(48)],[(0,1+k,1+(k+1)%48) for k in range(48)],'red_dark',.002)
bc.sphere('Heart_fill',.036,head(0,0,0),'red_dark',root,scale=(1,.70,1),seg=28,exact=True)
bc.sphere('Heart',.022,head(0,0,.017),'red',root,scale=(1,.65,1),seg=24,exact=True)
spiral=[]
for i in range(70):
    t=i/69;a=.2+t*math.pi*3.6;r=.003+.024*t
    spiral.append(head(r,a,.035+.003*t))
bc.sweep('Central_spiral',spiral,[.00085]*len(spiral),'ink',root,seg=6,sub=0,extras={'no_outline':True})

stem=[(0,0,0),(.008,.09,0),(-.008,.20,.002),(.006,.31,0),(0,.407,-.017)]
bc.sweep('Curved_stem',stem,[.004,.0044,.0048,.005,.006],'green',root,seg=12,sub=5)

# Five tapered sepals, with volume and a visible green underside.
for k in range(5):
    a=k*math.tau/5
    verts=[]
    for r,da,h in [(.004,-.18,-.044),(.034,-.32,-.049),(.064,0,-.032),(.034,.32,-.049),(.004,.18,-.044)]:verts.append(head(r,a+da,h))
    surface('Calyx_sepal_'+str(k),verts,[(0,1,2,3,4)],'green',.002)
bc.sphere('Calyx_base',.016,(0,.403,-.019),'green',root,scale=(1,1,1),seg=16)

# Two deliberately simple serrated leaves; central ridge carries a single ink vein.
for k,(origin,direction,length,width) in enumerate([((-.005,.235,.003),(-.76,.65,.07),.119,.027),((-.006,.135,.004),(.80,.60,.10),.128,.030)]):
    o=Vector(origin);d=Vector(direction).normalized();side=Vector((-d.y,d.x,0)).normalized()
    verts=[];faces=[];vein=[]
    for i in range(15):
        t=i/14;c=o+d*length*t+Vector((0,0,.009*math.sin(math.pi*t)))
        w=width*math.sin(math.pi*t)**.8*(1 if i%2 else .77)
        verts.extend([tuple(c-side*w),tuple(c+Vector((0,0,.003*math.sin(math.pi*t)))),tuple(c+side*w)])
        vein.append(tuple(c+Vector((0,0,.004))))
        if i:
            n=(i-1)*3;faces.extend([(n,n+3,n+4,n+1),(n+1,n+4,n+5,n+2)])
    surface('Serrated_leaf_'+str(k+1),verts,faces,'leaf',.0018)
    bc.sweep('Leaf_vein_'+str(k+1),vein,[.0007]*len(vein),'ink',root,seg=6,sub=0,extras={'no_outline':True})

for k,(x,y,sign) in enumerate([(.006,.075,1),(-.006,.185,-1),(.002,.295,1)]):
    bc.sweep('Thorn_'+str(k+1),[(x,y,0),(x+sign*.014,y+.007,.001),(x+sign*.023,y+.018,0)],[.004,.0035,.0002],'green',root,seg=8,sub=0)

out=os.path.join(bc.ROOT,'art','blender','flowers');os.makedirs(out,exist_ok=True)
assets=os.path.join(bc.ROOT,'assets','models','flowers');os.makedirs(assets,exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out,'rose.blend'))
bc.preview_toon(width=.00085,min_size=.003,cel=0,color='#201A20')
path=os.path.join(assets,'rose_toon.glb')
bc.export_glb(path,root)
# Explicit unlit contract, shared with the character assets.
raw=open(path,'rb').read();length,kind=struct.unpack_from('<I4s',raw,12);doc=json.loads(raw[20:20+length])
for mat in doc.get('materials',[]):
    col=bc._MATS.get(mat.get('name'))
    if col:mat['pbrMetallicRoughness']={'baseColorFactor':list(col.diffuse_color),'metallicFactor':0,'roughnessFactor':1}
    mat['extensions']={'KHR_materials_unlit':{}};mat.pop('emissiveFactor',None)
doc['extensionsUsed']=['KHR_materials_unlit'];doc.pop('extensionsRequired',None)
encoded=json.dumps(doc,separators=(',',':')).encode();encoded+=b' '*((-len(encoded))%4)
binary=raw[20+length:];total=20+len(encoded)+len(binary)
with open(path,'wb') as f:f.write(struct.pack('<4sII',b'glTF',2,total)+struct.pack('<I4s',len(encoded),b'JSON')+encoded+binary)
tris=sum(doc['accessors'][p['indices']]['count']//3 for m in doc['meshes'] for p in m['primitives'])
report={'triangles_with_outlines':tris,'outer_petals':6,'inner_petals':3,'leaves':2,'thorns':3,'height_m':.52,'source':'art/concepts/flowers/rose_cartoon.png','shading':'unlit; inverted hull contours'}
with open(os.path.join(assets,'rose_toon.json'),'w') as f:json.dump(report,f,indent=2)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out,'rose_toon.blend'))
print('ROSE_ASSET',json.dumps(report))
