"""Source migration for the October 30 district revision. Run once."""
from pathlib import Path
def edit(file,fn):
 p=Path(file);p.write_text(fn(p.read_text(encoding='utf-8')),encoding='utf-8')
def neighborhood(s):
 start=s.index('\tfor x in [-17,-6,6,17,24]:')
 s=s[:start]+'''\tvar detail=preload("res://src/world/district_detail.gd")
\tdetail.pavement(row,18.0,3.4);detail.pavement(row,9.35,2.3)
\tfor x in [-17,-6,6,17,27]:
\t\tdetail.attach(row,"street_lamp",Vector3(x,0,16.65),PI)
\t\tdetail.attach(row,"street_lamp",Vector3(x,0,10.10))
\tfor x in [-12,1,23]:
\t\tdetail.tree(row,Vector3(x,0,18.4),int(x));detail.bench(row,Vector3(x+2.4,0,18.5),PI)
\tfor x in [-20,32]:detail.tree(row,Vector3(x,0,9.4),int(x));detail.bench(row,Vector3(x+2.2,0,9.2),0)
\t# Continue the same architectural vocabulary on the shop side, with varied plaster.
\tfor spec in [["sage_townhouse",-22,Color("#B5A2AC")],["corner_apartments",35,Color("#BAAD86")],["blue_workshop",45,Color("#A3B6AE")]]:
\t\tdetail.house(row,spec[0],Vector3(spec[1],0,4.4),0,spec[2])
static func alley(parent: Node3D) -> void:
\tvar root=Node3D.new();root.name="AlleyArchitecture";parent.add_child(root)
\tvar detail=preload("res://src/world/district_detail.gd")
\t# Actual houses with depth, roofs and front doors, stepped with the slope.
\tfor i in 3:
\t\tvar z=1.0-i*7.2;var y=(z-6)*4.24/24
\t\tdetail.house(root,"sage_townhouse",Vector3(23.0,y,z),-PI/2,[Color("#A8B79D"),Color("#C1AA99"),Color("#A2B0BC")][i],.72)
\t\tvar body=StaticBody3D.new();root.add_child(body);K.solid(body,Vector3(5.1,4.5,7.2),Vector3(23.0,y+2.25,z))
\t# Tall service house closes the old gap beside the shed; no free-standing flat wall.
\tdetail.house(root,"blue_workshop",Vector3(13.65,0,1.0),PI/2,Color("#B4A896"),.62)
\tvar body=StaticBody3D.new();root.add_child(body);K.solid(body,Vector3(4.34,4.2,4.95),Vector3(13.65,2.1,1.0))
'''
 return s
edit('src/world/neighborhood_v2.gd',neighborhood)
def lower(s):
 a=s.index('\tblock(alley,Vector3(24,.20,6)');b=s.index('\t# The ramp joins',a)
 s=s[:a]+'\tpreload("res://src/world/district_detail.gd").plaza(v,alley)\n'+s[b:]
 s=s.replace('3.30 if initial','3.60 if initial').replace('3.30 if opened','3.60 if opened')
 s=s.replace('Vector3(3.8,.18,1.6),Vector3(18.1,-4.29,-18.4)','Vector3(4.0,.18,3.4),Vector3(18.3,-4.29,-18.8)')
 return s
edit('src/world/lower_alley.gd',lower)
def shop(s):
 # Cut real holes out of every exterior slab, including invisible walking colliders.
 old='[Rect2(-65,-56,58,146),Rect2(20.7,-56,54.3,146),Rect2(-7,-56,27.7,36),Rect2(-7,-13.2,23.4,103.2),Rect2(16.4,6,4.3,84)]'
 s=s.replace(old,'preload("res://src/world/district_detail.gd").floor_rects(Rect2(-65,-56,140,146),[Rect2(16.4,-20.5,4.3,26.5),Rect2(-11,-38,34.5,24.8),Rect2(7.55,1.6,1.7,6.2)])')
 old='Collection54.attach(floor_root,"shop_floor_botanical",Vector3(W*.5,.01,D*.5))'
 new='''# A real opening over the cellar staircase; four floor pieces, no invisible slab.
\tfor rect in preload("res://src/world/district_detail.gd").floor_rects(Rect2(0,0,W,D),[Rect2(7.55,1.6,1.7,6.2)]):
\t\tvar c=rect.get_center();_pattern_quad(floor_root,FLOOR_SHADER,rect.size,Vector3(c.x,.012,c.y),Vector3(-PI/2,0,0))'''
 s=s.replace(old,new)
 # Wall seams were rounded slab edges; wallpaper also crossed the rear door opening.
 s=s.replace('color, radius, 0.9, 0.0, 0.12)','color, 0.002, 0.9, 0.0, 0.0)')
 s=s.replace('_pattern_quad(_wall_root, WALLPAPER, Vector2(W, wp_h), Vector3(W * 0.5, wp_y, 0.011), Vector3.ZERO)', '''for span in [[0.0,5.4],[6.43,W]]:
\t\t_pattern_quad(_wall_root,WALLPAPER,Vector2(span[1]-span[0],wp_h),Vector3((span[0]+span[1])/2,wp_y,.011),Vector3.ZERO)
\t_pattern_quad(_wall_root,WALLPAPER,Vector2(1.03,H-2.3),Vector3(5.915,2.3+(H-2.3)/2,.011),Vector3.ZERO)''')
 # Rear service door is 1.03 m incl leaf thickness, not 1.20 m.
 s=s.replace('6.6, W+T','6.43, W+T').replace('5.4, 6.6, 2.3','5.4, 6.43, 2.3').replace('6.6,W,1','6.43,W,1')
 # Northern skull was inside the new doorway.
 s=s.replace('Vector3(6.08,3.9675,.17)','Vector3(4.85,3.9675,.17)')
 # Retire old simplistic neighbor facades where replaced, keeping annex placeholder contract.
 s=s.replace('if b[0].z>12:continue','if b[0].z>12 or b[0].x < -16 or b[0].x>25:continue')
 return s
edit('src/world/shop_room.gd',shop)
def cellar(s):
 a=s.index('\tvar ceiling=C.attach');b=s.index('\t# Keep the original',a)
 s=s[:a]+'''\tCellarKit.solid(v,Vector3(24,.3,18),Vector3(0,-.15,0))
\tfor rect in preload("res://src/world/district_detail.gd").floor_rects(Rect2(-12,-12,24,21),[Rect2(-4.25,-12,1.7,8.4)]):
\t\tvar center=rect.get_center();var size=Vector3(rect.size.x,.24,rect.size.y);var pos=Vector3(center.x,3.92,center.y)
\t\tCellarKit.box(v,size,pos,CellarKit.stone(Color("6A5890"),.34));CellarKit.solid(v,size,pos)
'''+s[b:]
 a=s.index('\tCellarKit.box(v,Vector3(24,3.8,.2)');b=s.index('\tvar front=',a)
 s=s[:a]+'''\tfor span in [[-12.2,-4.25],[-2.55,12.2]]:
\t\tvar size=Vector3(span[1]-span[0],3.8,.25);var pos=Vector3((span[0]+span[1])/2,1.9,-9.1)
\t\tCellarKit.box(v,size,pos,CellarKit.stone(Color("6A5890"),.34));CellarKit.solid(v,size,pos)
'''+s[b:]
 a=s.index('static func stairs(v)');b=s.index('static func cabinet(v)',a)
 s=s[:a]+'''static func stairs(v) -> void:
\tvar k=preload("res://src/world/mesh_kit.gd")
\tvar stair=Node3D.new();stair.name="ContinuousCellarStair";v.add_child(stair)
\t# 4.2 m rise, six metres run, aligned with the physical shop-floor opening.
\tfor i in 28:
\t\tvar y=(i+1)*.15;var z=-5.8-(i+.5)*6.0/28
\t\tk.box(stair,Vector3(1.6,.15,6.0/28+.01),Vector3(-3.4,y-.075,z),Color("#7C777A"),.008)
\tvar body=StaticBody3D.new();stair.add_child(body)
\tvar angle=atan(4.2/6.0);var ramp=Node3D.new();body.add_child(ramp);ramp.position=Vector3(-3.4,2.1-.08,-8.8);ramp.rotation.x=angle
\tk.solid(ramp,Vector3(1.6,.16,sqrt(36+4.2*4.2)),Vector3.ZERO)
\t# Closed side walls enclose the stair beyond the old cellar wall.
\tfor x in [-4.32,-2.48]:
\t\tCellarKit.box(v,Vector3(.14,4.2,6.3),Vector3(x,2.1,-8.9),CellarKit.stone(Color("6A5890"),.34));CellarKit.solid(v,Vector3(.14,4.2,6.3),Vector3(x,2.1,-8.9))
\tC.attach(v,"entry_sign",Vector3(-4.45,1.7,-5.6))

'''+s[b:]
 a=s.index('static func hatch(v)');b=s.index('static func consoles(v)',a)
 s=s[:a]+'''static func hatch(_v) -> void:
\t# Hatch and its animation anchors are now created in the lower court.
\tpass

'''+s[b:]
 a=s.index('\t# Broad, warm lighting');b=s.index('\tC.attach(v,"fusebox"',a)
 s=s[:a]+'''\tvar k=preload("res://src/world/mesh_kit.gd")
\tfor x in [-8.0,0.0,8.0]:
\t\tfor z in [-5.0,2.0,6.5]:
\t\t\tk.box(v,Vector3(1.55,.07,.30),Vector3(x,3.70,z),Color("#4B5359"),.015)
\t\t\tfor dz in [-.085,.085]:
\t\t\t\tvar tube=k.cylinder(v,.028,.028,1.35,Vector3(x,3.64,z+dz),Color("#E4EADB"),.4,1.4);tube.rotation.z=PI/2
\t\t\tCellarKit.omni(v,Vector3(x,3.40,z),Color("E3E8D8"),1.4,7.8,false)
'''+s[b:]
 s=s.replace('C.attach(v,"skeleton",Vector3(-5.0,0,8.90),PI)','preload("res://src/world/district_detail.gd").attach(v,"skeleton",Vector3(-5.0,0,8.70),PI)')
 s=s.replace('C.attach(v,["mushroom_mint","mushroom_pink","mushroom_lilac"][i%3],pos,0,.6+(i%3)*.2)','var mushroom=preload("res://src/world/district_detail.gd").attach(v,"mushroom",pos);mushroom.scale=Vector3.ONE*(.65+(i%3)*.2)')
 return s
edit('src/cellar_view/cellar_remodel.gd',cellar)
edit('src/cellar_view/cellar_view.gd',lambda s:s.replace('const HATCH_POS := Vector3(7.0,0,3.0)','const HATCH_POS := Vector3(8.0,0,17.5)').replace('Vector3(-9.0,0.1,7.1)','Vector3(-3.4,0.1,-4.5)'))
edit('src/cellar_view/cellar_equipment_visual.gd',lambda s:s.replace('-8.0 if i==0 else 8.0','-4.0 if i==0 else 4.0').replace('3.30,-7.7','3.30,0.0').replace('for i in 16:C.attach(self,"duct_module",Vector3(-7.5+i,3.48,-7.7))','''for z in [-5.0,0.0,5.0]:
\t\tfor i in 20:C.attach(self,"duct_module",Vector3(-9.5+i,3.48,z))
\tfor x in [-8.0,4.0]:
\t\tfor i in 14:C.attach(self,"duct_module",Vector3(x,3.48,-6.5+i),PI/2)'''))
edit('src/world/player.gd',lambda s:s.replace('\tname = "Player"','''\tif not InputMap.has_action("jump"):
\t\tInputMap.add_action("jump");var key=InputEventKey.new();key.physical_keycode=KEY_SPACE;InputMap.action_add_event("jump",key)
\tname = "Player"''').replace('\t\tvelocity.y = -0.5','\t\tvelocity.y = 6.2 if active and Input.is_action_just_pressed("jump") else -0.5'))
edit('src/world/shop_extensions.gd',lambda s:s.replace('_sync("enlargement", owned.has("enlargement"),','_sync("enlargement", true,').replace('_sync("upstairs", owned.has("upstairs"),','_sync("upstairs", true,').replace('owned.has("upstairs") and owned.has("enlargement") and not nonew','not nonew').replace('room.set_ext_annex(owned.has("enlargement"))','room.set_ext_annex(true)').replace('JARDIN — 280 m²','JARDIN — 440 m²'))
edit('src/world/shop_world.gd',lambda s:s.replace('func _climb(player', 'func _climb(player',1).replace('\t_climbing = true','\tif up and not Game.expansions.is_owned("upstairs"):\n\t\ttoast.emit("L’étage sera accessible en avançant dans l’histoire.","info");return\n\t_climbing = true'))
edit('src/world/surface_remodel.gd',lambda s:s.replace('var r=Node3D.new();C.attach(r,"shed_shell",Vector3(10.83,0,6.2))','''var r=Node3D.new()
\t# Opaque planked walls and a complete pitched roof replace the one-sided shell.
\tfor spec in [[Vector3(.12,2.3,2.7),Vector3(10.26,1.15,6.2)],[Vector3(1.14,2.3,.12),Vector3(10.83,1.15,4.85)],[Vector3(1.14,2.3,.12),Vector3(10.83,1.15,7.55)]]:
\t\tK.box(r,spec[0],spec[1],Color("#8B795A"),.012)
\tfor z in [5.125,7.275]:K.box(r,Vector3(.12,2.3,.55),Vector3(11.4,1.15,z),Color("#8B795A"),.012)
\tfor z in [4.85,7.55]:
\t\tfor i in 7:K.box(r,Vector3(.13,2.3,.018),Vector3(10.32+i*.17,1.15,z+.065),Color("#A48B64"),.004)
\tfor x in [10.52,11.14]:
\t\tvar roof=K.box(r,Vector3(.75,.10,2.95),Vector3(x,2.48,6.2),Color("#465D5B"),.02);roof.rotation.z=.26 if x<10.8 else -.26
\tK.box(r,Vector3(.12,.12,3.02),Vector3(10.83,2.57,6.2),Color("#304D4B"),.025)'''))
def garden(s):
 s=s.replace('Vector3(22,.06,12.8),Vector3(5,-.03,-6.5)','Vector3(22,.06,20),Vector3(5,-.03,-10.0)').replace('Vector3(22,.18,12.8),Vector3(5,-.09,-6.5)','Vector3(22,.18,20),Vector3(5,-.09,-10)')
 s=s.replace('12.9','20.0').replace('Vector3(x,.575,-6.5)','Vector3(x,.575,-10)').replace('Vector3(5,.55,-13)','Vector3(5,.55,-20)')
 a=s.index('\tfor x in [9.4,13.5]:');b=s.index('\tC.attach(root,"garden_arch"',a)
 s=s[:a]+'''\t# Untended garden: uneven groups of weeds and flowers, never solid raised beds.
\tfor i in 32:
\t\tvar x=8.1+fmod(i*2.37,7.2);var z=-1.8-fmod(i*1.93,17.1)
\t\tR.flowers(root,Vector3(x,.01,z),2,"daisy" if i%3 else "poppy",.35,.20+(i%4)*.04)
'''+s[b:]
 s=s.replace('280 m²','440 m²').replace('Color("#718B4A")','Color("#536D38")').replace('range(-12.7,-.4)','range(-19.7,-.4)').replace('for i in 1600:','for i in 2400:')
 return s
edit('src/world/rear_garden_v2.gd',garden)
edit('src/world/free_layout.gd',lambda s:s.replace('Rect2(-6,-13,22,13)','Rect2(-6,-20,22,20)'))
edit('src/world/main.gd',lambda s:s.replace('free_layout.setup(self)','free_layout.setup(self)\n\t# Keep the same functional compost interface, now physically in the garden.\n\tcellar._composter.reparent(world,true);cellar._composter.global_position=Vector3(13.5,0,-16.5)').replace('ZQSD : marcher  -  E','ZQSD : marcher  -  Espace : sauter  -  E'))
