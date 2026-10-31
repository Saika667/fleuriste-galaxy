"""Metric native architecture based on opposite_buildings_sheet.png. Front is +Z."""
import os,sys,math
import bpy
sys.path.insert(0,os.path.dirname(__file__))
exec(open(os.path.join(os.path.dirname(__file__),'surface_collection.py'),encoding='utf-8').read().split('\nSPECS=')[0],globals())
OUT=os.path.join(bc.ROOT,'assets/models/street');SOURCE=os.path.join(bc.ROOT,'art/blender/street')
os.makedirs(OUT,exist_ok=True);os.makedirs(SOURCE,exist_ok=True)

def window(r,x,y,z,balcony=False,shutters=False,w=1.1,h=1.75):
    box('Window_recess',(w+.22,h+.22,.09),(x,y,z),'recess',r,.015)
    box('Window_glass',(w,h,.04),(x,y,z+.06),'blue_glass',r,.005)
    for dx in [-w/2,w/2]:box('Stone_jamb',(.095,h+.12,.14),(x+dx,y,z+.10),'limestone',r,.012)
    for dy in [-h/2,h/2]:box('Lintel',(w+.22,.12,.18),(x,y+dy,z+.12),'limestone',r,.012)
    box('Projecting_sill',(w+.40,.13,.35),(x,y-h/2-.04,z+.18),'limestone',r,.02)
    for dx in [-w*.22,0,w*.22]:box('Window_mullion',(.032,h,.035),(x+dx,y,z+.09),'cream',r,.003)
    box('Window_crossrail',(w,.042,.035),(x,y+.2,z+.09),'cream',r,.003)
    if shutters:
        for sign in [-1,1]:
            box('Timber_shutter',(.40,h,.065),(x+sign*(w/2+.28),y,z+.09),'shutter',r,.01)
            for k in range(16):
                slat=box('Shutter_louvre',(.34,.055,.045),(x+sign*(w/2+.28),y-h*.44+k*h*.058,z+.145),'teal_dark',r,.003);slat.rotation_euler.x=-.35
            for dy in [-h*.42,h*.42]:box('Shutter_iron_hinge',(.34,.035,.022),(x+sign*(w/2+.28),y+dy,z+.18),'iron',r,.004)
            for dx in [-.18,.18]:box('Shutter_stile',(.034,h,.03),(x+sign*(w/2+.28)+dx,y,z+.15),'shutter',r,.004)
    if balcony:
        box('Balcony_stone_base',(w+.55,.11,.58),(x,y-h/2-.11,z+.30),'limestone',r,.025)
        for dy in [0,.65]:box('Iron_balcony_rail',(w+.45,.035,.035),(x,y-h/2+dy,z+.55),'iron',r,.005)
        for k in range(9):box('Iron_baluster',(.023,.65,.023),(x-w/2-.13+k*(w+.26)/8,y-h/2+.32,z+.55),'iron',r,.003)
        for sign in [-1,1]:box('Balcony_return',(.035,.035,.50),(x+sign*(w/2+.22),y-h/2+.65,z+.3),'iron',r,.004)

def building(name,w,levels,facade,kind):
    r=root(name)
    for k,c in {'facade':facade,'limestone':'#D9CBB0','slate':'#4B5861','slate_seam':'#667079','blue_glass':'#49646C','recess':'#27363B','iron':'#354640','cream':'#DDD8C8','shutter':'#7E9586','brick':'#9E6C50'}.items():bc.material(k,c)
    h=3.05*levels;depth=7.0;z=depth/2
    box('Building_masonry',(w,h,depth),(0,h/2,0),'facade',r,.035)
    box('Stone_plinth',(w+.06,.45,depth+.06),(0,.225,0),'limestone',r,.025)
    for y in [3.05*i for i in range(1,levels)]+[h-.12,h+.10]:box('Continuous_cornice',(w+.28,.16,depth+.25),(0,y,0),'limestone',r,.025)
    for x in [-w/2+.16,w/2-.16]:
        for k in range(int(h/.42)):box('Corner_quoins',(.36,.37,.13),(x,.55+k*.42,z+.045),'limestone',r,.008)
    if kind=='corner':
        for sign in [-1,1]:
            for level in range(levels):
                for zz in [-2.2,0,2.2]:
                    xx=sign*(w/2+.03);yy=1.48+level*3.05
                    box('Side_glass',(.05,1.75,1.1),(xx,yy,zz),'blue_glass',r,.007)
                    for dy in [-.9,.9]:box('Side_lintel',(.19,.12,1.3),(xx+sign*.03,yy+dy,zz),'limestone',r,.014)
                    for dz in [-.59,.59]:box('Side_jamb',(.14,1.8,.09),(xx+sign*.03,yy,zz+dz),'limestone',r,.01)
                    box('Side_window_mullion',(.06,1.75,.035),(xx+sign*.04,yy,zz),'cream',r,.004)
    columns=3 if w>=10 else 2;xs=[-w*.33+i*(w*.66)/(columns-1) for i in range(columns)]
    for level in range(levels):
        for x in xs:
            if level==0 and abs(x)<.5:continue
            window(r,x,1.48+level*3.05,z+.01,balcony=level>0 and kind!='workshop',shutters=kind=='house')
            if level>0:
                rear=bc.pivot('Rear_window',bc.G(x,1.48+level*3.05,-z-.03),r);rear.rotation_euler.z=math.pi
                window(rear,0,0,0,w=.95,h=1.55,shutters=True)
    box('Entry_frame',(1.55,2.5,.18),(0,1.25,z+.05),'limestone',r,.025)
    box('Entry_door',(1.22,2.23,.08),(0,1.12,z+.16),'teal_dark',r,.012)
    for y in [.54,1.25,1.90]:box('Door_recess_panel',(.93,.45,.03),(0,y,z+.21),'shutter',r,.012)
    box('Entry_threshold',(1.65,.08,.5),(0,.04,z+.22),'limestone',r,.015)
    oval('Door_knob',(.63,1.02,z+.24),(.045,.045,.045),'gold',r)
    for dx in [-.52,.52]:box('Door_moulding',(.04,1.9,.025),(dx,1.12,z+.22),'cream',r,.006)
    for yy in [.35,.80,1.10,1.48,1.69,2.02]:box('Panel_moulding',(1.0,.025,.025),(0,yy,z+.235),'limestone',r,.005)
    box('Letter_slot',(.32,.055,.02),(0,.84,z+.25),'gold',r,.005)
    box('Entry_transom',(.98,.27,.025),(0,2.10,z+.235),'blue_glass',r,.005)
    for xx in [-.31,0,.31]:box('Transom_muntin',(.018,.27,.02),(xx,2.10,z+.255),'iron',r,.003)
    for xx in [-.9,.9]:
        box('Entry_pilaster',(.18,2.6,.28),(xx,1.3,z+.12),'limestone',r,.025)
        box('Pilaster_cap',(.29,.14,.38),(xx,2.55,z+.16),'limestone',r,.018)
    box('Entry_pediment',(2.15,.17,.48),(0,2.69,z+.18),'limestone',r,.025)
    box('House_number',(.19,.15,.024),(.99,1.8,z+.17),'teal_dark',r,.01)
    letters('House_number_text','12',(.99,1.76,z+.19),.09,'cream',r)
    # Rear elevations are real architecture, with outward projecting joinery.
    rear=bc.pivot('Garden_doorway',bc.G(0,0,-z-.04),r);rear.rotation_euler.z=math.pi
    box('Garden_entry_door',(1.05,2.20,.08),(0,1.10,.04),'shutter',rear,.012)
    for dx in [-.59,.59]:box('Garden_door_jamb',(.12,2.32,.21),(dx,1.16,.08),'limestone',rear,.008)
    box('Garden_lintel',(1.30,.15,.25),(0,2.36,.09),'limestone',rear,.008)
    window(rear,-w*.30,1.52,0,w=1.10,h=1.45,shutters=True)
    window(rear,w*.30,1.52,0,w=1.10,h=1.45,shutters=True)
    box('Rear_threshold',(1.38,.12,.60),(0,.06,.22),'limestone',rear,.012)
    for x in [-w/2+.22,w/2-.22]:
        tube('Rear_downpipe',[(x,.15,-z-.16),(x,h-.10,-z-.16)],.045,'steel_dark',r)
        for y in [1,3.3,5.5]:box('Rear_pipe_clamp',(.15,.05,.17),(x,y,-z-.10),'iron',r,.004)
    for sign in [-1,1]:
        side=bc.pivot('Side_joinery',bc.G(sign*(w/2+.03),0,0),r);side.rotation_euler.z=-sign*math.pi/2
        for level in range(levels):
            for x in [-1.8,1.8]:window(side,x,1.48+level*3.05,0,w=.85,h=1.4,shutters=True)
    # Real gable volume, eaves and roof courses rather than a flat colored block.
    roof=1.75 if kind!='corner' else 2.25
    mesh('Pitched_slate_roof',[(-w/2-.25,h,-z-.30),(w/2+.25,h,-z-.30),(-w/2-.25,h,z+.30),(w/2+.25,h,z+.30),(-w/2-.25,h+roof,0),(w/2+.25,h+roof,0)],[(4,5,1,0),(3,5,4,2),(2,4,0),(5,3,1)],'slate',r,.015)
    for row in range(10):
        zz=z+.30-(row+.5)*(z+.30)/10;yy=h+roof*(1-zz/(z+.30))+.018
        box('Slate_course',(w+.50,.025,.035),(0,yy,zz),'slate_seam',r,.002)
    tube('Zinc_gutter',[(-w/2-.15,h-.04,z+.35),(w/2+.15,h-.04,z+.35)],.075,'steel_dark',r)
    for x in [-w/2+.25,w/2-.25]:
        tube('Rainwater_downpipe',[(x,h,z+.38),(x,h-.35,z+.29),(x,.2,z+.29)],.048,'steel_dark',r)
        for y in [1.0,3.4,5.8]:box('Downpipe_bracket',(.18,.055,.16),(x,y,z+.25),'iron',r,.006)
    for x in [-w*.34,w*.34]:
        box('Chimney_stack',(.65,1.7,.72),(x,h+roof-.25,-.9),'facade',r,.025)
        box('Chimney_cap',(.80,.13,.86),(x,h+roof+.62,-.9),'limestone',r,.015)
        for dx in [-.17,.17]:cylinder(r,'Terracotta_flue',.10,.42,(x+dx,h+roof+.84,-.9),'brick')
    if kind=='corner':
        for x in xs:
            box('Dormer_body',(1.35,1.50,.85),(x,h+.65,1.4),'limestone',r,.02)
            window(r,x,h+.66,1.86,w=.8,h=1.1)
            mesh('Dormer_pediment',[(x-.82,h+1.43,1.92),(x+.82,h+1.43,1.92),(x,h+1.95,1.92)],[(0,1,2)],'slate',r,.01)
    if kind=='bakery':
        for x in [-w*.32,w*.32]:
            box('Shop_display_recess',(3.1,1.95,.12),(x,1.30,z+.27),'recess',r,.02)
            for dx in [-1.6,1.6]:box('Shop_window_jamb',(.12,2.1,.18),(x+dx,1.30,z+.33),'walnut',r,.015)
            for yy in [.27,2.33]:box('Shop_window_horizontal',(3.3,.12,.18),(x,yy,z+.33),'walnut',r,.015)
            for yy in [.65,1.25,1.85]:
                box('Display_shelf',(3,.055,.20),(x,yy,z+.36),'wood',r,.009)
                for k in range(5):oval('Stylized_bread',(x-1.1+k*.55,yy+.10,z+.40),(.22,.10,.09),'gold',r)
        box('Shop_fascia',(w-.65,.64,.22),(0,3.12,z+.20),'walnut',r,.025)
        letters('Bakery_sign','BOULANGERIE',(0,2.95,z+.33),.43,'cream',r,font='georgia.ttf')
        for k in range(20):
            a=box('Striped_canvas',((w-.8)/20,.055,1.20),(-w/2+.4+(k+.5)*(w-.8)/20,2.55,z+.65),'cream' if k%2 else 'brick',r,.01);a.rotation_euler.x=.16
            box('Awning_valance',((w-.8)/20,.17,.055),(-w/2+.4+(k+.5)*(w-.8)/20,2.39,z+1.22),'cream' if k%2 else 'brick',r,.013)
        for xx in [-w*.42,w*.42]:tube('Awning_support',[(xx,2.0,z+.36),(xx,2.43,z+1.17),(xx,2.53,z+.4)],.025,'iron',r)
        bc.material('shop_glass','#B5D2D5')
        glass=bc._MATS['shop_glass'];glass.node_tree.nodes['Principled BSDF'].inputs['Alpha'].default_value=.18;glass.surface_render_method='DITHERED'
        for xx in [-w*.32,w*.32]:
            box('Display_glass',(3.05,1.88,.012),(xx,1.30,z+.48),'shop_glass',r,.003)
            for dx in [-.76,.76]:box('Display_mullion',(.045,1.93,.05),(xx+dx,1.30,z+.50),'cream',r,.005)
            letters('Window_gold_lettering','PAINS · PÂTISSERIES',(xx,1.81,z+.52),.14,'gold',r,font='georgia.ttf')
        tube('Projecting_sign_bracket',[(w*.42,3.35,z+.15),(w*.42,3.35,z+1.35)],.034,'iron',r)
        box('Hanging_bakery_sign',(1.9,.48,.09),(w*.42,3.02,z+1.31),'walnut',r,.035)
        letters('Hanging_sign_title','BOULANGERIE',(w*.42,2.94,z+1.37),.175,'cream',r,font='georgia.ttf')
    if kind=='workshop':
        box('Workshop_double_door',(w*.42,2.50,.10),(0,1.25,z+.24),'steel_dark',r,.02)
        for x in [-w*.14,0,w*.14]:window(r,x,1.8,z+.31,w=.65,h=.9)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SOURCE,name+'.blend'));bc.export_glb(os.path.join(OUT,name+'.glb'),r)
    print('ARCHITECTURE_MODEL',name,flush=True)

for spec in [('corner_apartments',12,3,'#C4B99F','corner'),('sage_townhouse',10,2,'#9BA88B','house'),('brick_bakery',12,3,'#AF7C60','bakery'),('blue_workshop',8,2,'#899FA5','workshop')]:building(*spec)
