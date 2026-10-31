"""Run with Blender opening art/blender/gel_bleu.blend."""
import bpy, bmesh, json, os
obj=bpy.data.objects['Continuous_gel_skin']
bm=bmesh.new();bm.from_mesh(obj.data)
assert all(e.is_manifold for e in bm.edges), 'Open or internal skin edges'
remaining=set(bm.verts);components=0
while remaining:
    components+=1;todo=[remaining.pop()]
    while todo:
        v=todo.pop()
        for edge in v.link_edges:
            other=edge.other_vert(v)
            if other in remaining:remaining.remove(other);todo.append(other)
assert components==1,components
bm.free()
for v in obj.data.vertices:
    assert abs(sum(g.weight for g in v.groups)-1)<.003, 'Unnormalized skin weights'
arm=next(mod.object for mod in obj.modifiers if mod.type=='ARMATURE')
def sample():
    deps=bpy.context.evaluated_depsgraph_get();deps.update()
    ev=obj.evaluated_get(deps);mesh=ev.to_mesh()
    points=[(ev.matrix_world@v.co).copy() for v in mesh.vertices];ev.to_mesh_clear();return points
rest=sample();bone=arm.pose.bones['upper_arm.R'];bone.rotation_mode='XYZ';bone.rotation_euler.x=.2
bpy.context.view_layer.update();posed=sample()
motion=max((a-b).length for a,b in zip(rest,posed));assert motion>.01,motion
bone.rotation_euler.x=0;bpy.context.view_layer.update();restored=sample()
assert max((a-b).length for a,b in zip(rest,restored))<.00001
report={'passed':True,'continuous_shell_components':components,'closed_manifold':True,'normalized_weights':True,'arm_pose_vertex_motion_m':motion,'restoration':True}
root=os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
json.dump(report,open(os.path.join(root,'out/blender/gel_skin_validation.json'),'w'),indent=2)
print('GEL_SKIN_VALIDATION',json.dumps(report))
