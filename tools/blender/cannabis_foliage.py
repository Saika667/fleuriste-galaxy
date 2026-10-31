"""Small forked foliage shoots shared by the six native cartoon props."""
import math
from mathutils import Vector


def add_bushy_shoots(plant, fan):
    # Anchor onto each design's existing trunk; stagger shoots in depth and height.
    anchors = {
        'cannabis_compact': [(0,.34,0),(-.004,.43,-.004),(0,.52,0)],
        'cannabis_elancee': [(.006,.40,0),(.012,.60,0),(0,.82,-.005)],
        'cannabis_pourpre': [(-.008,.28,-.006),(-.012,.40,-.01),(0,.57,-.004)],
        'cannabis_eventail': [(0,.30,0),(-.10,.46,-.024),(.10,.46,.018)],
        'cannabis_sauvage': [(-.015,.40,.005),(.035,.63,-.012),(-.01,.82,.005)],
        'cannabis_menthe_rose': [(-.004,.32,0),(-.008,.44,0),(0,.60,0)],
    }[plant.id]
    for level, anchor in enumerate(anchors):
        for side in (-1, 1):
            name = 'Bushy_shoot_%d_%s' % (level, 'left' if side < 0 else 'right')
            heading = side * (.80 if level != 1 else 2.30)
            outward = Vector((math.sin(heading), 0, math.cos(heading)))
            start = Vector(anchor)
            end = start + outward * (.19 if level < 2 else .15) + Vector((0,.105,0))
            mid = start.lerp(end,.55) + Vector((0,-.012,0))
            plant.tube(name,[tuple(start),tuple(mid),tuple(end)],[.0045,.003,.0018],seg=8,sub=3)
            # Two side twigs and a terminal leaf create a readable miniature branch.
            for index, (along, turn, size) in enumerate([(.43,-.65,.57),(.72,.65,.63),(1,0,.69)]):
                joint = start.lerp(end,along)
                direction = heading + turn
                leaf = joint + Vector((math.sin(direction)*.038,.018,math.cos(direction)*.038))
                plant.tube(name+'_petiole_'+str(index),[tuple(joint),tuple(leaf)],[.002,.0012],seg=6,sub=0)
                fan(name+'_leaf_'+str(index),tuple(leaf),direction,size)
    plant.features['small_foliage_shoots'] = 6
    plant.features['leaves_on_small_shoots'] = 18
