from pathlib import Path
import re
R=Path(__file__).resolve().parents[1]
def get(p):return (R/p).read_text(encoding='utf-8-sig')
def put(p,s):(R/p).write_text(s,encoding='utf-8')
def change(p,a,b):
 s=get(p);assert a in s,(p,a[:50]);put(p,s.replace(a,b))
change('src/world/main.gd','\tGame.apply_visitor_policy()','\tReviewAccess.active=ReviewAccess.ENABLED and not OS.get_cmdline_user_args().has("story-locks")\n\tGame.apply_visitor_policy()')
change('src/core/expansions.gd','return owned.has(id)','return ReviewAccess.active or owned.has(id)')
change('src/core/expansions.gd','return order().filter(func(i): return owned.has(i))','return order() if ReviewAccess.active else order().filter(func(i): return owned.has(i))')
p='src/world/lower_alley.gd';s=get(p);a=s.index('\tvar angle=');b=s.index('\tpreload("res://src/world/frontage_v4.gd").cellar',a);s=s[:a]+'\tpreload("res://src/world/district_v5.gd").alley(world_ramp)\n'+s[b:];put(p,s)
p='src/cellar_view/cellar_remodel.gd';s=get(p);a=s.index('\tvar mesh_kit=',s.index('static func stairs'));b=s.index('static func cabinet',a);s=s[:a]+'\tpreload("res://src/world/district_v5.gd").stairs(v)\n\n'+s[b:];s=s.replace('Rect2(-3.95,-12,1.1,4.9)','Rect2(-4.9,-7.5,1.1,3.8)').replace('[[-12.2,-3.95],[-2.85,12.2]]','[[-12.3,12.3]]').replace('Vector3(.2,3.8,18)','Vector3(.3,3.8,18.7)');put(p,s)
p='src/world/shop_room.gd';s=get(p).replace('Rect2(19.5,-21.7,9,32.3)','Rect2(19.0,-22,12,32.6)').replace('Rect2(7.85,3.1,1.1,4.6)','Rect2(8.8,-.2,1.1,3.6)')
# Explicit load-bearing slab for the shed, regardless of terrain/cellar cutouts.
s=s.replace('\t# clotures nord et sud','\tMeshKit.solid(_static,Vector3(3.5,.25,8.2),Vector3(11.75,-.125,4))\n\t# clotures nord et sud')
a=s.index('\tfor i in 16:',s.index('func _build_yard'));b=s.index('\t# The neighboring',a);s=s[:a]+s[b:]
# Remove the overhead invisible map ceiling, which would obstruct the relocated floor.
s=s.replace('Vector3(5, 7.0, 5)','Vector3(5, 11.5, 5)')
a=s.index('\tCollection54.attach(ceil_root,"shop_ceiling_botanical"');b=s.index('\tplacement_hide.append(ceil_root)',a)
s=s[:a]+'''\tfor rect in preload("res://src/world/district_detail.gd").floor_rects(Rect2(-.2,-.2,W+.4,D+.4),[Rect2(.22,.10,1.96,2.25)]):
\t\tvar center=rect.get_center();var size=Vector3(rect.size.x,.2,rect.size.y);var pos=Vector3(center.x,H+.1,center.y)
\t\tMeshKit.box(ceil_root,size,pos,Color("#DDE4D5"),0,.9,0,0);MeshKit.solid(_static,size,pos)
'''+s[b:]
s=s.replace('var roof = MeshKit.box(self, Vector3(W + 0.6, 0.3, D + 0.6), Vector3(W * 0.5, H + 0.35, D * 0.5), Color("#6E4A85"), 0.04)','var roof = Node3D.new();add_child(roof)')
# Door mouldings used to overlap the doorway posts; use flat ungraded box frames.
s=s.replace('color, 0.02, 0.9, 0.0, 0.12','color, 0.0, 0.9, 0.0, 0.0')
put(p,s)
change('src/world/player.gd','deg_to_rad(50)','deg_to_rad(60)')
p='src/world/neighborhood_v2.gd';s=get(p).replace('Vector3(x+2.4,0,18.5)','Vector3(x+2.4,0,17.95)').replace('Vector3(x+2.2,0,9.2)','Vector3(x+2.2,0,9.4)').replace('Vector3(31.0,y,z)','Vector3(34.0,y,z)').replace('Vector3(31.0,y+2.25,z)','Vector3(34.0,y+2.25,z)')
s=s.replace('var y=(z-10.6)*4.24/29.0','var y=preload("res://src/world/district_v5.gd").road_y(z)')
s=s.replace('\t\tvar body=StaticBody3D.new();root.add_child(body);K.solid(body,Vector3(5.1,4.5,7.2),Vector3(34.0,y+2.25,z))','\t\tpreload("res://src/world/lower_alley.gd").block(root,Vector3(5.10,y+5.2,7.25),Vector3(34,-5.2+(y+5.2)*.5,z),Color("#8E8D7D"))')
put(p,s)
p='src/world/district_detail.gd';s=get(p).replace('Rect2(19.5,8,9,3)','Rect2(19.0,8,12,3)').replace('Vector3(-7.5,-.1,25.4)','Vector3(-7.5,-.1,25.0)')
s=s.replace('else 19.5','else 19.5').replace('var x=-29.0 if side<0','var x=-33.0 if side<0').replace('-23.9 if side<0','-28.4 if side<0').replace('-22.4 if side<0','-26.9 if side<0')
s=s.replace('Vector3(x,0,34),0,Color("#AFB5A0") if x<0 else Color("#BBA68F"),.75','Vector3(x,0,33),0,Color("#AFB5A0") if x<0 else Color("#BBA68F"),1.0')
# Place garden furniture inside its own plot, with a clear path from the rear door.
s=s.replace('Vector3(x+1.5,0,29.6)','Vector3(x+2.4,0,28.5)')
a=s.index('\t# Tall buildings mask');b=s.index('\tvar sewer=',a);s=s[:a]+'\tpreload("res://src/world/district_v5.gd").perimeter(root)\n'+s[b:]
s=s.replace('"corner_apartments":12.0','"apartment_five":12.0,"corner_apartments":12.0').replace('var height=6.1 if','var height=18.3 if id=="apartment_five" else 6.1 if')
put(p,s)
p='src/world/shop_extensions.gd';s=get(p).replace('func refresh(owned: Array) -> void:','func refresh(owned: Array) -> void:\n\tif ReviewAccess.active:owned=GameData.get_data("expansions").order.duplicate()')
s=s.replace('"o": Vector2(-1.0, 0.0), "ex": Vector2(0, 1), "ez": Vector2(-1, 0), "y": 3.4','"o": Vector2(8.8, 0.0), "ex": Vector2(0, 1), "ez": Vector2(-1, 0), "y": 5.4')
s=s.replace('const STAIR_C := Vector3(-1.1,0,.95)','const STAIR_C := Vector3(1.2,0,1.1)').replace('const STAIR_RISE := 3.4','const STAIR_RISE := 5.4').replace('const LOFT_FLOOR_Y := 3.4','const LOFT_FLOOR_Y := 5.4')
s=s.replace('return Completion.balcony(self)','var r=Node3D.new();return r')
a=s.index('\t_set_ceiling_hole(true)',s.index('func _build_stairs'));b=s.index('\treturn n',a)
s=s[:a]+'''\tvar c=STAIR_C
\tvar Inter=preload("res://src/world/world_interactable.gd")
\tstair_bottom=_stair_body(Inter,n,c,2.4)
\tstair_top=_stair_body(Inter,n,Vector3(c.x,LOFT_FLOOR_Y,c.z),2.2)
\tloft_walk=preload("res://src/world/district_v5.gd").loft(self);n.add_child(loft_walk)
\troom.placement_hide.append(loft_walk);room.cut_hide.append(loft_walk)
'''+s[b:]
# The annex is now a single-storey attached room. Its facade has real joinery.
s=s.replace('Vector3(-10.7,0,4.4)','Vector3(-10.2,0,4.4)')
s=s.replace('var cap = MeshKit.box(a, Vector3(5, 4.1, 10.2), Vector3(-2.7, 5.45, 3.0), green, 0.08)','var cap = MeshKit.box(a, Vector3(5.2,.18,8.2),Vector3(-2.6,3.3,4),Color("#637773"),.008)')
s=s.replace('Vector3(5, 7.5, 1.9), Vector3(-2.7, 3.75, 7.15)','Vector3(5.2,3.2,.2), Vector3(-2.6,1.6,8.08)')
s=s.replace('\tvar hide_ps = [front, cap]','\tfor x in [-3.9,-1.3]:preload("res://src/world/frontage_v4.gd").window(a,Vector3(x,1.9,8.24),1.05,1.5,true)\n\tvar hide_ps = [front, cap]')
put(p,s)
p='src/world/surface_remodel.gd';s=get(p).replace('C.attach(r,"spiral_stair",ext.STAIR_C)','var stair=C.attach(r,"spiral_stair",ext.STAIR_C);stair.scale.y=5.4/3.4').replace('Vector3(-4.45,3.4,1.0)','Vector3(8.7,5.4,1.0)')
s=s.replace('for x in [10.65,12.5]:','for x in [11.7]:').replace('\tfor y in [.18,2.95]:','\tK.box(r,Vector3(.23,3.0,.27),Vector3(13.28,1.5,8.25),Color("#D8CAB0"),.005)\n\tfor y in [.18,2.95]:')
put(p,s)
change('src/world/main.gd','cellar._composter.global_position=Vector3(13.5,0,-11.5)','cellar._composter.global_position=Vector3(10,0,-6.2);cellar._composter.show()')
# Stop the world visibility manager from hiding a reparented functional composter.
change('src/world/free_layout.gd','Rect2(7.45,-4.2,1.4)','Rect2(8.5,-4.2,-.4)') if False else None
print('DISTRICT_V5_INTEGRATED')
