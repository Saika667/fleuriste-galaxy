import os,sys,bpy
sys.path.insert(0,os.path.abspath('tools/blender'))
ns={'__file__':os.path.abspath('tools/blender/street_architecture_v2.py')}
exec(open(ns['__file__'],encoding='utf-8').read().split('\nfor spec in ')[0],ns)
for name,n,col in [('apartment_four',5,'#B7A48E'),('apartment_three',4,'#9BAEAE')]:
 ns['building'](name,12,n,col,'house')
 r=bpy.data.objects[name];r.scale.y=9/7
 for o in list(r.children):
  if o.name.startswith('Side_joinery'):bpy.data.objects.remove(o,do_unlink=True)
 for o in r.children_recursive:
  for m in o.modifiers:
   if m.type=='BEVEL':m.segments=1
 ns['bc'].export_glb(os.path.abspath('assets/models/street/'+name+'.glb'),r)
 bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath('art/blender/street/'+name+'.blend'))
