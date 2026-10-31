"""Ten distinct static props for the five remaining approved growth sheets."""
import os,sys,math,ast
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from cannabis_remaining import Plant
from cannabis_compact_growth import young_leaf

# Reuse literal palette and planter specifications from the adult source, without
# constructing adult meshes or scaling the pots. Each young canopy is built below.
def design_specs():
    tree=ast.parse(open(os.path.join(os.path.dirname(__file__),'cannabis_remaining.py'),encoding='utf-8').read())
    specs={}
    for fn in tree.body:
        if not isinstance(fn,ast.FunctionDef):continue
        for stmt in fn.body:
            if isinstance(stmt,ast.Assign) and isinstance(stmt.value,ast.Call) and isinstance(stmt.value.func,ast.Name) and stmt.value.func.id=='Plant':
                call=stmt.value;args=[ast.literal_eval(v) for v in call.args]
                specs[args[0]]={'reference':args[1],'colors':args[2],'options':{k.arg:ast.literal_eval(k.value) for k in call.keywords}}
                spec=specs[args[0]]
            if isinstance(stmt,ast.Expr) and isinstance(stmt.value,ast.Call) and isinstance(stmt.value.func,ast.Attribute) and stmt.value.func.attr=='pot':
                spec['pot_args']=[ast.literal_eval(v) for v in stmt.value.args]
                spec['pot_options']={k.arg:ast.literal_eval(k.value) for k in stmt.value.keywords}
    return specs

SPECS=design_specs()

def create(family,stage):
    spec=SPECS[family]
    p=Plant(family+'_'+stage,'growth/'+spec['reference']+'_stades',spec['colors'],**spec['options'])
    p.pot(*spec['pot_args'],**spec['pot_options'])
    soil=p.pot_height*.86+.004
    p.outline_width=.0008;p.height_range=(.22,1.1)
    p.features={'family':family,'stage':stage,'pot_size_unchanged':True,'reference_soil_height_m':soil}
    if stage=='seedling':
        lean=-.012 if family=='cannabis_sauvage' else 0
        p.tube('Young_stem',[(0,soil,0),(lean*.3,soil+.05,0),(lean,soil+.105,0)],[.0045,.0038,.0025],seg=10,sub=3)
        for sign in (-1,1):
            young_leaf(p,'Cotyledon_'+str(sign),(lean*.3,soil+.05,0),(sign,.12,sign*.2),.047,.017,'green')
            young_leaf(p,'First_leaf_'+str(sign),(lean,soil+.102,0),(sign*.86,.35,sign*.30),.085,.021,'leaf',True)
        p.features.update({'cotyledons':2,'young_serrated_leaves':2,'buds_absent':True})
        p.head_height=soil+.10
        return p

    # Positions and heights are normalized above the unchanged soil surface.
    shapes={
        'cannabis_elancee':(.67,[(0,1,0),(-.105,.73,-.03),(.115,.59,.04),(-.09,.35,.06)]),
        'cannabis_pourpre':(.44,[(0,1,0),(-.155,.74,-.045),(.155,.74,-.045),(-.16,.40,.06),(.16,.40,.06),(0,.59,.125)]),
        'cannabis_eventail':(.46,[(0,1,-.02),(-.17,.73,-.04),(.17,.73,.03)]),
        'cannabis_sauvage':(.62,[(-.105,1,-.01),(.12,.75,-.03),(-.12,.49,.045),(.10,.27,.09)]),
        'cannabis_menthe_rose':(.46,[(0,1,0),(-.145,.73,-.04),(.145,.73,-.04),(-.13,.40,.095),(.13,.40,.095)])
    }
    height,nodes=shapes[family]
    crooked=family=='cannabis_sauvage'
    fan_shape=family=='cannabis_eventail'
    if crooked:
        points=[(0,soil,0),(-.012,soil+height*.24,.004),(.027,soil+height*.50,-.01),(-.017,soil+height*.76,.006),(-.105,soil+height,-.01)]
    else:
        points=[(0,soil,0),(-.004,soil+height*.28,0),(.003,soil+height*.60,0),(0,soil+height,0)]
    p.tube('Developing_trunk',points,[.010,.009,.006,.0035] if not crooked else [.010,.009,.007,.005,.0035],seg=12,sub=4)
    for k,(x,level,z) in enumerate(nodes):
        end=(x,soil+height*level,z)
        # The asymmetrical plant branches attach on its curved trunk.
        anchor=(.012 if crooked and level<.65 else -.006,soil+height*max(.16,level-.26),0)
        if fan_shape:anchor=(0,soil+height*.25,0)
        size=.30 if k==0 else .25
        p.terminal('Developing_cluster_'+str(k),anchor,end,size,1,.62 if k<3 else .54)
    for i,sign in enumerate((1,-1)):
        anchor=(.012 if crooked else 0,soil+height*.30,0)
        end=(sign*.012,soil+height*.47,sign*.12)
        p.foliage_branch('Small_foliage_shoot_'+str(i),anchor,end,0 if sign==1 else math.pi,.43)
    p.features.update({'leaf_size_relative_to_adult':.62,'bud_scale_range':[.25,.30],'small_foliage_shoots':2,'canopy_height_m':height})
    p.head_height=soil+height
    return p

if __name__=='__main__':
    ids=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else list(SPECS)
    for family in ids:
        for stage in ('seedling','growing'):create(family,stage).finish()
