"""Native editable models for sheets 05-10. Run in Blender with -- <character>.
Each design has its own geometry, palette and anatomical skeleton.
"""
import os, sys, math, random, json
import bpy, bmesh
from mathutils import Vector
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import bl_common as bc
from bl_common import G
from scientist_export import export

PI=math.pi
def profile_at(profile,y,sub=4):
    vals=bc._catmull([Vector(q[:3]) for q in profile],sub)
    zs=bc._catmull([Vector((q[3],0,0)) for q in profile],sub)
    for j,(p,q) in enumerate(zip(vals,vals[1:])):
        if p.x>=y>=q.x:
            t=(p.x-y)/max(.00001,p.x-q.x)
            v=p.lerp(q,t);return v.y,v.z,zs[j].x+(zs[j+1].x-zs[j].x)*t
    return profile[-1][1:]

def orient_spot(obj,normal):
    obj.rotation_euler=Vector((0,-1,0)).rotation_difference(G(*normal).normalized()).to_euler()

class Model:
    def __init__(self,name,palette,height):
        bc.reset_scene(); self.name=name;self.height=height;self.parts={};self.specs=[]
        self.root=bc.pivot('Rig',(0,0,0))
        for role,col in dict(ink='#27252B',eye='#FFFBEA',**palette).items():bc.material(role,col,spec=0)
        self.bone('pelvis',(0,.55*height,0),(0,.62*height,0))
        self.bone('spine',(0,.62*height,0),(0,.70*height,0),'pelvis')
        self.bone('chest',(0,.70*height,0),(0,.78*height,0),'spine')
        self.bone('neck',(0,.78*height,0),(0,.82*height,0),'chest')
        self.bone('head',(0,.82*height,0),(0,.96*height,0),'neck')
    def bone(self,n,a,b,p=None):self.specs.append((n,a,b,p))
    def part(self,bone):
        if bone not in self.parts:self.parts[bone]=bc.pivot('Part_'+bone,(0,0,0),self.root)
        return self.parts[bone]
    def ball(self,n,p,s,c,b='head',seg=28,detail=False):
        return bc.sphere(n,1,p,c,self.part(b),scale=s,seg=seg,exact=True,extras={'no_outline':True} if detail else None)
    def tube(self,n,p,r,c,b='chest',**kw):
        kw.setdefault('sub',3);kw.setdefault('seg',18)
        return bc.sweep(n,p,r,c,self.part(b),**kw)
    def line(self,n,p,c='ink',b='head',r=.0014,**kw):
        return self.tube(n,p,[r]*len(p),c,b,extras={'no_outline':True},**kw)
    def flat(self,n,p,c,b='chest',thick=.002):
        bm=bmesh.new();v=[bm.verts.new(G(*q)) for q in p];bm.faces.new(v)
        bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
        return bc._finish(n,bm,Vector((0,0,0)),c,self.part(b),thick=thick)
    def box(self,n,p,s,c,b='chest',bevel=.008):
        return bc.box(n,s,p,c,self.part(b),bevel=bevel)
    def rings(self,n,profile,c,b='chest',opening=0,wave=0,seg=48,sub=3):
        # Horizontal elliptical rings: (height, radius x, radius z, center z).
        vals=bc._catmull([Vector(q[:3]) for q in profile],sub) if sub else [Vector(q[:3]) for q in profile]
        zs=bc._catmull([Vector((q[3],0,0)) for q in profile],sub) if sub else [Vector((q[3],0,0)) for q in profile]
        bm=bmesh.new();rows=[]
        for j,(v,z) in enumerate(zip(vals,zs)):
            row=[]
            for i in range(seg+1):
                a=opening+(2*PI-2*opening)*i/seg
                y=v.x+wave*math.cos(a*7)*(j/max(1,len(vals)-1))**4
                row.append(bm.verts.new(G(v.y*math.sin(a),y,z.x+v.z*math.cos(a))))
            rows.append(row)
        for j in range(len(rows)-1):
            for i in range(seg):bm.faces.new((rows[j][i],rows[j+1][i],rows[j+1][i+1],rows[j][i+1]))
        bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
        return bc._finish(n,bm,Vector((0,0,0)),c,self.part(b),thick=.003)
    def eye(self,n,x,y,z,rx=.043,ry=None,rz=.025,b='head',pupil_ratio=.09):
        ry=ry or rx*1.1
        self.ball('Eye_'+n,(x,y,z),(rx,ry,rz),'eye',b,seg=36)
        self.ball('Pupil_'+n,(x,y,z+rz+.001),(rx*pupil_ratio,rx*pupil_ratio,.0022),'ink',b,seg=20,detail=True)
    def loop(self,n,center,rx,ry,c,b='head',r=.002):
        x,y,z=center
        self.line(n,[(x+rx*math.cos(i*2*PI/48),y+ry*math.sin(i*2*PI/48),z) for i in range(49)],c,b,r,sub=0)
    def hand(self,n,p,s,b,c='skin',fingers=4):
        x,y,z=p
        self.ball(n+'_palm',p,(s*.62,s,s*.32),c,b,seg=22)
        for i in range(fingers):
            xx=x+(i-(fingers-1)/2)*s*.36;ll=s*(.85-.12*abs(i-1.5))
            self.tube(n+'_finger_'+str(i),[(xx,y-s*.5,z),(xx,y-s*.8-ll*.5,z+.007),(xx+s*.08,y-s*.7-ll,z+.018)],
                [s*.17,s*.16,s*.12],c,b,seg=12,sub=2)
        self.tube(n+'_thumb',[(x-s*.48,y+.002,z),(x-s*.83,y-s*.25,z+.015),(x-s*.76,y-s*.6,z+.023)], [s*.23,s*.2,s*.13],c,b,seg=12)
    def arm(self,side,a,e,w,r,c='skin',label='',fingers=4,cap0='round'):
        up='upper_arm'+label+'.'+side;lo='forearm'+label+'.'+side;hand='hand'+label+'.'+side
        self.bone(up,a,e,'chest');self.bone(lo,e,w,up)
        end=(w[0],w[1]-.07,w[2]+.02);self.bone(hand,w,end,lo)
        self.tube('Arm'+label+side,[a,e],[r,r*.83],c,up,sub=0,cap0=cap0)
        self.tube('Forearm'+label+side,[e,w],[r*.83,r*.55],c,lo,sub=0)
        self.hand('Hand'+label+side,(w[0],w[1]-.035,w[2]+.008),r*1.5,hand,c,fingers)
        return up,lo,hand
    def leg(self,side,hip,knee,ankle,r,c,shoe='shoe'):
        t='thigh.'+side;s='shin.'+side;f='foot.'+side
        self.bone(t,hip,knee,'pelvis');self.bone(s,knee,ankle,t)
        self.bone(f,ankle,(ankle[0],.045,ankle[2]+.13),s)
        self.tube('Thigh'+side,[hip,knee],[r,r*.83],c,t,sub=0)
        self.tube('Shin'+side,[knee,ankle],[r*.83,r*.69],c,s,sub=0)
        x,y,z=ankle
        self.ball('Shoe'+side,(x,.064,z+.052),(r*1.50,.059,.125),shoe,f)
        self.ball('Sole'+side,(x,.024,z+.052),(r*1.55,.018,.13),'sole',f)
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
            assert bone in data.bones,bone
            for obj in part.children_recursive:
                if obj.type!='MESH':continue
                group=obj.vertex_groups.new(name=bone);group.add(list(range(len(obj.data.vertices))),1,'REPLACE')
                mod=obj.modifiers.new('Skeleton','ARMATURE');mod.object=arm
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(bc.ROOT,'art/blender/'+self.name+'.blend'))
        bc.preview_toon(width=.00125,min_size=.008,cel=0)
        export(self.root,os.path.join(bc.ROOT,'assets/models/characters/'+self.name+'_toon.glb'))
        views={k:dict(yaw=y,elev=0,focus=(0,self.height*.49,0),dist=self.height*6.9) for k,y in [('front',0),('back',180),('three_quarter',30)]}
        bc.render_preview(os.path.join(bc.ROOT,'out/blender/'+self.name),views=views,res=(800,1000),floor=False,bg='#FBFAF5',key_only=True,lens=200)
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(bc.ROOT,'art/blender/'+self.name+'_toon.blend'))

def human_face(m,cy,cz,rx,hy,ears=.022):
    m.ball('Head',(0,cy,cz),(rx,hy,rx*.88),'skin',seg=40)
    def surf(x,y):return cz+rx*.88*math.sqrt(max(.01,1-(x/rx)**2-((y-cy)/hy)**2))
    for sx in (-1,1):
        x=sx*rx*.44;y=cy+hy*.13;z=surf(x,y)+.008
        m.eye(str(sx),x,y,z,rx*.38,rx*.42,rx*.21)
        m.ball('Ear'+str(sx),(sx*(rx+.009),cy,cz),(ears,ears*1.45,.018),'skin',seg=24)
        m.line('Ear_fold'+str(sx),[(sx*(rx+.006),cy+.015,cz+.017),(sx*(rx+.018),cy+.020,cz+.019),(sx*(rx+.019),cy-.010,cz+.019)],'skin_line',r=.001)
        m.line('Brow'+str(sx),[(sx*rx*.15,cy+hy*.47,surf(sx*rx*.15,cy+hy*.47)+.004),(sx*rx*.43,cy+hy*.51,surf(sx*rx*.43,cy+hy*.51)+.004),(sx*rx*.7,cy+hy*.44,surf(sx*rx*.7,cy+hy*.44)+.004)],'hair',r=.004)
        m.line('Eye_bag'+str(sx),[(sx*rx*.16,cy-hy*.18,surf(sx*rx*.16,cy-hy*.18)+.003),(sx*rx*.45,cy-hy*.25,surf(sx*rx*.45,cy-hy*.25)+.003),(sx*rx*.70,cy-hy*.14,surf(sx*rx*.7,cy-hy*.14)+.003)],'skin_line',r=.0009)
    m.tube('Nose',[(0,cy+hy*.12,cz+rx*.84),(0,cy-hy*.21,cz+rx*1.22),(0,cy-hy*.4,cz+rx*1.1)],[(rx*.10,rx*.08),(rx*.115,rx*.13),(rx*.075,rx*.075)],'skin','head',seg=20)
    m.line('Mouth',[(-rx*.32,cy-hy*.59,surf(-rx*.32,cy-hy*.59)+.002),(0,cy-hy*.55,surf(0,cy-hy*.55)+.004),(rx*.32,cy-hy*.59,surf(rx*.32,cy-hy*.59)+.002)],r=.0013)
    for k in range(3):
        y=cy+hy*(.65+k*.1)
        m.line('Wrinkle'+str(k),[(x,y-.003*(1-(x/(rx*.45))**2),surf(x,y)+.0018) for x in [rx*(-.45+i*.09) for i in range(11)]],'skin_line',r=.0008,sub=0)
    return surf

def odette():
    m=Model('odette',dict(skin='#BD946A',skin_line='#826241',hair='#B6B7B4',hair_line='#7D7E7B',dress='#685466',seam='#483C4C',shawl='#707448',leaf='#484F2D',gold='#AF813A',bag='#A48A53',bag_line='#6E5934',shoe='#614046',sole='#35312B',sock='#4F5142'),1.98)
    m.rings('Long_dress',[(1.425,.072,.055,0),(1.36,.14,.086,0),(1.15,.118,.083,0),(.94,.122,.086,0),(.27,.178,.114,0)],'dress','spine',seg=56)
    for y in [1.30,1.19,1.08,.96,.84,.72,.60,.48,.36]:m.ball('Dress_button',(0,y,.095 if y>.9 else .12),(.004,.004,.002),'ink','spine',seg=12,detail=True)
    m.line('Dress_placket',[(.013,1.34,.087),(.013,.98,.091),(.013,.28,.119)],'seam','spine',r=.0009)
    for sx in (-1,1):
        m.line('Dress_pleat'+str(sx),[(sx*.095,.72,.095),(sx*.12,.28,.09)],'seam','spine',r=.001)
        side='R' if sx<0 else 'L'
        m.leg(side,(sx*.071,.39,0),(sx*.073,.23,0),(sx*.074,.11,0),.028,'sock')
        f='foot.'+side
        m.tube('Boot_cuff'+side,[(sx*.074,.09,0),(sx*.074,.205,0)],[.037,.035],'shoe',f,sub=0)
        for i in range(5):
            y=.09+i*.018
            m.line('Lace'+side+str(i),[(sx*.074-.023,y,.041),(sx*.074+.022,y+.011,.042)],'ink',f,r=.0013,sub=0)
        a,e,w=(sx*.139,1.36,0),(sx*.19,1.12,.004),(sx*.225,.88,.018)
        up,lo,hand=m.arm(side,a,e,w,.027)
        m.tube('Dress_sleeve_top'+side,[a,e],[.046,.037],'dress',up,sub=0)
        m.tube('Dress_sleeve_lower'+side,[e,(sx*.218,.925,.016)],[.038,.032],'dress',lo,sub=0)
    m.tube('Neck',[(0,1.39,0),(0,1.53,.008)],[.033,.029],'skin','neck')
    surf=human_face(m,1.645,.006,.105,.153,.021)
    for sx in (-1,1):
        x=sx*.046;y=1.665;z=surf(x,y)+.037
        m.loop('Glasses'+str(sx),(x,y,z),.048,.049,'gold',r=.0023)
        m.line('Glasses_arm'+str(sx),[(sx*.092,y,z),(sx*.118,y,.014)],'gold',r=.0016)
        m.loop('Earring'+str(sx),(sx*.119,1.60,.027),.008,.012,'gold',r=.0023)
    m.line('Glasses_bridge',[(-.009,1.67,.137),(0,1.675,.139),(.009,1.67,.137)],'gold',r=.002)
    # Continuous gray cap, scalloped side locks and a high curly bun.
    bc.dome('Gray_scalp',1,lambda a: .018 if abs(a)<1.05 else -.095,(0,1.69,0),'hair',m.part('head'),scale=(.113,.11,.105),rings=10,seg=40,subsurf=0,thick=.003)
    random.seed(5)
    for k in range(23):
        a=k*2.39996;rr=.047*math.sqrt((k+.5)/23)
        x=rr*math.cos(a);y=1.836+rr*math.sin(a)
        m.ball('Bun_curl'+str(k),(x,y,-.035+random.uniform(-.025,.025)),(.034,.037,.034),'hair',seg=18)
        m.line('Bun_curl_line'+str(k),[(x-.02,y,-.001),(x-.01,y+.016,.003),(x+.013,y+.015,.001)],'hair_line',r=.0009)
    m.loop('Hair_band',(0,1.79,.0),.060,.010,'shoe',r=.004)
    for sx in (-1,1):
        for k in range(5):m.ball('Side_curl'+str(sx)+str(k),(sx*(.086+.008*math.sin(k)),1.76-k*.026,.014),(.026,.030,.026),'hair',seg=18)
        m.line('Loose_curl'+str(sx),[(sx*(.12+.008*math.sin(i*1.1)),1.72-i*.012,.042) for i in range(16)],'hair_line',r=.0018)
    # Shawl is a full surface, with a V-shaped hem and a woven leaf motif.
    shawl=[(1.433,.05,.043,0),(1.365,.154,.099,0),(1.245,.193,.115,0),(1.15,.211,.122,0)]
    obj=m.rings('Shawl',shawl,'shawl','chest',opening=.24,seg=64,sub=3)
    for v in obj.data.vertices:
        x,y,z=v.co.x,v.co.z,-v.co.y
        factor=max(0,min(1,(1.27-y)/.12));v.co.z-=.10*max(0,1-abs(x)/.212)*factor
    for i in range(42):
        a=.24+(2*PI-.48)*i/41;x=.212*math.sin(a);z=.125*math.cos(a);y=1.15-.10*max(0,1-abs(x)/.212)
        m.tube('Fringe'+str(i),[(x,y,z),(x*1.025,y-.048,z*1.025)],[.0028,.0024],'shawl','chest',seg=8,sub=0)
    for back in (1,-1):
        for sx in (-1,1):
            for k in range(3):
                x=sx*(.066+k*.04);y=1.33-k*.028;z=back*(.107+k*.006)
                m.line('Woven_stem',[(x,y,z),(x+sx*.024,y-.12,z+.004*back)],'leaf','chest',r=.0008)
                for j in range(3):
                    yy=y-j*.034;xx=x+sx*j*.006
                    m.line('Woven_leaf',[(xx,yy,z+.002*back),(xx-sx*.015,yy-.008,z+.004*back),(xx-sx*.013,yy-.025,z+.004*back),(xx+sx*.006,yy-.028,z+.003*back)],'leaf','chest',r=.0008)
    # Satchel hangs at her left hip with the strap passing around the back.
    m.line('Satchel_strap',[(-.11,1.39,.112),(-.06,1.25,.12),(.05,1.02,.115),(.15,.83,.12)],'bag','spine',r=.009)
    m.line('Satchel_back_strap',[(-.11,1.39,-.106),(-.04,1.18,-.104),(.10,.96,-.109),(.15,.83,-.08)],'bag','spine',r=.009)
    m.box('Satchel',(.174,.86,.126),(.11,.17,.065),'bag','spine',.016)
    m.box('Satchel_flap',(.174,.912,.163),(.108,.062,.011),'bag','spine',.01)
    m.line('Satchel_seam',[(.128,.91,.171),(.13,.793,.171),(.217,.793,.171),(.22,.91,.171)],'bag_line','spine',r=.001)
    m.box('Satchel_buckle',(.183,.868,.176),(.019,.027,.007),'gold','spine',.002)
    return m

def leon():
    m=Model('leon',dict(skin='#E4BA91',skin_line='#AA805C',hair='#D1D0C6',hair_line='#8F918A',shirt='#A5BEC7',shirt_line='#657C85',coat='#8C4936',coat_line='#5F3026',pants='#626248',strap='#4B4531',gold='#A58C47',shoe='#363634',sole='#A4987D',sock='#454C48'),1.57)
    m.rings('Shirt',[(1.15,.057,.048,-.014),(1.10,.139,.084,-.025),(.91,.136,.107,-.006),(.77,.133,.113,0)],'shirt','spine')
    m.rings('Cardigan',[(1.15,.066,.057,-.024),(1.08,.164,.107,-.03),(.94,.16,.124,-.016),(.73,.148,.122,0)],'coat','chest',opening=.62)
    m.tube('Bent_neck',[(0,1.09,-.014),(0,1.20,.08)],[.042,.037],'skin','neck')
    surf=human_face(m,1.35,.082,.124,.158,.047)
    for sx in (-1,1):
        side='R' if sx<0 else 'L'
        a,e,w=(sx*.121,1.102,-.025),(sx*.192,.90,.014),(sx*.202,.689,.07)
        up,lo,h=m.arm(side,a,e,w,.027,cap0='flat')
        m.tube('Cardigan_sleeve'+side,[a,e],[.040,.042],'coat',up,sub=0,cap0='flat')
        m.tube('Cardigan_forearm'+side,[e,(sx*.2,.78,.047)],[.043,.035],'coat',lo,sub=0)
        for j in range(5):m.line('Cuff_rib'+side+str(j),[(sx*.20-.025+j*.012,.805,.082),(sx*.20-.025+j*.012,.778,.082)],'coat_line',lo,r=.0009,sub=0)
        m.leg(side,(sx*.072,.78,0),(sx*.073,.44,.028),(sx*.075,.13,.009),.053,'pants')
        m.tube('Sock'+side,[(sx*.075,.13,.009),(sx*.075,.21,.009)],[.026,.028],'sock','shin.'+side,sub=0)
        m.flat('Collar'+side,[(sx*.014,1.16,.075),(sx*.071,1.14,.071),(sx*.071,1.081,.095),(sx*.027,1.11,.105)],'shirt')
        m.line('Brace'+side,[(sx*.085,1.12,.087),(sx*.085,.98,.111),(sx*.083,.83,.118)],'strap','spine',r=.009)
        for y in (.87,.94):m.box('Brace_clasp',(sx*.084,y,.128),(.026,.015,.006),'gold','spine',.002)
        m.tube('White_moustache'+side,[(sx*.005,1.291,.217),(sx*.028,1.292,.222),(sx*.061,1.274,.206),(sx*.073,1.251,.19)],[(.014,.01),(.021,.012),(.017,.012),(.001,.001)],'hair','head',ref=(0,1,0))
        for k in range(3):m.line('Moustache_hair',[(sx*(.02+k*.014),1.287,.236),(sx*(.035+k*.014),1.266,.226)],'hair_line',r=.00075)
        for k in range(4):
            m.tube('Side_white_tuft',[(sx*.108,1.44-k*.018,.04),(sx*.146,1.445-k*.018,.035),(sx*.163,1.435-k*.018,.025)],[.019,.014,.0008],'hair','head',ref=(0,1,0),seg=12)
    bc.dome('Back_white_hair',1,lambda a:.10 if abs(a)<1.25 else -.07,(0,1.35,.08),'hair',m.part('head'),scale=(.13,.14,.118),rings=8,seg=40,subsurf=0,thick=.002)
    # Remove front bald cap, keep only side/back hair below the bald crown.
    cap=bpy.data.objects.get('Back_white_hair')
    bm=bmesh.new();bm.from_mesh(cap.data)
    dead=[v for v in bm.verts if v.co.z> .065 or -v.co.y>.025]
    bmesh.ops.delete(bm,geom=dead,context='VERTS');bm.to_mesh(cap.data);bm.free()
    for k in range(3):m.line('Sparse_hair'+str(k),[(-.018+k*.016,1.501,.05),(-.024+k*.018,1.54+k*.008,.055),(-.047+k*.022,1.55+k*.008,.06)],'hair_line',r=.001)
    m.rings('High_waist',[(.84,.135,.115,0),(.73,.139,.117,0),(.67,.12,.103,0)],'pants','pelvis',seg=40,sub=1)
    m.rings('Waist_band',[(.843,.139,.119,0),(.819,.139,.119,0)],'strap','pelvis',seg=40,sub=0)
    m.ball('Trouser_button',(0,.83,.124),(.007,.007,.003),'gold','pelvis',seg=16)
    for k in range(3):m.ball('Shirt_button',(0,1.10-k*.072,.111),(.003,.003,.002),'ink','spine',seg=12)
    for sx in (-1,1):
        for k in range(3):m.line('Cardigan_darn',[(sx*.14,.99-k*.05,.089),(sx*.151,1.005-k*.05,.092),(sx*.16,.985-k*.05,.091)],'coat_line','chest',r=.0008)
    return m

def vexa():
    m=Model('vexa',dict(skin='#AF97D1',spot='#7D65A0',dress='#30394F',seam='#22293C',gold='#BA985C',sash='#CB7259',shoe='#37383E',sole='#C2B495',horn='#E8DBB3'),2.18)
    # Broad crescent head, narrow chin and raised pointed temples.
    prof=[(2.01,.31,.084,0),(1.98,.307,.098,0),(1.91,.265,.115,0),(1.83,.165,.098,.002),(1.79,.040,.05,.002),(1.71,.027,.028,0)]
    m.rings('Crescent_head',prof,'skin','head',seg=64,sub=4)
    for sx in (-1,1):
        m.tube('Temple_point',[(sx*.274,1.956,0),(sx*.319,2.001,0),(sx*.324,2.035,0)],[.047,.026,.0007],'skin','head',ref=(0,1,0),seg=20)
        m.tube('Horn',[(sx*.177,2.007,-.006),(sx*.207,2.075,-.008),(sx*.253,2.115,-.006),(sx*.295,2.127,0)],[.023,.019,.011,.0004],'horn','head',ref=(0,0,1),seg=18)
        for k in range(3):m.ball('Temple_spot',(sx*(.246+k*.016),1.977-k*.017,.074),(.010-k*.002,.014-k*.003,.002),'spot',seg=16,detail=True)
    for i,x in enumerate((-.132,0,.132)):m.eye(str(i),x,1.935,.111,.045,.052,.026,pupil_ratio=.28)
    m.line('Little_smile',[(-.021,1.852,.104),(0,1.847,.111),(.021,1.852,.104)],r=.0012)
    m.rings('Tunic_top',[(1.715,.046,.041,0),(1.66,.112,.072,0),(1.48,.103,.07,0),(1.36,.075,.058,0)],'dress','chest')
    m.rings('Split_tunic',[(1.365,.080,.062,0),(1.18,.103,.072,0),(.49,.177,.094,0)],'dress','spine',opening=.34,seg=56)
    for sx in (-1,1):
        m.line('Gold_tunic_edge',[(sx*.012,1.71,.045),(sx*.017,1.60,.075),(sx*.016,1.38,.063)],'gold','chest',r=.003)
        m.line('Gold_skirt_edge',[(sx*.027,1.35,.059),(sx*.035,1.17,.069),(sx*.060,.49,.090)],'gold','spine',r=.003)
        side='R' if sx<0 else 'L'
        m.arm(side,(sx*.123,1.65,0),(sx*.213,1.36,.004),(sx*.341,1.10,.04),.025,fingers=3)
        m.arm(side,(sx*.087,1.43,-.012),(sx*.156,1.19,-.016),(sx*.203,1.00,.03),.022,label='2',fingers=3)
        m.leg(side,(sx*.065,.76,0),(sx*.10,.42,0),(sx*.145,.12,.006),.036,'shoe')
        for y in (.17,.205,.24):m.tube('Ankle_gold'+str(sx)+str(y),[(sx*(.145-(y-.12)*.04),y-.012,.006),(sx*(.145-(y-.12)*.04),y+.012,.006)],[.041,.041],'gold','shin.'+side,seg=20,sub=0,cap0='flat',cap1='flat')
    m.loop('Collar_medallion',(0,1.635,.091),.025,.027,'gold',b='chest',r=.005)
    m.rings('Sash_belt',[(1.40,.085,.068,0),(1.335,.087,.071,0)],'sash','spine',seg=48,sub=0)
    m.ball('Sash_knot',(0,1.36,.082),(.033,.035,.015),'sash','spine')
    m.flat('Sash_tail',[(-.012,1.35,.084),(.012,1.35,.084),(.024,.90,.09),(-.013,.90,.09)],'sash','spine')
    return m

def bloop():
    m=Model('bloop',dict(skin='#70CCC1',spot='#45A69F',apron='#C86F35',seam='#7C3D21',stain='#A75A2C',antenna='#EE8766'),1.39)
    profile=[(1.19,.015,.013,0),(1.17,.10,.077,0),(1.05,.164,.122,0),(.83,.18,.145,0),(.61,.245,.190,0),(.35,.277,.204,0),(.19,.205,.15,0),(.16,.102,.078,0)]
    body=m.rings('Pear_body',profile,'skin','chest',seg=96,sub=9)
    # Two real ellipsoidal lobes, fused to the pear. Their intersection forms
    # a curved valley in depth, with no stroke or separate crease object.
    bm=bmesh.new();bm.from_mesh(body.data)
    bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00001)
    bmesh.ops.holes_fill(bm,edges=[e for e in bm.edges if e.is_boundary],sides=0)
    bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
    bm.to_mesh(body.data);bm.free()
    # The pear is already closed; remove the shell-thickness modifier before fusion.
    for mod in list(body.modifiers):body.modifiers.remove(mod)
    cheeks=[m.ball('Rear_cheek_'+str(sx),(sx*.115,.365,-.174),(.140,.165,.145),'skin','chest',seg=48) for sx in (-1,1)]
    bpy.ops.object.select_all(action='DESELECT')
    body.select_set(True)
    for cheek in cheeks:cheek.select_set(True)
    bpy.context.view_layer.objects.active=body;bpy.ops.object.join()
    fusion=body.modifiers.new('Fused_round_cheeks','REMESH');fusion.mode='VOXEL';fusion.voxel_size=.0055
    fusion.use_smooth_shade=True
    bpy.ops.object.modifier_apply(modifier=fusion.name)
    smooth=body.modifiers.new('Smooth_organic_join','SMOOTH');smooth.factor=.65;smooth.iterations=4
    bpy.ops.object.modifier_apply(modifier=smooth.name)
    reduce=body.modifiers.new('Reduce_fusion_density','DECIMATE');reduce.ratio=.35
    reduce.use_symmetry=True;reduce.symmetry_axis='X'
    bpy.ops.object.modifier_apply(modifier=reduce.name)
    body.data.update()
    # Subtle toon tone on lower facing surfaces keeps the new relief readable
    # under the game's unlit character materials.
    bc.material('rear_shade','#61B7AD',spec=0)
    body.data.materials.append(bc._MATS['rear_shade'])
    for face in body.data.polygons:
        p=face.center
        side_dist=min(1,abs(abs(p.x)-.115)/.14)
        lower_arc=.265+.075*max(0,1-side_dist*side_dist)
        underside=.205<p.z<lower_arc and face.normal.z<-.10
        if p.y>.215 and underside:
            face.material_index=len(body.data.materials)-1
        face.use_smooth=True
    samples=[]
    for x in (-.115,0,.115):
        hit=body.ray_cast(Vector((x,.6,.365)),Vector((0,-1,0)))
        assert hit[0], 'Rear surface missing'
        samples.append(hit[1].y)
    assert min(samples[0],samples[2])-samples[1]>.035, samples
    with open(os.path.join(bc.ROOT,'out/blender/bloop_rear_geometry.json'),'w') as f:
        json.dump({'method':'two ellipsoidal lobes fused into one continuous body',
                   'rear_depth_left_center_right_m':samples,'valley_depth_m':min(samples[0],samples[2])-samples[1],
                   'crease_line_object':False},f,indent=2)
    m.eye('Cyclops',0,1.012,.133,.097,.106,.041,b='chest')
    m.line('Smile',[(-.075,.888,.143),(-.035,.869,.158),(.035,.869,.158),(.075,.888,.143)],b='chest',r=.0018)
    for sx in (-1,1):
        side='R' if sx<0 else 'L'
        m.tube('Antenna',[(sx*.067,1.163,0),(sx*.087,1.278,0),(sx*.149,1.341,.005),(sx*.19,1.35,.008)],[.009,.009,.008,.007],'skin','chest',seg=16)
        m.ball('Antenna_tip',(sx*.19,1.35,.008),(.026,.026,.025),'antenna','chest')
        m.arm(side,(sx*.17,.85,0),(sx*.27,.63,.006),(sx*.349,.40,.04),.024,fingers=3)
        t='thigh.'+side;s='shin.'+side;f='foot.'+side
        m.bone(t,(sx*.115,.20,0),(sx*.14,.13,0),'pelvis');m.bone(s,(sx*.14,.13,0),(sx*.145,.07,0),t);m.bone(f,(sx*.145,.07,0),(sx*.19,.04,.10),s)
        m.tube('Stub_leg',[(sx*.12,.20,0),(sx*.14,.11,0),(sx*.155,.064,.03)],[.045,.039,.046],'skin',s)
        m.ball('Web_foot',(sx*.157,.046,.06),(.081,.026,.084),'skin',f)
        m.line('Toe_division',[(sx*.18,.051,.139),(sx*.177,.063,.10),(sx*.169,.066,.088)],'spot',f,r=.0014)
    # Curved apron fitted to the front of the belly.
    bm=bmesh.new();rows=[]
    for j in range(30):
        t=j/29;y=.80-.57*t;rx=.158+.053*t
        bx,bz,zc=profile_at(profile,y,5)
        rows.append([bm.verts.new(G(rx*(i/24*2-1),y,zc+bz*math.sqrt(max(.02,1-(rx*(i/24*2-1)/bx)**2))+.008)) for i in range(25)])
    for j in range(29):
        for i in range(24):bm.faces.new((rows[j][i],rows[j+1][i],rows[j+1][i+1],rows[j][i+1]))
    bmesh.ops.recalc_face_normals(bm,faces=bm.faces);bc._finish('Orange_apron',bm,Vector((0,0,0)),'apron',m.part('chest'),thick=.004)
    m.flat('Apron_pocket',[(-.09,.53,.222),(.09,.53,.222),(.092,.38,.225),(-.092,.38,.225)],'apron')
    m.line('Pocket_stitch',[(-.088,.529,.227),(-.09,.384,.23),(.09,.384,.23),(.088,.529,.227)],'seam','chest',r=.0012,sub=0)
    for sx in (-1,1):
        m.line('Apron_shoulder_strap',[(sx*.151,.79,.13),(sx*.176,.91,.029),(sx*.16,.83,-.10),(sx*.174,.62,-.16)],'apron','chest',r=.011)
        m.ball('Apron_rivet',(sx*.15,.789,.143),(.009,.009,.003),'stain','chest',seg=16)
    m.rings('Apron_waist_tie',[(.635,.246,.196,0),(.615,.249,.197,0)],'apron','chest',seg=56,sub=0)
    m.ball('Back_knot',(0,.625,-.205),(.022,.024,.015),'apron','chest')
    for sx in (-1,1):
        m.loop('Bow_loop',(sx*.037,.63,-.215),.029,.015,'apron','chest',r=.009)
        m.flat('Bow_tail',[(sx*.005,.62,-.215),(sx*.023,.62,-.217),(sx*.059,.52,-.222),(sx*.027,.517,-.222)],'apron')
    random.seed(8)
    for i in range(14):
        y=random.uniform(.30,.72);x=random.uniform(-.15,.15);bx,bz,zc=profile_at(profile,y,5);z=zc+bz*math.sqrt(max(.02,1-(x/bx)**2))+.011
        m.ball('Apron_stain',(x,y,z),(random.uniform(.007,.018),random.uniform(.009,.022),.002),'stain','chest',seg=16,detail=True)
    for sx in (-1,1):
        for y,x,z in [(1.10,.11,.08),(.58,.24,.10),(.40,.265,.07),(.34,.23,-.12),(.86,.148,-.10)]:m.ball('Skin_spot',(sx*x,y,z),(.012,.026,.005),'spot','chest',seg=20,detail=True)
    for i,(x,y,rx,ry) in enumerate([(-.065,1.10,.014,.021),(.075,1.04,.019,.026),(-.11,.96,.011,.020),
          (.115,.88,.016,.030),(-.055,.80,.018,.021),(.068,.73,.011,.017),(-.16,.55,.022,.032),
          (.14,.47,.017,.024),(-.11,.36,.013,.021),(.09,.30,.018,.023),(-.19,.43,.009,.015),(.18,.57,.010,.019)]):
        bx,bz,zc=profile_at(profile,y,5);z=zc-bz*math.sqrt(max(.01,1-(x/bx)**2))-.002
        # Project rear spots onto the fused body, including the rounded cheeks.
        hit=body.ray_cast(Vector((x,.6,y)),Vector((0,-1,0)))
        if hit[0]:z=-hit[1].y-.0015
        spot=m.ball('Back_spot_'+str(i),(x,y,z),(rx,ry,.002),'spot','chest',seg=20,detail=True)
        orient_spot(spot,(hit[2].x,hit[2].z,-hit[2].y) if hit[0] else (x/(bx*bx),0,z/(bz*bz)))
    return m

def kragg():
    m=Model('kragg',dict(shell='#CAA04D',spot='#A57C35',joint='#9F732F',claw='#765128',chip='#E7D7A0',poncho='#5F7F77',seam='#36564F',stain='#536B55'),1.20)
    m.ball('Low_domed_shell',(0,.54,0),(.36,.32,.255),'shell','chest',seg=48)
    # Overlapping abdominal plates and horizontal shell lip.
    for i in range(3):
        y=.29+i*.065;m.rings('Abdominal_plate'+str(i),[(y+.07,.31+i*.012,.227+i*.006,0),(y,.27+i*.019,.21+i*.009,0)],'shell','pelvis',seg=48,sub=1)
    m.rings('Shell_lip',[(.49,.363,.265,0),(.455,.37,.268,0)],'joint','chest',seg=64,sub=0)
    # Small distressed teal poncho leaves eyes, claws and all legs uncovered.
    pon=m.rings('Poncho',[(.69,.28,.215,0),(.63,.35,.254,0),(.48,.395,.28,0)],'poncho','chest',seg=72,sub=3)
    for v in pon.data.vertices:
        yy=v.co.z
        if yy<.54:
            a=math.atan2(v.co.x,-v.co.y);v.co.z-=.032*(.5+.5*math.sin(a*15))*(.54-yy)/.06
    for back in (-1,1):
        m.line('Poncho_fold',[(-.18,.638,back*.229),(0,.61,back*.263),(.19,.638,back*.228)],'seam','chest',r=.0013)
    for sx in (-1,1):
        side='R' if sx<0 else 'L';eye='eye_stalk.'+side
        m.bone(eye,(sx*.12,.77,.06),(sx*.155,1.04,.064),'head')
        m.tube('Eye_stalk',[(sx*.115,.77,.066),(sx*.13,.90,.071),(sx*.16,1.034,.071)],[.023,.018,.021],'shell',eye,seg=20)
        for y in (.83,.94):m.ball('Stalk_joint',(sx*(.12+(y-.77)*.15),y,.07),(.023,.018,.023),'joint',eye,seg=20)
        m.eye(side,sx*.163,1.097,.074,.063,.067,.055,b=eye)
        # Exactly three walking legs per side, separated in depth.
        for k,z in enumerate((.15,0,-.17)):
            upper='leg'+str(k)+'.'+side;lower='legtip'+str(k)+'.'+side
            a=(sx*(.18+.06*k),.43,z);e=(sx*(.20+.09*k),.27,z+.018);w=(sx*(.22+.095*k),.07,z+.035)
            m.bone(upper,a,e,'pelvis');m.bone(lower,e,w,upper)
            m.tube('Leg_upper',[a,e],[.044,.036],'shell',upper,seg=18,sub=0)
            m.ball('Leg_joint',e,(.041,.038,.04),'joint',lower,seg=20)
            m.tube('Leg_lower',[e,(w[0],.13,w[2])],[.034,.024],'shell',lower,seg=18,sub=0)
            m.tube('Leg_point',[(w[0],.15,w[2]),w],[.025,.003],'claw',lower,seg=16,sub=0)
        # Two articulated claw arms; two curved pincers with a visible gap.
        a=(sx*.30,.52,.10);e=(sx*.418,.46,.14);w=(sx*.47,.34,.18)
        up='upper_arm.'+side;lo='forearm.'+side;hand='hand.'+side
        m.bone(up,a,e,'chest');m.bone(lo,e,w,up);m.bone(hand,w,(sx*.48,.17,.19),lo)
        m.tube('Claw_arm',[a,e,w],[.049,.048,.041],'shell',up,seg=20)
        m.ball('Claw_elbow',e,(.049,.043,.047),'joint',lo)
        m.ball('Claw_palm',(sx*.48,.31,.20),(.073,.103,.052),'shell',hand,seg=32)
        for sign in (-1,1):
            xx=sx*.48+sign*.046
            m.tube('Pincer',[(xx,.27,.201),(xx+sign*.015,.20,.207),(xx,.14,.211),(sx*.48+sign*.009,.17,.216)],[(.027,.036),(.027,.029),(.014,.019),(.001,.001)],'claw',hand,ref=(1,0,0),seg=20)
        m.flat('Shell_chip',[(sx*.20,.79,.123),(sx*.27,.737,.14),(sx*.25,.705,.185),(sx*.214,.72,.201),(sx*.18,.735,.19)],'chip')
        m.line('Chip_crack',[(sx*.20,.79,.128),(sx*.215,.75,.183),(sx*.20,.73,.195)],'joint','chest',r=.0011,sub=0)
    m.line('Shell_mouth',[(-.086,.727,.198),(0,.728,.213),(.086,.727,.198)],b='chest',r=.0022)
    random.seed(9)
    for i in range(35):
        a=random.uniform(0,2*PI);e=random.uniform(.30,1.2);x=.363*math.cos(e)*math.sin(a);y=.54+.323*math.sin(e);z=.258*math.cos(e)*math.cos(a)
        if z>.13 and abs(x)<.13:continue
        spot=m.ball('Shell_mottle',(x,y,z),(.009+random.random()*.012,.007+random.random()*.01,.002),'spot','chest',seg=16,detail=True)
        orient_spot(spot,(x/.36**2,(y-.54)/.32**2,z/.255**2))
    return m

def luma():
    m=Model('luma',dict(skin='#A3E4C2',spot='#B7A5D8',rim='#D3E9E4',vest='#D68C79',vest_line='#A45D50',belt='#514637',bag='#6C4B61',bag_line='#432E41'),1.87)
    # Bell silhouette with a waved thin rim; closed underneath with a narrow neck.
    prof=[(1.79,.004,.004,0),(1.77,.08,.066,0),(1.69,.158,.116,0),(1.57,.221,.151,0),(1.46,.289,.183,0),(1.405,.338,.197,0),(1.375,.313,.184,0),(1.39,.242,.14,0),(1.39,.095,.055,0),(1.32,.048,.042,0)]
    m.rings('Bell_head',prof,'skin','head',wave=.012,seg=80,sub=4)
    for r,y in [(1,1.394),(.96,1.38)]:
        m.line('Bell_rim',[(.33*r*math.sin(a),y+.012*math.cos(7*a),.195*r*math.cos(a)) for a in [2*PI*i/100 for i in range(101)]],'rim','head',r=.004,sub=0)
    for sx in (-1,1):
        m.eye(str(sx),sx*.083,1.545,.164,.061,.073,.036)
        for k in range(2):m.line('Eyelash',[(sx*(.126+k*.009),1.59+k*.012,.183),(sx*(.144+k*.012),1.602+k*.014,.182)],b='head',r=.0013,sub=0)
        m.line('Brow',[(sx*.043,1.653,.128),(sx*.077,1.662,.136),(sx*.108,1.651,.129)],b='head',r=.0013)
    m.line('Wavy_mouth',[(-.026,1.44,.188),(-.012,1.447,.192),(0,1.44,.194),(.012,1.446,.192),(.025,1.44,.188)],r=.0015)
    random.seed(10)
    for i in range(30):
        a=2*PI*i/30;y=random.uniform(1.46,1.75)
        rx,rz,zc=profile_at(prof,y)
        x=(rx+.001)*math.sin(a);z=(rz+.001)*math.cos(a)
        if z>.1 and abs(x)<.15 and y<1.65:continue
        spot=m.ball('Lavender_spot',(x,y,z),(.018,.013,.002),'spot',seg=20,detail=True)
        orient_spot(spot,(math.sin(a),.65,math.cos(a)))
    m.rings('Body',[(1.34,.047,.04,0),(1.25,.084,.062,0),(1.08,.091,.065,0),(.94,.108,.076,0),(.84,.105,.076,0)],'skin','chest')
    m.ball('Rounded_pelvis',(0,.88,0),(.111,.085,.078),'skin','pelvis',seg=32)
    m.rings('Open_coral_vest',[(1.315,.057,.05,0),(1.26,.10,.076,0),(1.10,.109,.081,0),(1.04,.118,.085,0)],'vest','chest',opening=.58,seg=48)
    for sx in (-1,1):
        m.line('Vest_front_edge',[(sx*.033,1.31,.046),(sx*.058,1.20,.074),(sx*.064,1.04,.074)],'vest_line','chest',r=.0013)
        m.flat('Vest_pocket',[(sx*.065,1.15,.080),(sx*.091,1.15,.066),(sx*.102,1.09,.060),(sx*.068,1.088,.080)],'vest')
        side='R' if sx<0 else 'L';up='upper_arm.'+side;lo='forearm.'+side
        a=(sx*.091,1.265,0);e=(sx*.187,1.087,.015);w=(sx*.303,.91,.04)
        m.bone(up,a,e,'chest');m.bone(lo,e,w,up)
        m.tube('Arm_tentacle_top',[a,(sx*.13,1.16,.008),e],[.022,.026,.031],'skin',up,seg=22)
        m.tube('Arm_tentacle_end',[e,(sx*.30,.98,.034),(sx*.31,.87,.042),(sx*.28,.865,.046)],[.031,.041,.031,.008],'skin',lo,seg=24)
        for k in range(3):m.ball('Arm_spot',(sx*(.23+k*.024),1.04-k*.045,.066),(.012,.019,.003),'spot',lo,seg=16,detail=True)
    m.rings('Waist_belt',[(1.027,.112,.081,0),(1.006,.113,.082,0)],'belt','pelvis',seg=48,sub=0)
    m.ball('Hip_pouch',(.085,1.002,.088),(.058,.055,.029),'bag','pelvis')
    m.flat('Pouch_flap',[(.039,1.034,.105),(.128,1.034,.108),(.11,.995,.122),(.071,.981,.121)],'bag','pelvis')
    m.line('Pouch_seam',[(.044,1.03,.116),(.065,.974,.115),(.11,.977,.115)],'bag_line','pelvis',r=.0012)
    # Three separate lower tentacles, splayed in depth and sideways.
    for k,(x,z) in enumerate([(-.073,.013),(0,.055),(.073,-.038)]):
        n='tentacle'+str(k);tip=n+'_tip';sign=(-1,1,1)[k]
        a=(x,.91,z);b=((-.115,.005,.14)[k],.63,z);c=((-.21,.055,.255)[k],.34,z+.04);d=((-.16,.015,.205)[k],.23,z+.08)
        m.bone(n,a,b,'pelvis');m.bone(tip,b,d,n)
        m.tube('Tentacle_top'+str(k),[a,(x,.77,z),b],[.049,.044,.035],'skin',n,seg=24)
        m.tube('Tentacle_end'+str(k),[b,c,d,(d[0]+sign*.008,.213,d[2]+.015)],[.035,.042,.025,.004],'skin',tip,seg=24)
        for j in range(3):
            t=j/3;xx=b[0]*(1-t)+c[0]*t;yy=b[1]*(1-t)+c[1]*t
            m.ball('Tentacle_spot',(xx,yy,z+.043),(.010,.023,.003),'spot',tip,seg=18,detail=True)
    return m

if __name__=='__main__':
    args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else ['odette']
    name=args[0]
    assert name in ('odette','leon','vexa','bloop','kragg','luma')
    globals()[name]().finish()
