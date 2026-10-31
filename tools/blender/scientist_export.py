"""Export a consolidated, skinned, unlit GLB with geometric toon outlines."""
import json
import os
import struct
import bpy


def export(root, path):
    colors={}
    for mat in bpy.data.materials:
        emission=next((n for n in mat.node_tree.nodes if n.type=="EMISSION"),None) if mat.use_nodes else None
        colors[mat.name]=list(emission.inputs["Color"].default_value if emission else mat.diffuse_color)
    meshes=[o for o in root.children_recursive if o.type=="MESH" and not o.hide_get()]
    buckets={}
    for obj in meshes:
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.context.view_layer.objects.active=obj
        for mod in list(obj.modifiers):
            if mod.type!="ARMATURE":
                bpy.ops.object.modifier_apply(modifier=mod.name)
        buckets.setdefault(obj.parent.name,[]).append(obj)
    for parent,objects in buckets.items():
        bpy.ops.object.select_all(action="DESELECT")
        for obj in objects:
            obj.select_set(True)
        bpy.context.view_layer.objects.active=objects[0]
        if len(objects)>1:
            bpy.ops.object.join()
        bpy.context.object.name=parent+"_Geometry"
    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    for obj in root.children_recursive:
        if not obj.hide_get():
            obj.select_set(True)
    bpy.ops.export_scene.gltf(filepath=path,export_format="GLB",use_selection=True,
                             export_apply=False,export_skins=True,export_extras=True,
                             export_cameras=False,export_lights=False)
    raw=open(path,"rb").read()
    length,kind=struct.unpack_from("<I4s",raw,12)
    assert kind==b"JSON"
    doc=json.loads(raw[20:20+length])
    for mat in doc.get("materials",[]):
        color=colors.get(mat.get("name"))
        if color:
            mat["pbrMetallicRoughness"]={"baseColorFactor":color,"metallicFactor":0,"roughnessFactor":1}
        mat.pop("emissiveFactor",None)
        mat["extensions"]={"KHR_materials_unlit":{}}
    doc["extensionsUsed"]=["KHR_materials_unlit"]
    doc.pop("extensionsRequired",None)
    encoded=json.dumps(doc,separators=(",",":"),ensure_ascii=True).encode()
    encoded+=b" "*((-len(encoded))%4)
    binary=raw[20+length:]
    total=12+8+len(encoded)+len(binary)
    with open(path,"wb") as f:
        f.write(struct.pack("<4sII",b"glTF",2,total))
        f.write(struct.pack("<I4s",len(encoded),b"JSON"))
        f.write(encoded)
        f.write(binary)
    assert doc.get("skins"), "Missing skin"
    assert all(not n.get("name","").startswith(("Mouth_open","Mouth_shout","Blush_")) for n in doc["nodes"])
    tris=sum(doc["accessors"][p["indices"]]["count"]//3 for m in doc["meshes"] for p in m["primitives"])
    report={"file":path,"bytes":total,"triangles_including_outlines":tris,
            "meshes":len(doc["meshes"]),"material_primitives":sum(len(m["primitives"]) for m in doc["meshes"]),
            "materials":len(doc["materials"]),"skins":len(doc["skins"]),
            "joints":len(doc["skins"][0]["joints"]),"animations":len(doc.get("animations",[])),
            "shading":"KHR_materials_unlit; inverted hull outlines",
            "checks":["GLB header and JSON parsed", "skeleton exported", "hidden expressions excluded"]}
    with open(os.path.splitext(path)[0]+".json","w",encoding="utf-8") as f:
        json.dump(report,f,indent=2,ensure_ascii=False)
    print("GAME_ASSET",json.dumps(report))
