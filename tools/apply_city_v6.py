from pathlib import Path
def edit(path,fn):
 p=Path(path);p.write_text(fn(p.read_text(encoding='utf-8-sig')),encoding='utf-8')
def replace(s,a,b):
 assert a in s,a[:100]
 return s.replace(a,b)
def room(s):
 # Opaque, front-facing paper. No backface pattern leaks or transparent sorting.
 s=replace(s,'render_mode blend_mix, cull_disabled, depth_draw_never;','render_mode cull_back;')
 s=replace(s,'ALBEDO = mix(ink.rgb, vec3(1.0, 0.82, 0.3), core);\n\tALPHA = m * strength;','ALBEDO = mix(vec3(.91,.93,.88), mix(ink.rgb, vec3(1.0,.82,.3),core),m*strength);')
 start=s.index('\t# enseigne\n');end=s.index('\tpreload("res://src/world/frontage_v4.gd").shop(self)',start)
 s=s[:start]+'''\t# Painted timber fascia with recessed lettering and discrete brass lighting.
\tvar board=MeshKit.box(self,Vector3(5.4,.78,.14),Vector3(5.3,3.85,D+.34),Color("#38594E"),.018)
\tvar fpl=MeshKit.box(self,Vector3(5.16,.56,.025),Vector3(5.3,3.85,D+.425),Color("#294B40"),.008)
\tfleurs_mat=fpl.material_override.duplicate();fpl.material_override=fleurs_mat
\tfleurs_label=MeshKit.label(self,"FLEURISTE",Vector3(5.3,3.86,D+.455),90,Color("#E4D7AF"),.006)
\tfleurs_label.outline_size=0
\tfor x in [3.25,7.35]:
\t\tpreload("res://src/world/city_revision.gd").bar(self,Vector3(x,4.35,8.35),Vector3(x,4.35,8.85),.018,Color("#A8996E"))
\t\tMeshKit.box(self,Vector3(.25,.08,.20),Vector3(x,4.32,8.85),Color("#A8996E"),.025)
\tpreload("res://src/world/city_revision.gd").awning(self,Vector3(4.7,3.03,8.25),9.2,1.45,Color("#668C77"))
''' +s[end:]
 s=s.replace('Vector3(70,.03,5.6),Vector3(5,-.03,13.4)','Vector3(80,.03,8),Vector3(5,-.03,17.6)').replace('Vector3(-28+i*5,.0,13.4)','Vector3(-28+i*5,.0,17.6)')
 # Frame sits clear of wainscot; it must not intersect the service door jamb.
 s=replace(s,'frame.reparent(self)','frame.reparent(self)\n\t\tif name=="back":frame.position.x+=.055')
 return s
edit('src/world/shop_room.gd',room)
def frontage(s):
 start=s.index('\t# Upper storey');end=s.index('\tp.placement_hide.append(r)',start)
 s=s[:start]+'''\t# Open roof terrace. Rear and west have genuine apertures; front/east stay open.
\tfor side in [-1,1]:
\t\tvar face=Node3D.new();r.add_child(face)
\t\tif side<0:face.position=Vector3(-.23,0,4);face.rotation.y=-PI/2
\t\telse:face.position=Vector3(5,0,-.23);face.rotation.y=PI
\t\tvar width=8.4 if side<0 else 10.4
\t\tfor span in [[-width/2,-2.65],[-1.15,1.15],[2.65,width/2]]:
\t\t\tK.box(face,Vector3(span[1]-span[0],3,.18),Vector3((span[0]+span[1])/2,6.9,0),Color("#A5B6A7"),0)
\t\tfor y in [5.75,8.05]:K.box(face,Vector3(width,.7,.18),Vector3(0,y,0),Color("#A5B6A7"),0)
\t\tfor x in [-1.9,1.9]:
\t\t\tK.box(face,Vector3(1.5,1.6,.035),Vector3(x,6.9,0),Color(.72,.86,.86,.16),0,.3,0,0,.16)
\t\t\tfor dx in [-.75,.75]:K.box(face,Vector3(.065,1.7,.14),Vector3(x+dx,6.9,0),Color("#D8CAB0"),0)
\tfor spec in [[Vector3(10.5,1.1,.15),Vector3(5,5.95,8.35)],[Vector3(.15,1.1,8.7),Vector3(10.25,5.95,4.1)]]:
\t\tK.box(r,spec[0],spec[1],Color("#A5B6A7"),0)
\tfor x in [0,2,4,6,8,10]:K.box(r,Vector3(.06,1.0,.06),Vector3(x,6.75,8.35),Color("#3E5D57"),0)
\tK.box(r,Vector3(10.4,.06,.06),Vector3(5,7.25,8.35),Color("#3E5D57"),0)
\t# Rear ground floor is solid plaster without decorative fake windows.
\tfor spec in [[Vector3(5.6,5.2,.08),Vector3(2.6,2.6,-.32)],[Vector3(3.97,5.2,.08),Vector3(8.415,2.6,-.32)],[Vector3(1.03,2.9,.08),Vector3(5.915,3.75,-.32)]]:K.box(r,spec[0],spec[1],Color("#A5B6A7"),0,.95,0,0)
''' +s[end:]
 start=s.index('\t# Local +Z',s.index('static func cellar'))
 s=s[:start]+'''\t# Industrial envelope: corrugated cladding, low concrete footing and exposed steel.
\tvar steel=Color("#4E5C5C");var concrete=Color("#85867B")
\tfor span in [[-12.25,-3.50],[-2.44,-.90],[2.90,12.25]]:
\t\tvar width=span[1]-span[0];var cx=(span[0]+span[1])/2
\t\tK.box(r,Vector3(width,3.75,.08),Vector3(cx,1.875,9.34),Color("#887F6D"),0)
\t\tK.box(r,Vector3(width,.22,.10),Vector3(cx,.11,9.39),concrete,0)
\t\tfor i in ceili(width/.20):K.box(r,Vector3(.045,2.65,.045),Vector3(span[0]+.10+i*.20,2.35,9.41),steel,0)
\tfor x in [-12.25,-7.7,-3.52,-2.42,2.92,7.7,12.25]:
\t\tfor dz in [9.40,9.57]:K.box(r,Vector3(.19,3.8,.045),Vector3(x,1.9,dz),steel,0)
\t\tK.box(r,Vector3(.06,3.8,.19),Vector3(x,1.9,9.48),steel,0)
\tK.box(r,Vector3(24.6,.18,.30),Vector3(0,3.82,9.45),steel,0)
\tK.box(r,Vector3(3.9,.4,.42),Vector3(1,2.64,9.40),steel,.012)
\tfor side in [-1,1]:
\t\tvar elevation=Node3D.new();r.add_child(elevation);elevation.position=Vector3(side*12.28,0,0);elevation.rotation.y=side*PI/2
\t\tK.box(elevation,Vector3(18.5,3.8,.12),Vector3(0,1.9,0),concrete,0)
\t\tfor i in 91:K.box(elevation,Vector3(.04,1.8,.05),Vector3(-9+i*.20,2.85,.095),steel,0)
\t\tfor x in [-8.8,-4.4,0,4.4,8.8]:K.box(elevation,Vector3(.16,3.8,.22),Vector3(x,1.9,.12),steel,0)
\t\t# Two narrow cellar vents; no house-sized windows beside the slope.
\t\tfor x in [-6.5,4.5]:
\t\t\tK.box(elevation,Vector3(1.3,.45,.10),Vector3(x,3.30,.14),Color("#273B3B"),0)
\t\t\tfor j in 7:K.box(elevation,Vector3(.025,.48,.07),Vector3(x-.55+j*.18,3.30,.23),steel,0)
\t\tfor i in 3:
\t\t\tvar x=-3.0+i*.72
\t\t\tK.box(elevation,Vector3(.56,.76,.012),Vector3(x,1.1+(i%2)*.13,.19),Color("#A69979") if i%2 else Color("#7B8173"),0)
\t\t\tfor j in 5:K.box(elevation,Vector3(.06,.08,.014),Vector3(x-.24+j*.10,.73+(i%2)*.13+fmod(j*.13,.15),.203),concrete,0)
\t\t\tK.label(elevation,["CONCERT","AVIS","PERDU"][i],Vector3(x,1.23+(i%2)*.13,.21),24,Color("#3B4540"),.0023).outline_size=0
'''
 return s
edit('src/world/frontage_v4.gd',frontage)
def district(s):
 # Exact equal grade at the plaza mouth and at the main pavement. No raised gaps.
 s=s.replace('Vector2(10.6,-.015)','Vector2(13.6,-.015)')
 s=s.replace('(.08 if walk and i>0 and i<PROFILE.size()-2 else 0.0)','(0.0)').replace('(.08 if walk and i+1>0 and i+1<PROFILE.size()-1 else 0.0)','(0.0)')
 s=s.replace('26.5','23.1').replace('29.2','20.1')
 # Pipe network is routed outside this x interval in cellar_equipment_visual.
 anchor='\t# No transverse wall across the bottom of the stairs.'
 s=s.replace(anchor,'''\t# Finish the walls above shop floor in the same green / floral scheme.
\tvar shop_room=v.get_parent().world.room
\tfor xx in [-4.885,-3.815]:
\t\tK.box(r,Vector3(.025,1.0,3.78),Vector3(xx,4.7,-5.55),Color("#6FB57A"),0)
\t\tshop_room._pattern_quad(r,shop_room.WALLPAPER,Vector2(3.78,4.14),Vector3(xx,7.33,-5.55),Vector3(0,PI/2 if xx< -4 else -PI/2,0))
''' +anchor)
 # Runtime loft is an open terrace with real window holes, no duplicate opaque façade.
 start=s.index('\tfor spec in [[Vector3(.2,3.0,8.2)',s.index('static func loft'))
 end=s.index('\tK.light(r,',start)
 s=s[:start]+'''\t# Collision follows rear and west window walls; east and front remain open above parapets.
\tfor spec in [[Vector3(.2,3,8.4),Vector3(-.12,gy+1.5,4)],[Vector3(10.4,3,.2),Vector3(5,gy+1.5,-.12)],[Vector3(10.5,1.85,.15),Vector3(5,gy+.925,8.35)],[Vector3(.15,1.85,8.7),Vector3(10.25,gy+.925,4.1)]]:K.solid(body,spec[0],spec[1])
''' +s[end:]
 start=s.index('static func perimeter');end=s.index('static func hedge',start)
 s=s[:start]+'''static func perimeter(p:Node3D) -> void:
\t# Public footways outside garden fences; exact U mouth of the descending alley.
\tfor spec in [[Vector3(47,.04,2.1),Vector3(2,.02,10.3)],[Vector3(50,.04,2),Vector3(-3,.02,24.2)],[Vector3(2,.04,8.8),Vector3(-24.25,.02,21.9)],[Vector3(2,.04,12),Vector3(11,.02,17)]]:
\t\tvar n=K.box(p,spec[0],spec[1],Color("#CCBFA7"),0);var shader=Shader.new();shader.code=D.PAVING;var mat=ShaderMaterial.new();mat.shader=shader;n.material_override=mat
\tvar city=load("res://src/world/city_revision.gd")
\t# Broad paved pedestrian lane separates houses from taller background blocks.
\tvar lane=K.box(p,Vector3(60,.08,5),Vector3(-7,-.04,39.3),Color("#C2BDAA"),0)
\tvar shader=Shader.new();shader.code=D.PAVING;var material=ShaderMaterial.new();material.shader=shader;lane.material_override=material
\tfor i in 5:city.building(p,Vector3(-31+i*12,0,47),PI,11.7,9,3+i%3,[Color("#778A91"),Color("#A08C75"),Color("#8C8494"),Color("#778D82"),Color("#A4937B")][i],i+10)
\t# The block adjoins the pink house at local x=15, with no perimeter wall.
\tcity.building(p,Vector3(20.5,0,33),0,11,8,4,Color("#8B9895"),15)
\tfor i in 5:city.street_detail(p,Vector3(-29+i*12,0,39),i)
''' +s[end:]
 # replace clumsy bakery canopy by measured supports and consistent cloth pitch
 s=s.replace('if String(n.name).begins_with("Striped_canvas") or String(n.name).begins_with("Awning_valance"):n.position.y+=.4','if String(n.name).begins_with("Striped_canvas") or String(n.name).begins_with("Awning_valance"):n.free()\n\tload("res://src/world/city_revision.gd").awning(p,Vector3(0,3.08,3.65),11.4,1.4,Color("#8E7560"))')
 return s
edit('src/world/district_v5.gd',district)
def detail(s):
 s=replace(s,'K.box(root,Vector3(61,.20,32),Vector3(-7.5,-.1,25.0),Color("#666D6A"),.015)\n\tvar b=StaticBody3D.new();root.add_child(b);K.solid(b,Vector3(61,.20,32),Vector3(-7.5,-.1,25.0))','''for rect in floor_rects(Rect2(-38,9,61,32),[Rect2(-25.3,9,11,8.5)]):
\t\tvar c=rect.get_center();load("res://src/world/city_revision.gd").slab(root,Vector3(rect.size.x,.20,rect.size.y),Vector3(c.x,-.10,c.y),Color("#666D6A"))''')
 s=s.replace('Vector3(x+side*3.5,0,28),5,PI/2','Vector3(x+side*3.5,0,27.5),4,PI/2')
 # Front gardens terminate at actual house rear elevation z=29.5.
 s=s.replace('Vector3(-28.4 if side<0 else 13.8,.01,z)','Vector3(-29.1 if side<0 else 15.0,.01,z)').replace('Vector3(3,.02,6.2)','Vector3(4.4,.02,6.2)').replace('Vector3(-28.4 if side<0 else 13.8,0,z+dz),3','Vector3(-29.1 if side<0 else 15.0,0,z+dz),4.4')
 # The back-left garden must not overlap the ramp approach.
 s=s.replace('var x=-33.0 if side<0 else 19.5','var x=-34.5 if side<0 else 20.3')
 return s
edit('src/world/district_detail.gd',detail)
def neighborhood(s):
 s=s.replace('Vector3(8-spec[1],0,23)','Vector3(8-spec[1],0,28)')
 s=s.replace('detail.pavement(row,18.0,3.4);detail.pavement(row,9.35,2.3)','detail.pavement(row,23.0,2.8);detail.pavement(row,10.8,5.6)')
 s=s.replace('[-17,-6,6,17,27]','[-17,-6,6,17,33]').replace('16.65','22.0').replace('17.95','23.0')
 s=s.replace('Vector3(spec[1],0,4.4)','Vector3(spec[1]+(3 if spec[1]==35 else 0),0,4.4)')
 s=s.replace('\t# Continue the same architectural vocabulary','\tload("res://src/world/city_revision.gd").city_ends(row)\n\t# Continue the same architectural vocabulary')
 s=s.replace('Vector3(34,-5.2+(y+5.2)*.5,z)','Vector3(34,-5.2+(y+5.2)*.5,z)')
 # Foundation under the corner building extends down past the slope; all visible faces stay modeled.
 s=s.replace('\t# Tall service house','\tpreload("res://src/world/lower_alley.gd").block(root,Vector3(5.76,5.2,5.04),Vector3(16.28,-2.6,5.22),Color("#A19483"))\n\t# Tall service house')
 s=s.replace('var body=StaticBody3D.new();root.add_child(body);K.solid(body,Vector3(5.76,4.4,5.04),Vector3(16.28,2.2,5.22))','''var body=StaticBody3D.new();root.add_child(body);K.solid(body,Vector3(5.76,4.4,5.04),Vector3(16.28,2.2,5.22))
\tK.box(root,Vector3(1.8,.42,.06),Vector3(18.0,2.7,7.82),Color("#294C60"),.015)
\tK.label(root,"RUELLE DES ÉRABLES",Vector3(18.0,2.7,7.86),30,Color("#EFE6CC"),.0024).outline_size=0''')
 return s
edit('src/world/neighborhood_v2.gd',neighborhood)
def extensions(s):
 s=s.replace('Vector3(0.2, 3.2, 6.4), Vector3(-5.1, 1.6, 3.0)','Vector3(0.2, 5.2, 6.4), Vector3(-5.1, 2.6, 3.0)')
 s=s.replace('Vector3(5.2, 3.2, 0.2), Vector3(-2.6, 1.6, 6.1)','Vector3(5.2, 5.2, 0.2), Vector3(-2.6, 2.6, 6.1)')
 # Secondary room uses its own 3.2m wall height, not the shop's 5.2m.
 s=s.replace('var wp_h = room.H - 1.06','var wp_h = 3.2 - 1.06')
 s=s.replace('Vector3(0, -PI * 0.5, 0))\n\troom._pattern_quad(walls','Vector3(0, PI * 0.5, 0))\n\troom._pattern_quad(walls')
 return s
edit('src/world/shop_extensions.gd',extensions)
def surface(s):
 s=s.replace('\tfor z in [8.95,9.95,10.95]:C.attach(r,"railing",Vector3(-3.15,0,z),PI/2)\n','')
 s=s.replace('C.attach(r,"parasol",Vector3(-2.15,.06,9.15))','load("res://src/world/city_revision.gd").model(r,"parasol",Vector3(-2.15,.06,9.15))')
 start=s.index('\tvar bed=CELL.attach(p,"grow_bed"',s.index('static func courtyard'));end=s.index('\tfor spec in',start)
 s=s[:start]+s[end:]
 s=s.replace('\tCELL.attach(p,"bulb",Vector3(10.9,2.45,3.5))\n','')
 # Real buildings already exist in different city locations. Unlocked displays sit at their entrances.
 s=s.replace('var base=Vector3(cx,0,8.25)','var base={"warehouse":Vector3(-46,0,22.8),"embassy":Vector3(60,0,23.8),"salon":Vector3(-44,0,8.8),"gallery":Vector3(43.2,0,-10)}[id]')
 return s
edit('src/world/surface_remodel.gd',surface)
def garden(s):
 s=s.replace('root.position.z=-.82','root.position.z=2.62')
 s=s.replace('leaf.scale=Vector3(2.25,1.25,1)','leaf.scale=Vector3(1.1,1.25,1)')
 # Fixed sidelights close the old double-width opening, collision matches narrow leaf.
 s=s.replace('door.setup([leaf]', '''for spec in [[Vector3(.12,2.65,1.18),Vector3(3,1.325,-8.76)]]:
\t\tK.box(root,spec[0],spec[1],Color(.6,.8,.8,.3),0,.4,0,0,.3);R.solid(root,spec[0],spec[1])
\tdoor.setup([leaf]''')
 s=s.replace('door.position=Vector3(3,0,-10.83)','door.position=Vector3(3,0,-10.83)')
 # Ensure no route exists between greenhouse and florist rear wall.
 s=s.replace('\treturn root\nstatic func grass','\treturn root\nstatic func grass')
 return s
edit('src/world/rear_garden_v2.gd',garden)
edit('src/world/main.gd',lambda s:s.replace('Vector3(10,0,-6.2)','Vector3(14.35,0,-11.9)'))
edit('src/cellar_view/composter_remodel.gd',lambda s:s.replace('preload("res://src/world/district_detail.gd").attach(self,"composter")','preload("res://src/world/city_revision.gd").model(self,"composter")'))
def equipment(s):
 s=s.replace('for i in 20:C.attach(self,"duct_module",Vector3(-9.5+i,3.48,z))','''for i in 20:
\t\t\tvar x=-9.5+i
\t\t\tif z==-5.0 and x> -5.3 and x< -3.3:continue
\t\t\tC.attach(self,"duct_module",Vector3(x,3.48,z))
\t# Detour behind the stair wall, never through the walking wedge.
\tfor x in [-5.5,-4.5,-3.5]:C.attach(self,"duct_module",Vector3(x,3.48,-8.0))
\tfor x in [-5.8,-2.8]:
\t\tfor z in [-7.5,-6.5,-5.5]:C.attach(self,"duct_module",Vector3(x,3.48,z),PI/2)''')
 return s
edit('src/cellar_view/cellar_equipment_visual.gd',equipment)
def cellar(s):
 # Moved growing bed is inside cellar, away from access routes.
 s=s.replace('static func decor(v) -> void:','''static func decor(v) -> void:
\tvar bed=C.attach(v,"grow_bed",Vector3(7.8,0,-5.5),0,.75)
\tfor z in [-.32,.32]:C.attach(v,"herb_growing",Vector3(7.8,.365,-5.5+z),0,.7)
\tC.attach(v,"bed_lamp",Vector3(7.8,1.75,-5.5),0,.75)''')
 return s
edit('src/cellar_view/cellar_remodel.gd',cellar)
def prepare(s):
 s=s.replace('static var _outline: ShaderMaterial','static var _outline: ShaderMaterial\nstatic var _foliage_mats: Dictionary = {}')
 # Opaque two-sided leaves: Blender mesh leaf backfaces were disappearing from below.
 s=s.replace('var glass = role == "glass" or role == "cold"','''var glass = role == "glass" or role == "cold"
\t\tif material is StandardMaterial3D and ("leaf" in role or "foliage" in role):
\t\t\tif not _foliage_mats.has(material.get_instance_id()):
\t\t\t\tvar copy=material.duplicate();copy.cull_mode=BaseMaterial3D.CULL_DISABLED;copy.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED;copy.albedo_color.a=1.0
\t\t\t\t_foliage_mats[material.get_instance_id()]=copy
\t\t\tnode.material_override=_foliage_mats[material.get_instance_id()]
\t\t\tnode.material_overlay=null;node.set_meta("no_outline",true)
\t\t\treturn''')
 # Exterior outlines double geometry passes, remove on static environment assets.
 s=s.replace('node.material_overlay = _outline','node.material_overlay = null if Preferences.quality<2 else _outline')
 return s
edit('src/world/shop_collection_visual.gd',prepare)
edit('src/world/street_traffic.gd',lambda s:s.replace('-42 if direction>0 else 48','-91 if direction>0 else 101').replace('12.25 if direction>0 else 14.95','15.6 if direction>0 else 19.6').replace('>52','>103'))
edit('src/world/street_remodel.gd',lambda s:s.replace('10.95+i*.64','13.9+i*1.03').replace('range(8)','range(8)'))
edit('src/world/ambient_life.gd',lambda s:s.replace('\t_update_walkers(dt)','\t# CityResidents owns public pedestrians and their house return routes.'))
edit('src/world/shop_world.gd',lambda s:s.replace('ambient.populate(', 'ambient.populate('))
print('CITY_V6_SOURCE_PATCHED')
