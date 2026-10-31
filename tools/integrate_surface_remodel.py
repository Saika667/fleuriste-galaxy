import pathlib,re
R=pathlib.Path(__file__).resolve().parents[1]
p=R/'src/world/shop_extensions.gd';s=p.read_text(encoding='utf-8')
if 'const Remodel=' not in s:s=s.replace('const Factory =', 'const Remodel=preload("res://src/world/surface_remodel.gd")\nconst Factory =',1)
for name in ['terrace','garden','greenhouse','shed','gallery','warehouse','salon','embassy']:
 pattern=rf'func _build_{name}\(\) -> Node3D:\n.*?(?=\n(?:func |const |# ---)|\Z)'
 body=f'func _build_{name}() -> Node3D:\n\treturn Remodel.'+(f'{name}(self)' if name in ['terrace','garden','greenhouse','shed'] else f'late(self,"{name}")')+'\n\n'
 s,n=re.subn(pattern,lambda m:body,s,flags=re.S);assert n==1,(name,n)
if 'Remodel.decorate(self,id,n)' not in s:s=s.replace('\t\t_nodes[id] = n','\t\t_nodes[id] = n\n\t\tRemodel.decorate(self,id,n)',1)
if 'var _fixed_fixture_roots' not in s:s=s.replace('var _staff_slots := 1','var _staff_slots := 1\nvar _fixed_fixture_roots: Array=[]\nvar _fixture_timer:=0.0',1)
if 'room.set_extension_fronts(owned)' not in s:s=s.replace('\troom.set_ext_terrace(owned.has("terrace"))','\troom.set_extension_fronts(owned)\n\tRemodel.fixed_visibility(self)\n\troom.set_ext_terrace(owned.has("terrace"))',1)
if '_fixture_timer+=_dt' not in s:s=s.replace('func _process(_dt: float) -> void:\n','func _process(_dt: float) -> void:\n\t_fixture_timer+=_dt\n\tif _fixture_timer>.5:\n\t\t_fixture_timer=0\n\t\tRemodel.fixed_visibility(self)\n',1)
s=s.replace('d.root.visible = i == 0 or slots >= 2','d.root.visible = (i == 0 or slots >= 2) and not d.root.get_meta("inactive_surface",false)')
# Never flatten interactive native subassemblies or editable surface roots.
if 'ancestor.has_meta("surface_model")' not in s:
 needle='\t\tvar skipped := false'
 s=s.replace(needle,'\t\tvar ancestor: Node=mi\n\t\tvar native:=false\n\t\twhile ancestor!=root and ancestor!=null:\n\t\t\tif ancestor.has_meta("surface_model") or ancestor.has_meta("layout_surfaces") or ancestor.has_meta("articulated"):native=true;break\n\t\t\tancestor=ancestor.get_parent()\n\t\tif native:continue\n'+needle,1)
if '\t# --- escalier en colimacon' in s:
 start=s.index('\t# --- escalier en colimacon',s.index('func _build_stairs'))
 end=s.index('\t# rambarde du palier',start)
 s=s[:start]+'\t# Native stair follows the existing 17-step climbing path exactly.\n'+s[end:]
p.write_text(s,encoding='utf-8')
room=R/'src/world/shop_room.gd';s=room.read_text(encoding='utf-8')
if '# bac de culture : bois sombre' in s:
 start=s.index('\t# bac de culture : bois sombre');end=s.index('\t# ampoule nue',start)
 s=s[:start]+'\tpreload("res://src/world/surface_remodel.gd").courtyard(self,yard)\n'+s[end:]
 s=s.replace('\tMeshKit.cylinder(yard, 0.008, 0.008, 0.5, Vector3(W + 0.9, 2.75, 3.5), MeshKit.INK)\n','').replace('\tMeshKit.sphere(yard, 0.09, Vector3(W + 0.9, 2.45, 3.5), Color("#E8D8FF"), Vector3.ONE, 0.3, 2.0)\n','').replace('\tMeshKit.cylinder(yard, 0.25, 0.25, 0.5, Vector3(W + 2.4, 2.7, 6.0), MeshKit.INK)\n','')
if 'var legacy_fronts:' not in s:
 s=s.replace('var design_assets: Array = []','var legacy_fronts: Dictionary={}\nvar design_assets: Array = []',1)
 start=s.index('\t# devantures voisines : auvents rayes')
 chunk=s[start:]
 chunk=chunk.replace('\t\tvar sx: float = s[0]','\t\tvar first_child=ex.get_child_count()\n\t\tvar sx: float = s[0]',1)
 chunk+='\n\t\tvar front_group=Node3D.new()\n\t\tfront_group.name="LegacyFront_"+str(s[1])\n\t\tfront_group.set_meta("legacy_front",s[1])\n\t\tvar members=ex.get_children().slice(first_child)\n\t\tex.add_child(front_group)\n\t\tfor member in members:member.reparent(front_group)\n\t\tlegacy_fronts[int(s[1])]=front_group\n'
 s=s[:start]+chunk
 s+='\nfunc set_extension_fronts(owned: Array) -> void:\n\tif legacy_fronts.has(2):legacy_fronts[2].visible=not ("gallery" in owned or "warehouse" in owned)\n\tif legacy_fronts.has(3):legacy_fronts[3].visible=not ("salon" in owned or "embassy" in owned)\n'
 # Exterior bouquets reuse approved native flower models rather than proxy spheres.
 start=s.index('\t# seaux de fleurs devant les vitrines');end=s.index('\t# bouche d\'egout',start)
 s=s[:start]+'\t# Native flower buckets already approved for the shop.\n\tfor i in 4:Decor.bucket(ex,Vector3([.9,2.3,7.7,9.1][i],0,D+.55),0,i)\n'+s[end:]
room.write_text(s,encoding='utf-8')
print('Integrated all ten surface extensions')
