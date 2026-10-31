"""Finish overlooked variants using the already approved botanical design vocabulary."""
import os,sys,json,struct,math
import bpy
sys.path.insert(0,os.path.dirname(__file__))
exec(open(os.path.join(os.path.dirname(__file__),'surface_collection.py'),encoding='utf-8').read().split('\nSPECS=')[0],globals())
OUT=os.path.join(bc.ROOT,'assets/models/completion');BLEND=os.path.join(bc.ROOT,'art/blender/completion')
os.makedirs(OUT,exist_ok=True);os.makedirs(BLEND,exist_ok=True)
def garden_bench():
    r=root('BotanicalGardenBench')
    for z in [-.21,-.07,.07,.21]:plank(r,(0,.455,z),(1.9,.055,.13),'walnut')
    for x in [-.78,.78]:
        for z in [-.22,.22]:tube('Cast_iron_foot',[(x+(.04 if x>0 else -.04),.02,z+.03),(x,.20,z),(x,.46,z)],.028,'teal_dark',r)
        tube('Curved_back_stanchion',[(x,.26,-.22),(x,.68,-.27),(x,.97,-.32)],.025,'teal_dark',r)
        tube('Rolled_armrest',[(x,.43,.23),(x,.64,.23),(x,.67,-.24)],.023,'teal',r)
        front_loop('Arm_scroll',x,.57,.05,.035,.055,.010,'gold',r)
    for y in [.68,.80,.92]:plank(r,(0,y,-.29),(1.87,.085,.038),'walnut')
    leaf_emblem(r,(0,.80,-.265),.060,'gold')
    tube('Underseat_stretcher',[(-.78,.24,0),(.78,.24,0)],.022,'teal_dark',r)
    box('Rose_seat_cushion',(.48,.055,.35),(-.42,.51,.01),'pink',r,.035)
    for x in [-.88,.88]:
        for y in [.68,.80,.92]:screw(r,(x,y,-.265),.007,'gold')
    return r
def workshop_window():
    r=root('BotanicalWorkshopWindow');w=2.2;h=1.7
    frame(r,w,h,'walnut')
    for x in [-w/2,w/2]:box('Inner_moulding',(.027,h,.035),(x,0,.055),'gold',r,.004)
    for y in [-h/2,h/2]:box('Inner_moulding',(w,.027,.035),(0,y,.055),'gold',r,.004)
    box('Center_mullion',(.045,h,.07),(0,0,.025),'teal',r,.008)
    box('Horizontal_mullion',(w,.04,.07),(0,.16,.025),'teal',r,.008)
    for x in [-.55,.55]:box('Clear_pane',(1.04,1.62,.006),(x,0,0),'glass',r)
    box('Timber_sill',(2.38,.075,.23),(0,-.90,.035),'walnut',r,.015)
    for x in [-.04,.04]:box('Latch_plate',(.03,.11,.008),(x,-.18,.068),'gold',r,.004)
    tube('Brass_latch',[(-.04,-.18,.08),(.06,-.13,.08)],.009,'gold',r)
    return r
def pavement_board():
    r=root('BotanicalLivePavementBoard')
    for z in [-.17,.24]:
        for x in [-.47,.47]:tube('Splayed_leg',[(x,0,z),(x,1.19,0)],.027,'walnut',r)
    box('Board_body',(.9,.92,.07),(0,.74,0),'teal_dark',r,.035)
    for x in [-.43,.43]:box('Carved_side_moulding',(.045,.89,.045),(x,.74,.055),'walnut',r,.012)
    for y in [.30,1.18]:box('Carved_header',(.89,.045,.045),(0,y,.055),'walnut',r,.012)
    bc.material('board_neon','#F2B9B2')
    m=bc._MATS['board_neon'];bs=m.node_tree.nodes['Principled BSDF'];bs.inputs['Emission Color'].default_value=bc.hex_color('#F2B9B2');bs.inputs['Emission Strength'].default_value=.8
    tube('Live_neon_border',[(-.37,.35,.080),(.37,.35,.080),(.39,.37,.080),(.39,1.10,.080),(.37,1.12,.080),(-.37,1.12,.080),(-.39,1.10,.080),(-.39,.37,.080),(-.37,.35,.080)],.004,'board_neon',r)
    letters('Flat_queue_title',"EN FILE\nD'ATTENTE",(0,.70,.055),.075,'pink',r,'COOPBL.TTF')
    for x in [-.32,.32]:leaf_emblem(r,(x,1.08,.058),.040,'gold')
    for name,y in [('StateAnchor',.94),('CountAnchor',.48)]:bc.pivot(name,bc.G(0,y,.066),r)
    return r
BUCKETS.extend([('bucket_clearance','steel',.40,.18,'SOLDES\nFUNÈBRES'),('bucket_biting','steel_dark',.40,.18,'MORDENT\nUN PEU')])
SPECS=[('garden_bench',garden_bench),('workshop_window',workshop_window),('pavement_board',pavement_board),('bucket_clearance',lambda:bucket(6)),('bucket_biting',lambda:bucket(7))]
report=[]
for name,build in SPECS:
    n=build();n['completion_asset']=name;bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BLEND,name+'.blend'));path=os.path.join(OUT,name+'.glb');bc.export_glb(path,n)
    raw=open(path,'rb').read();length=struct.unpack_from('<I',raw,12)[0];g=json.loads(raw[20:20+length]);report.append(dict(asset=name,triangles=sum(g['accessors'][p['indices']]['count']//3 for m in g['meshes'] for p in m['primitives'])))
json.dump(report,open(os.path.join(OUT,'manifest.json'),'w'),indent=2);print('COMPLETION_MODELS_COMPLETE',len(report),flush=True)
