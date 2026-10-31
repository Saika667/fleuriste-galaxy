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
	# Rear ground floor is solid plaster without decorative fake windows.
	for spec in [[Vector3(5.6,5.2,.08),Vector3(2.6,2.6,-.32)],[Vector3(3.97,5.2,.08),Vector3(8.415,2.6,-.32)],[Vector3(1.03,2.9,.08),Vector3(5.915,3.75,-.32)]]:K.box(r,spec[0],spec[1],Color("#A5B6A7"),0,.95,0,0)
	p.placement_hide.append(r);p.cut_hide.append(r)
static func cellar(v:Node3D) -> void:
	var r=Node3D.new();r.name="CellarStreetFrontage";r.set_meta("cellar_external",true);v.add_child(r)
	# Industrial envelope: corrugated cladding, low concrete footing and exposed steel.
	var steel=Color("#4E5C5C");var concrete=Color("#85867B")
	K.box(r,Vector3(2.1,.16,18.5),Vector3(-13.3,4.12,0),steel,0)
	for z in [-9.2,9.2]:K.box(r,Vector3(2.1,4.2,.16),Vector3(-13.3,2.1,z),concrete,0)
	for span in [[-12.25,-3.78],[-2.16,-.90],[2.90,12.25]]:
		var width=span[1]-span[0];var cx=(span[0]+span[1])/2
		K.box(r,Vector3(width,4.2,.08),Vector3(cx,2.1,9.34),Color("#887F6D"),0)
		K.box(r,Vector3(width,.22,.10),Vector3(cx,.11,9.39),concrete,0)
		for i in ceili(width/.20):K.box(r,Vector3(.045,3.8,.045),Vector3(span[0]+.10+i*.20,2.1,9.41),steel,0)
	for x in [-12.25,-7.7,-3.80,-2.14,2.92,7.7,12.25]:
		for dz in [9.40,9.57]:K.box(r,Vector3(.19,3.8,.045),Vector3(x,1.9,dz),steel,0)
		K.box(r,Vector3(.06,3.8,.19),Vector3(x,1.9,9.48),steel,0)
	K.box(r,Vector3(24.6,.18,.30),Vector3(0,4.18,9.45),steel,0)
	K.box(r,Vector3(3.9,.4,.42),Vector3(1,2.64,9.40),steel,.012)
	for side in [-1,1]:
		var elevation=Node3D.new();r.add_child(elevation);elevation.position=Vector3(-14.3 if side<0 else 12.28,0,0);elevation.rotation.y=side*PI/2
		K.box(elevation,Vector3(18.5,4.2,.12),Vector3(0,2.1,0),concrete,0)
		for i in 91:K.box(elevation,Vector3(.04,3.8,.05),Vector3(-9+i*.20,2.1,.095),steel,0)
		for x in [-8.8,-4.4,0,4.4,8.8]:K.box(elevation,Vector3(.16,4.2,.22),Vector3(x,2.1,.12),steel,0)
		K.box(elevation,Vector3(18.7,.13,.34),Vector3(0,4.18,.10),steel,0)
		K.box(elevation,Vector3(18.5,.22,.17),Vector3(0,.11,.08),concrete,0)
		# Two narrow cellar vents; no house-sized windows beside the slope.
		for x in [-6.5,4.5]:
			K.box(elevation,Vector3(1.3,.45,.10),Vector3(x,3.30,.14),Color("#273B3B"),0)
			for j in 7:K.box(elevation,Vector3(.025,.48,.07),Vector3(x-.55+j*.18,3.30,.23),steel,0)
		for i in 3:
			var x=-3.0+i*.72
			K.box(elevation,Vector3(.56,.76,.012),Vector3(x,1.1+(i%2)*.13,.19),Color("#A69979") if i%2 else Color("#7B8173"),0)
			for j in 5:K.box(elevation,Vector3(.06,.08,.014),Vector3(x-.24+j*.10,.73+(i%2)*.13+fmod(j*.13,.15),.203),concrete,0)
			K.label(elevation,["CONCERT","AVIS","PERDU"][i],Vector3(x,1.23+(i%2)*.13,.21),24,Color("#3B4540"),.0023).outline_size=0
