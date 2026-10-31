from pathlib import Path
def edit(file,fn):
 p=Path(file);p.write_text(fn(p.read_text(encoding='utf-8')),encoding='utf-8')
def layout(s):
 s=s.replace('var carried_box:=""','var carried_box:=""\nvar carried_boxes:Array[String]=[]\nvar tinted_meshes:Array=[]\nvar preview_material:ShaderMaterial')
 s=s.replace('var placement_help: Label','var placement_help: Control')
 a=s.index('\tvar layer=CanvasLayer.new();layer.layer=15;');b=s.index('func reset()',a)
 s=s[:a]+'''\tvar layer=CanvasLayer.new();layer.layer=15;add_child(layer);placement_help=preload("res://src/ui/placement_legend.gd").new();layer.add_child(placement_help);placement_help.hide()
\tvar shader=Shader.new();shader.code="shader_type spatial; render_mode unshaded,blend_mix,depth_draw_never; uniform vec4 tint:source_color=vec4(.25,.8,.35,.25); void fragment(){ALBEDO=tint.rgb;ALPHA=tint.a;}"
\tpreview_material=ShaderMaterial.new();preview_material.shader=shader
'''+s[b:]
 s=s.replace('cancel();carried_box=""','cancel();carried_box="";carried_boxes.clear()')
 s=s.replace('if order.id!=carried_box:', 'if order.id not in carried_boxes and order.id!=carried_box:')
 s=s.replace('body.action_fn=func(_p):carried_box=order.id;set_collisions(body,false);main._on_toast("E : ouvrir le carton · G : poser · Poubelle : jeter l’emballage vide.","info")','body.action_fn=func(_p):take_box(order.id)')
 s=s.replace('"stock_shelf_botanical","wall_shelf"','"stock_shelf_botanical","stock_shelf_ivory","wall_shelf"')
 s=s.replace('main._on_toast("R / T : tourner · Molette : ajuster · Clic gauche : poser · Échap : annuler.","info")','placement_tutorial()\n\tapply_preview(ghost)')
 s=s.replace('func cancel() -> void:\n','func cancel() -> void:\n\tclear_preview()\n')
 a=s.index('\t\tplacement_help.text=');b=s.index('\ttimer+=dt',a)
 s=s[:a]+'\t\tplacement_help.update_valid(can_drop)\n\tif preview_material!=null:preview_material.set_shader_parameter("tint",Color(.25,.85,.38,.24) if can_drop else Color(.95,.18,.14,.30))\n'+s[b:]
 a=s.index('\tif carried_box!="" and parcels.has(carried_box):');b=s.index('\tif ghost==null and held_original=="":return',a)
 s=s[:a]+'''\tfor i in carried_boxes.size():
\t\tvar id=carried_boxes[i]
\t\tif not parcels.has(id):continue
\t\tvar node=parcels[id];node.global_transform=main.player.camera.global_transform
\t\tnode.position+=-main.player.camera.global_basis.z*(1.08+i*.08)-main.player.camera.global_basis.y*(.42-i*.17)
'''+s[b:]
 # All held and original props use the same volume-aware validation, on wall supports too.
 s=s.replace('if held_uid!="" and hit.normal.y>.55:can_drop=validate_target(held_uid,target,yaw)','if held_uid!="":can_drop=validate_target(held_uid,target,yaw)\n\telif held_original!="":can_drop=validate_original(originals[held_original],target,yaw)')
 s=s.replace('if order.empty_disposed or order.id==carried_box:continue','if order.empty_disposed or order.id in carried_boxes or order.id==carried_box:continue')
 s=s.replace('proposed.grow(.025).intersects','proposed.grow(.012).intersects')
 # Wall-mounted shelves are a 3.5 cm board below their origin, not a cabinet-sized cuboid.
 s=s.replace('var proposed=Transform3D(Basis(Vector3.UP,angle),pos)*AABB(Vector3(-size.x/2,0,-size.z/2),size)','''var wall_shelf="shelf" in String(d.get("model","")) and d.role!="stock_shelf"
\tif wall_shelf:size.y=.035
\tvar center_offset=Vector3(0,-.0175,0) if wall_shelf else Vector3(0,size.y*.5,0)
\tvar proposed=Transform3D(Basis(Vector3.UP,angle),pos)*AABB(Vector3(-size.x/2,center_offset.y-size.y*.5,-size.z/2),size)''')
 s=s.replace('pos+Vector3(0,size.y*.5+.025,0)','pos+center_offset+Vector3(0,.025,0)')
 s=s.replace('set_collisions(originals[key],false)\n','set_collisions(originals[key],false);placement_tutorial();apply_preview(originals[key])\n')
 # Press E while targeting a second parcel must reach its pickup callback.
 s=s.replace('var order=find_order(carried_box)\n\t\t\tif order.state', '''if main.player.focus!=null and main.player.focus.has_meta("parcel_id") and main.player.focus.get_meta("parcel_id") not in carried_boxes:return
\t\t\tvar order=find_order(carried_box)
\t\t\tif order.state''',1)
 s=s.replace('if order.state=="opened" and main.player.focus==trash:', 'if order.state=="opened" and main.player.focus==trash:')
 a=s.index('func drop_box()');b=s.index('func adopt_world()',a)
 s=s[:a]+'''func take_box(id:String) -> bool:
\tvar order=find_order(id)
\tif order.is_empty() or id in carried_boxes:return false
\tvar count=0
\tfor carried in carried_boxes:
\t\tif find_order(carried).get("state","")==order.state:count+=1
\tif count>=(2 if order.state=="sealed" else 5):main._on_toast("Maximum : 2 cartons pleins et 5 cartons vides.","info");return false
\tcarried_boxes.append(id);carried_box=id;set_collisions(parcels[id],false)
\tmain._on_toast("Cartons portés : %d · E : ouvrir · G : poser le dernier."%carried_boxes.size(),"info");return true
func drop_box() -> void:
\tvar order=find_order(carried_box)
\tif order.is_empty():carried_box="";return
\tvar camera=main.player.camera;var from=main.player.global_position-main.player.global_basis.z*1.3+Vector3.UP*1.5
\tvar hit=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,from-Vector3.UP*5,1))
\tvar pos=hit.position if not hit.is_empty() else main.player.global_position
\tvar shape=BoxShape3D.new();shape.size=Vector3(.63,.44,.46)
\tvar query=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1;query.transform=Transform3D(Basis.IDENTITY,pos+Vector3(0,.245,0))
\tif not get_world_3d().direct_space_state.intersect_shape(query).is_empty():main._on_toast("Pas assez de place pour poser le carton.","warn");return
\torder.position=[pos.x,pos.y,pos.z];set_collisions(parcels[carried_box],true);carried_boxes.erase(carried_box);carried_box=carried_boxes.back() if not carried_boxes.is_empty() else "";sync()
func build_trash() -> void:
\ttrash=INTER.new();add_child(trash);trash.position=Vector3(9,0,9.5)
\tpreload("res://src/world/district_detail.gd").attach(trash,"recycling_bin")
\tK.solid(trash,Vector3(.7,1.1,.7),Vector3(0,.55,0));trash.prompt_fn=func():return "Recycler les cartons vides" if carried_box!="" else "~Recyclage des emballages"
\ttrash.action_fn=func(_p):discard_box()
func discard_box() -> void:
\tvar disposed=0
\tvar all=carried_boxes.duplicate()
\tif carried_box!="" and carried_box not in all:all.append(carried_box)
\tfor id in all:
\t\tvar order=find_order(id)
\t\tif order.get("state","")!="opened":continue
\t\torder.empty_disposed=true;carried_boxes.erase(id);disposed+=1
\tcarried_box=carried_boxes.back() if not carried_boxes.is_empty() else ""
\tif disposed==0:main._on_toast("Ouvrez les cartons avant de recycler les emballages.","info")
\tGame.logistics.changed.emit()
func discard_at_municipal_bin() -> void:
\tif held_uid!="":
\t\tvar uid=held_uid;cancel()
\t\tif roots.has(uid):roots[uid].queue_free();roots.erase(uid)
\t\tGame.vases.set_contents("free|"+uid,{});Game.logistics.owned.erase(uid);Game.logistics.changed.emit()
\t\tmain._on_toast("Objet jeté.","info");return
\tif held_original!="":
\t\tmain._on_toast("Les équipements fixes se déplacent mais ne se jettent pas.","info");return
\tdiscard_box()
func placement_tutorial() -> void:
\tif Game.progression.has_flag("free_placement_tutorial_v3"):return
\tGame.progression.set_flag("free_placement_tutorial_v3")
\tmain._on_toast("Déplacez-vous pour viser un support. R : 90°, T : 180°, molette : 15°, Ctrl : grille fine. Clic pour poser, Échap pour annuler. Le meuble devient rouge en cas d’obstacle.","info")
func apply_preview(root:Node3D) -> void:
\tclear_preview()
\tfor mesh in root.find_children("*","MeshInstance3D",true,false):
\t\ttinted_meshes.append({"mesh":mesh,"overlay":mesh.material_overlay});mesh.material_overlay=preview_material
func clear_preview() -> void:
\tfor record in tinted_meshes:
\t\tif is_instance_valid(record.mesh):record.mesh.material_overlay=record.overlay
\ttinted_meshes.clear()
func validate_original(root:Node3D,pos:Vector3,angle:float) -> bool:
\tvar bounds=AABB();var first=true
\tfor m in root.find_children("*","MeshInstance3D",true,false):
\t\tif m.mesh==null:continue
\t\tvar local=root.global_transform.affine_inverse()*m.global_transform*m.get_aabb()
\t\tbounds=local if first else bounds.merge(local);first=false
\tif first:return true
\tvar shape=BoxShape3D.new();shape.size=(bounds.size-Vector3.ONE*.04).max(Vector3.ONE*.025)
\tvar query=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1;query.transform=Transform3D(Basis(Vector3.UP,angle),pos+Basis(Vector3.UP,angle)*bounds.get_center()+Vector3.UP*.025)
\treturn get_world_3d().direct_space_state.intersect_shape(query).is_empty()
'''+s[b:]
 # Allow the municipal disposal target in placement mode, before swallowing E.
 s=s.replace('if event.keycode in [KEY_R,KEY_T]', '''if event.keycode==KEY_E and main.player.focus!=null and main.player.focus.name=="MunicipalDisposal":discard_at_municipal_bin();get_viewport().set_input_as_handled();return
\t\tif event.keycode in [KEY_R,KEY_T]''',1)
 # Wall shelves' pick proxy is query-only. Their physical thickness never extends to the floor.
 return s
edit('src/world/free_layout.gd',layout)
edit('src/ui/hud.gd',lambda s:s.replace('res://src/ui/dial.gd','res://src/ui/compact_dial.gd').replace('_clock.offset_bottom = 304','_clock.offset_bottom = 104'))
def dialogue(s):
 s=s.replace('var _portrait\n','var _portrait\nvar _notary:Control\n')
 a=s.index('\tadd_child(_portrait)')+len('\tadd_child(_portrait)')
 s=s[:a]+'''\n\t_notary=preload("res://src/ui/notary_portrait.gd").new();add_child(_notary)
\t_notary.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM);_notary.offset_left=-665;_notary.offset_right=-285;_notary.offset_top=-514;_notary.offset_bottom=-34;_notary.z_index=1;_notary.hide()
'''+s[a:]
 s=s.replace('\t_say(text, "neutral")','\t_portrait.visible=not "notaire" in speaker.to_lower();_notary.visible=not _portrait.visible\n\t_say(text, "neutral")')
 s=s.replace('func _reset(uid: String) -> void:\n','func _reset(uid: String) -> void:\n\tif _notary!=null:_notary.hide();_portrait.show()\n')
 return s
edit('src/ui/dialogue_box.gd',dialogue)
