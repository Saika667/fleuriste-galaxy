"""Six editable character assets reconstructed from the user's second reference set.
Run in Blender: --python tools/blender/characters/cast_v2.py -- <identifier>.
"""
import os, sys, math, random, json, struct
import bpy, bmesh
from mathutils import Vector
from mathutils.bvhtree import BVHTree
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from remaining_cast import Model, profile_at, orient_spot
import bl_common as bc
from bl_common import G
from scientist_export import export
PI=math.pi
GEL_OPACITY=.46

def fuse_gel(m):
    """One outer skin, with smooth weights transferred from the original limbs."""
    bpy.context.view_layer.update();objects=[];trees={}
    for bone,part in m.parts.items():
        verts=[];faces=[]
        for obj in list(part.children):
            if obj.type!='MESH' or not obj.data.materials or obj.data.materials[0].name!='gel':continue
            objects.append(obj)
            for mod in list(obj.modifiers):obj.modifiers.remove(mod)
            bm=bmesh.new();bm.from_mesh(obj.data)
            bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00001)
            bmesh.ops.holes_fill(bm,edges=[e for e in bm.edges if e.is_boundary],sides=0)
            bmesh.ops.recalc_face_normals(bm,faces=bm.faces);bm.to_mesh(obj.data);bm.free()
            offset=len(verts);verts.extend(obj.matrix_world@v.co for v in obj.data.vertices)
            faces.extend(tuple(offset+i for i in p.vertices) for p in obj.data.polygons)
        if verts:trees[bone]=BVHTree.FromPolygons(verts,faces)
    bpy.ops.object.select_all(action='DESELECT')
    for obj in objects:obj.select_set(True)
    skin=objects[0];bpy.context.view_layer.objects.active=skin;bpy.ops.object.join()
    skin.name='Continuous_gel_skin';skin['no_outline']=True;skin['preweighted']=True
    mod=skin.modifiers.new('Union_outer_skin','REMESH');mod.mode='VOXEL';mod.voxel_size=.0045;mod.use_smooth_shade=True
    bpy.ops.object.modifier_apply(modifier=mod.name)
    mod=skin.modifiers.new('Smooth_join','SMOOTH');mod.factor=.6;mod.iterations=4
    bpy.ops.object.modifier_apply(modifier=mod.name)
    mod=skin.modifiers.new('Simplify_skin','DECIMATE');mod.ratio=.28
    bpy.ops.object.modifier_apply(modifier=mod.name)
    skin.data.materials.clear();skin.data.materials.append(bc._MATS['gel'])
    groups={n:skin.vertex_groups.new(name=n) for n in trees}
    for v in skin.data.vertices:
        p=skin.matrix_world@v.co
        near=sorted((tree.find_nearest(p)[3],name) for name,tree in trees.items())[:4]
        weights=[(name,math.exp(-max(0,d-near[0][0])**2/.018**2)) for d,name in near]
        total=sum(w for n,w in weights)
        for name,w in weights:
            if w/total>.001:groups[name].add([v.index],w/total,'REPLACE')
    for p in skin.data.polygons:p.use_smooth=True
    # No internal arm caps, crest overlaps or foot intersections remain.
    assert sum(1 for obj in m.root.children_recursive if obj.type=='MESH' and obj.data.materials and obj.data.materials[0].name=='gel')==1

def projected_line(m,obj,n,points,b,c='seam',rear=False,r=.0013):
    bpy.context.view_layer.update();inv=obj.matrix_world.inverted();out=[]
    for x,y in points:
        hit=obj.ray_cast(inv@G(x,y,-.8 if rear else .8),inv.to_3x3()@G(0,0,1 if rear else -1))
        if hit[0]:
            p=obj.matrix_world@hit[1];out.append((p.x,p.z,-p.y+(-.002 if rear else .002)))
    if len(out)>1:m.line(n,out,c,b,r=r,sub=3)

class Cast(Model):
    def rock(self,n,p,s,c,b='chest',seed=0):
        rng=random.Random(seed);bm=bmesh.new()
        bmesh.ops.create_icosphere(bm,subdivisions=2,radius=1)
        for v in bm.verts:
            r=1+rng.uniform(-.09,.09);v.co=Vector((v.co.x*s[0]*r,-v.co.y*s[2]*r,v.co.z*s[1]*r))
        return bc._finish(n,bm,G(*p),c,self.part(b),smooth=False)
    def patch(self,n,x,y,z,rx,ry,c,b='chest',normal=(0,0,1)):
        obj=self.ball(n,(x,y,z),(rx,ry,.002),c,b,seg=20,detail=True)
        orient_spot(obj,normal);return obj
    def limb(self,side,a,e,w,r,c='skin',label='',hand=True):
        up='upper_arm'+label+'.'+side;lo='forearm'+label+'.'+side;h='hand'+label+'.'+side
        self.bone(up,a,e,'chest');self.bone(lo,e,w,up)
        self.bone(h,w,(w[0],w[1]-.075,w[2]+.015),lo)
        self.tube('Upper_arm'+label+side,[a,e],[r,r*.85],c,up,sub=0,cap0='flat')
        self.tube('Lower_arm'+label+side,[e,w],[r*.85,r*.60],c,lo,sub=0)
        if hand:self.hand('Hand'+label+side,(w[0],w[1]-.03,w[2]+.008),r*1.5,h,c)
        return up,lo,h
    def bare_leg(self,side,a,k,w,r,c='skin',toes=3):
        t='thigh.'+side;s='shin.'+side;f='foot.'+side
        self.bone(t,a,k,'pelvis');self.bone(s,k,w,t);self.bone(f,w,(w[0],.045,w[2]+.14),s)
        self.tube('Thigh'+side,[a,k],[r,r*.85],c,t,sub=0)
        self.tube('Shin'+side,[k,w],[r*.85,r*.65],c,s,sub=0)
        self.ball('Foot'+side,(w[0],.055,w[2]+.055),(r*1.65,.046,.10),c,f)
        for j in range(toes):
            x=w[0]+(j-(toes-1)/2)*r*.95
            self.ball('Toe'+side+str(j),(x,.041,w[2]+.125),(r*.61,.032,.065),c,f,seg=22)
        return t,s,f
    def finish(self):
        data=bpy.data.armatures.new(self.name+'Skeleton');arm=bpy.data.objects.new(self.name+'Skeleton',data)
        bpy.context.collection.objects.link(arm);arm.parent=self.root
        bpy.ops.object.select_all(action='DESELECT');arm.select_set(True);bpy.context.view_layer.objects.active=arm
        bpy.ops.object.mode_set(mode='EDIT')
        for n,a,b,p in self.specs:
            bone=data.edit_bones.new(n);bone.head=G(*a);bone.tail=G(*b)
            if p:bone.parent=data.edit_bones[p]
        bpy.ops.object.mode_set(mode='OBJECT');bpy.context.view_layer.update()
        for bone,part in self.parts.items():
            assert bone in data.bones
            for obj in part.children_recursive:
                if obj.type!='MESH':continue
                if not obj.get('preweighted'):
                    group=obj.vertex_groups.new(name=bone);group.add(list(range(len(obj.data.vertices))),1,'REPLACE')
                mod=obj.modifiers.new('Skeleton','ARMATURE');mod.object=arm
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(bc.ROOT,'art/blender/'+self.name+'.blend'))
        bc.preview_toon(width=.0012,min_size=.008,cel=0)
        if self.name=='gel_bleu':
            # Transparency is retained in the native Blender preview and patched
            # explicitly in GLB, since the common exporter resets base colors.
            mat=bc._MATS['gel'];nt=mat.node_tree;nt.nodes.clear()
            out=nt.nodes.new('ShaderNodeOutputMaterial');mix=nt.nodes.new('ShaderNodeMixShader')
            trans=nt.nodes.new('ShaderNodeBsdfTransparent');em=nt.nodes.new('ShaderNodeEmission')
            em.inputs['Color'].default_value=bc.hex_color('#6CCCF2');mix.inputs[0].default_value=GEL_OPACITY
            nt.links.new(trans.outputs[0],mix.inputs[1]);nt.links.new(em.outputs[0],mix.inputs[2]);nt.links.new(mix.outputs[0],out.inputs[0])
            mat.surface_render_method='DITHERED'
        path=os.path.join(bc.ROOT,'assets/models/characters/'+self.name+'_toon.glb')
        export(self.root,path)
        if self.name=='gel_bleu':patch_gel(path)
        views={k:dict(yaw=y,elev=0,focus=(0,self.height*.49,0),dist=self.height*6.9) for k,y in [('front',0),('back',180),('three_quarter',30)]}
        bc.render_preview(os.path.join(bc.ROOT,'out/blender/'+self.name),views=views,res=(900,1100),floor=False,bg='#FBFAF5',key_only=True,lens=200)
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(bc.ROOT,'art/blender/'+self.name+'_toon.blend'))

def patch_gel(path):
    raw=open(path,'rb').read();length=struct.unpack_from('<I',raw,12)[0]
    doc=json.loads(raw[20:20+length]);found=False
    for mat in doc['materials']:
        if mat.get('name')=='gel':
            mat['alphaMode']='BLEND';mat['doubleSided']=False
            mat['pbrMetallicRoughness']['baseColorFactor']=list(bc.hex_color('#6CCCF2')[:3])+[GEL_OPACITY]
            found=True
    assert found,'Missing translucent gel material'
    encoded=json.dumps(doc,separators=(',',':')).encode();encoded+=b' '*((-len(encoded))%4)
    binary=raw[20+length:];total=20+len(encoded)+len(binary)
    with open(path,'wb') as f:f.write(struct.pack('<4sIII4s',b'glTF',2,total,len(encoded),b'JSON')+encoded+binary)
    report_path=os.path.splitext(path)[0]+'.json';report=json.load(open(report_path,encoding='utf-8'))
    report.update(bytes=total,translucent_shell={'material':'gel','alpha':GEL_OPACITY,'mode':'BLEND','continuous_skin':True})
    json.dump(report,open(report_path,'w',encoding='utf-8'),indent=2,ensure_ascii=False)

def face(m,cy=1.65,rx=.108,hy=.145,female=False):
    m.ball('Face',(0,cy,0),(rx,hy,.099),'skin','head',seg=48)
    def surf(x,y):return .099*math.sqrt(max(.01,1-(x/rx)**2-((y-cy)/hy)**2))
    for sx in (-1,1):
        x=sx*.044;y=cy+.021;z=surf(x,y)+.006
        m.eye(str(sx),x,y,z,.043,.049,.028,pupil_ratio=.20)
        m.ball('Ear',(sx*.111,cy-.015,-.006),(.023,.033,.021),'skin','head')
        m.line('Ear_fold',[(sx*.115,cy+.002,.015),(sx*.123,cy+.008,.017),(sx*.122,cy-.028,.017)],'skin_line','head',r=.001)
        m.line('Brow',[(sx*.016,cy+.081,.087),(sx*.042,cy+.089,.086),(sx*.077,cy+.079,.075)],'hair','head',r=.0033 if female else .004)
        if female:
            for k in range(2):m.line('Eyelash',[(sx*(.073+k*.007),cy+.052+k*.009,.108),(sx*(.085+k*.009),cy+.065+k*.009,.106)],r=.0012)
    m.tube('Nose',[(0,cy+.014,.095),(0,cy-.018,.137),(-.002,cy-.044,.126)],[(.009,.008),(.015,.017),(.009,.009)],'skin','head',seg=22)
    if female:
        m.ball('Open_smile',(0,cy-.073,.086),(.040,.023,.008),'mouth','head',seg=32)
        m.ball('Tongue',(.012,cy-.083,.093),(.019,.009,.003),'tongue','head',seg=20,detail=True)
        m.flat('Teeth',[(-.025,cy-.057,.097),(.026,cy-.057,.097),(.020,cy-.066,.098),(-.023,cy-.068,.098)],'eye','head')
    else:
        m.line('Wry_smile',[(-.035,cy-.070,.087),(-.007,cy-.075,.092),(.027,cy-.069,.089),(.041,cy-.060,.079)],r=.0015)
        m.line('Forehead_fold',[(-.04,cy+.112,.064),(0,cy+.107,.071),(.04,cy+.115,.060)],'skin_line','head',r=.0009)
        rng=random.Random(50)
        for k in range(37):
            x=rng.uniform(-.07,.07);y=rng.uniform(cy-.132,cy-.062)
            if abs(x)<.04 and y>cy-.082:continue
            z=surf(x,y)+.002
            m.line('Stubble'+str(k),[(x,y,z),(x+.001,y+.004,z)],'hair','head',r=.0007,sub=0)
    return surf

def tousled_hair(m,female=False):
    bc.dome('Hair_cap',1,lambda a:.045 if abs(a)<1.0 else -.075,(0,1.69,-.008),'hair',m.part('head'),scale=(.12,.118,.111),rings=16,seg=56,subsurf=0,thick=.003)
    def lock(n,pts,widths,depth=.022):
        top=max(widths)
        return m.tube(n,pts,[(max(.0006,depth*w/top),w) for w in widths],'hair','head',ref=(0,0,1),seg=26,sub=8,cap_len=.25)
    if not female:
        clumps=[([(-.075,1.77,.02),(-.116,1.815,.008),(-.16,1.83,-.008)],[.035,.025,.0006]),
                ([(-.04,1.79,.015),(-.070,1.852,0),(-.11,1.868,-.015)],[.038,.028,.0006]),
                ([(.008,1.79,.01),(-.004,1.863,-.005),(-.045,1.886,-.02)],[.035,.026,.0006]),
                ([(.05,1.78,.01),(.09,1.841,-.008),(.137,1.854,-.025)],[.036,.027,.0006]),
                ([(.085,1.76,.0),(.128,1.785,-.013),(.163,1.774,-.028)],[.029,.021,.0006])]
        for k,(pts,widths) in enumerate(clumps):lock('Wild_lock'+str(k),pts,widths)
        for k in range(4):
            x=-.07+k*.045
            lock('Back_crown_lock',[(x,1.755,-.075),(x+.025,1.806,-.10),(x+.058,1.813,-.12)],[.030,.020,.0007],.027)
        lock('Asymmetric_forelock',[(.071,1.787,.056),(.018,1.818,.075),(-.053,1.782,.095),(-.089,1.744,.061)],[.025,.030,.022,.0007],.018)
        for sx in (-1,1):
            for k in range(3):lock('Side_lock',[(sx*.095,1.70-k*.045,-.035),(sx*.13,1.70-k*.045,-.055),(sx*.14,1.66-k*.045,-.070)],[.027,.023,.0007])
            lock('Above_ear_upper_lock',[(sx*.100,1.738,.014),(sx*.125,1.744,.018),(sx*.147,1.731,.014)],[.016,.012,.0006],.014)
            lock('Above_ear_lower_lock',[(sx*.108,1.713,.015),(sx*.132,1.714,.019),(sx*.149,1.695,.016)],[.014,.010,.0006],.013)
            m.tube('Gray_temple',[(sx*.10,1.74,.019),(sx*.114,1.70,.012),(sx*.111,1.67,.009)],[.012,.010,.001],'gray','head',seg=14)
    else:
        lock('Swept_fringe',[(.08,1.80,.05),(.02,1.807,.085),(-.06,1.765,.085),(-.102,1.70,.04)],[.028,.032,.025,.004])
        lock('Long_face_lock',[(-.092,1.745,.045),(-.112,1.65,.042),(-.12,1.53,.049),(-.10,1.49,.043)],[.021,.020,.014,.0007],.016)
        m.ball('Ponytail_tie',(.061,1.825,-.097),(.042,.033,.030),'pants','head')
        m.ball('High_ponytail',(.108,1.814,-.14),(.078,.137,.075),'hair','head',seg=40)
        for k in range(5):
            lock('Ponytail_tip'+str(k),[(.073+k*.017,1.78,-.13),(.086+k*.019,1.68,-.14),(.09+k*.027,1.60+.018*(k%2),-.13)],[.034,.026,.0007],.028)

def boots(m,side,x,y=.17):
    f='foot.'+side
    m.tube('Boot_shaft'+side,[(x,.09,0),(x,y+.04,0)],[.050,.045],'shoe',f,sub=0)
    for yy,zz in ((.11,.085),(.15,.055),(.205,.037)):
        m.tube('Boot_strap'+side,[(x-.043,yy,zz),(x,yy+.013,zz+.009),(x+.043,yy,zz)],[(.006,.016)]*3,'trim',f,seg=12,ref=(0,1,0),cap_len=.2)
    m.box('Boot_heel_patch'+side,(x,.095,-.072),(.060,.035,.009),'trim',f,.004)

def cargo(m,side,x,heroine=False):
    t='thigh.'+side
    if side=='L':
        m.box('Cargo_pocket'+side,(x+.038,.69,.061),(.081,.18,.032),'pants',t,.009)
        m.box('Cargo_flap'+side,(x+.038,.755,.082),(.087,.040,.012),'trim',t,.004)
        m.box('Cargo_tag'+side,(x+.052,.670,.081),(.010,.065,.004),'light' if heroine else 'sole',t,.002)
    m.box('Knee_pad'+side,(x,.43,.052),(.068,.12,.013),'trim','shin.'+side,.011)

def radio(m,n,p,c='light',b='pelvis'):
    x,y,z=p;m.box(n,p,(.054,.097,.034),'metal',b,.008)
    m.box(n+'_screen',(x,y+.004,z+.020),(.018,.058,.004),c,b,.002)
    m.tube(n+'_aerial',[(x+.014,y+.048,z),(x+.014,y+.096,z)],[.003,.0024],'metal',b,seg=10,sub=0)
    m.ball(n+'_tip',(x+.014,y+.097,z),(.005,.005,.005),c,b,seg=12)

def explorer(heroine=False):
    ident='heroine' if heroine else 'aventurier'
    m=Cast(ident,dict(skin='#E7B58B',skin_line='#AB805D',hair='#493724',gray='#969285',shirt='#333E42',jacket='#83483F' if heroine else '#62553D',jacket_line='#382C27',pants='#56583A',trim='#424432',shoe='#393C3D' if heroine else '#403C33',sole='#B3AA94',metal='#666C68',light='#86E5EB' if heroine else '#99CBAE',mouth='#532527',tongue='#D38488',gold='#C5983D'),1.97 if heroine else 1.94)
    if heroine:
        m.rings('Bare_waist',[(1.13,.085,.061,0),(1.04,.076,.055,0),(.945,.10,.071,0)],'skin','spine')
        m.rings('Crop_top',[(1.395,.049,.043,0),(1.34,.127,.085,0),(1.14,.089,.069,.003)],'shirt','chest')
        bottom=1.10
        m.line('Navel',[(0,1.027,.058),(.003,1.022,.059),(0,1.016,.058)],'skin_line','spine',r=.001)
    else:
        m.rings('Shirt',[(1.40,.053,.045,0),(1.33,.143,.089,0),(1.10,.12,.086,0),(.94,.119,.083,0)],'shirt','spine')
        m.line('Shirt_crease',[(-.045,1.01,.087),(0,.999,.092),(.055,1.012,.086)],'ink','spine',r=.001)
        bottom=.94
    m.rings('Open_jacket',[(1.42,.058,.051,0),(1.35,.153,.101,0),(1.20,.143,.101,0),(bottom,.126 if not heroine else .109,.088,0)],'jacket','chest',opening=.64,seg=64)
    m.rings('Raised_collar',[(1.48,.075,.068,0),(1.40,.08,.065,0)],'jacket','chest',opening=.69,seg=44,sub=1)
    for sx in (-1,1):
        m.line('Jacket_edge',[(sx*.039,1.47,.054),(sx*.065,1.35,.088),(sx*(.077 if not heroine else .066),bottom,.073)],'jacket_line','chest',r=.002)
        m.line('Back_panel_seam',[(sx*.10,1.34,-.076),(sx*.09,1.16,-.079),(sx*.09,bottom+.03,-.068)],'jacket_line','chest',r=.0012)
    m.line('Back_yoke',[(-.12,1.33,-.068),(0,1.32,-.106),(.12,1.33,-.068)],'jacket_line','chest',r=.0015)
    m.tube('Neck',[(0,1.39,0),(0,1.54,.004)],[.038,.036],'skin','neck')
    face(m,female=heroine);tousled_hair(m,heroine)
    m.rings('Trouser_hips',[(.977,.112,.076,0),(.87,.132,.086,0),(.79,.113,.075,0)],'pants','pelvis',seg=48)
    m.rings('Belt',[(.984,.117,.081,0),(.951,.121,.084,0)],'trim','pelvis',seg=48,sub=0)
    m.box('Buckle',(0,.965,.092),(.057,.040,.011),'metal','pelvis',.004)
    m.box('Buckle_inset',(0,.965,.099),(.036,.024,.003),'trim','pelvis',.002)
    for sx in (-1,1):
        side='R' if sx<0 else 'L';x=sx*.076
        m.leg(side,(x,.87,0),(sx*.09,.48,0),(sx*.11,.17,0),.060,'pants')
        boots(m,side,sx*.11);cargo(m,side,x,heroine)
        m.box('Belt_pouch',(sx*.11,.968,.054),(.044,.049,.038),'trim','pelvis',.007)
        a=(sx*.13,1.35,0);e=(sx*.22,1.15,.015);w=(sx*.163,.921,.085)
        if heroine and sx<0:e=(-.255,1.195,.015);w=(-.355,1.415,.067)
        up,lo,h=m.limb(side,a,e,w,.031,hand=False)
        m.tube('Jacket_upper_sleeve'+side,[a,e],[.045,.043],'jacket',up,sub=0,cap0='flat')
        # Rolled sleeve ends leave exposed forearms.
        yy=1.13 if not (heroine and sx<0) else 1.23
        end=(e[0]+(w[0]-e[0])*.18,e[1]+(w[1]-e[1])*.18,e[2]+(w[2]-e[2])*.18)
        m.tube('Rolled_cuff'+side,[e,end],[.048,.046],'jacket' if heroine else 'trim',lo,sub=0,cap0='flat',cap1='flat')
        m.ball('Shoulder_pad'+side,(sx*.142,1.341,.002),(.044,.054,.052),'metal' if heroine else 'trim',up)
        m.box('Shoulder_panel'+side,(sx*.148,1.344,.051),(.040,.019,.006),'light',up,.003)
        if heroine:m.box('Sleeve_rank'+side,(sx*.176,1.286,.043),(.038,.015,.006),'gold',up,.002)
        if not (heroine and sx<0):
            # Hands rest inside the trouser pockets, with the thumb visible.
            m.ball('Pocket_hand'+side,(w[0],w[1]-.016,w[2]),(.025,.045,.020),'skin',h)
            m.tube('Pocket_thumb'+side,[(w[0]-sx*.015,w[1]+.009,w[2]+.006),(w[0]-sx*.017,w[1]-.027,w[2]+.016)],[.010,.009],'skin',h,seg=14,sub=0)
            m.line('Pocket_opening'+side,[(sx*.114,.939,.055),(sx*.156,.892,.064)],'ink','pelvis',r=.0014)
        else:
            m.ball('Peace_palm',(-.36,1.455,.077),(.029,.038,.019),'skin',h)
            for j,(dx,dy) in enumerate([(-.033,.115),(.015,.127)]):
                m.tube('Peace_finger'+str(j),[(-.365+dx*.3,1.478,.08),(-.365+dx*.8,1.52,.080),(-.365+dx,1.478+dy,.079)],[.009,.0085,.007],'skin',h,seg=16)
            for k in range(2):m.ball('Folded_finger',(-.35+k*.012,1.446,.096),(.010,.016,.008),'skin',h,seg=18)
            m.tube('Peace_thumb',[(-.386,1.448,.095),(-.37,1.46,.106),(-.35,1.457,.106)],[.010,.009,.007],'skin',h,seg=16)
            m.tube('Wrist_computer',[(-.350,1.386,.065),(-.360,1.417,.069)],[.035,.035],'metal',lo,seg=20,cap0='flat',cap1='flat',sub=0)
            m.box('Wrist_screen',(-.355,1.40,.103),(.032,.023,.005),'light',lo,.003)
    radio(m,'Belt_device',((-.14 if heroine else .145),.945,.074))
    if heroine:
        for sx in (-1,1):m.box('Boot_light',(sx*.11,.185,.048),(.010,.044,.004),'light','foot.'+('R' if sx<0 else 'L'),.002)
    return m

def reptile_mecano():
    m=Cast('reptile_mecano',dict(skin='#EE982C',belly='#F5CA79',spot='#CD772D',crest='#B9512B',pants='#505438',stain='#393E28',shirt='#DDD3A2',strap='#383D29',shoe='#EE982C',sole='#292C29',metal='#777D76',trim='#9B9D8D',belt='#62462B',light='#8BDA62',red='#7C3025'),1.96)
    m.rings('Sleeveless_shirt',[(1.40,.050,.043,0),(1.34,.123,.082,0),(1.10,.118,.08,0),(.94,.119,.078,0)],'shirt','chest')
    m.rings('Overall_waist',[(1.02,.126,.085,0),(.86,.133,.09,0),(.78,.11,.075,0)],'pants','pelvis')
    m.flat('Overall_bib',[(-.084,1.28,.090),(.084,1.28,.090),(.105,.995,.093),(-.105,.995,.093)],'pants')
    m.box('Bib_pocket',(0,1.17,.097),(.109,.099,.009),'pants','chest',.008)
    m.line('Bib_pocket_seam',[(-.054,1.215,.105),(-.052,1.125,.106),(.052,1.125,.106),(.054,1.215,.105)],'strap','chest',r=.001)
    for sx in (-1,1):
        m.line('Overall_shoulder_strap',[(sx*.073,1.285,.094),(sx*.10,1.415,.024),(sx*.096,1.34,-.076),(sx*.080,1.23,-.092)],'strap','chest',r=.013)
        m.flat('Overall_back_panel',[(sx*.080,1.23,-.092),(sx*.013,1.21,-.096),(sx*.03,1.00,-.093),(sx*.12,1.00,-.066)],'pants')
        m.box('Strap_buckle',(sx*.073,1.31,.106),(.029,.035,.010),'metal','chest',.003)
        m.ball('Bib_rivet',(sx*.078,1.275,.105),(.005,.005,.003),'trim','chest',seg=14)
    m.tube('Long_neck',[(0,1.37,0),(0,1.52,.021),(0,1.66,.035)],[.041,.039,.044],'skin','neck',seg=28)
    m.tube('Neck_underside',[(0,1.39,.037),(0,1.52,.062),(0,1.65,.072)],[(.025,.005),(.025,.006),(.028,.005)],'belly','neck',seg=20)
    for k in range(4):m.line('Neck_plate', [(-.022,1.43+k*.046,.061),(0,1.425+k*.046,.069),(.022,1.43+k*.046,.061)],'spot','neck',r=.0009)
    m.ball('Reptile_skull',(0,1.77,.012),(.114,.154,.105),'skin','head',seg=44)
    m.tube('Long_snout',[(0,1.705,.050),(0,1.685,.13),(0,1.666,.198)],[(.080,.05),(.075,.037),(.053,.025)],'skin','head',seg=32,ref=(1,0,0))
    m.ball('Lower_jaw',(0,1.645,.123),(.070,.019,.097),'belly','head',seg=30)
    for sx in (-1,1):
        m.eye(str(sx),sx*.047,1.794,.101,.043,.051,.031,pupil_ratio=.20)
        m.patch('Nostril',sx*.024,1.681,.219,.003,.005,'strap','head')
        m.line('Smile',[(sx*.022,1.644,.208),(sx*.060,1.659,.164),(sx*.083,1.685,.104)],'strap','head',r=.0015)
        m.line('Brow',[(sx*.019,1.862,.075),(sx*.05,1.871,.075),(sx*.079,1.86,.064)],'strap','head',r=.0014)
    bpy.context.view_layer.update()
    smile=[]
    for j in range(31):
        x=-.066+j*.132/30;y=1.645+.020*(x/.066)**2;front=-1
        for obj in [bpy.data.objects['Reptile_skull'],bpy.data.objects['Long_snout'],bpy.data.objects['Lower_jaw']]:
            inv=obj.matrix_world.inverted();hit=obj.ray_cast(inv@G(x,y,.8),inv.to_3x3()@G(0,0,-1))
            if hit[0]:front=max(front,-(obj.matrix_world@hit[1]).y)
        if front>-1:smile.append((x,y,front+.002))
    m.line('Surface_following_smile',smile,'strap','head',r=.0017,sub=0)
    # Thick red crest, visible in profile and on the back of the head.
    for k,(y,z) in enumerate([(1.90,-.012),(1.85,-.073),(1.78,-.092),(1.70,-.084),(1.64,-.063)]):
        m.tube('Crest_fin'+str(k),[(0,y,z),(0,y+.018,z-.070),(0,y+.050,z-.094)],[(.020,.038),(.015,.036),(.001,.001)],'crest','head',ref=(1,0,0),seg=18)
    for k,y in enumerate([1.90,1.84,1.77,1.70,1.64]):
        m.tube('Visible_crest_fan'+str(k),[(.052,y,-.071),(.117,y+.035,-.079),(.153,y+.023,-.076)],[(.028,.022),(.031,.017),(.001,.001)],'crest','head',ref=(0,1,0),seg=18)
    m.bone('tail',(0,.86,-.08),(.25,.36,-.26),'pelvis');m.bone('tail_tip',(.25,.36,-.26),(.46,.56,-.11),'tail')
    tail=m.tube('Long_tail',[(0,.86,-.08),(.075,.58,-.20),(.24,.34,-.24),(.42,.33,-.20),(.49,.46,-.13),(.46,.65,-.11)],[.068,.063,.052,.037,.022,.001],'skin','tail',seg=30,sub=6)
    m.tube('Tail_underside',[(.02,.74,-.145),(.10,.48,-.15),(.26,.30,-.195),(.42,.31,-.17)],[(.032,.007),(.033,.008),(.026,.006),(.006,.003)],'belly','tail',seg=18)
    for sx in (-1,1):
        side='R' if sx<0 else 'L';x=sx*.077
        m.leg(side,(x,.85,0),(sx*.085,.48,0),(sx*.10,.15,0),.054,'pants',shoe='skin')
        # Bare orange feet with three black claws replace shoes and soles.
        f='foot.'+side
        for obj in list(m.part(f).children):bpy.data.objects.remove(obj,do_unlink=True)
        m.ball('Bare_foot'+side,(sx*.10,.065,.047),(.073,.042,.11),'skin',f)
        m.tube('Bare_ankle'+side,[(sx*.10,.175,0),(sx*.10,.075,0)],[.029,.031],'skin','shin.'+side,seg=20,sub=0)
        for j in range(3):
            xx=sx*.10+(j-1)*.047
            m.tube('Toe'+side+str(j),[(xx,.058,.094),(xx,.041,.165)],[.026,.022],'skin',f,seg=18,sub=0)
            m.tube('Black_claw'+side+str(j),[(xx,.046,.165),(xx,.032,.194),(xx,.023,.203)],[.022,.015,.001],'sole',f,seg=16)
        m.tube('Rolled_trouser_hem'+side,[(sx*.10,.19,0),(sx*.10,.225,0)],[.046,.047],'pants','shin.'+side,seg=24,sub=0,cap0='flat',cap1='flat')
        m.box('Overall_cargo'+side,(x+sx*.037,.68,.057),(.062,.15,.025),'pants','thigh.'+side,.007)
        m.box('Overall_cargo_flap'+side,(x+sx*.037,.735,.073),(.066,.033,.008),'strap','thigh.'+side,.003)
        if sx<0:a,e,w=(-.105,1.32,0),(-.25,1.10,.055),(-.34,1.365,.095)
        else:a,e,w=(.105,1.32,0),(.18,1.10,.009),(.23,.875,.03)
        up,lo,h=m.limb(side,a,e,w,.030,hand=sx>0)
        if sx<0:
            m.ball('Tool_grip',(-.34,1.395,.10),(.036,.045,.025),'skin',h)
            for j in range(3):
                yy=1.375+j*.021
                m.tube('Gripping_finger',[(-.37,yy,.112),(-.345,yy+.009,.136),(-.317,yy+.005,.127)],[.009,.01,.008],'skin',h,seg=14)
            m.box('Wrench_handle',(-.34,1.46,.094),(.026,.24,.014),'metal',h,.007)
            m.loop('Wrench_handle_hole',(-.34,1.36,.107),.008,.010,'strap',h,r=.002)
            # Open U-shaped jaw, not a solid disk.
            m.tube('Wrench_jaw',[(-.377,1.63,.094),(-.385,1.586,.094),(-.369,1.566,.094),(-.311,1.566,.094),(-.295,1.59,.094),(-.304,1.63,.094)],[.011]*6,'metal',h,seg=16,sub=2,cap0='flat',cap1='flat')
        for k in range(5):
            aa,bb=(a,e) if k<2 else (e,w);t=(k+1)/3 if k<2 else (k-1)/4
            xx=aa[0]+(bb[0]-aa[0])*t;yy=aa[1]+(bb[1]-aa[1])*t;zz=aa[2]+(bb[2]-aa[2])*t+.026*(1-.12*k)
            m.patch('Arm_spot',xx,yy,zz,.007,.012,'spot',up if k<2 else lo)
    m.rings('Tool_belt',[(1.006,.131,.092,0),(.963,.135,.095,0)],'belt','pelvis',seg=48,sub=0)
    m.box('Belt_buckle',(0,.984,.103),(.065,.041,.011),'metal','pelvis',.004)
    radio(m,'Mechanic_radio',(.14,.965,.06))
    m.box('Tool_holster',(-.14,.91,.052),(.051,.13,.047),'belt','pelvis',.008)
    m.tube('Screwdriver', [(-.13,.90,.08),(-.13,1.07,.08)],[.004,.004],'metal','pelvis',seg=10,sub=0)
    m.tube('Red_handle',[(-.13,1.035,.08),(-.13,1.085,.08)],[.009,.009],'red','pelvis',seg=14,sub=0)
    for sx in (-1,1):
        for k in range(6):
            a=1.3+k*.43;x=sx*.106*math.sin(a);z=.012-.10*abs(math.cos(a))
            m.patch('Skull_spot',x,1.77+.11*math.cos(a),z,.009,.015,'spot','head',normal=(sx*.7,0,-.7))
    for k,(x,y) in enumerate([(.09,.55),(.14,.44),(.24,.34),(.34,.315),(.43,.35),(.485,.46)]):
        inv=tail.matrix_world.inverted();hit=tail.ray_cast(inv@G(x,y,-.8),inv.to_3x3()@G(0,0,1))
        if hit[0]:
            p=tail.matrix_world@hit[1];normal=tail.matrix_world.to_3x3()@hit[2]
            m.patch('Tail_spot',p.x,p.z,-p.y-.001,.010,.015,'spot','tail',normal=(normal.x,normal.z,-normal.y))
    return m

def mushroom(m,n,x,y,z,r,h):
    m.tube(n+'_stem',[(x,y,z),(x+.012,y+h*.55,z+.005),(x+.018,y+h,z)],[r*.17,r*.15,r*.20],'gill','chest',seg=16)
    xx=x+.018;top=y+h
    m.rings(n+'_cap',[(top+.045,.002,.002,0),(top+.035,r*.47,r*.47,0),(top+.008,r,r,0),(top-.004,r*.92,r*.92,0)],'fungus','chest',seg=36,sub=3)
    # The cap helper builds around the center axis, move its vertices to the stem.
    cap=bpy.data.objects[n+'_cap'];cap.data.transform(__import__('mathutils').Matrix.Translation(G(xx,0,z)))
    m.ball(n+'_underside',(xx,top-.004,z),(r*.91,.009,r*.91),'gill','chest',seg=28)
    for j in range(13):
        a=2*PI*j/13
        m.line(n+'_gill'+str(j),[(xx,top-.015,z),(xx+r*.84*math.sin(a),top-.011,z+r*.84*math.cos(a))],'gill_line','chest',r=.0009,sub=0)

def cyclope_roche():
    m=Cast('cyclope_roche',dict(skin='#8F9082',stone='#62665E',stone_light='#A5A594',seam='#575B51',fungus='#A66545',gill='#E4D6B2',gill_line='#9E8E6F'),2.34)
    m.rings('Stone_torso',[(1.85,.11,.10,0),(1.74,.29,.16,0),(1.56,.25,.16,0),(1.35,.17,.12,0),(1.10,.16,.12,0),(.98,.19,.13,0)],'skin','chest',seg=56,sub=5)
    for sx in (-1,1):
        m.ball('Pectoral',(sx*.135,1.59,.108),(.158,.135,.083),'skin','chest',seg=32)
        m.line('Chest_fold',[(sx*.022,1.49,.153),(sx*.13,1.47,.173),(sx*.223,1.51,.116)],'seam','chest',r=.0015)
        side='R' if sx<0 else 'L'
        a=(sx*.255,1.73,0);e=(sx*.34,1.34,.017);w=(sx*.39,.91,.04)
        up,lo,h=m.limb(side,a,e,w,.11,hand=False)
        for part,bad in [(up,'Upper_arm'+side),(lo,'Lower_arm'+side)]:
            bpy.data.objects.remove(bpy.data.objects[bad],do_unlink=True)
        upper=m.tube('Sculpted_deltoid_biceps'+side,[a,(sx*.282,1.61,.015),(sx*.315,1.46,.022),e],
                     [(.114,.102),(.140,.125),(.102,.095),(.073,.072)],'skin',up,seg=36,sub=6,cap0='flat')
        lower=m.tube('Sculpted_forearm'+side,[e,(sx*.355,1.25,.026),(sx*.38,1.08,.036),w],
                     [(.075,.073),(.117,.101),(.087,.078),(.065,.061)],'skin',lo,seg=36,sub=6)
        projected_line(m,upper,'Biceps_fold'+side,[(sx*.235,1.63),(sx*.242,1.56),(sx*.27,1.49),(sx*.31,1.46)],up)
        projected_line(m,upper,'Triceps_fold'+side,[(sx*.29,1.64),(sx*.31,1.57),(sx*.32,1.48)],up,rear=True)
        projected_line(m,lower,'Forearm_tendon'+side,[(sx*.36,1.20),(sx*.372,1.11),(sx*.38,1.02)],lo,r=.001)
        m.ball('Rock_palm',(w[0],.85,.047),(.103,.12,.075),'skin',h,seg=28)
        for k in range(4):
            x=w[0]+(k-1.5)*.042
            m.tube('Rock_finger',[(x,.83,.068),(x,.75,.092),(x+.012,.73,.116)],[.026,.025,.018],'skin',h,seg=16)
        m.tube('Rock_thumb',[(w[0]-sx*.085,.91,.077),(w[0]-sx*.119,.84,.095),(w[0]-sx*.105,.80,.11)],[.037,.029,.02],'skin',h,seg=18)
        t,s,f=m.bare_leg(side,(sx*.115,1.03,0),(sx*.135,.58,.011),(sx*.15,.12,0),.106)
        for bad in ['Thigh'+side,'Shin'+side]:bpy.data.objects.remove(bpy.data.objects[bad],do_unlink=True)
        thigh=m.tube('Sculpted_quadriceps'+side,[(sx*.115,1.03,0),(sx*.119,.89,.018),(sx*.13,.73,.021),(sx*.135,.59,.011)],
                     [(.112,.100),(.137,.124),(.112,.103),(.078,.074)],'skin',t,seg=36,sub=6)
        calf=m.tube('Sculpted_calf'+side,[(sx*.135,.59,.011),(sx*.14,.44,-.018),(sx*.15,.27,-.012),(sx*.15,.12,0)],
                    [(.079,.075),(.105,.109),(.072,.078),(.052,.053)],'skin',s,seg=36,sub=6)
        m.ball('Kneecap'+side,(sx*.135,.585,.059),(.070,.069,.039),'skin',s,seg=28)
        projected_line(m,thigh,'Quadriceps_fold'+side,[(sx*.073,.92),(sx*.072,.82),(sx*.095,.70),(sx*.129,.66)],t)
        projected_line(m,thigh,'Hamstring_fold'+side,[(sx*.127,.93),(sx*.14,.80),(sx*.143,.69)],t,rear=True)
        projected_line(m,calf,'Calf_fold'+side,[(sx*.11,.48),(sx*.10,.41),(sx*.122,.31)],s,rear=True)
        for obj in list(m.part(f).children):bpy.data.objects.remove(obj,do_unlink=True)
        x=sx*.15
        m.tube('Refined_foot'+side,[(x,.060,-.045),(x,.073,.034),(x,.054,.119)],[(.054,.040),(.081,.050),(.072,.035)],'skin',f,seg=32,sub=5)
        m.tube('Achilles'+side,[(x,.17,-.012),(x,.07,-.025)],[.048,.050],'skin',f,seg=24,sub=0)
        for j in range(3):
            xx=x+(j-1)*.052
            m.ball('Rounded_toe'+side+str(j),(xx,.045,.145),(.029,.031,.046),'skin',f,seg=28)
            m.ball('Toe_stone_top'+side+str(j),(xx,.067,.155),(.022,.009,.029),'stone',f,seg=22)
        for j,(yy,xx,zz,rx,ry) in enumerate([(1.70,.286,.10,.067,.11),(1.47,.29,.07,.049,.083),(1.18,.36,.091,.046,.10),(.91,.405,.103,.037,.045)]):
            bone=up if j<2 else lo if j==2 else h
            m.rock('Arm_rock_plate',(sx*xx,yy,zz),(rx,ry,.026),'stone',bone,seed=j+11)
        for j,(yy,xx,zz) in enumerate([(.93,.13,.112),(.67,.15,.10),(.43,.14,.09),(.28,.16,.075)]):
            m.rock('Leg_rock_plate',(sx*xx,yy,zz),(.047,.078,.023),'stone',t if yy>.58 else s,seed=j+24)
        for j,(dx,dz,r,hg) in enumerate([(-.05,.005,.098,.17),(.06,-.04,.073,.11),(.075,.075,.062,.085),(-.08,.08,.043,.07),(.02,.11,.025,.035)]):
            mushroom(m,'Mushroom_'+side+str(j),sx*(.24+dx),1.77,dz,r,hg)
    m.tube('Thick_neck',[(0,1.76,0),(0,1.96,0)],[.103,.10],'skin','neck',seg=30)
    m.rings('Column_head',[(2.33,.018,.023,-.003),(2.27,.078,.085,0),(2.17,.118,.107,0),(2.05,.118,.108,0),(1.92,.107,.10,.005),(1.84,.068,.073,.008)],'skin','head',seg=52,sub=4)
    m.eye('Cyclops',0,2.116,.112,.085,.096,.040,pupil_ratio=.20)
    m.tube('Massive_brow',[(-.092,2.198,.081),(0,2.225,.117),(.092,2.198,.081)],[(.025,.027),(.032,.023),(.024,.027)],'skin','head',seg=24,ref=(0,0,1))
    m.line('Rock_mouth',[(-.069,1.974,.093),(0,1.98,.111),(.069,1.974,.093)],'seam','head',r=.002)
    m.line('Under_mouth',[(-.047,1.95,.10),(0,1.947,.112),(.047,1.951,.10)],'seam','head',r=.0013)
    rng=random.Random(22)
    for k in range(28):
        a=rng.uniform(0,2*PI);yy=rng.uniform(1.2,1.77);rx,rz,zc=profile_at([(1.85,.11,.10,0),(1.74,.29,.16,0),(1.56,.25,.16,0),(1.35,.17,.12,0),(1.10,.16,.12,0)],yy,5)
        x=rx*math.sin(a);z=zc+rz*math.cos(a)
        if z>.05 and abs(x)<.12:continue
        plate=m.rock('Body_rock_plate',(x,yy,z),(.023+rng.random()*.025,.028+rng.random()*.034,.015),'stone','chest',seed=k)
        orient_spot(plate,(math.sin(a),0,math.cos(a)))
    for sx in (-1,1):
        for j,(y,z) in enumerate([(2.25,-.025),(2.14,-.052),(2.03,-.075),(1.92,-.018)]):
            m.rock('Head_rock_plate',(sx*.093,y,z),(.029,.045,.027),'stone','head',seed=j)
        m.line('Head_crack',[(sx*.073,2.25,.063),(sx*.065,2.27,.07),(sx*.078,2.29,.048)],'seam','head',r=.001,sub=0)
    return m

def mantide():
    m=Cast('mantide',dict(skin='#95A34B',armor='#6D8038',belly='#D1CD68',spot='#657E36',joint='#62742F',edge='#4C5B27'),2.23)
    m.rings('Insect_thorax',[(1.78,.046,.040,0),(1.70,.095,.066,0),(1.56,.063,.048,0),(1.35,.040,.038,0),(1.24,.056,.044,-.005)],'armor','chest',seg=48)
    m.tube('Yellow_sternum',[(0,1.74,.038),(0,1.64,.055),(0,1.53,.047),(0,1.38,.036)],[(.040,.007),(.068,.014),(.040,.012),(.021,.008)],'belly','chest',seg=24)
    m.bone('abdomen',(0,1.31,-.01),(0,1.01,-.11),'pelvis')
    m.tube('Long_abdomen',[(0,1.32,-.018),(0,1.20,-.07),(0,1.03,-.13),(0,.94,-.14)],[(.053,.06),(.093,.091),(.072,.071),(.005,.005)],'skin','abdomen',seg=32,sub=5)
    for j,y in enumerate([1.27,1.19,1.11,1.03]):
        w=[.058,.080,.075,.047][j]
        m.tube('Belly_segment'+str(j),[(-w,y,-.002),(0,y-.021,.014-j*.019),(w,y,-.002)],[(.011,.012)]*3,'belly','abdomen',ref=(0,0,1),seg=16)
        m.line('Back_abdomen_segment',[(-w,y,-.13),(0,y-.015,-.169),(w,y,-.13)],'edge','abdomen',r=.001)
    m.tube('Thin_neck',[(0,1.73,0),(0,1.87,.014)],[.023,.021],'skin','neck',seg=20)
    m.ball('Insect_head',(0,1.966,.008),(.109,.139,.094),'skin','head',seg=44)
    m.tube('Lower_face',[(0,1.956,.066),(0,1.865,.066)],[(.034,.014),(.026,.020)],'belly','head',seg=24)
    for sx in (-1,1):
        m.eye(str(sx),sx*.049,1.975,.088,.046,.053,.030,pupil_ratio=.20)
        m.tube('Mandible',[(sx*.030,1.88,.079),(sx*.049,1.853,.097),(sx*.033,1.818,.108),(sx*.019,1.825,.109)],[.012,.016,.010,.001],'belly','head',seg=18)
        m.tube('Long_antenna',[(sx*.040,2.074,0),(sx*.056,2.17,0),(sx*.09,2.245,.002),(sx*.13,2.25,.01)],[.0045,.0045,.0035,.002],'belly','head',seg=12)
        m.ball('Antenna_tip',(sx*.13,2.25,.01),(.012,.005,.008),'belly','head',seg=16)
        side='R' if sx<0 else 'L'
        for label,a,e,w in [('',(sx*.085,1.70,0),(sx*.20,1.47,.01),(sx*.32,1.25,.035)),('2',(sx*.052,1.45,-.025),(sx*.15,1.25,-.012),(sx*.22,1.04,.03))]:
            up,lo,h=m.limb(side,a,e,w,.018,label=label,hand=False)
            m.ball('Shoulder_armor'+label+side,a,(.034,.035,.033),'armor',up)
            m.ball('Elbow_joint'+label+side,e,(.023,.024,.021),'joint',lo)
            m.tube('Blade_forearm'+label+side,[e,w],[(.027,.021),(.018,.016)],'skin',lo,seg=20,sub=0)
            for k in range(3):
                t=.25+k*.21;xx=e[0]+(w[0]-e[0])*t;yy=e[1]+(w[1]-e[1])*t
                m.tube('Forearm_spine',[(xx-sx*.015,yy,.016),(xx-sx*.035,yy-.028,.017)],[.009,.001],'belly',lo,seg=10,sub=0)
            m.ball('Thin_palm'+label+side,(w[0],w[1]-.025,w[2]),(.022,.036,.014),'skin',h,seg=20)
            for k in range(3):
                xx=w[0]+(k-1)*.018
                m.tube('Articulated_finger',[(xx,w[1]-.04,w[2]),(xx+sx*.006,w[1]-.083,w[2]+.01),(xx+sx*.019,w[1]-.11,w[2]+.022)],[.006,.0055,.0035],'skin',h,seg=12)
            m.tube('Insect_thumb',[(w[0]-sx*.018,w[1]-.013,w[2]),(w[0]-sx*.036,w[1]-.044,w[2]+.014)],[.007,.004],'skin',h,seg=12,sub=0)
        t,s,f=m.bare_leg(side,(sx*.052,1.25,-.01),(sx*.083,.69,0),(sx*.115,.11,0),.023,toes=2)
        for obj in list(m.part(f).children):bpy.data.objects.remove(obj,do_unlink=True)
        m.ball('Ankle_join',(sx*.115,.105,0),(.024,.023,.024),'skin',f,seg=22)
        m.tube('Foot_connector',[(sx*.115,.105,0),(sx*.115,.05,.025)],[.018,.023],'skin',f,seg=18,sub=0)
        m.ball('Splayed_foot',(sx*.115,.05,.04),(.037,.026,.066),'skin',f,seg=24)
        for j in (-1,1):
            m.tube('Long_insect_toe',[(sx*.115,.048,.05),(sx*.115+j*.039,.034,.11),(sx*.115+j*.071,.026,.14)],[(.014,.021),(.011,.019),(.001,.001)],'skin',f,ref=(0,1,0),seg=22)
        m.ball('Knee_joint',(sx*.083,.69,0),(.031,.037,.027),'armor',s)
        for j in range(3):
            y=.55-j*.07;xx=sx*(.09+j*.004)
            m.tube('Shin_spike',[(xx,y,0),(xx+sx*.028,y-.038,0)],[.009,.001],'skin',s,seg=12,sub=0)
        for k in range(4):
            m.patch('Temple_spot',sx*(.060+k*.009),2.02-k*.024,-.070,.008,.011,'spot','head',normal=(sx*.6,0,-.8))
    m.line('Back_thorax_ridge',[(0,1.76,-.045),(0,1.56,-.052),(0,1.34,-.040)],'edge','chest',r=.0013)
    return m

def gel_bleu():
    m=Cast('gel_bleu',dict(gel='#6CCCF2',blue='#51ACD9',edge='#4798BE',highlight='#D2F6FC',vein='#8B87CD',organ='#A9A0DF',core='#EE9BDD',heart='#F8B9E7',mouth='#562646',tongue='#F29DBF'),1.65)
    def transparent(obj):obj['no_outline']=True;return obj
    prof=[(1.40,.009,.009,0),(1.36,.107,.076,0),(1.23,.156,.116,0),(1.12,.135,.105,0),(.98,.086,.076,0),(.83,.105,.091,0),(.64,.165,.125,0),(.39,.198,.145,0),(.24,.165,.124,0),(.22,.08,.075,0)]
    transparent(m.rings('Translucent_body',prof,'gel','chest',seg=64,sub=5))
    transparent(m.tube('Tall_gel_crest',[(.018,1.36,0),(.024,1.47,-.003),(.062,1.555,0),(.086,1.574,.002)],[.026,.029,.026,.016],'gel','chest',seg=24))
    for x,y in [(-.060,1.395),(.087,1.407),(.121,1.34)]:
        transparent(m.tube('Small_crest',[(x,y-.05,0),(x+.008,y,.002)],[.012,.015],'gel','chest',seg=20,sub=0))
    for sx in (-1,1):
        m.eye(str(sx),sx*.054,1.23,.113,.050,.057,.030,b='chest',pupil_ratio=.20)
        m.line('Happy_brow',[(sx*.022,1.307,.086),(sx*.053,1.32,.085),(sx*.080,1.307,.073)],'edge','chest',r=.0013)
        side='R' if sx<0 else 'L';up='upper_arm.'+side;lo='forearm.'+side;h='hand.'+side
        a=(sx*.105,.84,0);e=(sx*.24,.75,.017);w=(sx*.29,.98,.028)
        m.bone(up,a,e,'chest');m.bone(lo,e,w,up);m.bone(h,w,(sx*.28,1.02,.028),lo)
        transparent(m.tube('Gel_arm_top',[a,(sx*.17,.74,.01),e],[.028,.038,.046],'gel',up,seg=24))
        transparent(m.tube('Gel_arm_curl',[e,(sx*.29,.79,.024),w,(sx*.27,1.005,.03)],[.046,.040,.044,.030],'gel',lo,seg=24))
        transparent(m.ball('Gel_hand',(sx*.29,1.003,.029),(.055,.038,.043),'gel',h))
        t='thigh.'+side;s='shin.'+side;f='foot.'+side
        m.bone(t,(sx*.091,.27,0),(sx*.10,.16,0),'pelvis');m.bone(s,(sx*.10,.16,0),(sx*.13,.06,0),t);m.bone(f,(sx*.13,.06,0),(sx*.16,.036,.10),s)
        transparent(m.tube('Gel_leg',[(sx*.091,.28,0),(sx*.10,.16,0),(sx*.13,.07,.03)],[.045,.038,.048],'gel',s,seg=24))
        transparent(m.ball('Gel_foot',(sx*.13,.042,.059),(.074,.030,.086),'gel',f))
    m.ball('Open_happy_mouth',(0,1.135,.109),(.060,.039,.014),'mouth','chest',seg=32)
    m.ball('Pink_tongue',(.018,1.115,.123),(.025,.013,.003),'tongue','chest',seg=24,detail=True)
    m.bone('core',(0,.55,0),(0,.71,0),'chest')
    m.ball('Internal_core',(0,.63,0),(.085,.092,.063),'core','core',seg=36)
    for k in range(8):
        a=2*PI*k/8
        m.ball('Core_lobe',(.048*math.sin(a),.63+.052*math.cos(a),.021),(.025,.031,.025),'heart','core',seg=22)
    for sx in (-1,1):
        for j in range(3):
            x=sx*(.018+j*.022)
            m.tube('Internal_vein',[(x,.64,.003),(x+sx*.023,.82,.008),(x-sx*.014,.94,.014),(x,1.08,.005)],[.009,.007,.007,.003],'vein','chest',seg=14,sub=5)
        m.ball('Internal_organ',(sx*.094,.40,.015),(.047,.067,.044),'organ','chest',seg=28)
        m.tube('Core_vessel',[(sx*.03,.59,.02),(sx*.06,.49,.025),(sx*.04,.35,.03),(sx*.055,.30,.03)],[.013,.012,.009,.005],'vein','chest',seg=18)
    m.ball('Lower_organ',(0,.31,-.02),(.048,.06,.039),'organ','chest',seg=26)
    rng=random.Random(4)
    for k in range(23):
        y=rng.uniform(.32,1.32);a=rng.uniform(0,2*PI);rx,rz,zc=profile_at(prof,y,5)
        x=(rx+.003)*math.sin(a);z=(rz+.003)*math.cos(a)
        if z>.05 and y>1.09 and abs(x)<.12:continue
        r=rng.uniform(.009,.020)
        m.ball('Blue_bubble',(x,y,z),(r,r*1.2,r*.55),'blue','chest',seg=18,detail=True)
        m.patch('Bubble_glint',x-.003,y+.006,z+(.006 if z>0 else -.006),r*.35,r*.44,'highlight','chest',normal=(math.sin(a),0,math.cos(a)))
    for sx in (-1,1):
        m.patch('Head_gloss',sx*.10,1.29,.077,.014,.034,'highlight','chest',normal=(sx*.55,.2,.8))
        m.patch('Arm_gloss',sx*.29,1.016,.068,.027,.010,'highlight','hand.'+('R' if sx<0 else 'L'))
        m.patch('Foot_gloss',sx*.13,.057,.135,.023,.009,'highlight','foot.'+('R' if sx<0 else 'L'))
    # Exterior contour strokes in the side plane keep a clean cartoon silhouette.
    for sx in (-1,1):m.line('Gel_silhouette',[(sx*p[1],p[0],0) for p in prof[1:-1]],'edge','chest',r=.0014,sub=4)
    fuse_gel(m)
    bc._MATS['gel'].node_tree.nodes['Principled BSDF'].inputs['Alpha'].default_value=GEL_OPACITY
    bc._MATS['gel'].surface_render_method='DITHERED'
    return m

if __name__=='__main__':
    args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else ['reptile_mecano']
    name=args[0]
    builders={'reptile_mecano':reptile_mecano,'cyclope_roche':cyclope_roche,'mantide':mantide,'gel_bleu':gel_bleu,
              'aventurier':lambda:explorer(False),'heroine':lambda:explorer(True)}
    assert name in builders,name
    builders[name]().finish()
