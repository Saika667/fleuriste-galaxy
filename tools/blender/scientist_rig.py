"""Deformation skeleton for the independent scientist asset (Godot coordinates)."""
import bpy
from mathutils import Vector
from bl_common import G


def bind(root, head_y, head_z, shoulder_y):
    data = bpy.data.armatures.new("ScientistSkeleton")
    arm = bpy.data.objects.new("ScientistSkeleton", data)
    bpy.context.collection.objects.link(arm)
    arm.parent = root
    arm.show_in_front = True
    bpy.context.view_layer.objects.active = arm
    arm.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    specs = [
        ("pelvis", (0,.86,0), (0,.98,0), None),
        ("spine", (0,.98,0), (0,1.17,.04), "pelvis"),
        ("chest", (0,1.17,.04), (0,1.36,.075), "spine"),
        ("neck", (0,1.36,.075), (0,head_y-.13,head_z-.02), "chest"),
        ("head", (0,head_y-.13,head_z-.02), (0,head_y+.18,head_z), "neck"),
    ]
    for i,sx in ((0,-1),(1,1)):
        side = "R" if i==0 else "L"
        shoulder=(sx*.148,shoulder_y,.06)
        elbow=(-.18,1.06,.06) if i==0 else (.168,1.04,.025)
        wrist=(-.25,.87,.20) if i==0 else (.178,.77,.05)
        hand=(-.255,.81,.225) if i==0 else (.18,.61,.055)
        x=-.07 if i==0 else .075
        specs += [
            (f"upper_arm.{side}",shoulder,elbow,"chest"),
            (f"forearm.{side}",elbow,wrist,f"upper_arm.{side}"),
            (f"hand.{side}",wrist,hand,f"forearm.{side}"),
            (f"thigh.{side}",(x,.90,0),(x,.52,.005),"pelvis"),
            (f"shin.{side}",(x,.52,.005),(x,.11,-.006),f"thigh.{side}"),
            (f"foot.{side}",(x,.11,-.006),(x,.04,.15),f"shin.{side}"),
        ]
    for name,a,b,parent in specs:
        bone=data.edit_bones.new(name)
        bone.head, bone.tail = G(*a),G(*b)
        if parent:
            bone.parent=data.edit_bones[parent]
    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.context.view_layer.update()

    def smooth(a,b,x):
        u=max(0,min(1,(x-a)/(b-a)))
        return u*u*(3-2*u)

    for obj in list(root.children_recursive):
        if obj.type!="MESH":
            continue
        parents=[]
        p=obj.parent
        while p:
            parents.append(p.name)
            p=p.parent
        name=obj.name
        groups={}
        def assign(index,bone,weight):
            if weight < .0001:
                return
            if bone not in groups:
                groups[bone]=obj.vertex_groups.new(name=bone)
            groups[bone].add([index],weight,"REPLACE")
        for vertex in obj.data.vertices:
            pos=obj.matrix_world @ vertex.co
            y=pos.z
            weights={"pelvis":1.0}
            if "Head" in parents:
                weights={"head":1.0}
            elif name.startswith("Neck"):
                weights={"neck":1.0}
            elif "Arm_0" in parents or "Arm_1" in parents:
                i=0 if "Arm_0" in parents else 1
                side="R" if i==0 else "L"
                if name.startswith("Cane_") or any(t in name for t in ("hand","finger","thumb","fist")):
                    weights={f"hand.{side}":1.0}
                else:
                    w=smooth(1.01,1.11,y)
                    weights={f"upper_arm.{side}":w,f"forearm.{side}":1-w}
            elif "Leg_0" in parents or "Leg_1" in parents:
                side="R" if "Leg_0" in parents else "L"
                if any(t in name for t in ("shoe","sole","strap")):
                    weights={f"foot.{side}":1.0}
                else:
                    w=smooth(.47,.57,y)
                    weights={f"thigh.{side}":w,f"shin.{side}":1-w}
            elif "Torso" in parents:
                a=smooth(.96,1.12,y)
                b=smooth(1.16,1.30,y)
                weights={"pelvis":1-a,"spine":a*(1-b),"chest":a*b}
            for bone,w in weights.items():
                assign(vertex.index,bone,w)
        mod=obj.modifiers.new("Skeleton","ARMATURE")
        mod.object=arm
    return arm
