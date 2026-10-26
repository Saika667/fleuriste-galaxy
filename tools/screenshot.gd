extends SceneTree
# Usage: godot --path <projet> --resolution 1920x1080 --script res://tools/screenshot.gd -- res://scenes/x.tscn out.png [frames]
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("usage: -- <res://scene.tscn> <out.png> [frames]")
		quit(2)
		return
	var frames := 30
	if args.size() > 2:
		frames = int(args[2])
	var packed = load(args[0])
	if packed == null:
		push_error("scene introuvable: " + args[0])
		quit(3)
		return
	root.add_child(packed.instantiate())
	_run(args[1], frames)

func _run(out: String, frames: int) -> void:
	for i in frames:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var err := img.save_png(out)
	print("screenshot ", out, " ", img.get_width(), "x", img.get_height(), " err=", err)
	quit(0 if err == OK else 4)
