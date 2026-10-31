"""Kit humain, style « Rick et Morty » : adulte ~5 tetes, tete ovale plus haute que large, gros yeux globuleux qui se
touchent (pupille-point, cils au coin externe), nez en bosse, bouche fine (dents quand elle s'ouvre), cou mince,
corps fin, bras longs a coude, mains a 4 doigts, cheveux en masses a pointes. Cel-shading 2 tons + trait fin (apercu).
Memes noms de pieces/pivots que human_base.py : CustomerActor peut charger l'un ou l'autre kit.

Lancer (PowerShell) : tools\\blender\\run.ps1 -Script tools\\blender\\characters\\human_rm.py
Options (apres --) : --torso dress|basic|coat  --hat sun|bowler|fedora|tophat|beanie|cap|none  --mood neutral|happy|bored|angry|shock
Sortie : assets/models/characters/human_rm.glb, art/blender/human_rm.blend, apercus out/blender/rm_*.png.

Pivots (coordonnees Godot) : Leg_i (+-0.068, HIP_Y), Arm_i (+-0.135, SHO_Y), Head (0, HEAD_Y). Le visage est en metres
relatifs a Head. La bouche est dessinee dans un repere agrandi (spacing 0.027 comme le code du jeu) puis reduite par MOUTH_S,
pour que les formules de _apply_mood (decalages en unites locales) gardent la bonne amplitude.
"""
import math
import os
import sys

import bpy
from mathutils import Vector

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import bl_common as bc  # noqa: E402
from bl_common import G, box, lathe, sphere, sweep  # noqa: E402

ARGS = bc.script_args()
TORSO = ARGS[ARGS.index("--torso") + 1] if "--torso" in ARGS else "dress"
HAT = ARGS[ARGS.index("--hat") + 1] if "--hat" in ARGS else "none"
MOOD = ARGS[ARGS.index("--mood") + 1] if "--mood" in ARGS else "neutral"

HIP_Y = 0.88
SHO_Y = 1.27
HEAD_Y = 1.50
HX, HY, HZ = 0.128, 0.165, 0.135  # tete ovale (plus haute que large)
KH = 0.70  # echelle des chapeaux (profils dessines pour une tete de rayon 0.21 x 1.3)
HAT_DY = -0.005
MOUTH_S = 0.55
NO_OUTLINE = {"no_outline": True}

bc.reset_scene()
for role, col in [
    ("skin", "#F7DCC4"), ("skin_shade", "#E9C3A6"), ("top", "#4FA3C7"), ("top_light", "#A9D8EA"), ("bottom", "#F7DCC4"),
    ("bottom_shade", "#D8B998"), ("shoe", "#7A4A36"), ("sole", "#3B2620"), ("strap", "#2B1E33"), ("hair", "#B8562F"),
    ("hat", "#F2D16B"), ("hat_dark", "#5B3F8C"), ("hat_shade", "#C9A43E"), ("accent", "#F6E3A1"), ("ink", "#14121A"),
    ("blood", "#C8423B"), ("petal", "#F07FA0"), ("paper", "#FFF8EC"), ("eye_white", "#FFFFFF"), ("iris", "#14121A"),
    ("gloss", "#FFFFFF"), ("brow", "#5A2B1A"), ("lip", "#C5606C"), ("mouth", "#2A1620"), ("mouth_in", "#5B1E2A"),
    ("teeth", "#FFFFFF"), ("tongue", "#E8788A"), ("blush", "#F09A8E"), ("cerne", "#D9A0B4"), ("button", "#F6E3A1"),
    ("bone", "#EDE6D3"),
]:
    bc.material(role, col, 0.9, spec=0.0)

rig = bc.pivot("Rig", (0, 0, 0))
torso = bc.pivot("Torso", (0, 0, 0), rig)


def _smooth(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


def jaw(x, y, z):
    """Tete en oeuf : machoire qui s'affine vers un menton doux, legerement avance."""
    if y < 0:
        t = min(1.0, -y / HY)
        x *= 1 - 0.30 * t ** 1.4
        z *= 1 - 0.10 * t
        if z > 0:
            z += 0.012 * t * t
    return x, y, z


def surf_z(x, y):
    """z de la surface avant de la tete (y relatif au centre), deformation de machoire comprise (approx.)."""
    xs = x
    if y < 0:
        t = min(1.0, -y / HY)
        xs = x / (1 - 0.30 * t ** 1.4)
    z = HZ * math.sqrt(max(0.0, 1 - (xs / HX) ** 2 - (y / HY) ** 2))
    if y < 0:
        t = min(1.0, -y / HY)
        z = z * (1 - 0.10 * t) + 0.012 * t * t
    return z


def H(x, y, z):
    return (x, HEAD_Y + y, z)


# ============================================================ JAMBES
def build_legs():
    for i, sx in enumerate((-1, 1)):
        x = sx * 0.068
        leg = bc.pivot(f"Leg_{i}", G(x, HIP_Y, 0), rig)
        sweep(f"Leg_{i}_limb", [(x, 0.84, 0), (x, 0.70, 0.004), (x * 0.95, 0.50, 0.008), (x * 0.92, 0.30, -0.004), (x * 0.92, 0.09, 0.0)],
              [(0.055, 0.053), (0.05, 0.048), (0.04, 0.04), (0.042, 0.041), (0.028, 0.028)], "bottom", leg, cap0="round",
              cap1="round", seg=16)
        xs = x * 0.92
        sweep(f"Leg_{i}_shoe", [(xs, 0.05, -0.04), (xs, 0.048, 0.02), (xs, 0.04, 0.08), (xs, 0.035, 0.125)],
              [(0.036, 0.04), (0.04, 0.038), (0.042, 0.03), (0.034, 0.025)], "shoe", leg, cap0="round", cap1="round",
              cap_len=0.9, seg=16)
        sweep(f"Leg_{i}_sole", [(xs, 0.012, -0.04), (xs, 0.012, 0.05), (xs, 0.012, 0.13)],
              [(0.038, 0.012), (0.043, 0.012), (0.036, 0.011)], "sole", leg, cap0="round", cap1="round", cap_len=0.9, seg=14)


# ============================================================ TORSES
def build_torsos():
    # robe : corsage ajuste + jupe trapeze au genou
    sweep("Torso_dress", [(0, 1.295, 0), (0, 1.255, 0), (0, 1.17, 0.006), (0, 1.07, 0.0), (0, 0.98, 0)],
          [(0.06, 0.05), (0.128, 0.075), (0.122, 0.088), (0.096, 0.07), (0.104, 0.074)], "top", torso, cap0="flat",
          cap1="flat", seg=24, sq=2.3)
    skirt = [(0.0, 1.0), (0.1, 1.0), (0.115, 0.95), (0.14, 0.85), (0.162, 0.74), (0.185, 0.62), (0.205, 0.53)]
    lathe("Torso_dress_skirt", skirt, "top", torso, seg=36,
          mod=lambda th, t: (1.0 - 0.2 * (1 - math.cos(2 * th)) / 2 * (1 - t * 0.3), 0.0),
          subsurf=0, smooth=1, thick=0.008, closed_top=True)
    sweep("Detail_sash", [(0, 0.995, 0), (0, 1.03, 0)], [(0.1, 0.073), (0.098, 0.072)], "accent", torso, cap0="open", cap1="open",
          thick=0.008, seg=24, sq=2.3)
    for k in range(2):
        sphere(f"Detail_button_{k}", 0.009, (0, 1.2 - k * 0.07, 0.088 - k * 0.006), "button", torso, seg=10)

    # tee-shirt + pantalon (jambes 'bottom')
    sweep("Torso_basic", [(0, 1.295, 0), (0, 1.255, 0), (0, 1.17, 0.004), (0, 1.05, 0.0), (0, 0.9, 0)],
          [(0.06, 0.05), (0.13, 0.077), (0.124, 0.085), (0.11, 0.075), (0.118, 0.078)], "top", torso, cap0="flat", cap1="open",
          thick=0.008, seg=24, sq=2.3)
    sweep("Torso_basic_hem", [(0, 0.94, 0), (0, 0.86, 0)], [(0.12, 0.08), (0.124, 0.082)], "bottom", torso, cap0="open",
          cap1="flat", seg=24, sq=2.3)
    sweep("Detail_belt", [(0, 0.89, 0), (0, 0.915, 0)], [(0.124, 0.082), (0.124, 0.082)], "ink", torso, cap0="open", cap1="open",
          thick=0.006, seg=24, sq=2.3)
    sweep("Detail_band", [(0, 1.1, 0), (0, 1.14, 0)], [(0.118, 0.082), (0.12, 0.084)], "accent", torso, cap0="open", cap1="open",
          thick=0.006, seg=24, sq=2.3)
    box("Detail_tie", (0.035, 0.16, 0.012), (0, 1.17, 0.086), "blood", torso, bevel=0.004)

    # blouse longue
    sweep("Torso_coat", [(0, 1.3, 0), (0, 1.25, 0), (0, 1.1, 0.0), (0, 0.85, 0), (0, 0.55, 0)],
          [(0.065, 0.055), (0.14, 0.085), (0.135, 0.095), (0.15, 0.1), (0.19, 0.12)], "top", torso, cap0="flat", cap1="open",
          thick=0.01, seg=26, sq=2.3)
    for sx in (-1, 1):
        sweep(f"Torso_coat_lapel_{sx}", [(sx * 0.02, 1.28, 0.06), (sx * 0.05, 1.18, 0.09), (sx * 0.04, 1.08, 0.098)],
              [(0.028, 0.006), (0.032, 0.006), (0.022, 0.006)], "top_light", torso, ref=(0, 0, 1), seg=10, cap_len=0.6)
        box(f"Torso_coat_pocket_{sx}", (0.06, 0.05, 0.008), (sx * 0.075, 0.82, 0.105), "top_light", torso, bevel=0.004)
    for k in range(3):
        sphere(f"Torso_coat_button_{k}", 0.009, (0.02, 1.08 - k * 0.1, 0.098 + k * 0.003), "button", torso, seg=10)

    # cou mince et visible
    sweep("Neck", [(0, 1.25, 0), (0, 1.33, 0.004), (0, 1.42, 0.008)], [(0.036, 0.034), (0.033, 0.031), (0.034, 0.032)], "skin", rig,
          cap0="round", cap1="round", seg=14)


# ============================================================ BRAS (longs, coude) + MAINS 4 doigts
def build_arms():
    for i, sx in enumerate((-1, 1)):
        x = sx * 0.135
        arm = bc.pivot(f"Arm_{i}", G(x, SHO_Y, 0), rig)
        sweep(f"Arm_{i}_limb", [(x - sx * 0.005, 1.27, 0), (x + sx * 0.012, 1.15, 0.002), (x + sx * 0.022, 1.02, -0.004),
                                (x + sx * 0.045, 0.9, 0.012), (x + sx * 0.058, 0.8, 0.02)],
              [(0.032, 0.031), (0.028, 0.027), (0.025, 0.025), (0.024, 0.023), (0.021, 0.02)], "skin", arm, cap0="round",
              cap1="round", seg=14)
        sweep(f"Arm_{i}_sleeve", [(x - sx * 0.004, 1.285, 0), (x + sx * 0.006, 1.22, 0.001), (x + sx * 0.013, 1.15, 0.002)],
              [(0.05, 0.048), (0.046, 0.044), (0.044, 0.042)], "top", arm, cap0="round", cap1="open", thick=0.005, seg=18)
        hx = x + sx * 0.059
        sweep(f"Arm_{i}_hand", [(hx, 0.8, 0.02), (hx + sx * 0.002, 0.765, 0.024), (hx + sx * 0.003, 0.735, 0.026)],
              [(0.026, 0.014), (0.03, 0.016), (0.028, 0.015)], "skin", arm, ref=(0, 0, 1), cap0="round", cap1="round", seg=14)
        for fi, fx in enumerate((-0.017, 0.0, 0.017)):
            sweep(f"Arm_{i}_finger_{fi}", [(hx + fx, 0.74, 0.027), (hx + fx * 1.15, 0.705, 0.03), (hx + fx * 1.2, 0.675, 0.034)],
                  [(0.0082, 0.0082), (0.0076, 0.0076), (0.0068, 0.0068)], "skin", arm, cap0="round", cap1="round", seg=8)
        sweep(f"Arm_{i}_thumb", [(hx - sx * 0.022, 0.775, 0.028), (hx - sx * 0.036, 0.75, 0.036), (hx - sx * 0.04, 0.725, 0.042)],
              [(0.0095, 0.0095), (0.0085, 0.0085), (0.0074, 0.0074)], "skin", arm, cap0="round", cap1="round", seg=8)


# ============================================================ TETE
def build_head():
    head = bc.pivot("Head", G(0, HEAD_Y, 0), rig)
    bc.blob("Head_skull", 1.0, (0, HEAD_Y, 0), "skin", head, scale=(HX, HY, HZ), deform=jaw, seg=40, subsurf=0)
    z0 = surf_z(0, -0.01)
    sweep("Head_nose", [H(0, 0.0, z0 - 0.012), H(0, -0.022, z0 + 0.012), H(0, -0.038, z0 + 0.018)],
          [(0.012, 0.012), (0.0155, 0.015), (0.0165, 0.016)], "skin", head, seg=14)
    for sx in (-1, 1):
        sphere(f"Head_ear_{sx}", 0.032, H(sx * 0.124, -0.012, -0.01), "skin", head, scale=(0.36, 1.0, 0.72), seg=14)

    for i, sx in enumerate((-1, 1)):
        ex, ey = sx * 0.05, 0.028
        ez = surf_z(ex, ey) - 0.004
        rx, ry, rz = 0.051, 0.062, 0.04  # oeil globuleux qui deborde du visage
        eye = bc.pivot(f"Eye_{i}", G(*H(ex, ey, ez)), head)
        sphere(f"Eye_{i}_white", 1.0, H(ex, ey, ez), "eye_white", eye, scale=(rx, ry, rz), seg=28, exact=True)
        px, py = ex - sx * 0.006, ey - 0.006
        pz = ez + rz * math.sqrt(max(0.0, 1 - ((px - ex) / rx) ** 2 - ((py - ey) / ry) ** 2)) + 0.0005
        sphere(f"Eye_{i}_pupil", 0.0072, H(px, py, pz), "iris", eye, scale=(1, 1, 0.4), seg=12, exact=True, extras=NO_OUTLINE)
        for k, ang in enumerate((25, 45, 65)):  # 3 cils au coin superieur externe
            a = math.radians(ang)
            bx0, by0 = ex + sx * rx * math.cos(a) * 0.98, ey + ry * math.sin(a) * 0.98
            bz0 = ez + rz * 0.35
            d = Vector((sx * math.cos(a), math.sin(a), 0.0)).normalized()
            sweep(f"Eye_{i}_lash_{k}", [H(bx0, by0, bz0), H(bx0 + d.x * 0.012, by0 + d.y * 0.012 + 0.002, bz0 + 0.002),
                                        H(bx0 + d.x * 0.02, by0 + d.y * 0.02 + 0.006, bz0)],
                  [(0.0032, 0.0032), (0.0024, 0.0024), (0.0012, 0.0012)], "ink", eye, seg=6, sub=0, extras=NO_OUTLINE)
        bx, by = sx * 0.06, 0.112
        bz = surf_z(bx, by) + 0.004
        brow = bc.pivot(f"Brow_{i}", G(*H(bx, by, bz)), head)
        bp = []
        for u in (-1.0, -0.5, 0.0, 0.5, 1.0):
            xx = bx + sx * u * 0.034
            yy = by + 0.008 * (1 - u * u) + 0.003 * u
            bp.append(H(xx, yy, surf_z(xx, yy) + 0.004))
        sweep(f"Brow_{i}_bar", bp, [(0.0042, 0.0035), (0.005, 0.004), (0.005, 0.004), (0.0042, 0.0035), (0.0025, 0.0022)], "brow",
              brow, ref=(0, 1, 0), seg=8, extras=NO_OUTLINE)
        bxx, byy = sx * 0.085, -0.045
        sphere(f"Blush_{i}", 0.028, H(bxx, byy, surf_z(bxx, byy) - 0.004), "blush", head, scale=(1.3, 0.9, 0.35), seg=12,
               extras=NO_OUTLINE)

    # bouche : repere local agrandi puis reduit par MOUTH_S (amplitudes de _apply_mood conservees)
    my = -0.092
    mz = surf_z(0, my) + 0.003
    mouth = bc.pivot("Mouth", G(*H(0, my, mz)), head)
    for i in range(5):
        lx = (i - 2) * 0.027
        seg = bc.pivot(f"Mouth_seg_{i}", G(*H(lx, my, mz)), mouth)
        sweep(f"Mouth_seg_{i}_bar", [H(lx - 0.02, my, mz), H(lx + 0.02, my, mz)], [(0.0062, 0.0055), (0.0062, 0.0055)], "mouth", seg,
              ref=(0, 1, 0), seg=8, extras=NO_OUTLINE)
    mo = sphere("Mouth_open", 0.05, H(0, my - 0.02, mz - 0.006), "mouth_in", mouth, scale=(1.25, 0.85, 0.35), seg=18, exact=True,
                extras=NO_OUTLINE)
    teeth = box("Mouth_teeth", (0.085, 0.016, 0.014), H(0, my - 0.002, mz), "teeth", mouth, bevel=0.004, extras=NO_OUTLINE)
    tongue = sphere("Mouth_tongue", 0.026, H(0, my - 0.036, mz - 0.002), "tongue", mouth, scale=(1.4, 0.6, 0.35), seg=12,
                    extras=NO_OUTLINE)
    for o in (teeth, tongue):  # montrees/cachees avec Mouth_open
        bpy.context.view_layer.update()
        mw = o.matrix_world.copy()
        o.parent = mo
        o.matrix_world = mw
    bpy.context.view_layer.update()
    mouth.scale = (MOUTH_S, MOUTH_S, MOUTH_S)
    return head


# ============================================================ CHEVEUX : carre souple, frange balayee, pointes
def hair_ymin(psi):
    a = abs(psi)
    y = 0.105
    y += (0.035 - 0.105) * _smooth(0.3, 1.0, a)
    y += (-0.125 - 0.035) * _smooth(1.0, 1.45, a)
    y += (-0.14 - -0.125) * _smooth(1.6, 2.6, a)
    return y


def hair_flare(x, y, z):
    if y < 0:
        t = min(1.0, -y / HY)
        x *= 1 + 0.38 * t
        z *= 1 + 0.30 * t
    return x, y, z


def build_hair(head):
    bc.dome("Hair_cap", 1.0, hair_ymin, H(0, 0.006, -0.008), "hair", head, scale=(HX + 0.014, HY + 0.012, HZ + 0.016),
            deform=hair_flare, rings=12, seg=40, subsurf=0, thick=0.01)
    sweep("Hair_bang_0", [H(0.035, 0.18, 0.045), H(-0.005, 0.165, 0.108), H(-0.06, 0.138, 0.128), H(-0.112, 0.095, 0.105),
                          H(-0.135, 0.045, 0.078)],
          [(0.012, 0.045), (0.014, 0.05), (0.013, 0.04), (0.01, 0.022), (0.004, 0.006)], "hair", head, ref=(0, 0, 1), seg=12,
          cap_len=0.6)
    sweep("Hair_bang_1", [H(0.05, 0.176, 0.04), H(0.085, 0.155, 0.095), H(0.115, 0.118, 0.098), H(0.132, 0.075, 0.075)],
          [(0.011, 0.032), (0.012, 0.034), (0.01, 0.022), (0.004, 0.006)], "hair", head, ref=(0, 0, 1), seg=12, cap_len=0.6)
    for k, psi in enumerate((-2.75, -2.0, -1.45, 1.45, 2.0, 2.75)):
        y0 = -0.095
        r0 = math.sqrt(max(0.0, 1 - (y0 / (HY + 0.012)) ** 2))
        bx0 = (HX + 0.014) * r0 * math.sin(psi) * (1 + 0.38 * (-y0 / HY))
        bz0 = (HZ + 0.016) * r0 * math.cos(psi) * (1 + 0.30 * (-y0 / HY)) - 0.008
        out = Vector((math.sin(psi), 0, math.cos(psi)))
        tip = Vector((bx0, y0 - 0.075, bz0)) + out * 0.03
        sweep(f"Hair_tip_{k}", [H(bx0 * 0.92, y0 + 0.03, bz0 * 0.92), H(bx0, y0 - 0.02, bz0), H(tip.x, tip.y, tip.z)],
              [(0.03, 0.03), (0.026, 0.026), (0.004, 0.004)], "hair", head, ref=(0, 1, 0), seg=10, cap_len=1.2)


# ============================================================ CHAPEAUX (profils de human_base, a l'echelle KH)
def HK(x, y, z):
    return (KH * x, HEAD_Y + HAT_DY + KH * y, KH * z)


def ksphere(name, r, loc, role, parent, **kw):
    return sphere(name, r * KH, HK(*loc), role, parent, **kw)


def ksweep(name, pts, radii, role, parent, **kw):
    rr = [((r * KH, r * KH) if isinstance(r, (int, float)) else (r[0] * KH, r[1] * KH)) for r in radii]
    return sweep(name, [HK(*p) for p in pts], rr, role, parent, **kw)


def klathe(name, profile, role, parent, dz=0.0, **kw):
    if "thick" in kw:
        kw["thick"] = kw["thick"] * KH
    return lathe(name, [(r * KH, y * KH) for r, y in profile], role, parent, loc=(0, HEAD_Y + HAT_DY, KH * dz), **kw)


def build_hats(head):
    def fat(profile, k=1.07):
        return [((r * k) if (y > 0.178 and r < 0.27) else r, y) for r, y in profile]

    def tilt(profile, front=-0.012, side=0.0):
        n = len(profile)

        def f(th, t):
            r = profile[min(n - 1, max(0, int(round(t * (n - 1)))))][0]
            return (1.0, r * (front * math.sin(th) + side * math.cos(th)))

        return f

    sun = fat([(0.0, 0.305), (0.06, 0.309), (0.125, 0.3), (0.18, 0.272), (0.222, 0.225), (0.238, 0.185), (0.242, 0.175),
               (0.29, 0.172), (0.35, 0.162), (0.40, 0.145), (0.425, 0.132), (0.43, 0.124), (0.42, 0.117), (0.39, 0.122),
               (0.34, 0.133), (0.28, 0.142), (0.24, 0.15), (0.225, 0.16)])
    tl = tilt(sun, front=0.10, side=-0.05)
    klathe("Hat_sun", sun, "hat", head, seg=32, mod=lambda th, t: (1.0, tl(th, t)[1] + 0.016 * math.sin(3 * th + 0.4) * t * t), subsurf=1)
    band = fat([(0.246, 0.18), (0.249, 0.186), (0.247, 0.222), (0.243, 0.227)])
    klathe("Hat_sun_band", band, "petal", head, seg=32, mod=tilt(band, front=0.10, side=-0.05), subsurf=0, thick=0.005, closed_top=False)
    fx, fy, fz = 0.2, 0.2, 0.17
    for k in range(5):
        a = 2 * math.pi * k / 5
        ksphere(f"Hat_sun_flower_{k}", 0.05, (fx + 0.055 * math.cos(a), fy + 0.055 * math.sin(a), fz + 0.03), "petal", head,
                scale=(1, 1, 0.5), seg=12)
    ksphere("Hat_sun_flower_c", 0.034, (fx, fy, fz + 0.055), "hat", head, seg=12, scale=(1, 1, 0.8))

    bowler = fat([(0.0, 0.378), (0.075, 0.374), (0.14, 0.35), (0.19, 0.3), (0.215, 0.24), (0.222, 0.19), (0.23, 0.185),
                  (0.3, 0.185), (0.322, 0.178), (0.324, 0.168), (0.31, 0.162), (0.23, 0.162), (0.2, 0.17)])
    klathe("Hat_bowler", bowler, "hat_dark", head, seg=32, mod=tilt(bowler, 0.03, 0.03), subsurf=1)
    klathe("Hat_bowler_band", [(0.243, 0.19), (0.246, 0.196), (0.246, 0.228), (0.243, 0.232)], "blood", head, seg=32, subsurf=0,
           thick=0.005, closed_top=False)

    fed = fat([(0.0, 0.33), (0.06, 0.327), (0.12, 0.31), (0.18, 0.285), (0.215, 0.245), (0.226, 0.2), (0.235, 0.185), (0.3, 0.18),
               (0.36, 0.17), (0.395, 0.152), (0.4, 0.142), (0.39, 0.137), (0.36, 0.142), (0.3, 0.152), (0.235, 0.16), (0.205, 0.166)])

    def fed_mod(th, t):
        _, dy = tilt(fed, 0.05, 0.02)(th, t)
        k = max(0.0, (t - 0.45) / 0.55) if t < 0.5 else 0.0
        return (1.0 - 0.1 * k * (0.5 + 0.5 * math.cos(2 * th)), dy)

    klathe("Hat_fedora", fed, "hat_dark", head, seg=32, mod=fed_mod, subsurf=1)
    klathe("Hat_fedora_band", [(0.245, 0.192), (0.248, 0.198), (0.246, 0.232), (0.243, 0.236)], "blood", head, seg=32, subsurf=0,
           thick=0.005, closed_top=False)

    top = fat([(0.0, 0.52), (0.1, 0.518), (0.19, 0.51), (0.202, 0.49), (0.205, 0.3), (0.207, 0.2), (0.225, 0.19), (0.3, 0.186),
               (0.34, 0.178), (0.346, 0.169), (0.338, 0.163), (0.3, 0.168), (0.23, 0.168), (0.2, 0.174)])
    klathe("Hat_tophat", top, "hat_dark", head, seg=32, mod=tilt(top, 0.03, 0.0), subsurf=1)
    klathe("Hat_tophat_band", [(0.222, 0.22), (0.225, 0.226), (0.225, 0.275), (0.222, 0.279)], "blood", head, seg=32, subsurf=0,
           thick=0.005, closed_top=False)

    bean = fat([(0.0, 0.46), (0.1, 0.45), (0.19, 0.4), (0.24, 0.32), (0.26, 0.23), (0.264, 0.17), (0.258, 0.12), (0.24, 0.13),
                (0.242, 0.2), (0.225, 0.22)], 1.05)
    klathe("Hat_beanie", bean, "hat", head, dz=-0.02, seg=32, mod=lambda th, t: 1.0 + (0.018 * math.cos(16 * th) if t > 0.55 else 0.0),
           subsurf=1)
    ksphere("Hat_beanie_pompom", 0.07, (0, 0.485, -0.02), "paper", head, seg=14)

    cap = fat([(0.0, 0.385), (0.09, 0.38), (0.18, 0.345), (0.235, 0.285), (0.252, 0.215), (0.256, 0.16), (0.238, 0.15), (0.222, 0.18),
               (0.2, 0.21)], 1.05)
    klathe("Hat_cap", cap, "hat", head, dz=-0.015, seg=32, subsurf=1)
    ksweep("Hat_cap_visor", [(-0.16, 0.17, 0.215), (0.0, 0.168, 0.3), (0.16, 0.17, 0.215)],
           [(0.024, 0.01), (0.06, 0.01), (0.024, 0.01)], "hat_shade", head, ref=(0, 0, 1), seg=12, cap_len=0.5)


# ============================================================ ASSEMBLAGE
build_legs()
build_torsos()
build_arms()
head_p = build_head()
build_hair(head_p)
build_hats(head_p)

glb = os.path.join(bc.ROOT, "assets", "models", "characters", "human_rm.glb")
blend = os.path.join(bc.ROOT, "art", "blender", "human_rm.blend")
os.makedirs(os.path.dirname(blend), exist_ok=True)
bc.export_glb(glb, rig)
bpy.ops.wm.save_as_mainfile(filepath=blend)
print("EXPORT", glb)

# ---- apercu : variante demandee, humeur simulee comme CustomerActor._apply_mood ------------------------
for o in bpy.data.objects:
    if o.type != "MESH":
        continue
    kind = o.name.split("_")[0]
    if kind == "Torso" and not o.name.startswith(f"Torso_{TORSO}"):
        o.hide_render = True
    if kind == "Hat" and not o.name.startswith(f"Hat_{HAT}"):
        o.hide_render = True
    if kind == "Detail":
        keep_detail = ((TORSO == "dress" and o.name.split("_")[1] in ("sash", "button"))
                       or (TORSO == "basic" and o.name == "Detail_belt") or (TORSO == "coat" and o.name == "Detail_tie"))
        o.hide_render = not keep_detail
    if kind == "Hair" and o.name.startswith("Hair_bang") and HAT in ("beanie", "cap"):
        o.hide_render = True
    if kind == "Blush":
        o.hide_render = True

smile, brow_tilt, brow_up, opened = {"neutral": (0.35, 0, 0, False), "happy": (0.85, 0, 0.012, False),
                                     "bored": (-0.1, 0, -0.008, False), "angry": (-0.9, 0.55, -0.012, False),
                                     "shock": (0.0, 0, 0.02, True)}[MOOD]
for i in range(5):
    u = (i - 2) / 2.0
    c = smile * 0.06
    seg_o = bpy.data.objects[f"Mouth_seg_{i}"]
    seg_o.location.z += c * u * u - c * 0.35
    seg_o.rotation_euler = (0, -math.atan(2.0 * c * u / 0.054), 0)
for i in range(2):
    bo = bpy.data.objects[f"Brow_{i}"]
    bo.rotation_euler = (0, (brow_tilt if i == 0 else -brow_tilt), 0)
    bo.location.z += brow_up * 0.6
for n in ("Mouth_open", "Mouth_tongue", "Mouth_teeth"):
    bpy.data.objects[n].hide_render = not opened
if opened:
    for i in range(5):
        bpy.data.objects[f"Mouth_seg_{i}_bar"].hide_render = True
if MOOD == "angry":
    for o in bpy.data.objects:
        if o.name.startswith("Blush_"):
            o.hide_render = False

bc.preview_toon(width=0.0032, cel=0.0, min_size=0.02)
out = os.path.join(bc.ROOT, "out", "blender", f"rm_{TORSO}_{HAT}" + ("" if MOOD == "neutral" else f"_{MOOD}"))
os.makedirs(os.path.dirname(out), exist_ok=True)
views = {
    "front": dict(yaw=0), "three_quarter": dict(yaw=30), "side": dict(yaw=90), "back": dict(yaw=180),
    "face": dict(yaw=18, focus=(0, 1.48, 0), dist=1.5, elev=3),
}
bc.render_preview(out, views=views, res=(900, 1250), focus=(0, 0.92, 0), dist=5.2, floor=False, bg="#CFE6EC", key_only=True)
print("PREVIEW", out)
