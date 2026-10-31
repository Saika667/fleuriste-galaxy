"""V2 independante du vieux savant : voir docs/old_scientist_v2.md pour les limites de fidelite.
References : art/ref/old_scientist/*.png
(face, dos, profil, visage, canne, expressions). Style « Rick et Morty » : aplats + trait noir fin.

Lancer (PowerShell) : tools\\blender\\run.ps1 -Script tools\\blender\\characters\\old_scientist_v2.py
Sorties : *_v2.blend, *_v2.glb, *_v2_toon.glb et apercus out/blender/sci_v2_*.png.

Mesures prises sur la vue de face (1 px ~ 1,28 mm, 1,80 m du crane a la semelle) : tete tres longue (0,41 m), yeux ronds
presque joints, long nez tombant, epaules a 1,33 m, ceinture a 0,95 m, ourlet de blouse a 0,52 m, chevilles a 0,17 m.
Contrat du jeu : Rig > Torso, Leg_0/1, Arm_0/1 (Arm_0 = main droite du perso, x negatif, tient la canne), Head > Eye_0/1,
Brow_0/1, Mouth > Mouth_seg_0..4, Mouth_open (bouche en O), Blush_0/1 ; en plus Mouth_shout (bouche hurlante, dents jaunes).
"""
import math
import os
import random
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import bl_common as bc  # noqa: E402
from bl_common import G, box, cylinder, lathe, sphere, sweep  # noqa: E402

ARGS = bc.script_args()
QUICK = "--quick" in ARGS
MOOD = ARGS[ARGS.index("--mood") + 1] if "--mood" in ARGS else "neutral"
NO_OUTLINE = {"no_outline": True}
RNG = random.Random(11)

# Finer longitudinal sampling is essential for the curved drawing strokes.
_sweep = sweep
def sweep(*args, **kwargs):
    kwargs.setdefault("sub", 5)
    return _sweep(*args, **kwargs)

HEAD_Y, HEAD_Z = 1.595, 0.23  # centre de la tete (bien en avant du buste : dos voute)
HX, HY, HZ = 0.108, 0.205, 0.118
HIP_Y, SHO_Y = 0.90, 1.36
MOUTH_S = 0.85

bc.reset_scene()
for role, col in [
    ("skin", "#E7C9A6"), ("top", "#EEECDD"), ("top_light", "#D3D6BE"), ("shirt", "#80865A"), ("bottom", "#69603E"),
    ("belt", "#5E4630"), ("strap", "#6B4A32"), ("buckle", "#8E9196"), ("sock", "#2F3638"), ("shoe", "#5A5450"),
    ("sole", "#B0AE9F"), ("hair", "#C5CFD1"), ("brow", "#BFC9CC"), ("ink", "#191A17"), ("eye_white", "#FFFEF8"),
    ("iris", "#14121A"), ("bag", "#A39088"), ("spot", "#B08A6A"), ("stubble", "#6B6058"), ("stain", "#B5A98C"),
    ("hole", "#9C8E70"), ("mouth", "#3A2A2A"), ("mouth_in", "#6A2028"), ("tongue", "#D9707A"), ("teeth", "#E8D98A"),
    ("blush", "#E89A8A"), ("metal", "#4A4D50"), ("metal_dark", "#323437"), ("rubber", "#3A3A3D"), ("glow", "#7CF25A"),
    ("glow_dark", "#2E7A2A"), ("wire", "#A8402E"),
]:
    bc.material(role, col, 0.9, spec=0.0)

rig = bc.pivot("Rig", (0, 0, 0))
torso = bc.pivot("Torso", (0, 0, 0), rig)


# ======================================================================== outils
def gv(x, y, z):
    """Vecteur direction Godot -> Blender."""
    return Vector((x, -z, y))


def bvh_of(objs):
    deps = bpy.context.evaluated_depsgraph_get()
    deps.update()
    bm = bmesh.new()
    for o in objs:
        ev = o.evaluated_get(deps)
        me = ev.to_mesh()
        tmp = bmesh.new()
        tmp.from_mesh(me)
        tmp.transform(o.matrix_world)
        m2 = bpy.data.meshes.new("tmp")
        tmp.to_mesh(m2)
        tmp.free()
        bm.from_mesh(m2)
        bpy.data.meshes.remove(m2)
        ev.to_mesh_clear()
    t = BVHTree.FromBMesh(bm)
    bm.free()
    return t


def hit(tree, origin, direction):
    loc, nor, _, _ = tree.ray_cast(G(*origin), gv(*direction).normalized(), 3.0)
    return loc, nor


def decal(name, tree, origin, direction, size, role, parent, jag=0.35, n=11, lift=0.0018, seed=0, extras=None):
    """Tache/accroc plat pose sur une surface (contour irregulier), oriente selon la normale du point touche."""
    loc, nor = hit(tree, origin, direction)
    if loc is None:
        return None
    r = random.Random(seed)
    bm = bmesh.new()
    c = bm.verts.new((0, 0, 0))
    ring = []
    for k in range(n):
        a = 2 * math.pi * k / n
        f = 1.0 - jag * r.random() if k % 2 else 1.0 + jag * 0.3 * r.random()
        ring.append(bm.verts.new((math.cos(a) * size[0] * f, math.sin(a) * size[1] * f, 0)))
    for k in range(n):
        bm.faces.new((c, ring[k], ring[(k + 1) % n]))
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(o)
    o.data.materials.append(bc._MATS[role])
    q = nor.to_track_quat("Z", "Y")
    o.matrix_world = Matrix.Translation(loc + nor * lift) @ q.to_matrix().to_4x4()
    for k_, v_ in (extras or NO_OUTLINE).items():
        o[k_] = v_
    bc._parent(o, parent)
    return o


def jag_end(obj, center, tangent, amp, teeth, seed=0, tol=0.003):
    """Bord dechire : les sommets de l'extremite (le long de `tangent`) sont decales en dents de scie irregulieres."""
    r = random.Random(seed)
    C, T = G(*center), gv(*tangent).normalized()
    U = T.cross(Vector((0, 0, 1)) if abs(T.z) < 0.9 else Vector((1, 0, 0))).normalized()
    V = T.cross(U)
    offs = [r.random() for _ in range(teeth * 2)]
    mw, mwi = obj.matrix_world, obj.matrix_world.inverted()
    for v in obj.data.vertices:
        p = mw @ v.co
        if (p - C).dot(T) < -tol:
            continue
        d = p - C
        a = (math.atan2(d.dot(V), d.dot(U)) / (2 * math.pi)) % 1.0
        x = a * teeth
        k = int(x)
        frac = x - k
        tri = 1 - abs(frac - 0.5) * 2  # pointe au milieu de chaque dent
        depth = amp * (0.35 + 0.65 * offs[k % len(offs)]) * tri
        v.co = mwi @ (p + T * depth)


def line(name, pts, r, parent, role="ink", taper=True):
    rr = []
    n = len(pts)
    for k in range(n):
        u = k / max(1, n - 1)
        f = (0.45 + 0.55 * math.sin(math.pi * u)) if taper else 1.0
        rr.append((r * f, r * f))
    return sweep(name, pts, rr, role, parent, seg=8, sub=6, extras=NO_OUTLINE)


# ======================================================================== TETE
def head_deform(x, y, z):
    """Tete tres longue : crane en oeuf, machoire qui fond vers un petit menton avance, front fuyant, arcade marquee."""
    if y < 0:
        t = min(1.0, -y / HY)
        x *= 1 - 0.56 * t ** 1.25
        z *= 1 - 0.22 * t ** 1.3
        if z > 0:
            z += 0.016 * t
    else:
        u = y / HY
        if z < 0:
            z *= 1 + 0.16 * u
        else:
            z *= 1 - 0.10 * u * u
            z += 0.012 * math.exp(-((y - HY * 0.32) / 0.028) ** 2) * max(0.0, 1 - (x / (HX * 0.9)) ** 2)  # arcade
        x *= 1 + 0.04 * u
    return x, y, z


head = bc.pivot("Head", G(0, HEAD_Y, HEAD_Z), rig)
head_profile = [
    (0.205, 0.002, 0.003, -0.010), (0.195, 0.041, 0.052, -0.006),
    (0.170, 0.073, 0.084, -0.004), (0.125, 0.099, 0.106, 0.0),
    (0.065, 0.106, 0.114, 0.0), (0.005, 0.102, 0.111, 0.0),
    (-0.055, 0.094, 0.097, 0.002), (-0.105, 0.082, 0.077, 0.010),
    (-0.137, 0.077, 0.064, 0.023), (-0.155, 0.057, 0.058, 0.026),
    (-0.183, 0.043, 0.044, 0.030), (-0.201, 0.025, 0.027, 0.032),
    (-0.205, 0.002, 0.003, 0.032),
]
skull = sweep("Head_skull", [(0, HEAD_Y+y, HEAD_Z+z) for y,x,d,z in head_profile],
              [(x,d) for y,x,d,z in head_profile], "skin", head, seg=64,
              cap0="flat", cap1="flat", sub=4)
HT = bvh_of([skull])


def HP(x, y, z):
    return (x, HEAD_Y + y, HEAD_Z + z)


def surf(x, y):
    loc, _ = hit(HT, HP(x, y, 0.5), (0, 0, -1))
    return (-loc.y - HEAD_Z) if loc is not None else 0.0


def face_line(name, pts2d, r, parent, lift=0.0022, role="ink"):
    return line(name, [HP(x, y, surf(x, y) + lift) for x, y in pts2d], r, parent, role)


# ---- yeux : ronds, presque joints, pupille-point ; cernes sombres --------------------------------
EY, EX, ER = 0.008, 0.050, 0.046
for i, sx in enumerate((-1, 1)):
    ex = sx * EX
    ez = surf(ex, EY) + 0.012
    eye = bc.pivot(f"Eye_{i}", G(*HP(ex, EY, ez)), head)
    rx, ry, rz = ER, ER * 1.02, 0.036
    sphere(f"Eye_{i}_white", 1.0, HP(ex, EY, ez), "eye_white", eye, scale=(rx, ry, rz), seg=28, exact=True)
    px, py = ex + (0.004 if sx < 0 else -0.002), EY - 0.004
    pz = ez + rz * math.sqrt(max(0.0, 1 - ((px - ex) / rx) ** 2 - ((py - EY) / ry) ** 2)) + 0.0004
    sphere(f"Eye_{i}_pupil", 0.0038, HP(px, py, pz), "iris", eye, scale=(1, 1, 0.4), seg=20, exact=True, extras=NO_OUTLINE)
    # cerne : croissant sombre sous l'oeil + deux plis
    by = EY - ry * 0.95
    sphere(f"Eye_{i}_bag", 1.0, HP(ex + sx * 0.004, by, surf(ex, by) - 0.001), "bag", eye, scale=(rx * 0.94, 0.019, 0.012), seg=32,
           exact=True, extras=NO_OUTLINE)
    for k, (dy, w) in enumerate(((-0.004, 0.90), (-0.020, 0.70))):
        pts = [(ex + sx * rx * w * math.cos(a), EY - ry * 1.0 + dy - 0.012 * math.sin(a)) for a in
               [math.radians(t) for t in (-10, 30, 70, 110, 150, 190)]]
        pts = [(ex + (px_ - ex), py_) for px_, py_ in pts]
        face_line(f"Eye_{i}_bagline_{k}", pts, 0.0011, eye)
    # pattes d'oie
    for k in range(2):
        a0 = math.radians(-5 - k * 22)
        x0, y0 = ex + sx * rx * 1.05 * math.cos(a0), EY + ry * 1.05 * math.sin(a0)
        face_line(f"Eye_{i}_crow_{k}", [(x0, y0), (x0 + sx * 0.012, y0 - 0.002 - k * 0.004)], 0.0018, eye)

    # sourcil broussailleux, fronce (coin interieur bas)
    bx, byb = sx * 0.05, EY + ry + 0.016
    brow = bc.pivot(f"Brow_{i}", G(*HP(bx, byb, surf(bx, byb))), head)
    bp2 = [(sx * 0.012, EY + ry + 0.004), (sx * 0.03, EY + ry + 0.014), (sx * 0.055, EY + ry + 0.024), (sx * 0.08, EY + ry + 0.022),
           (sx * 0.097, EY + ry + 0.008)]
    bpts = [HP(x, y, surf(x, y) + 0.008) for x, y in bp2]
    sweep(f"Brow_{i}_bar", bpts, [(0.009, 0.007), (0.013, 0.009), (0.014, 0.01), (0.012, 0.009), (0.005, 0.005)], "brow", brow,
          ref=(0, 1, 0), seg=10)
    sphere(f"Blush_{i}", 1.0, HP(sx * 0.07, -0.08, surf(sx * 0.07, -0.08) - 0.004), "blush", head, scale=(0.026, 0.018, 0.01),
           seg=12, exact=True, extras=NO_OUTLINE)

# rides du front, plis du froncement
for k in range(3):
    y = EY + 0.1 + k * 0.017
    face_line(f"Head_wrinkle_{k}", [(-0.055, y - 0.004), (-0.025, y + 0.004), (0.0, y - 0.002), (0.025, y + 0.005), (0.055, y - 0.003)],
              0.0009, head)
for sx in (-1, 1):
    face_line(f"Head_furrow_{sx}", [(sx * 0.008, EY + ER + 0.01), (sx * 0.011, EY + ER + 0.035)], 0.0018, head)

# ---- long nez tombant -------------------------------------------------------------------------------
z0 = surf(0, EY - 0.02)
nose_pts = [HP(0, EY + 0.012, surf(0, EY + 0.012) - 0.012), HP(0, EY - 0.035, z0 + 0.018), HP(0, EY - 0.078, z0 + 0.045),
            HP(0, EY - 0.1, z0 + 0.052), HP(0, EY - 0.112, z0 + 0.038)]
sweep("Head_nose", nose_pts, [(0.012, 0.012), (0.013, 0.014), (0.017, 0.018), (0.02, 0.021), (0.016, 0.015)], "skin", head, seg=14)
for sx in (-1, 1):
    line(f"Head_nostril_{sx}", [HP(sx * 0.008, EY - 0.112, z0 + 0.04), HP(sx * 0.017, EY - 0.105, z0 + 0.032),
                                HP(sx * 0.016, EY - 0.094, z0 + 0.028)], 0.0019, head)

# ---- bouche, plis, menton mal rase ------------------------------------------------------------------
MY = -0.136
mz = surf(0, MY) + 0.002
mouth = bc.pivot("Mouth", G(*HP(0, MY, mz)), head)
for i in range(5):
    lx = (i - 2) * 0.027
    seg = bc.pivot(f"Mouth_seg_{i}", G(*HP(lx, MY, mz)), mouth)
    sweep(f"Mouth_seg_{i}_bar", [HP(lx - 0.015, MY, mz), HP(lx + 0.015, MY, mz)], [(0.0018, 0.0018)] * 2, "ink", seg, ref=(0, 1, 0),
          seg=8, extras=NO_OUTLINE)
mo = bc.blob("Mouth_open", 1.0, HP(0, MY - 0.012, mz - 0.006), "mouth_in", mouth, scale=(0.05, 0.068, 0.022), seg=20,
             extras=NO_OUTLINE)
tg = sphere("Mouth_tongue", 1.0, HP(0, MY - 0.05, mz + 0.004), "tongue", mouth, scale=(0.034, 0.018, 0.012), seg=12, exact=True,
            extras=NO_OUTLINE)
sh = bc.blob("Mouth_shout", 1.0, HP(0, MY - 0.02, mz - 0.006), "mouth_in", mouth, scale=(0.15, 0.1, 0.026), seg=24,
             deform=lambda x, y, z: (x, y * 0.55 if y > 0 else y, z), extras=NO_OUTLINE)
teeth = []
for k in range(6):  # dents jaunes de travers
    tx = -0.09 + k * 0.036 + RNG.uniform(-0.006, 0.006)
    teeth.append(box(f"Mouth_shout_tooth_t{k}", (0.026, 0.03 + RNG.uniform(-0.008, 0.008), 0.01), HP(tx, MY + 0.02, mz + 0.02),
                     "teeth", mouth, bevel=0.004, rot=(0, RNG.uniform(-0.25, 0.25), 0), extras=NO_OUTLINE))
for k in range(4):
    tx = -0.06 + k * 0.04 + RNG.uniform(-0.006, 0.006)
    teeth.append(box(f"Mouth_shout_tooth_b{k}", (0.024, 0.024, 0.01), HP(tx, MY - 0.085, mz + 0.016), "teeth", mouth, bevel=0.004,
                     rot=(0, RNG.uniform(-0.3, 0.3), 0), extras=NO_OUTLINE))
for o, par in [(tg, mo)] + [(t, sh) for t in teeth]:
    bpy.context.view_layer.update()
    mw = o.matrix_world.copy()
    o.parent = par
    o.matrix_world = mw
bpy.context.view_layer.update()
mouth.scale = (MOUTH_S,) * 3
face_line("Head_lowerlip", [(-0.016, MY - 0.016), (0.0, MY - 0.02), (0.016, MY - 0.016)], 0.0019, head)
for sx in (-1, 1):
    face_line(f"Head_nasolabial_{sx}", [(sx * 0.028, EY - 0.1), (sx * 0.046, MY + 0.005), (sx * 0.05, MY - 0.03)], 0.002, head)
    face_line(f"Head_jowl_{sx}", [(sx * 0.044, MY - 0.03), (sx * 0.04, MY - 0.06), (sx * 0.03, -0.185)], 0.0019, head)
    face_line(f"Head_cheek_{sx}", [(sx * 0.082, EY - 0.05), (sx * 0.075, EY - 0.09)], 0.0018, head)
for k in range(18):  # short tapered strokes rather than dotted stubble
    x = RNG.uniform(-0.045, 0.045)
    y = RNG.uniform(-0.205, -0.165) + abs(x) * 0.5
    face_line(f"Head_stubble_{k}", [(x,y), (x+RNG.uniform(-0.002,0.002),y+0.004)], 0.0007, head, role="stubble")

# ---- oreilles decollees --------------------------------------------------------------------------------
for sx in (-1, 1):
    ear = bc.blob(f"Head_ear_{sx}", 1.0, HP(sx * 0.107, -0.035, -0.005), "skin", head, scale=(0.02, 0.055, 0.038), seg=18,
                  deform=lambda x, y, z, s=sx: (x + s * 0.012 * (1 - abs(y) / 0.055), y, z))
    line(f"Head_ear_in_{sx}", [HP(sx * 0.128, -0.012, 0.016), HP(sx * 0.13, -0.035, 0.022), HP(sx * 0.128, -0.06, 0.012)], 0.0022, head)

# ---- taches de vieillesse sur le crane ---------------------------------------------------------------
for k, (x, y, s) in enumerate(((0.035, 0.175, 0.016), (0.058, 0.15, 0.012), (0.07, 0.122, 0.009), (0.028, 0.193, 0.008),
                               (0.075, 0.1, 0.006))):
    decal(f"Head_spot_{k}", HT, HP(x, y + 0.04, 0.3), (0, -0.25, -1), (s, s * 0.9), "spot", head, jag=0.1, n=12, seed=k)

# ======================================================================== CHEVEUX
def head_point(psi, y, puff=0.0):
    yy = max(-0.999, min(0.999, y / HY))
    rho = math.sqrt(1 - yy * yy)
    x, z = HX * rho * math.sin(psi), HZ * rho * math.cos(psi)
    x, y2, z = head_deform(x, y, z)
    zf = puff * (0.15 if z > 0 else 0.7)  # le volume part sur les cotes et l arriere, jamais devant le visage
    return Vector((x * (1 + puff), y2, z * (1 + zf)))


def hair_band():
    """Couronne de cheveux hirsutes (cotes + arriere), bords haut et bas dechiquetes, crane chauve au-dessus."""
    p0, p1, n_psi, rows = 1.45, 2 * math.pi - 1.45, 72, 15
    r = random.Random(5)
    jt = [r.random() for _ in range(n_psi + 1)]
    jb = [r.random() for _ in range(n_psi + 1)]
    bm = bmesh.new()
    grid = []
    for i in range(n_psi + 1):
        psi = p0 + (p1 - p0) * i / n_psi
        side = abs(math.sin(psi))
        back = max(0.0, -math.cos(psi))
        top = 0.14 - 0.035 * back + 0.008*math.cos(psi*11)
        bot = -0.100 - 0.055 * back + 0.020*math.cos(psi*15)
        row = []
        for j in range(rows):
            s = j / (rows - 1)
            y = top + (bot - top) * s
            puff = 0.18 + 0.50 * side * math.sin(math.pi * min(1.0, s * 1.1)) + 0.15 * back * math.sin(math.pi * s)
            p = head_point(psi, y, puff)
            row.append(bm.verts.new(G(*HP(p.x, p.y, p.z))))
        grid.append(row)
    for i in range(n_psi):
        for j in range(rows - 1):
            bm.faces.new((grid[i][j], grid[i + 1][j], grid[i + 1][j + 1], grid[i][j + 1]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    o = bc._finish("Hair_mass", bm, Vector((0, 0, 0)), "hair", head, smooth=True, thick=0.012)
    return o


hair_band()
r = random.Random(3)
k = 0
for sx in (-1, 1):  # ailes de meches : larges a la base, pointes qui partent vers l'exterieur (certaines retombent)
    for psi, y, up, L, w in ((1.25, 0.11, 0.45, 0.1, 0.03), (1.45, 0.075, 0.1, 0.13, 0.036), (1.7, 0.02, -0.2, 0.13, 0.036),
                             (1.85, -0.04, -0.5, 0.11, 0.032), (2.0, -0.08, -0.85, 0.09, 0.028), (2.15, 0.08, 0.3, 0.11, 0.032),
                             (2.35, 0.03, -0.15, 0.1, 0.032), (2.6, -0.04, -0.6, 0.09, 0.03), (2.85, 0.07, 0.2, 0.07, 0.028),
                             (3.0, -0.1, -0.8, 0.07, 0.03)):
        p = head_point(sx * max(1.48,psi), y, 0.3)
        d = Vector((math.sin(sx * psi), up - 0.25, math.cos(sx * psi) * 0.3 - 0.35)).normalized()
        L *= r.uniform(0.65, 0.85)
        w *= 0.8
        m = p + d * L * 0.50 + Vector((0, 0.018, -0.006))
        t = p + d * L + Vector((0, -0.024, -0.018))
        sweep(f"Hair_lock_{k}", [HP(*p), HP(*m), HP(*t)], [(w * 0.8, w), (w * 0.55, w * 0.65), (0.0007, 0.0007)], "hair", head, seg=16,
              cap_len=0.2, ref=(0, 1, 0))
        k += 1
for k2, (x0, z0_, dx, h) in enumerate(((-0.035, 0.0, -0.05, 0.11), (-0.012, 0.01, -0.02, 0.12), (0.012, -0.01, 0.025, 0.1),
                                        (0.04, -0.02, 0.06, 0.1), (-0.055, -0.03, -0.07, 0.08), (0.06, -0.04, 0.085, 0.07))):
    base = HP(x0, HY * 0.93 - abs(x0) * 0.5, z0_)
    line(f"Hair_strand_{k2}", [base, (base[0] + dx * 0.4, base[1] + h * 0.6, base[2] - 0.01), (base[0] + dx, base[1] + h, base[2] - 0.03)],
         0.0009, head, taper=True)

# ======================================================================== COU
sweep("Neck", [(0, SHO_Y + 0.02, 0.07), (0, 1.4, 0.12), (0, HEAD_Y - 0.15, HEAD_Z - 0.03)], [(0.037, 0.034), (0.034, 0.032), (0.036, 0.034)],
      "skin", rig, seg=14)
sphere("Neck_adam", 0.011, (0, 1.39, 0.15), "skin", rig, seg=10)
for sx in (-1, 1):
    line(f"Neck_tendon_{sx}", [(sx * 0.014, 1.35, 0.115), (sx * 0.02, 1.39, 0.148), (sx * 0.024, 1.43, 0.17)], 0.0018, rig)

# ======================================================================== TORSE
sweep("Torso_shirt", [(0, 1.36, 0.085), (0, 1.32, 0.072), (0, 1.2, 0.05), (0, 1.05, 0.022), (0, 0.95, 0.0), (0, 0.88, 0.0)],
      [(0.05, 0.042), (0.13, 0.068), (0.118, 0.074), (0.098, 0.07), (0.103, 0.07), (0.103, 0.07)], "shirt", torso, cap0="flat",
      cap1="flat", seg=24, sq=2.3)
sweep("Torso_pants", [(0, 0.97, 0.0), (0, 0.84, 0.0)], [(0.106, 0.073), (0.106, 0.073)], "bottom", torso, cap0="flat", cap1="flat",
      seg=24, sq=2.3)
sweep("Detail_belt", [(0, 0.965, 0.0), (0, 0.93, 0.0)], [(0.109, 0.076), (0.109, 0.076)], "belt", torso, cap0="open", cap1="open",
      thick=0.005, seg=24, sq=2.3)
box("Detail_buckle", (0.058, 0.04, 0.012), (0, 0.948, 0.08), "buckle", torso, bevel=0.004)
box("Detail_buckle_in", (0.034, 0.02, 0.006), (0, 0.948, 0.086), "metal_dark", torso, bevel=0.002, extras=NO_OUTLINE)

# blouse longue ouverte, ourlet dechire
coat_pts = [(0, 1.395, 0.075), (0, 1.36, 0.065), (0, 1.2, 0.04), (0, 1.0, -0.004), (0, 0.8, -0.03), (0, 0.52, -0.055)]
coat_rad = [(0.072, 0.058), (0.158, 0.085), (0.14, 0.095), (0.135, 0.1), (0.15, 0.115), (0.172, 0.13)]
coat = None


def gap(y):  # demi-largeur de l'ouverture devant
    pts = [(1.37, 0.04), (1.3, 0.05), (1.2, 0.07), (1.0, 0.088), (0.8, 0.11), (0.5, 0.14)]
    for (y0, g0), (y1, g1) in zip(pts, pts[1:]):
        if y0 >= y >= y1:
            return g0 + (g1 - g0) * (y0 - y) / (y0 - y1)
    return pts[-1][1]


# Explicit open garment surface: smooth front edges and a genuinely jagged hem.
bm = bmesh.new()
grid = []
N, ROWS = 96, 40
for j in range(ROWS+1):
    u = j / ROWS
    y = 1.395 - 0.875*u
    for a in range(len(coat_pts)-1):
        if coat_pts[a][1] >= y >= coat_pts[a+1][1]:
            t = (coat_pts[a][1]-y)/(coat_pts[a][1]-coat_pts[a+1][1])
            rx,rz = [coat_rad[a][q]*(1-t)+coat_rad[a+1][q]*t for q in (0,1)]
            cz = coat_pts[a][2]*(1-t)+coat_pts[a+1][2]*t
            break
    opening = min(rx*0.83, gap(y)*0.77)
    start = math.asin(opening/rx)
    row=[]
    for i in range(N+1):
        psi = start + (2*math.pi-2*start)*i/N
        tooth = 1-abs((i/3.0)%2-1)
        hem = (0.010+0.043*tooth+0.010*math.sin(i*1.7)) * max(0,(u-0.89)/0.11)
        row.append(bm.verts.new(G(rx*math.sin(psi), y-hem, cz+rz*math.cos(psi))))
    grid.append(row)
for j in range(ROWS):
    for i in range(N):
        bm.faces.new((grid[j][i],grid[j+1][i],grid[j+1][i+1],grid[j][i+1]))
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
coat = bc._finish("Torso_coat", bm, Vector((0,0,0)), "top", torso)
md = coat.modifiers.new("Solid", "SOLIDIFY")
md.thickness = 0.008
md.offset = 1
coat.data.materials.append(bc._MATS["top_light"])
md.material_offset = 1
md.material_offset_rim = 0
# col et revers
collar = [(0.075 * math.sin(a), 1.395, 0.075 + 0.06 * math.cos(a)) for a in [math.radians(t) for t in range(50, 311, 20)]]
sweep("Torso_coat_collar", collar, [(0.024, 0.006)] * len(collar), "top", torso, ref=(0, 1, 0), seg=8, cap_len=0.4)
for sx in (-1, 1):
    pts = [(sx*.045,1.375,.125),(sx*.108,1.255,.137),(sx*.084,1.229,.145),
           (sx*.112,1.204,.132),(sx*.071,1.124,.113),(sx*.060,1.260,.147)]
    bm=bmesh.new()
    verts=[bm.verts.new(G(*p)) for p in pts]
    bm.faces.new(verts if sx>0 else list(reversed(verts)))
    bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
    bc._finish(f"Torso_coat_lapel_{sx}",bm,Vector((0,0,0)),"top",torso,thick=.003,extras=NO_OUTLINE)
    line(f"Torso_lapel_edge_{sx}",pts[:5],.0009,torso,taper=False)
line("Torso_coat_seam", [(0, 1.33, -0.035), (0, 1.0, -0.106), (0, 0.6, -0.145)], 0.0018, torso, taper=False)

# bandouliere + boitier a voyant
for nm, pts, ref in (("front", [(-0.1, 1.335, 0.1), (-0.04, 1.27, 0.128), (0.03, 1.19, 0.118), (0.085, 1.1, 0.09)], (0, 0, 1)),
                     ("shoulder", [(-0.1, 1.335, 0.1), (-0.115, 1.36, 0.055), (-0.1, 1.335, 0.01)], (0, 1, 0))):
    sweep(f"Detail_strap_{nm}", pts, [(0.004, 0.012)] * len(pts) if ref != (0, 1, 0) else [(0.012, 0.004)] * len(pts), "strap", torso,
          ref=ref, seg=8, cap_len=0.3)
box("Detail_pager", (0.034, 0.062, 0.024), (0.045, 1.17, 0.13), "metal", torso, bevel=0.006, rot=(0, -0.45, 0))
box("Detail_pager_screen", (0.014, 0.03, 0.004), (0.046, 1.18, 0.143), "glow", torso, bevel=0.002, rot=(0, -0.45, 0), extras=NO_OUTLINE)
sphere("Detail_pager_led", 0.0065, (0.05, 1.149, 0.142), "glow", torso, seg=10)
sweep("Detail_pager_wire", [(0.05, 1.14, 0.13), (0.06, 1.1, 0.11), (0.07, 1.06, 0.09)], [(0.003, 0.003)] * 3, "wire", torso, seg=6)

# ======================================================================== JAMBES
for i, (sx, x) in enumerate(((-1, -0.07), (1, 0.075))):
    leg = bc.pivot(f"Leg_{i}", G(x, HIP_Y, 0), rig)
    sweep(f"Leg_{i}_limb", [(x, 0.93, 0.0), (x, 0.6, 0.0), (x, 0.42, 0.006), (x, 0.24, -0.004), (x, 0.16, -0.006)],
          [(0.046, 0.044), (0.042, 0.04), (0.038, 0.037), (0.036, 0.035), (0.035, 0.034)], "bottom", leg, cap0="round", cap1="open",
          thick=0.004, seg=16)
    sweep(f"Leg_{i}_sock", [(x, 0.18, -0.006), (x, 0.08, -0.006)], [(0.027, 0.027)] * 2, "sock", leg, cap0="round", cap1="round", seg=12)
    xs = x + sx * 0.005
    sweep(f"Leg_{i}_shoe", [(xs, 0.072, -0.065), (xs, 0.075, 0.0), (xs, 0.064, 0.085), (xs, 0.052, 0.15)],
          [(0.058, 0.058), (0.066, 0.056), (0.068, 0.048), (0.056, 0.038)], "shoe", leg, cap0="round", cap1="round", cap_len=0.85, seg=18)
    sweep(f"Leg_{i}_sole", [(xs, 0.018, -0.068), (xs, 0.018, 0.04), (xs, 0.018, 0.155)], [(0.062, 0.018), (0.07, 0.018), (0.06, 0.017)],
          "sole", leg, cap0="round", cap1="round", cap_len=0.85, seg=16)
    sweep(f"Leg_{i}_strap", [(xs - 0.068, 0.098, 0.045), (xs, 0.118, 0.055), (xs + 0.068, 0.098, 0.045)], [(0.004, 0.02)] * 3, "shoe",
          leg, ref=(0, 0, 1), seg=8, cap_len=0.3)
leg_bvh = bvh_of([bpy.data.objects["Leg_1_limb"]])
decal("Leg_1_hole", leg_bvh, (0.08, 0.43, 0.3), (0, 0, -1), (0.016, 0.022), "hole", bpy.data.objects["Leg_1"], jag=0.5, seed=4)

# ======================================================================== BRAS
def arm(i, sx, elbow, wrist, sleeve_end_y, holding):
    x = sx * 0.148
    piv = bc.pivot(f"Arm_{i}", G(x, SHO_Y, 0.06), rig)
    sh = (x - sx * 0.008, SHO_Y + 0.005, 0.06)
    pts = [sh, elbow, wrist]
    sweep(f"Arm_{i}_limb", pts, [(0.03, 0.029), (0.024, 0.023), (0.02, 0.019)], "skin", piv, seg=12)
    # manche de blouse jusqu'au bas de l'avant-bras, bord dechire
    t = (elbow[1] - sleeve_end_y) / (elbow[1] - wrist[1])
    se = tuple(elbow[k] + (wrist[k] - elbow[k]) * t for k in range(3))
    slv = sweep(f"Arm_{i}_sleeve", [sh, elbow, se], [(0.038, 0.036), (0.032, 0.030), (0.030, 0.028)], "top", piv, cap0="round", cap1="open",
                seg=18)
    tg = Vector(se) - Vector(elbow)
    jag_end(slv, se, tuple(tg.normalized()), 0.03, 9, seed=10 + i)
    m = slv.modifiers.new("Solid", "SOLIDIFY")
    m.thickness = 0.006
    m.offset = 1
    return piv


# bras gauche du perso (x+) : pend, grande main ouverte
a1 = arm(1, 1, (0.168, 1.04, 0.025), (0.178, 0.77, 0.05), 0.82, False)
hx, hy, hz = 0.18, 0.765, 0.055
sweep("Arm_1_hand", [(hx, hy, hz), (hx + 0.004, hy - 0.04, hz + 0.006), (hx + 0.006, hy - 0.075, hz + 0.01)],
      [(0.017, 0.032), (0.018, 0.038), (0.016, 0.034)], "skin", a1, ref=(1, 0, 0), seg=12)
for fi, fz in enumerate((-0.022, 0.0, 0.021)):
    sweep(f"Arm_1_finger_{fi}", [(hx + 0.006, hy - 0.08, hz + 0.01 + fz), (hx + 0.008, hy - 0.125, hz + 0.014 + fz * 1.1),
                                 (hx + 0.004, hy - 0.165, hz + 0.022 + fz * 1.15)],
          [(0.0095, 0.0095), (0.0088, 0.0088), (0.0078, 0.0078)], "skin", a1, seg=8)
sweep("Arm_1_thumb", [(hx - 0.004, hy - 0.025, hz + 0.03), (hx - 0.008, hy - 0.06, hz + 0.045), (hx - 0.008, hy - 0.09, hz + 0.05)],
      [(0.011, 0.011), (0.0098, 0.0098), (0.0085, 0.0085)], "skin", a1, seg=8)

# bras droit du perso (x-) : tient la canne, avant-bras en avant
a0 = arm(0, -1, (-0.18, 1.06, 0.06), (-0.25, 0.87, 0.2), 0.90, True)
CX, CZ = -0.255, 0.225  # axe de la canne dans le poing
sphere("Arm_0_fist", 1.0, (CX + 0.004, 0.84, CZ), "skin", a0, scale=(0.034, 0.045, 0.03), seg=16, exact=True)
for fi in range(4):
    y = 0.865 - fi * 0.019
    sweep(f"Arm_0_finger_{fi}", [(CX - 0.026, y, CZ - 0.004), (CX - 0.01, y - 0.002, CZ + 0.03), (CX + 0.018, y - 0.004, CZ + 0.024)],
          [(0.0098, 0.0098), (0.0098, 0.0098), (0.009, 0.009)], "skin", a0, seg=8)
sweep("Arm_0_thumb", [(CX + 0.03, 0.87, CZ - 0.01), (CX + 0.022, 0.878, CZ + 0.018), (CX + 0.002, 0.874, CZ + 0.03)],
      [(0.0112, 0.0112), (0.0102, 0.0102), (0.009, 0.009)], "skin", a0, seg=8)

# ======================================================================== CANNE-GADGET (enfant de Arm_0)
TOP = 0.95
pole = [(CX, TOP - 0.01, CZ), (CX - 0.012, 0.7, CZ + 0.005), (CX - 0.025, 0.47, CZ + 0.01), (CX - 0.075, 0.37, CZ + 0.015),
        (CX - 0.1, 0.3, CZ + 0.016), (CX - 0.1, 0.2, CZ + 0.016), (CX - 0.1, 0.07, CZ + 0.016)]
sweep("Cane_pole", pole, [(0.0115, 0.0115)] * len(pole), "metal", a0, seg=12, cap0="flat", cap1="flat")
for k, y in enumerate((0.9, 0.73, 0.55, 0.26, 0.12)):
    # position du collier sur la canne (interpolation lineaire de la polyligne)
    for (p0, p1) in zip(pole, pole[1:]):
        if p0[1] >= y >= p1[1]:
            t = (p0[1] - y) / (p0[1] - p1[1])
            c = tuple(p0[q] + (p1[q] - p0[q]) * t for q in range(3))
            break
    cylinder(f"Cane_clamp_{k}", 0.017, 0.017, 0.028, c, "metal_dark", a0, seg=14, bevel=0.003)
lathe("Cane_foot", [(0.02, 0.07), (0.022, 0.05), (0.04, 0.03), (0.05, 0.012), (0.05, 0.0), (0.0, 0.0)], "rubber", a0,
      loc=(CX - 0.1, 0.0, CZ + 0.016), seg=20, subsurf=0, closed_top=True)
cylinder("Cane_neck", 0.02, 0.024, 0.03, (CX, TOP + 0.005, CZ), "metal_dark", a0, seg=14, bevel=0.004)
box("Cane_head", (0.072, 0.05, 0.06), (CX, TOP + 0.045, CZ), "metal", a0, bevel=0.012)
box("Cane_screen", (0.034, 0.02, 0.004), (CX, TOP + 0.045, CZ + 0.031), "glow", a0, bevel=0.002, extras=NO_OUTLINE)
line("Cane_wave", [(CX - 0.013, TOP + 0.045, CZ + 0.034), (CX - 0.005, TOP + 0.045, CZ + 0.034), (CX - 0.001, TOP + 0.053, CZ + 0.034),
                   (CX + 0.004, TOP + 0.038, CZ + 0.034), (CX + 0.008, TOP + 0.045, CZ + 0.034), (CX + 0.014, TOP + 0.045, CZ + 0.034)],
     0.0012, a0, role="glow_dark", taper=False)
for sx in (-1, 1):
    sphere(f"Cane_lamp_{sx}", 1.0, (CX + sx * 0.04, TOP + 0.045, CZ), "glow", a0, scale=(0.01, 0.014, 0.014), seg=12, exact=True)
lathe("Cane_bulb", [(0.0, TOP + 0.13), (0.012, TOP + 0.128), (0.02, TOP + 0.12), (0.022, TOP + 0.105), (0.022, TOP + 0.075),
                    (0.0, TOP + 0.075)], "glow", a0, loc=(CX - 0.006, 0.0, CZ - 0.004), seg=20, subsurf=0)
cylinder("Cane_antenna", 0.003, 0.003, 0.06, (CX + 0.026, TOP + 0.1, CZ - 0.01), "metal_dark", a0, seg=8, bevel=0.0)
sphere("Cane_antenna_tip", 0.006, (CX + 0.026, TOP + 0.133, CZ - 0.01), "metal_dark", a0, seg=8)
sweep("Cane_wire", [(CX + 0.016, TOP - 0.005, CZ + 0.006), (CX + 0.03, 0.85, CZ + 0.01), (CX + 0.032, 0.78, CZ + 0.012),
                    (CX + 0.014, 0.735, CZ + 0.008)], [(0.0035, 0.0035)] * 4, "wire", a0, seg=6)

# ======================================================================== taches et accrocs sur la blouse
coat_tree = bvh_of([bpy.data.objects["Torso_coat"]])
for k, (o_, d_, s_, role) in enumerate((
        ((0.3, 0.78, 0.05), (-1, 0, 0), (0.016, 0.02), "stain"), ((0.3, 0.62, -0.02), (-1, 0, 0), (0.022, 0.018), "stain"),
        ((-0.3, 0.7, 0.0), (1, 0, 0), (0.018, 0.024), "stain"), ((0.1, 0.62, 0.4), (0, 0, -1), (0.016, 0.022), "hole"),
        ((-0.09, 1.02, 0.4), (0, 0, -1), (0.012, 0.016), "stain"), ((0.05, 0.75, -0.4), (0, 0, 1), (0.03, 0.026), "hole"),
        ((-0.06, 0.95, -0.4), (0, 0, 1), (0.016, 0.02), "stain"), ((0.08, 1.05, -0.4), (0, 0, 1), (0.01, 0.014), "stain"))):
    decal(f"Torso_coat_{role}_{k}", coat_tree, o_, d_, s_, role, torso, jag=0.45, seed=20 + k)
for i in (0, 1):
    st = bvh_of([bpy.data.objects[f"Arm_{i}_sleeve"]])
    sx = -1 if i == 0 else 1
    decal(f"Arm_{i}_sleeve_stain", st, (sx * 0.4, 1.0, 0.0), (-sx, 0, 0), (0.014, 0.018), "hole", bpy.data.objects[f"Arm_{i}"], jag=0.5,
          seed=40 + i)

# ======================================================================== EXPORT
def rotate_world_mesh(obj, center, radians):
    transform = Matrix.Translation(G(*center)) @ Matrix.Rotation(radians,4,"Z") @ Matrix.Translation(-G(*center))
    local = obj.matrix_world.inverted() @ transform @ obj.matrix_world
    obj.data.transform(local)

bpy.context.view_layer.update()
for obj in bpy.data.objects:
    if obj.type != "MESH":
        continue
    if obj.name.startswith(("Arm_1_hand","Arm_1_finger","Arm_1_thumb")):
        rotate_world_mesh(obj,(hx,hy,hz),math.radians(-65))
    for i,x in ((0,-.075),(1,.080)):
        if obj.name.startswith((f"Leg_{i}_shoe",f"Leg_{i}_sole",f"Leg_{i}_strap")):
            rotate_world_mesh(obj,(x,.08,-.006),math.radians(-22 if i==0 else 22))

# The default frown is one continuous surface-following stroke.
if MOOD == "neutral":
    pts=[]
    for k in range(25):
        x=-.067+.134*k/24
        y=MY-.014+ .014*(1-(x/.067)**2)
        pts.append(HP(x,y,surf(x,y)+.002))
    line("Mouth_neutral",pts,.0010,head,taper=True)

glb = os.path.join(bc.ROOT, "assets", "models", "characters", "old_scientist_v2.glb")
blend = os.path.join(bc.ROOT, "art", "blender", "old_scientist_v2.blend")
os.makedirs(os.path.dirname(blend), exist_ok=True)

# ======================================================================== APERCU
smile, brow_tilt, brow_up, mode = {"neutral": (-0.45, 0.0, 0.0, "line"), "happy": (0.6, -0.25, 0.01, "line"),
                                   "angry": (-0.9, 0.35, -0.01, "shout"), "shock": (0.0, -0.3, 0.02, "open")}[MOOD]
O = bpy.data.objects
for i in range(5):
    u = (i - 2) / 2.0
    c = smile * 0.06
    O[f"Mouth_seg_{i}"].location.z += c * u * u - c * 0.35
    O[f"Mouth_seg_{i}"].rotation_euler = (0, -math.atan(2.0 * c * u / 0.054), 0)
    O[f"Mouth_seg_{i}_bar"].hide_render = mode != "line" or MOOD == "neutral"
for i in range(2):
    O[f"Brow_{i}"].rotation_euler = (0, (brow_tilt if i == 0 else -brow_tilt), 0)
    O[f"Brow_{i}"].location.z += brow_up
    O[f"Blush_{i}"].hide_render = True
for o in O:
    if o.name.startswith("Mouth_open") or o.name == "Mouth_tongue":
        o.hide_render = mode != "open"
    if o.name.startswith("Mouth_shout"):
        o.hide_render = mode != "shout"

# Keep the source editable, with expression alternatives hidden by default.
from scientist_rig import bind
bind(rig, HEAD_Y, HEAD_Z, SHO_Y)
for o in list(O):
    if o.type == "MESH":
        o.hide_set(o.hide_render or (o.parent is not None and o.parent.hide_render))
bpy.ops.wm.save_as_mainfile(filepath=blend)
bpy.ops.object.select_all(action="DESELECT")
rig.select_set(True)
for o in rig.children_recursive:
    if not o.hide_get():
        o.select_set(True)
bpy.ops.export_scene.gltf(filepath=glb, export_format="GLB", use_selection=True,
                         export_apply=True, export_yup=True, export_extras=True,
                         export_cameras=False, export_lights=False)
print("EXPORT", glb)
bc.preview_toon(width=0.0017, cel=0.0, min_size=0.012)
from scientist_export import export as export_game
if not QUICK:
    export_game(rig, glb.replace(".glb","_toon.glb"))
od = os.path.join(bc.ROOT, "out", "blender")
pre = os.path.join(od, "sci_v2" if MOOD == "neutral" else f"sci_v2_{MOOD}")
if MOOD == "neutral":
    full = {"front": dict(yaw=0, elev=0), "back": dict(yaw=180, elev=0), "profile": dict(yaw=90, elev=0),
            "three_quarter": dict(yaw=28, elev=0)}
    full = {k: dict(v, focus=(0, 0.93, 0.03), dist=12.6) for k, v in full.items()}
    if QUICK:
        full = {k:v for k,v in full.items() if k in ("front","three_quarter")}
    bc.render_preview(pre, views=full, res=(640,960) if QUICK else (1024,1536), floor=False, bg="#FBFAF5", key_only=True, lens=200)
faces = {"face_front": dict(yaw=0, elev=0), "face_profile": dict(yaw=90, elev=0), "face_34": dict(yaw=30, elev=0)}
faces = {k: dict(v, focus=(0, HEAD_Y + 0.015, HEAD_Z), dist=4.0) for k, v in faces.items()}
if QUICK:
    faces = {"face_front":faces["face_front"]}
bc.render_preview(pre, views=faces, res=(640,640) if QUICK else (1024,1024), floor=False, bg="#FBFAF5", key_only=True, lens=200)
print("PREVIEW", pre)
