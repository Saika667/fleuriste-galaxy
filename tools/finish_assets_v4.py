from pathlib import Path
root=Path(__file__).resolve().parents[1]
def edit(p,a,b):
 f=root/p;s=f.read_text(encoding='utf-8-sig');assert a in s,(p,a[:60]);f.write_text(s.replace(a,b),encoding='utf-8')
p='tools/blender/district_detail_v3.py'
edit(p,"[(-.17,.03,.45),(.11,0,.70),(.29,-.13,.32)]","[(-.13,.03,.17),(.09,0,.25),(.19,-.10,.12),(-.05,-.12,.09)]")
edit(p,".009,'cream',r)",".003,'cream',r)")
edit(p,"(.023,.007,.018),'cream',r)","(.008,.003,.006),'cream',r)")
edit(p,"tube('Sacrum',[(0,.97,-.015),(0,.85,-.025),(0,.79,.005)],.036,'bone',r)","""mesh('Triangular_sacrum',[(-.058,.97,-.065),(.058,.97,-.065),(0,.855,-.085),(-.045,.97,-.025),(.045,.97,-.025),(0,.855,-.065)],[(0,1,2),(5,4,3),(0,3,4,1),(1,4,5,2),(2,5,3,0)],'bone',r)
 for j in range(4):oval('Coccygeal_vertebra',(0,.849-j*.015,-.083+j*.004),(.015-j*.0027,.010-j*.001,.010-j*.0015),'bone',r)""")
edit(p,"""  for k in range(5):
   x=s*(.275+k*.018);bone((x,.85,.03),(x,.77,.05),.010)
   bone((x,.77,.05),(x+s*.009,.70+(k%2)*.015,.075),.008)
   bone((s*(.08+k*.018),.09,.025),(s*(.08+k*.018),.055,.16-k*.012),.012)""","""  for j in range(2):
   for k in range(3):oval('Carpal',(s*(.291+k*.014),.854-j*.015,.03),(.009,.009,.008),'bone',r)
  for k,length in enumerate([.090,.107,.100,.077]):
   x=s*(.284+k*.021);tip=s*(.275+k*.029)
   bone((s*.315,.825,.03),(x,.786,.039),.0075)
   bone((x,.786,.039),(tip,.786-length*.48,.048),.0065)
   bone((tip,.786-length*.48,.048),(tip,.786-length*.79,.056),.0057)
   bone((tip,.786-length*.79,.056),(tip,.786-length,.063),.005)
  bone((s*.293,.827,.04),(s*.252,.797,.055),.008)
  bone((s*.252,.797,.055),(s*.239,.767,.074),.007)
  bone((s*.239,.767,.074),(s*.244,.745,.087),.006)
  for k in range(5):bone((s*(.08+k*.018),.09,.025),(s*(.08+k*.018),.055,.16-k*.012),.012)""")
edit(p,"oval('Silver_sidehair',(s*.135,1.81,-.025),(.043,.14,.12),'silver',r)","""for j in range(7):
   oval('Layered_silver_lock',(s*(.136+j*.0018),1.91-j*.023,-.04-j*.006),(.022,.044,.073),'silver',r)
  tube('Spectacle_temple',[(s*.137,1.82,.177),(s*.157,1.82,.08),(s*.164,1.80,-.015),(s*.16,1.765,-.025)],.005,'ink',r)""")
edit(p,"'teal_dark',r)\n  tube('Sleeve'","'suit',r)\n  mesh('Folded_shirt_collar',[(s*.015,1.48,.139),(s*.10,1.49,.127),(s*.072,1.389,.155),(s*.025,1.426,.160)],[(0,1,2,3)],'cream',r)\n  tube('Lapel_pickstitch',[(s*.115,1.455,.146),(s*.194,1.352,.15),(s*.135,1.327,.166),(s*.151,1.283,.166),(s*.012,1.14,.165)],.0025,'steel',r)\n  box('Pocket_welt',(.10,.012,.016),(s*.14,1.11,.128),'ink',r,.002)\n  tube('Sleeve'")
edit(p,"cylinder(r,'Neck',.07", "oval('Tie_knot',(0,1.433,.16),(.029,.027,.015),'tie',r)\n cylinder(r,'Neck',.07")

p='tools/blender/street_architecture_v2.py'
edit(p,"if level>0:window(r,x,1.48+level*3.05,-z-.15,w=.9,h=1.5)","""if level>0:
                rear=bc.pivot('Rear_window',bc.G(x,1.48+level*3.05,-z-.03),r);rear.rotation_euler.z=math.pi
                window(rear,0,0,0,w=.95,h=1.55,shutters=True)""")
edit(p,"    # Real gable volume", """    # Rear elevations are real architecture, with outward projecting joinery.
    rear=bc.pivot('Garden_doorway',bc.G(0,0,-z-.04),r);rear.rotation_euler.z=math.pi
    box('Garden_entry_door',(1.05,2.20,.08),(0,1.10,.04),'shutter',rear,.012)
    for dx in [-.59,.59]:box('Garden_door_jamb',(.12,2.32,.21),(dx,1.16,.08),'limestone',rear,.008)
    box('Garden_lintel',(1.30,.15,.25),(0,2.36,.09),'limestone',rear,.008)
    window(rear,-w*.30,1.52,0,w=1.10,h=1.45,shutters=True)
    window(rear,w*.30,1.52,0,w=1.10,h=1.45,shutters=True)
    box('Rear_threshold',(1.38,.12,.60),(0,.06,.22),'limestone',rear,.012)
    for x in [-w/2+.22,w/2-.22]:
        tube('Rear_downpipe',[(x,.15,-z-.16),(x,h-.10,-z-.16)],.045,'steel_dark',r)
        for y in [1,3.3,5.5]:box('Rear_pipe_clamp',(.15,.05,.17),(x,y,-z-.10),'iron',r,.004)
    for sign in [-1,1]:
        side=bc.pivot('Side_joinery',bc.G(sign*(w/2+.03),0,0),r);side.rotation_euler.z=-sign*math.pi/2
        for level in range(levels):
            for x in [-1.8,1.8]:window(side,x,1.48+level*3.05,0,w=.85,h=1.4,shutters=True)
    # Real gable volume""")
print('MODEL_REFINEMENTS_APPLIED')
