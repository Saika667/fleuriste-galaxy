extends RefCounted
## Used only by generated catalogue copies of the real game builders.
static var entries: Array=[]
static var counters: Dictionary={}

static func record(parent: Node,start: int,id: String,title: String,category: String,source: String) -> void:
	var nodes=[]
	for i in range(start,parent.get_child_count()):
		var child=parent.get_child(i)
		if child is Node3D and visual(child):nodes.append(child)
	if nodes.is_empty():return
	var n=int(counters.get(id,0))+1;counters[id]=n
	entries.append({"id":id+"_%02d"%n,"title":title+(" — exemplaire "+str(n) if n>1 else ""),"nodes":nodes,"category":category,"instances":1,"source":source,"world_position":parent.to_global(Vector3.ZERO) if parent is Node3D else Vector3.ZERO})

static func visual(node: Node) -> bool:
	if node is MeshInstance3D or node is Label3D:return true
	for child in node.get_children():
		if visual(child):return true
	return false
