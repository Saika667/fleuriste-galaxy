extends RefCounted
var t
const MERGE=preload("res://src/world/static_merge.gd")
func two_surfaces() -> ArrayMesh:
	var source=BoxMesh.new();source.size=Vector3(1,2,1)
	var mesh=ArrayMesh.new()
	for color in [Color.RED,Color.BLUE]:
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,source.surface_get_arrays(0))
		var material=StandardMaterial3D.new();material.albedo_color=color
		mesh.surface_set_material(mesh.get_surface_count()-1,material)
	return mesh
func test_multi_material_batches_preserve_geometry_and_colors() -> void:
	var root=Node3D.new();var part=MeshInstance3D.new();part.mesh=two_surfaces();part.position=Vector3(3,0,2);root.add_child(part)
	MERGE.merge(root)
	var count=0;var reds=0;var blues=0;var vertices=[]
	for node in root.find_children("*","MeshInstance3D",true,false):
		count+=node.mesh.get_faces().size()
		var arrays=node.mesh.surface_get_arrays(0)
		for color in arrays[Mesh.ARRAY_COLOR]:
			if color.r>.9 and color.b<.1:reds+=1
			if color.b>.9 and color.r<.1:blues+=1
		for v in arrays[Mesh.ARRAY_VERTEX]:vertices.append(node.transform*v)
	t.eq(count,72,"Two boxes keep their 24 triangles")
	t.check(reds>0 and blues>0,"Both surface colors survive batching")
	t.check(vertices.all(func(v):return v.x>=2.49 and v.x<=3.51 and v.z>=1.49 and v.z<=2.51),"The source transform is preserved")
	root.free()
func test_skinned_meshes_keep_their_skin_and_surfaces() -> void:
	var root=Node3D.new();var part=MeshInstance3D.new();part.mesh=two_surfaces();part.skin=Skin.new();root.add_child(part)
	var original=part.mesh;var skin=part.skin
	MERGE.merge(root)
	t.check(is_instance_valid(part) and part.get_parent()==root,"Skinned mesh stays attached")
	t.check(part.mesh==original and part.skin==skin,"Skin and mesh are not replaced")
	t.eq(part.mesh.get_surface_count(),2,"Skinned surfaces are not split")
	root.free()
