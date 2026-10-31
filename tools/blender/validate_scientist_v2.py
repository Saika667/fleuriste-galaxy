"""Reimport the actual delivery GLB, verify skin deformation and render it."""
import json
import math
import os
import sys
import bpy
sys.path.insert(0,os.path.dirname(__file__))
import bl_common as bc

path=os.path.join(bc.ROOT,"assets/models/characters/old_scientist_v2_toon.glb")
bc.reset_scene()
bpy.ops.import_scene.gltf(filepath=path)
arm=next(o for o in bpy.data.objects if o.type=="ARMATURE")
meshes=[o for o in bpy.context.scene.objects if o.type=="MESH" and any(m.type=="ARMATURE" for m in o.modifiers)]
assert len(meshes)==11
assert len(arm.data.bones)==17
unweighted=0
for obj in meshes:
    for vertex in obj.data.vertices:
        assert all(math.isfinite(n) for n in vertex.co)
        if not vertex.groups or abs(sum(g.weight for g in vertex.groups)-1)>0.002:
            if unweighted<8:
                print("BAD_WEIGHT",obj.name,vertex.index,list(vertex.co),[(obj.vertex_groups[g.group].name,g.weight) for g in vertex.groups])
            unweighted+=1
assert unweighted==0,("Invalid skin weights",unweighted)

def samples():
    deps=bpy.context.evaluated_depsgraph_get()
    deps.update()
    out=[]
    for obj in meshes:
        ev=obj.evaluated_get(deps)
        mesh=ev.to_mesh()
        out.extend((ev.matrix_world@v.co).copy() for v in mesh.vertices)
        ev.to_mesh_clear()
    return out

rest=samples()
bone=arm.pose.bones["forearm.R"]
bone.rotation_mode="XYZ"
bone.rotation_euler.x=math.radians(15)
bpy.context.view_layer.update()
posed=samples()
max_motion=max((a-b).length for a,b in zip(rest,posed))
assert max_motion>.01,max_motion
bone.rotation_euler.x=0
bpy.context.view_layer.update()
restored=samples()
assert max((a-b).length for a,b in zip(rest,restored))<1e-5
report={"reimport":"passed","joint_count":len(arm.data.bones),"finite_vertex_positions":"passed",
        "normalized_skin_weights":"passed","forearm_pose_max_vertex_motion_m":max_motion,
        "restore_bind_pose":"passed","runtime_engine_test":"not run"}
with open(os.path.join(bc.ROOT,"out/blender/sci_v2_validation.json"),"w") as f:
    json.dump(report,f,indent=2)
print("VALIDATION",json.dumps(report))
bc.render_preview(os.path.join(bc.ROOT,"out/blender/sci_v2_imported"),
                  views={"three_quarter":dict(yaw=28,elev=0,focus=(0,.93,.03),dist=12.6)},
                  res=(768,1152),floor=False,bg="#FBFAF5",key_only=True,lens=200)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(bc.ROOT,"art/blender/old_scientist_v2_toon.blend"))
