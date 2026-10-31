extends SceneTree
func _init():
 var C=load("res://src/cellar_view/cellar_collection.gd")
 for id in ["grow_bed","herb_ripe","harvest_jar_q2","floor"]:
  var n=C.create(id);var counts={}
  for m in n.find_children("*","MeshInstance3D",true,false):
   var key=str(m.mesh.get_surface_count())+"|"+str(m.get_meta_list())+"|"+str(m.get_surface_override_material(0)!=null)
   counts[key]=counts.get(key,0)+1
  print("MESH_AUDIT ",id," ",counts," merge=",load("res://src/world/static_merge.gd").last_stats)
  n.free()
 quit()
