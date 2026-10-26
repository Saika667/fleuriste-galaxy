extends RefCounted
## Fusion des maillages statiques d'un arbre de noeuds : les MeshInstance3D immobiles qui partagent un
## « type » de materiau (rugosite, lisere, transparence...) et un meme secteur de l'espace deviennent UN maillage.
## La couleur du materiau d'origine est cuite dans les couleurs de sommet (materiau partage, albedo blanc,
## couleurs de sommet en sRGB) : meme rendu, mais des dizaines d'appels de dessin en moins, aussi dans les
## passes d'ombre. Les materiaux emissifs ou touches par le code gardent leur propre materiau.
##
## Ce qui n'est jamais fusionne (il bouge, se cache ou se retrouve par le code) :
##  - tout noeud reference par une variable d'un des `owners` (tableaux et dictionnaires compris) : il bouge
##    ou se cache d'un bloc, donc ses descendants fusionnent ENTRE EUX (il sert d'ancre), jamais avec le reste ;
##  - les noeuds de `deep` (dont les enfants sont animes un par un, par nom) et leurs descendants ;
##  - les noeuds avec script, meta (hors "no_outline"), caches, ou qui ne sont pas des Node3D/MeshInstance3D simples ;
##  - les maillages transparents par instance, a portee de visibilite, ou sans materiau explicite.
## Les materiaux references par les `owners` (changes en cours de partie : vitres, neons...) ne sont jamais cuits.

const MeshKitRef = preload("res://src/world/mesh_kit.gd")
const CELL := 6.0
const MAX_DEPTH := 4

## "-- nomerge" (arguments de la ligne de commande) coupe la fusion, pour comparer avant/apres.
static var enabled := not OS.get_cmdline_user_args().has("nomerge")
static var last_stats := {}
static var last_pinned := {}
static var _class_mats := {}  # cle de type -> StandardMaterial3D partage (albedo blanc)
static var _baked := {}  # "mesh|couleur" -> ArrayMesh a couleurs cuites


static func merge(root: Node3D, owners: Array = [], containers: Array = [], deep: Array = [], cell := CELL) -> Dictionary:
	if not enabled:
		return {}
	var pinned := {}
	var pinned_mats := {}
	var cont := {}
	var deepset := {}
	for c in containers:
		if c is Node:
			cont[c.get_instance_id()] = true
	for c in deep:
		if c is Node:
			deepset[c.get_instance_id()] = true
	for o in owners:
		_collect(o, pinned, pinned_mats, root, 0, {})
	last_pinned = pinned
	var groups := {}
	var candidates := 0
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var anchor = _anchor_of(mi, root, pinned, cont, deepset)
		if anchor == null or not _mergeable(mi):
			continue
		candidates += 1
		var mat: Material = mi.material_override
		if mat == null:
			mat = mi.mesh.surface_get_material(0)
		var xf: Transform3D = _relative(mi, anchor)
		var aabb: AABB = xf * mi.mesh.get_aabb()
		var ctr: Vector3 = aabb.get_center()
		var mesh: Mesh = mi.mesh
		var out_mat: Material = mat
		var mkey = str(mat.get_instance_id())
		var ck = "" if pinned_mats.has(mat.get_instance_id()) else _class_key(mat)
		if ck != "":
			mesh = _baked_mesh(mi.mesh, mat)
			out_mat = _class_mat(ck, mat)
			mkey = ck
		var shadow = mi.cast_shadow
		if shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and mi.has_meta("tiny_off"):
			shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON  # petit : rejoint le groupe qui projette (aucun appel de dessin de plus)
		var key = "%d|%s|%d|%d|%d|%s|%d|%d|%d|%d" % [anchor.get_instance_id(), mkey, mi.material_overlay.get_instance_id() if mi.material_overlay != null else 0, shadow, mi.layers, _format_of(mesh), _cell(ctr.x, cell), _cell(ctr.y, cell), _cell(ctr.z, cell), 1 if mi.get_meta("no_outline", false) else 0]
		if not groups.has(key):
			groups[key] = {"anchor": anchor, "mat": out_mat, "ov": mi.material_overlay, "shadow": shadow, "layers": mi.layers, "no_outline": mi.get_meta("no_outline", false), "items": [], "xf": [], "mesh": []}
		groups[key].items.append(mi)
		groups[key].xf.append(xf)
		groups[key].mesh.append(mesh)
	var merged := 0
	var removed := 0
	for k in groups:
		var g = groups[k]
		if g.items.size() < 2:
			continue
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in g.items.size():
			st.append_from(g.mesh[i], 0, g.xf[i])
		var node = MeshInstance3D.new()
		node.name = "Merged"
		node.mesh = st.commit()
		node.material_override = g.mat
		node.material_overlay = g.ov
		node.cast_shadow = g.shadow
		node.layers = g.layers
		if g.no_outline:
			node.set_meta("no_outline", true)
		g.anchor.add_child(node)
		merged += 1
		for mi in g.items:
			removed += 1
			if mi.get_child_count() == 0:
				mi.get_parent().remove_child(mi)
				mi.free()
			else:
				mi.mesh = null
	last_stats = {"candidates": candidates, "removed": removed, "merged": merged}
	return last_stats


static func _cell(v: float, cell: float) -> int:
	return 0 if cell >= 1.0e5 else floori(v / cell)


static func _anchor_of(mi: Node, root: Node3D, pinned: Dictionary, cont: Dictionary, deep: Dictionary) -> Node3D:
	var n: Node = mi
	while n != null and n != root:
		var id = n.get_instance_id()
		if deep.has(id):
			return null
		if pinned.has(id) or cont.has(id):
			# un noeud qui porte des donnees (meta : visage, etc.) n'est jamais une ancre : le code y retrouve ses enfants
			if n == mi or _has_data_meta(n):
				return null
			return n
		if not _plain(n):
			return null
		n = n.get_parent()
	return root


## Transformation de mi dans le repere de anchor (sans exiger que l'arbre soit dans la scene).
static func _relative(mi: Node3D, anchor: Node) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var n: Node = mi
	while n != anchor and n is Node3D:
		xf = n.transform * xf
		n = n.get_parent()
	return xf


static func _format_of(m: Mesh) -> String:
	if m is ArrayMesh:
		return "a%d" % m.surface_get_format(0)
	return m.get_class()


# --- couleur cuite dans les sommets ---

## Cle du « type » d'un materiau (tout sauf la couleur), ou "" s'il ne peut pas etre cuit.
static func _class_key(m: Material) -> String:
	if m.get_class() != "StandardMaterial3D":
		return ""
	var s := m as StandardMaterial3D
	if s.albedo_texture != null or s.emission_enabled or s.normal_enabled or s.shading_mode != BaseMaterial3D.SHADING_MODE_PER_PIXEL:
		return ""
	if s.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED or s.no_depth_test or s.metallic != 0.0 or s.render_priority != 0 or s.grow:
		return ""
	return "k|%d|%d|%d|%.1f|%d|%.2f|%.2f|%d" % [s.transparency, s.blend_mode, s.cull_mode, _rough(s.roughness), 1 if s.rim_enabled else 0, s.rim, s.rim_tint, s.next_pass.get_instance_id() if s.next_pass != null else 0]


## Rugosite arrondie au pas de 0,2 (0,3 0,5 0,7 0,9) : moins de types de materiaux, donc plus de fusions.
static func _rough(r: float) -> float:
	return clampf(snappedf(r - 0.1, 0.2) + 0.1, 0.1, 0.9)


static func _class_mat(ck: String, src: StandardMaterial3D) -> StandardMaterial3D:
	if _class_mats.has(ck):
		return _class_mats[ck]
	var m = StandardMaterial3D.new()
	m.albedo_color = Color.WHITE
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.transparency = src.transparency
	m.blend_mode = src.blend_mode
	m.cull_mode = src.cull_mode
	m.roughness = _rough(src.roughness)
	m.rim_enabled = src.rim_enabled
	m.rim = src.rim
	m.rim_tint = src.rim_tint
	m.next_pass = src.next_pass
	_class_mats[ck] = m
	return m


## Copie du maillage dont les couleurs de sommet valent (couleur d'origine x albedo du materiau), encodees en sRGB.
static func _baked_mesh(mesh: Mesh, mat: StandardMaterial3D) -> ArrayMesh:
	var col: Color = mat.albedo_color
	var key = "%d|%s|%d" % [mesh.get_instance_id(), col.to_html(true), 1 if mat.vertex_color_use_as_albedo else 0]
	var shared = mesh.has_meta("shared")
	if shared and _baked.has(key):
		return _baked[key]
	var arrays: Array = mesh.surface_get_arrays(0)
	var n: int = arrays[Mesh.ARRAY_VERTEX].size()
	var alb = col.srgb_to_linear()
	var out = PackedColorArray()
	var old = arrays[Mesh.ARRAY_COLOR]
	out.resize(n)
	if old == null or old.size() != n or not mat.vertex_color_use_as_albedo:
		out.fill(Color(col.r, col.g, col.b, col.a))
	else:
		var cache := {}
		for i in n:
			var c: Color = old[i]
			var ck = c.to_rgba32()
			var r: Color = cache.get(ck, Color(-1, 0, 0, 0))
			if r.r < 0.0:
				r = Color(c.r * alb.r, c.g * alb.g, c.b * alb.b, 1.0).linear_to_srgb()
				r.a = c.a * col.a
				cache[ck] = r
			out[i] = r
	arrays[Mesh.ARRAY_COLOR] = out
	arrays[Mesh.ARRAY_TANGENT] = null
	var am = ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	if shared:
		if _baked.size() > 600:
			_baked.clear()
		_baked[key] = am
	return am


static func _has_data_meta(n: Node) -> bool:
	for m in n.get_meta_list():
		if m != "no_outline" and m != "sway" and m != "tiny_off":
			return true
	return false


static func _plain(n: Node) -> bool:
	if n.get_script() != null:
		return false
	var cls = n.get_class()
	if cls != "Node3D" and cls != "MeshInstance3D":
		return false
	if not n.visible:
		return false
	for m in n.get_meta_list():
		if m != "no_outline" and m != "tiny_off":
			return false
	return true


static func _mergeable(mi: MeshInstance3D) -> bool:
	if mi.mesh == null or mi.mesh.get_surface_count() != 1 or mi.transparency != 0.0 or not mi.visible:
		return false
	if mi.visibility_range_end > 0.0 or mi.visibility_range_begin > 0.0:
		return false
	if mi.get_surface_override_material(0) != null:
		return false
	if mi.material_override == null and mi.mesh.surface_get_material(0) == null:
		return false
	return true


# --- noeuds et materiaux references par le code ---

static func _collect(v, pinned: Dictionary, pinned_mats: Dictionary, root: Node3D, depth: int, seen: Dictionary) -> void:
	if depth > MAX_DEPTH:
		return
	if v is Node:
		if is_instance_valid(v):
			if v != root and root.is_ancestor_of(v):
				pinned[v.get_instance_id()] = true
			if depth == 0 or v.get_script() != null:
				_collect_props(v, pinned, pinned_mats, root, depth, seen)
	elif v is Array:
		for e in v:
			_collect(e, pinned, pinned_mats, root, depth + 1, seen)
	elif v is Dictionary:
		for k in v:
			_collect(k, pinned, pinned_mats, root, depth + 1, seen)
			_collect(v[k], pinned, pinned_mats, root, depth + 1, seen)
	elif v is Material:
		pinned_mats[v.get_instance_id()] = true
	elif v is Object and is_instance_valid(v):
		if v.get_script() != null:
			_collect_props(v, pinned, pinned_mats, root, depth, seen)


static func _collect_props(o: Object, pinned: Dictionary, pinned_mats: Dictionary, root: Node3D, depth: int, seen: Dictionary) -> void:
	var id = o.get_instance_id()
	if seen.has(id):
		return
	seen[id] = true
	for p in o.get_property_list():
		if (int(p.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE) == 0:
			continue
		_collect(o.get(p.name), pinned, pinned_mats, root, depth + 1, seen)
