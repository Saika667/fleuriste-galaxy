import os,sys,bpy
sys.path.insert(0,os.path.abspath('tools/blender'))
ns={'__file__':os.path.abspath('tools/blender/street_architecture_v2.py')}
s=open(ns['__file__'],encoding='utf-8').read().split('\nfor spec in ')[0]
s=s.replace("box('Workshop_double_door',(w*.42,2.50,.10),(0,1.25,z+.24),'steel_dark',r,.02)","pass").replace('window(r,x,1.8,z+.31,w=.65,h=.9)','window(r,x,4.6,z+.31,w=.65,h=.9)')
exec(s,ns)
ns['building']('blue_workshop',8,2,'#899FA5','workshop')
