import bpy,sys,os
sys.path.insert(0,os.path.abspath('tools/blender'))
import bl_common as bc
bpy.ops.wm.open_mainfile(filepath=os.path.abspath('art/blender/street/apartment_five.blend'))
r=bpy.data.objects.get('apartment_five')
for o in r.children_recursive:
 for m in o.modifiers:
  if m.type=='BEVEL':m.segments=1
bc.export_glb(os.path.abspath('assets/models/street/apartment_five.glb'),r)
bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath('art/blender/street/apartment_five.blend'))
