extends RefCounted
const K=preload("res://src/world/mesh_kit.gd")
static func window(p:Node3D,pos:Vector3,w:float,h:float,shutters:=false) -> void:
	K.box(p,Vector3(w,h,.065),pos,Color("#425E64"),.004)
	for dx in [-w/2,w/2]:K.box(p,Vector3(.10,h+.20,.18),pos+Vector3(dx,0,.04),Color("#D8CAB0"),.008)
	for dy in [-h/2,h/2]:K.box(p,Vector3(w+.20,.12,.24),pos+Vector3(0,dy,.06),Color("#D8CAB0"),.008)
	for dx in [-w*.24,0,w*.24]:K.box(p,Vector3(.035,h,.04),pos+Vector3(dx,0,.06),Color("#C6C7AC"),.003)
	K.box(p,Vector3(w,.035,.04),pos+Vector3(0,.12,.07),Color("#C6C7AC"),.002)
	K.box(p,Vector3(w+.35,.13,.36),pos+Vector3(0,-h*.5-.07,.12),Color("#D8CAB0"),.012)
	if shutters:
		for side in [-1,1]:
			K.box(p,Vector3(.38,h,.07),pos+Vector3(side*(w*.5+.28),0,.03),Color("#607D73"),.008)
			for j in 12:K.box(p,Vector3(.32,.045,.035),pos+Vector3(side*(w*.5+.28),-h*.43+j*h*.078,.08),Color("#81988B"),.002)
static func shop(p:Node3D) -> void:
	var r=Node3D.new();r.name="FloristStreetFrontage";p.add_child(r)
	# Frames respect every existing shop aperture and never cover the glazing.
	for x in [-.12,4.65,6.28,10.12]:
		K.box(r,Vector3(.23,2.72,.23),Vector3(x,1.36,8.27),Color("#D8CAB0"),.008)
		for y in [.15,.40,2.55]:K.box(r,Vector3(.31,.11,.29),Vector3(x,y,8.29),Color("#C1B69D"),.008)
	for y in [2.75,3.28,4.52]:K.box(r,Vector3(10.65,.16,.32),Vector3(5,y,8.25),Color("#D8CAB0"),.008)
	# Upper storey has real recessed window joinery and the same stone trim as the street.
	K.box(r,Vector3(10.4,3.0,.20),Vector3(5,6.9,8.72),Color("#A5B6A7"),0)
	for x in [.05,9.95]:
		for i in 6:K.box(r,Vector3(.28,.36,.28),Vector3(x,5.56+i*.49,8.85),Color("#D8CAB0"),.004)
	for x in [1.5,5,8.5]:window(r,Vector3(x,6.9,8.86),1.2,1.55,true)
	K.box(r,Vector3(10.7,.20,.40),Vector3(5,8.48,8.76),Color("#D8CAB0"),.008)
	for x in [-.15,10.15]:
		K.cylinder(r,.045,.045,7.1,Vector3(x,3.55,9.05),Color("#576A66"))
		for y in [1,3,5,6.7]:K.box(r,Vector3(.15,.05,.16),Vector3(x,y,8.99),Color("#384B48"),.003)
	for x in [-.23,10.23]:K.box(r,Vector3(.20,3.0,9.0),Vector3(x,6.9,4.3),Color("#A5B6A7"),0)
	K.box(r,Vector3(10.65,3.0,.20),Vector3(5,6.9,-.20),Color("#A5B6A7"),0)
	for side in [-1,1]:
		var roof=K.box(r,Vector3(11.3,.13,4.95),Vector3(5,9.25,4.3+side*2.34),Color("#526568"),.008);roof.rotation.x=side*atan(1.5/4.68)
		for i in 9:
			var z=side*(.22+i*.52);var y=10.0-absf(z)*1.5/4.68
			K.box(r,Vector3(11.3,.025,.035),Vector3(5,y,4.3+z),Color("#6A7777"),.002)
	for spec in [[Vector3(5.6,5.2,.08),Vector3(2.6,2.6,-.32)],[Vector3(3.97,5.2,.08),Vector3(8.415,2.6,-.32)],[Vector3(1.03,2.9,.08),Vector3(5.915,3.75,-.32)]]:K.box(r,spec[0],spec[1],Color("#A5B6A7"),0,.95,0,0)
	# Rear elevation: continuous plaster, framed ground-floor openings and upper windows.
	var back=Node3D.new();r.add_child(back);back.rotation.y=PI;back.position=Vector3(5,0,-.25)
	for x in [-5.05,5.05]:K.box(back,Vector3(.24,8.4,.23),Vector3(x,4.2,.05),Color("#D8CAB0"),0)
	for y in [.2,5.3,8.45]:K.box(back,Vector3(10.5,.18,.30),Vector3(0,y,.10),Color("#D8CAB0"),.004)
	for x in [-3.5,0,3.5]:window(back,Vector3(x,6.9,.16),1.2,1.55,true)
	for x in [-3.4,2.6]:window(back,Vector3(x,2.2,.15),1.15,1.6,true)
	p.placement_hide.append(r);p.cut_hide.append(r)
static func cellar(v:Node3D) -> void:
	var r=Node3D.new();r.name="CellarStreetFrontage";r.set_meta("cellar_external",true);v.add_child(r)
	# Local +Z faces the lower plaza. Stone piers break up the long elevation.
	for x in [-12,-8.4,-4.8,3.45,7.5,12]:
		K.box(r,Vector3(.30,3.78,.24),Vector3(x,1.89,9.36),Color("#AEA58F"),.008)
		for y in [.17,3.58]:K.box(r,Vector3(.43,.18,.34),Vector3(x,y,9.4),Color("#C5B79B"),.012)
	for y in [.15,3.77]:K.box(r,Vector3(24.5,.19,.34),Vector3(0,y,9.35),Color("#AEA58F"),.008)
	for x in [-10.3,-6.6,5.6,9.5]:window(r,Vector3(x,2.1,9.36),1.10,1.25,true)
	for x in [-11.8,11.8]:
		K.cylinder(r,.05,.05,3.65,Vector3(x,1.82,9.55),Color("#4F6560"))
	# Shutter cassette closes the header, including the strip above the metal slats.
	K.box(r,Vector3(4,.43,.48),Vector3(1,2.61,9.41),Color("#515F5B"),.022)
	for y in [2.46,2.60,2.74]:K.box(r,Vector3(3.85,.023,.025),Vector3(1,y,9.67),Color("#75847A"),.003)

	for side in [-1,1]:
		var elevation=Node3D.new();r.add_child(elevation);elevation.position=Vector3(side*12.32,0,0);elevation.rotation.y=side*PI/2
		K.box(elevation,Vector3(18,3.8,.15),Vector3(0,1.9,0),Color("#777F73"),0)
		for y in [.15,3.78]:K.box(elevation,Vector3(18.3,.18,.30),Vector3(0,y,.12),Color("#AEA58F"),.006)
		for z in [-6,-2,2,6]:window(elevation,Vector3(z,2.1,.12),1.0,1.3,true)
