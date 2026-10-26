extends Node
## Cache de dessin pour les decors dessines en code (papier, cadre, bandeau, personnages animes...).
## Godot rejoue toutes les commandes de dessin d'un Control a CHAQUE image, meme si rien ne change : un papier
## filigrane ou un cadre cout ~1 ms. Ici un "peintre" (Control qui sait se dessiner) est rendu dans un SubViewport
## (une fois, ou a basse frequence pour une animation) et l'hote n'affiche plus qu'une texture (1 commande).
##
## Usage (dans l'hote, un Control) :
##   var baker := Baked.new(); baker.factory = func(): ...peintre...; baker.margin = 64; add_child(baker)
##   dans _draw() : if baker.draw(self): return   # sinon dessin direct (avant que le cache soit pret)
## Tant que le cache n'est pas pret, l'hote dessine directement : aucun clignotement a l'ouverture.

## Fabrique un peintre neuf : func() -> Control (non ajoute a l'arbre, taille geree ici).
var factory: Callable
## Resynchronise un peintre existant avant un nouveau rendu (animation) : func(painter) -> void.
var sync: Callable
## Marge (px logiques) autour de l'hote : le decor deborde parfois (scotch, clous).
var margin: float = 0.0
## > 0 : nouveau rendu toutes les `interval` secondes (animation douce). 0 : rendu unique.
var interval: float = 0.0

var baked_ok: bool = false
var _host: Control
var _vp: SubViewport
var _painter: Control
var _bake_size := Vector2.ZERO
var _bake_scale: float = 1.0
var _wait: float = 0.0
var _gen: int = 0
var _pending: bool = false
static var _mat: ShaderMaterial = null


func _ready() -> void:
	_host = get_parent() as Control
	_host.resized.connect(invalidate)
	_host.visibility_changed.connect(_on_visibility)
	get_viewport().size_changed.connect(invalidate)
	if _mat == null:
		# La texture d'un SubViewport transparent est en alpha premultiplie : fusion premultipliee, et la
		# modulation heritee (fondu, ghost...) est appliquee aux couleurs aussi (COLOR.a / alpha de texture).
		var sh := Shader.new()
		sh.code = "shader_type canvas_item;\nrender_mode blend_premul_alpha;\nvoid fragment() {\n	vec4 t = texture(TEXTURE, UV);\n	float ma = t.a > 0.0 ? COLOR.a / t.a : 0.0;\n	COLOR = vec4(COLOR.rgb * ma, COLOR.a);\n}\n"
		_mat = ShaderMaterial.new()
		_mat.shader = sh
	_on_visibility()


func _stretch() -> float:
	var s: float = get_viewport().get_final_transform().get_scale().x
	return clampf(s, 0.5, 3.0)


func _on_visibility() -> void:
	if _host != null and _host.is_visible_in_tree():
		_schedule()


func _schedule() -> void:
	if baked_ok or _pending or _vp != null:
		return
	_pending = true
	# on laisse la mise en page se stabiliser avant de figer le dessin
	await get_tree().create_timer(0.25).timeout
	_pending = false
	if is_inside_tree() and _host.is_visible_in_tree() and not baked_ok and _vp == null:
		_bake()


func invalidate() -> void:
	if _host == null:
		return
	_gen += 1
	if baked_ok or _vp != null:
		baked_ok = false
		_host.material = null
		if _vp != null:
			_vp.queue_free()
			_vp = null
			_painter = null
		_host.queue_redraw()
	_on_visibility()


func _bake() -> void:
	var sz := _host.size
	if sz.x < 8.0 or sz.y < 8.0 or not factory.is_valid():
		return
	_bake_size = sz
	_bake_scale = _stretch()
	_gen += 1
	var gen := _gen
	_vp = SubViewport.new()
	_vp.size = Vector2i(ceili((sz.x + margin * 2.0) * _bake_scale), ceili((sz.y + margin * 2.0) * _bake_scale))
	_vp.transparent_bg = true
	_vp.disable_3d = true
	_vp.gui_disable_input = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	_painter = factory.call()
	_painter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_painter.scale = Vector2(_bake_scale, _bake_scale)
	_painter.position = Vector2(margin, margin) * _bake_scale
	_painter.size = sz
	_vp.add_child(_painter)
	add_child(_vp)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	if gen != _gen or _vp == null:
		return
	baked_ok = true
	_wait = randf() * interval  # etale les rendus des differentes instances
	_host.material = _mat
	_host.queue_redraw()
	if interval <= 0.0:
		# rendu unique termine : le peintre n'est plus utile (la texture reste valide)
		_painter.queue_free()
		_painter = null


## Dessine la texture mise en cache ; retourne false si le cache n'est pas (ou plus) valable.
func draw(ci: CanvasItem) -> bool:
	if not baked_ok or _vp == null or _host.size != _bake_size:
		return false
	var m := margin
	ci.draw_texture_rect(_vp.get_texture(), Rect2(-m, -m, _bake_size.x + 2.0 * m, _bake_size.y + 2.0 * m), false)
	return true


## Rendu immediat (l'hote a change d'etat : nouveau client, expression...).
func refresh() -> void:
	if baked_ok and _painter != null and is_instance_valid(_painter) and _vp != null:
		_render_now()
	elif _vp != null or baked_ok:
		invalidate()


func _render_now() -> void:
	if sync.is_valid():
		sync.call(_painter)
	_painter.queue_redraw()
	_vp.render_target_update_mode = SubViewport.UPDATE_ONCE


func _process(delta: float) -> void:
	if interval <= 0.0 or not baked_ok or _painter == null or not is_instance_valid(_painter):
		return
	if not _host.is_visible_in_tree():
		return
	_wait += delta
	if _wait < interval:
		return
	_wait = fmod(_wait, interval)
	_render_now()
