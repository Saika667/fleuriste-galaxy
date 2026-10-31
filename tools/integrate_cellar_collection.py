"""Install the native collection while retaining CellarView gameplay contracts."""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]
def replace_method(s,name,body):
    pat=rf'(?m)^(?:static )?func {re.escape(name)}\([^\n]*\n[\s\S]*?(?=^(?:static )?func |^class |\Z)'
    m=re.search(pat,s)
    assert m,name
    header=m.group().split('\n')[0]
    return s[:m.start()]+header+'\n'+body.rstrip()+'\n\n\n'+s[m.end():]
p=ROOT/'src/cellar_view/cellar_view.gd';s=p.read_text(encoding='utf-8')
s=s.replace('Vector3(10.0, 3.0, 8.0)','Vector3(24.0, 3.8, 18.0)').replace('const STAIRS_X := -3.6','const STAIRS_X := -10.5')
s=re.sub(r'^const BIN_POS := .*$', 'const BIN_POS := [Vector3(-6,0,-6.2),Vector3(-2,0,-6.2),Vector3(2,0,-6.2),Vector3(6,0,-6.2)]',s,flags=re.M)
for name,value in [('CABINET_POS','Vector3(10.9,0,3.2)'),('COMPOSTER_POS','Vector3(-10.0,0,-2.4)'),('COUNTER_POS','Vector3(1,0,6.7)'),('HATCH_POS','Vector3(7.0,0,3.0)'),('GUEST_Z','8.0')]:
    s=re.sub(rf'^const {name} := .*$',f'const {name} := {value}',s,flags=re.M)
if 'const Remodel=' not in s:s=s.replace('\nsignal exit_requested\n','\nconst Remodel=preload("res://src/cellar_view/cellar_remodel.gd")\n\nsignal exit_requested\n',1)
s=s.replace('\tCellarScenery.build(self)','\t# Native decor is built by Remodel; the old dressing is intentionally replaced.')
for method,fn in [('_build_room','room'),('_build_stairs','stairs'),('_build_cabinet','cabinet'),('_refresh_cabinet','cabinet_refresh'),('_build_seed_crate','seed_crate'),('_build_counter','counter'),('_build_hatch','hatch'),('_build_decor','decor'),('_build_consoles','consoles')]:s=replace_method(s,method,'\tRemodel.'+fn+'(self)')
s=s.replace('Vector3(STAIRS_X, 0.1, 0.9)','Vector3(-9.0,0.1,7.1)')
s=s.replace('_composter = ComposterView.new()','_composter = load("res://src/cellar_view/composter_remodel.gd").new()').replace('_composter.rotation.y = 2.5','_composter.rotation.y = PI * .5')
s=s.replace('env.ambient_light_energy = 0.55','env.ambient_light_energy = 0.80').replace('env.fog_density = 0.03','env.fog_density = 0.004').replace('env.volumetric_fog_density = 0.06','env.volumetric_fog_density = 0.008').replace('env.volumetric_fog_length = 14.0','env.volumetric_fog_length = 32.0')
p.write_text(s,encoding='utf-8')

p=ROOT/'src/cellar_view/planter_view.gd';s=p.read_text(encoding='utf-8')
s=s.replace('const LIFT := 0.17','const LIFT := 0.0')
if 'const Native=' not in s:s=s.replace('const LIFT', 'const Native=preload("res://src/cellar_view/cellar_collection.gd")\nconst LIFT',1)
s=re.sub(r'^const SLOT_POS := .*$', 'const SLOT_POS := [Vector3(-.43,.483,-.24),Vector3(.43,.483,-.24),Vector3(-.43,.483,.24),Vector3(.43,.483,.24)]',s,flags=re.M)
s=replace_method(s,'_build_bin','''	_bin=Node3D.new();_bin.position.y=LIFT;add_child(_bin)
	Native.attach(_bin,"grow_bed")
	CellarKit.solid(_bin,Vector3(1.8,.55,1.1),Vector3(0,.275,0))
	_lamp_rig=Node3D.new();_lamp_rig.position.y=2.65;_bin.add_child(_lamp_rig)
	Native.attach(_lamp_rig,"bed_lamp")
	_lamp_light=CellarKit.spot(_lamp_rig,Vector3(0,-.08,0),Vector3(0,-2,0),Color("B4E7C7"),1.1,3.2,65)
	_build_props()
	for i in 4:
		var slot=Node3D.new();slot.position=SLOT_POS[i];_bin.add_child(slot);_slots.append(slot)
		var ii=i
		_its.append(CellarKit.interactable(_bin,Vector3(.78,1.1,.45),SLOT_POS[i]+Vector3(0,.25,0),func():return view.slot_prompt(index,ii),func(p):view.slot_action(index,ii,p)))
''')
s=replace_method(s,'_build_props','''	Native.attach(_bin,"culture_jar",Vector3(.79,.56,.40))
	Native.attach(_bin,"trowel",Vector3(-.72,.56,.48),0,.7).rotation.x=PI/2
	Native.attach(_bin,"shears" if index%2 else "watering_can",Vector3(-.80,.56,-.40),0,.65)
	Native.attach(_bin,"label",Vector3(0,.36,.58))
	Native.attach(_bin,"power_strip",Vector3(1.1,-LIFT,.1))
	if index%2==0:Native.attach(_bin,"bucket",Vector3(-1.20,-LIFT,0))
''')
if '\t\tfor c in _lamp_rig.get_children():' in s:
    a=s.index('\t\tfor c in _lamp_rig.get_children():',s.index('var lv = int(cellar.equipment.lamp)'))
    b=s.index('\n\n',a)
    s=s[:a]+'\t\t_lamp_light.light_energy = 1.1 + .15 * lv'+s[b:]
s=s.replace('(s.crop == "gloom_moss" or s.crop == "star_vine") and ','')
p.write_text(s,encoding='utf-8')
p=ROOT/'src/cellar_view/plant_view.gd';s=p.read_text(encoding='utf-8')
s=replace_method(s,'build','''	return preload("res://src/cellar_view/cellar_collection.gd").plant(crop,stage)
''')
p.write_text(s,encoding='utf-8')
print('Native cellar builders integrated; gameplay, four-slot beds and visitor controllers preserved.')
