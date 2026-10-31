"""Kit humain du jeu (clients, figurants) : memes noms de pieces/pivots que CustomerActor._build_human, proportions chibi (~3,3 tetes).

Lancer : tools\\blender\\run.ps1 -Script tools\\blender\\characters\\human_base.py
Options (apres --) : --torso dress|basic|coat  --hat sun|bowler|fedora|tophat|beanie|cap|none  --ao
Sortie : assets/models/characters/human_base.glb, art/blender/human_base.blend, apercus out/blender/.
Toutes les variantes (Torso_*, Hat_*, Detail_*, Hair_*) sont dans le glb ; Godot garde celles du style et masque le reste.

Pivots (coordonnees Godot) : Leg_i (+-0.125, HIP_Y), Arm_i (+-0.30, SHO_Y), Head (0, HEAD_Y). Les traits du visage sont
dessines a l'echelle d'une tete "ancienne" (rayon 0.21) puis agrandis par K : toutes les valeurs head-local sont en unites K.
"""
import math
import os
import sys

import bpy

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import bl_common as bc  # noqa: E402
from bl_common import G, box, cylinder, lathe, sphere, sweep  # noqa: E402

ARGS = bc.script_args()
bc.SEG_SCALE = 0.75  # budget triangles : sections 24 -> 18 segments
TORSO = ARGS[ARGS.index("--torso") + 1] if "--torso" in ARGS else "dress"
HAT = ARGS[ARGS.index("--hat") + 1] if "--hat" in ARGS else "sun"
BAKE_AO = "--ao" in ARGS

HIP_Y = 0.60
SHO_Y = 1.10
HEAD_Y = 1.45
K = 1.30  # agrandissement de la tete par rapport au dessin initial (rayon 0.21 -> 0.273)
LEG_X = 0.125
ARM_X = 0.30
NO_OUTLINE = {"no_outline": True}

bc.reset_scene()
for role, col, rough, spec in [
    ("skin", "#F7CBB0", 0.62, 0.2), ("skin_shade", "#E9A98E", 0.65, 0.15), ("top", "#F4709A", 0.7, 0.15),
    ("top_light", "#FFD3E0", 0.7, 0.15), ("bottom", "#7A3358", 0.75, 0.15), ("bottom_shade", "#5A2342", 0.8, 0.1),
    ("shoe", "#FFF6E5", 0.5, 0.3), ("sole", "#BFA98A", 0.85, 0.1), ("strap", "#2B1E33", 0.5, 0.3),
    ("hair", "#7A3B2E", 0.6, 0.25), ("hat", "#FFD24A", 0.8, 0.12), ("hat_dark", "#8A2E5E", 0.6, 0.2),
    ("hat_shade", "#D9AC2E", 0.8, 0.12), ("accent", "#FFF6E5", 0.7, 0.15), ("ink", "#2B1E33", 0.5, 0.3),
    ("blood", "#D63A4A", 0.6, 0.3), ("petal", "#FF7FA8", 0.6, 0.2), ("paper", "#FFF6E5", 0.7, 0.15),
    ("eye_white", "#FFFFFF", 0.25, 0.4), ("iris", "#6B4630", 0.3, 0.5), ("gloss", "#FFFFFF", 0.1, 0.5),
    ("brow", "#3A2018", 0.6, 0.15), ("lip", "#C5606C", 0.45, 0.3), ("mouth", "#5A2A34", 0.6, 0.2),
    ("mouth_in", "#5A2A30", 0.5, 0.2), ("tongue", "#E8788A", 0.5, 0.2), ("blush", "#F0788A", 0.9, 0.1),
    ("cerne", "#D9A0B4", 0.9, 0.05), ("button", "#FFF6E5", 0.35, 0.5), ("bone", "#EDE6D3", 0.55, 0.25),
]:
    bc.material(role, col, rough, spec=spec)

rig = bc.pivot("Rig", (0, 0, 0))
torso = bc.pivot("Torso", (0, 0, 0), rig)


# ---- aides tete : coordonnees "ancienne tete" x K ---------------------------------------------------
def HK(x, y, z):
    return (K * x, HEAD_Y + K * y, K * z)


def _rads(radii):
    return [((r * K, r * K) if isinstance(r, (int, float)) else (r[0] * K, r[1] * K)) for r in radii]


def ksphere(name, r, loc, role, parent, **kw):
    return sphere(name, r * K, HK(*loc), role, parent, **kw)


def ksweep(name, pts, radii, role, parent, **kw):
    if "thick" in kw:
        kw["thick"] = kw["thick"] * K
    return sweep(name, [HK(*p) for p in pts], _rads(radii), role, parent, **kw)


def klathe(name, profile, role, parent, dy=0.0, dz=0.0, **kw):
    if "thick" in kw:
        kw["thick"] = kw["thick"] * K
    return lathe(name, [(r * K, y * K) for r, y in profile], role, parent, loc=(0, HEAD_Y + K * dy, K * dz), **kw)


def gauss(x, y, z, cx, cy, cz, s):
    return math.exp(-((x - cx) ** 2 + (y - cy) ** 2 + (z - cz) ** 2) / (2 * s * s))


def _smooth(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


# ============================================================ JAMBES
def build_legs():
    for i, sx in enumerate((-1, 1)):
        x = sx * LEG_X
        leg = bc.pivot(f"Leg_{i}", G(x, HIP_Y, 0), rig)
        pts = [(x, 0.575, 0), (x, 0.47, 0.006), (x, 0.36, 0.008), (x, 0.22, 0.0), (x, 0.13, -0.004)]
        rad = [(0.108, 0.106), (0.100, 0.098), (0.088, 0.088), (0.080, 0.078), (0.072, 0.07)]
        sweep(f"Leg_{i}_limb", pts, rad, "bottom", leg, cap0="round", cap1="round", seg=28)
        for k, yy in enumerate((0.31, 0.235, 0.16)):  # chaussettes rayees
            r = 0.092 - (0.31 - yy) * 0.12
            sweep(f"Leg_{i}_stripe_{k}", [(x, yy + 0.022, 0.0), (x, yy - 0.002, 0.0)], [(r + 0.004, r + 0.004)] * 2, "paper", leg,
                  cap0="open", cap1="open", thick=0.006, seg=28)
        # chaussure Mary-Jane bombee : dessus + semelle + bride + bouton
        shoe_pts = [(x, 0.078, -0.09), (x, 0.074, -0.03), (x, 0.066, 0.05), (x, 0.056, 0.13), (x, 0.048, 0.205)]
        shoe_rad = [(0.074, 0.072), (0.084, 0.082), (0.09, 0.072), (0.086, 0.06), (0.066, 0.046)]
        sweep(f"Leg_{i}_shoe", shoe_pts, shoe_rad, "strap", leg, cap0="round", cap1="round", cap_len=0.9, seg=28)
        sole_pts = [(x, 0.02, -0.088), (x, 0.02, 0.0), (x, 0.02, 0.1), (x, 0.02, 0.205)]
        sole_rad = [(0.074, 0.024), (0.088, 0.026), (0.094, 0.026), (0.07, 0.022)]
        sweep(f"Leg_{i}_sole", sole_pts, sole_rad, "sole", leg, cap0="round", cap1="round", cap_len=0.9, seg=22)
        sweep(f"Leg_{i}_strap", [(x - 0.085, 0.116, 0.035), (x, 0.126, 0.04), (x + 0.085, 0.116, 0.035)],
              [(0.012, 0.014), (0.014, 0.016), (0.012, 0.014)], "shoe", leg, ref=(0, 0, 1), seg=12, cap_len=0.8)
        sphere(f"Leg_{i}_buckle", 0.016, (x + sx * 0.088, 0.116, 0.036), "button", leg, seg=12)


# ============================================================ TORSES
def build_torsos():
    # --- robe : corsage sablier + jupe cloche plissee + jupon + ceinture + col claudine
    bodice_pts = [(0, 0.70, 0), (0, 0.78, 0), (0, 0.88, 0.004), (0, 0.98, 0.012), (0, 1.06, 0.004), (0, 1.10, -0.002),
                  (0, 1.122, -0.004)]
    bodice_rad = [(0.150, 0.118), (0.156, 0.120), (0.182, 0.134), (0.212, 0.146), (0.236, 0.140), (0.205, 0.118),
                  (0.100, 0.082)]
    sweep("Torso_dress", bodice_pts, bodice_rad, "top", torso, cap0="flat", cap1="flat", seg=36, sq=2.2)

    def pleats(th, t):
        amp = 0.075 * t
        f = 1.0 + amp * math.cos(8 * th) + 0.025 * t * math.cos(5 * th + 0.7)
        dy = 0.02 * (t ** 4) * math.cos(8 * th + 0.3)
        return (f, dy)

    skirt = [(0.0, 0.76), (0.15, 0.76), (0.19, 0.72), (0.25, 0.64), (0.33, 0.54), (0.41, 0.44), (0.455, 0.37), (0.468, 0.345)]
    lathe("Torso_dress_skirt", skirt, "top", torso, seg=60, mod=pleats, subsurf=0, smooth=1, thick=0.014, closed_top=True)
    lathe("Torso_dress_hem", [(0.47, 0.35), (0.478, 0.338), (0.47, 0.322), (0.46, 0.33)], "top_light", torso, seg=64, mod=pleats,
          subsurf=0, thick=0.008, closed_top=False)
    lathe("Torso_dress_petticoat", [(0.34, 0.41), (0.43, 0.34), (0.50, 0.30), (0.505, 0.285), (0.49, 0.275), (0.44, 0.285)],
          "paper", torso, seg=72, mod=lambda th, t: (1.0 + 0.035 * math.cos(18 * th) * t, 0.012 * math.cos(18 * th) * t),
          subsurf=0, thick=0.006, closed_top=False)
    sweep("Detail_sash", [(0, 0.70, 0), (0, 0.765, 0)], [(0.158, 0.124), (0.162, 0.127)], "accent", torso, cap0="open",
          cap1="open", thick=0.016, seg=32, sq=2.2)
    for sx in (-1, 1):
        sweep(f"Detail_bow_{sx}", [(sx * 0.01, 0.735, -0.125), (sx * 0.09, 0.78, -0.15), (sx * 0.17, 0.75, -0.165)],
              [(0.03, 0.016), (0.05, 0.018), (0.042, 0.016)], "accent", torso, seg=16, cap_len=0.8)
        sweep(f"Detail_bowtail_{sx}", [(sx * 0.01, 0.72, -0.13), (sx * 0.05, 0.58, -0.17), (sx * 0.08, 0.46, -0.2)],
              [(0.032, 0.01), (0.034, 0.01), (0.028, 0.008)], "accent", torso, seg=12, cap_len=0.6)
    sphere("Detail_bowknot", 0.032, (0, 0.735, -0.135), "accent", torso, scale=(1, 1, 0.8), seg=16)
    sweep("Detail_collar", [(0, 1.152, -0.004), (0, 1.118, -0.004)], [(0.11, 0.095), (0.205, 0.17)], "paper", torso,
          cap0="open", cap1="open", thick=0.012, seg=44)
    for k in range(2):  # gros boutons visibles de loin
        sphere(f"Detail_button_{k}", 0.021, (0, 0.95 - k * 0.1, 0.145 - k * 0.012), "button", torso, seg=14)
    for k in range(5):  # broche fleur (echo du chapeau)
        a = 2 * math.pi * k / 5
        sphere(f"Detail_brooch_{k}", 0.021, (0.1 + 0.027 * math.cos(a), 1.02 + 0.027 * math.sin(a), 0.14), "petal", torso,
               scale=(1, 1, 0.5), seg=12)
    sphere("Detail_brooch_c", 0.016, (0.1, 1.02, 0.15), "hat", torso, seg=12)

    # --- pull / chemisier (hauteurs ramenees a la nouvelle echelle)
    def ty(y_old, lo=0.70, hi=1.50, nlo=0.60, nhi=1.14):
        return nlo + (y_old - lo) * (nhi - nlo) / (hi - lo)

    pts = [(0, ty(y), 0.0) for y in (0.70, 0.78, 0.9, 1.04, 1.18, 1.32, 1.42, 1.48)]
    rad = [(0.218, 0.168), (0.22, 0.17), (0.204, 0.158), (0.208, 0.16), (0.23, 0.17), (0.256, 0.158), (0.226, 0.128),
           (0.108, 0.088)]
    sweep("Torso_basic", pts, rad, "top", torso, cap0="open", cap1="flat", thick=0.014, seg=32, sq=2.2)
    sweep("Torso_basic_hem", [(0, 0.60, 0), (0, 0.65, 0)], [(0.222, 0.172), (0.222, 0.172)], "top_light", torso,
          cap0="open", cap1="open", thick=0.022, seg=32, sq=2.2)
    sweep("Torso_basic_neck", [(0, 1.145, -0.004), (0, 1.105, -0.004)], [(0.106, 0.09), (0.118, 0.1)], "top_light", torso,
          cap0="open", cap1="open", thick=0.014, seg=28)

    # --- manteau
    def tc(y_old):
        return ty(y_old, 0.44, 1.49, 0.30, 1.14)

    pts = [(0, tc(y), 0.0) for y in (0.44, 0.6, 0.8, 1.0, 1.2, 1.34, 1.43, 1.49)]
    rad = [(0.34, 0.26), (0.31, 0.24), (0.272, 0.2), (0.258, 0.19), (0.282, 0.2), (0.3, 0.18), (0.244, 0.138), (0.115, 0.092)]
    sweep("Torso_coat", pts, rad, "top", torso, cap0="open", cap1="flat", thick=0.018, seg=36, sq=2.2)
    sweep("Torso_coat_collar", [(0, 1.15, -0.01), (0, 1.09, -0.01)], [(0.125, 0.105), (0.17, 0.14)], "top_light", torso,
          cap0="open", cap1="open", thick=0.016, seg=32)
    for sx in (-1, 1):
        sweep(f"Torso_coat_lapel_{sx}", [(sx * 0.03, 1.12, 0.1), (sx * 0.075, 0.99, 0.17), (sx * 0.055, 0.85, 0.2)],
              [(0.075, 0.016), (0.085, 0.018), (0.06, 0.016)], "top_light", torso, ref=(0, 0, 1), seg=14, cap_len=0.6)
    for k in range(3):
        sphere(f"Torso_coat_button_{k}", 0.022, (0.05, 0.92 - k * 0.12, 0.2), "button", torso, seg=12)
    sweep("Torso_coat_belt", [(0, 0.68, 0), (0, 0.74, 0)], [(0.268, 0.2), (0.27, 0.202)], "ink", torso, cap0="open",
          cap1="open", thick=0.016, seg=32, sq=2.2)
    box("Torso_coat_buckle", (0.07, 0.05, 0.016), (0, 0.71, 0.206), "button", torso, bevel=0.006)

    # petits details
    sweep("Detail_belt", [(0, 0.64, 0), (0, 0.70, 0)], [(0.208, 0.16), (0.21, 0.162)], "accent", torso, cap0="open",
          cap1="open", thick=0.016, seg=32, sq=2.2)
    sweep("Detail_band", [(0, 0.86, 0), (0, 0.94, 0)], [(0.228, 0.168), (0.232, 0.17)], "accent", torso, cap0="open",
          cap1="open", thick=0.014, seg=32, sq=2.2)
    sphere("Detail_belly", 0.3, (0, 0.75, 0.1), "top", torso, scale=(1, 0.9, 0.85))
    box("Detail_tie", (0.1, 0.3, 0.035), (0, 0.9, 0.2), "blood", torso, bevel=0.014)

    # cou court et epais, avale par le col
    sweep("Neck", [(0, 1.08, 0), (0, 1.2, 0.004), (0, 1.3, 0.006)], [(0.098, 0.096), (0.092, 0.09), (0.094, 0.092)],
          "skin_shade", rig, cap0="round", cap1="round", seg=22)


# ============================================================ BRAS + MAINS
def build_arms():
    for i, sx in enumerate((-1, 1)):
        x = sx * ARM_X
        arm = bc.pivot(f"Arm_{i}", G(x, SHO_Y, 0), rig)
        pts = [(x - sx * 0.02, 1.11, 0), (x + sx * 0.012, 0.94, 0.006), (x + sx * 0.03, 0.80, 0.02), (x + sx * 0.036, 0.72, 0.014)]
        rad = [(0.078, 0.076), (0.068, 0.066), (0.058, 0.057), (0.053, 0.053)]
        sweep(f"Arm_{i}_limb", pts, rad, "top", arm, cap0="round", cap1="round", seg=26)
        sphere(f"Arm_{i}_shoulder", 0.098, (x - sx * 0.03, 1.115, 0), "top", arm, scale=(1.0, 0.95, 0.95), seg=30)
        hx = x + sx * 0.036
        sweep(f"Arm_{i}_cuff", [(hx, 0.77, 0.016), (hx, 0.705, 0.014)], [(0.064, 0.064), (0.06, 0.06)], "top_light", arm,
              cap0="open", cap1="open", thick=0.012, seg=26)
        # main moufle : paume ronde + 4 doigts epais + pouce
        sweep(f"Arm_{i}_hand", [(hx, 0.715, 0.014), (hx, 0.65, 0.02), (hx, 0.595, 0.026)],
              [(0.052, 0.04), (0.058, 0.042), (0.054, 0.038)], "skin", arm, cap0="round", cap1="round", seg=20)
        for fi, (fx, ln) in enumerate(((-0.036, 0.08), (-0.012, 0.096), (0.012, 0.09), (0.036, 0.072))):
            sweep(f"Arm_{i}_finger_{fi}", [(hx + fx, 0.61, 0.026), (hx + fx, 0.61 - ln * 0.55, 0.036), (hx + fx, 0.61 - ln, 0.048)],
                  [(0.017, 0.017), (0.0165, 0.0165), (0.0145, 0.0145)], "skin", arm, cap0="round", cap1="round", seg=12)
        sweep(f"Arm_{i}_thumb", [(hx - sx * 0.044, 0.68, 0.03), (hx - sx * 0.07, 0.635, 0.05), (hx - sx * 0.076, 0.595, 0.064)],
              [(0.022, 0.02), (0.019, 0.018), (0.016, 0.016)], "skin", arm, cap0="round", cap1="round", seg=12)


# ============================================================ TETE
def head_deform(x, y, z):
    """Coordonnees de l'ancienne tete (rayon 0.21)."""
    r = 0.21
    if y < 0:
        t = min(1.0, -y / r)
        x *= 1 - 0.20 * t ** 1.5
        z *= 1 - 0.07 * t ** 1.5
        if z > 0:
            z += 0.012 * t ** 2
    if z < 0 and y > -0.06:
        z *= 1.05
    if y > 0.08:
        y += 0.006
    for sx in (-1, 1):
        g = gauss(x, y, z, sx * 0.128, -0.05, 0.125, 0.05)  # joues
        x += sx * 0.016 * g
        z += 0.010 * g
        g2 = gauss(x, y, z, sx * 0.078, 0.03, 0.175, 0.04)  # orbites
        z -= 0.006 * g2
    return x, y, z


def head_deform_k(x, y, z):
    """Meme deformation, mais en coordonnees monde-locales (deja multipliees par K)."""
    a, b, c = head_deform(x / K, y / K, z / K)
    return a * K, b * K, c * K


def build_head():
    head = bc.pivot("Head", G(0, HEAD_Y, 0), rig)
    bc.blob("Head_skull", 0.21 * K, (0, HEAD_Y, 0), "skin", head, deform=head_deform_k, seg=56, subsurf=0)
    # nez discret
    ksphere("Head_nose", 0.022, (0, -0.012, 0.201), "skin", head, scale=(1, 0.9, 1.0), seg=18, extras=NO_OUTLINE)
    for sx in (-1, 1):
        # oreilles petites, a moitie cachees par les cheveux
        ksphere(f"Head_ear_{sx}", 0.03, (sx * 0.205, -0.01, -0.005), "skin", head, scale=(0.5, 1.2, 0.85), seg=16)

    for i, sx in enumerate((-1, 1)):
        ex, ey, ez = sx * 0.078, 0.03, 0.172
        eye = bc.pivot(f"Eye_{i}", G(*HK(ex, ey, ez)), head)
        ksphere(f"Eye_{i}_white", 0.052, (ex, ey, ez), "eye_white", eye, scale=(1, 1.12, 0.62), seg=28, exact=True)
        ksphere(f"Eye_{i}_iris", 0.041, (ex, ey - 0.004, ez + 0.018), "iris", eye, scale=(1, 1.1, 0.5), seg=28, exact=True)
        ksphere(f"Eye_{i}_pupil", 0.023, (ex, ey - 0.005, ez + 0.03), "ink", eye, scale=(1, 1.1, 0.45), seg=20, exact=True)
        ksphere(f"Eye_{i}_glint", 0.012, (ex + 0.013, ey + 0.016, ez + 0.041), "gloss", eye, seg=12)
        ksphere(f"Eye_{i}_glint2", 0.006, (ex - 0.012, ey - 0.014, ez + 0.039), "gloss", eye, seg=10)
        lid = ksphere(f"Eye_{i}_lid", 0.0555, (ex, ey + 0.004, ez + 0.002), "skin", eye, scale=(1, 1.12, 0.66), seg=28, exact=True)
        _trim_lower(lid, cut=0.040 * K)
        # trait de cils epais le long de la paupiere + petit battement exterieur
        lp, lr = [], []
        for u in (-1.0, -0.6, -0.2, 0.2, 0.6, 1.0, 1.25):
            lx = ex + sx * u * 0.046
            ly = ey + 0.046 - 0.006 * u * u + 0.004 * max(0.0, u)
            lz = ez + 0.004 + 0.027 * math.sqrt(max(0.0, 1 - min(1.0, u * u))) + 0.003
            lp.append((lx, ly, lz))
            lr.append((0.0045 if u < -0.9 else 0.0085 if u < 1.1 else 0.005,) * 2)
        ksweep(f"Eye_{i}_lash", lp, lr, "ink", eye, seg=10, ref=(0, 1, 0), subsurf=0)
        # cerne leger sous l'oeil (touche macabre discrete)
        ksphere(f"Eye_{i}_cerne", 0.03, (ex, ey - 0.064, ez - 0.012), "cerne", eye, scale=(1.7, 0.45, 0.25), seg=14,
                extras=NO_OUTLINE)

        # sourcil epais et expressif
        bx, by, bz = sx * 0.078, 0.128, 0.166
        brow = bc.pivot(f"Brow_{i}", G(*HK(bx, by, bz)), head)
        bp = []
        for u in (-1.0, -0.5, 0.0, 0.5, 1.0):
            bp.append(HK(bx + sx * u * 0.052, by + 0.012 * (1 - u * u) + 0.004 * u, bz - (u * 0.052) ** 2 * 3.0 + 0.002))
        sweep(f"Brow_{i}_bar", bp, _rads([(0.012, 0.010), (0.0145, 0.0105), (0.0145, 0.0105), (0.0115, 0.009), (0.0065, 0.006)]),
              "brow", brow, ref=(0, 1, 0), seg=10, extras=NO_OUTLINE)

        ksphere(f"Blush_{i}", 0.04, (sx * 0.125, -0.04, 0.15), "blush", head, scale=(1.3, 1.0, 0.7), seg=16, extras=NO_OUTLINE)

    # bouche : 5 segments fins (leur hauteur dessine le sourire) + ovale ouvert avec langue
    mp = (0, -0.078, 0.192)
    mouth = bc.pivot("Mouth", G(*HK(*mp)), head)
    for i in range(5):
        sx = (i - 2) * 0.027
        seg = bc.pivot(f"Mouth_seg_{i}", G(*HK(mp[0] + sx, mp[1], mp[2])), mouth)
        ksweep(f"Mouth_seg_{i}_bar", [(mp[0] + sx - 0.0225, mp[1], mp[2]), (mp[0] + sx + 0.0225, mp[1], mp[2])],
               [(0.0078, 0.007), (0.0078, 0.007)], "mouth", seg, ref=(0, 1, 0), seg=10, extras=NO_OUTLINE, subsurf=0)
    ksphere("Mouth_open", 0.034, (mp[0], mp[1] - 0.018, mp[2] - 0.004), "mouth_in", mouth, scale=(1.1, 0.9, 0.4), seg=20,
            extras=NO_OUTLINE)
    ksphere("Mouth_tongue", 0.02, (mp[0], mp[1] - 0.032, mp[2] - 0.001), "tongue", mouth, scale=(1.2, 0.6, 0.4), seg=12,
            extras=NO_OUTLINE)
    mouth.scale = (0.9, 0.9, 0.9)
    return head


def _trim_lower(obj, cut):
    """Garde la partie haute d'une coque spherique (au-dessus de `cut` metres du centre)."""
    import bmesh
    me = obj.data
    bm = bmesh.new()
    bm.from_mesh(me)
    dead = [v for v in bm.verts if v.co.z < cut]
    bmesh.ops.delete(bm, geom=dead, context="VERTS")
    bm.to_mesh(me)
    bm.free()
    md = obj.modifiers.new("Solid", "SOLIDIFY")
    md.thickness = 0.004 * K
    md.offset = 1


# ============================================================ CHEVEUX
def hair_ymin(psi):
    """Bord de la coiffe selon l'azimut (0 = face) : front, tempes, oreille degagee, nuque couverte."""
    a = abs(psi)
    y = 0.095
    y += (0.0 - 0.095) * _smooth(0.35, 1.1, a)
    y += (0.045 - 0.0) * _smooth(1.1, 1.4, a)
    y += (-0.19 - 0.045) * _smooth(1.8, 2.5, a)
    return y


def build_hair(head):
    bc.dome("Hair_cap", 0.228 * K, lambda p: hair_ymin(p) * K, (0, HEAD_Y + 0.004 * K, -0.008 * K), "hair", head,
            scale=(1.0, 1.0, 1.02), deform=head_deform_k, rings=14, seg=56, subsurf=0, thick=0.014 * K)
    # frange : 4 grosses meches fusionnees
    for k, x0 in enumerate((-0.125, -0.04, 0.04, 0.125)):
        pts = [(x0 * 0.6, 0.228, 0.0), (x0 * 1.0, 0.2, 0.14), (x0 * 1.12, 0.16, 0.205), (x0 * 1.2 + (0.018 if x0 > 0 else -0.018), 0.134, 0.208)]
        ksweep(f"Hair_bang_{k}", pts, [(0.055, 0.04), (0.056, 0.038), (0.044, 0.03), (0.012, 0.01)], "hair", head,
               seg=16, cap_len=1.1)
    # meches laterales epaisses, courbes
    for sx in (-1, 1):
        pts = [(sx * 0.17, 0.045, 0.07), (sx * 0.205, -0.01, 0.075), (sx * 0.215, -0.1, 0.06), (sx * 0.19, -0.17, 0.08)]
        ksweep(f"Hair_side_{sx}", pts, [(0.045, 0.034), (0.044, 0.032), (0.036, 0.026), (0.012, 0.012)], "hair", head, seg=14,
               cap_len=1.4)
    # chignon fondu dans la masse + attache + os (touche macabre)
    ksweep("Hair_bun_base", [(0, 0.05, -0.17), (0, 0.0, -0.22), (0, -0.01, -0.25)], [(0.11, 0.1), (0.12, 0.11), (0.12, 0.11)], "hair",
           head, seg=24, cap_len=1.0)
    ksphere("Hair_bun", 0.125, (0, -0.01, -0.265), "hair", head, scale=(1, 0.95, 0.9), seg=36)
    for k, ang in enumerate((-0.5, 0.5)):
        pts = [(math.sin(ang) * 0.03, 0.08, -0.22), (math.sin(ang) * 0.12, 0.08, -0.3), (math.sin(ang) * 0.12, -0.04, -0.35),
               (math.sin(ang) * 0.05, -0.12, -0.3)]
        ksweep(f"Hair_bun_swirl_{k}", pts, [(0.02, 0.016), (0.026, 0.018), (0.026, 0.018), (0.008, 0.008)], "hair", head, seg=10,
               cap_len=1.3)
    cylinder("Hair_bone", 0.011 * K, 0.011 * K, 0.27 * K, HK(0, -0.01, -0.31), "bone", head, seg=14, bevel=0.003, rot=(0, math.pi / 2, 0))
    for sx in (-1, 1):
        for dz in (-0.018, 0.018):
            sphere(f"Hair_bone_end_{sx}_{dz}", 0.022 * K, HK(sx * 0.135, -0.01, -0.31 + dz), "bone", head, seg=12)


# ============================================================ CHAPEAUX
def build_hats(head):
    PROF = {}
    def fat(profile, k=1.07):
        """Calotte legerement plus large (la frange ne doit pas percer) : seules les parties au-dessus du bord sont grossies."""
        return [((r * k) if (y > 0.178 and r < 0.27) else r, y) for r, y in profile]


    def tilt(profile, front=-0.012, side=0.0):
        """Inclinaison : decalage vertical proportionnel au rayon (devant : front, cote : side)."""
        n = len(profile)

        def f(th, t):
            r = profile[min(n - 1, max(0, int(round(t * (n - 1)))))][0]
            return (1.0, r * (front * math.sin(th) + side * math.cos(th)))

        return f

    # chapeau de soleil : calotte qui epouse le crane, large bord ondule, ruban, fleur
    sun = [(0.0, 0.305), (0.06, 0.309), (0.125, 0.3), (0.18, 0.272), (0.222, 0.225), (0.238, 0.185), (0.242, 0.175),
           (0.29, 0.172), (0.35, 0.162), (0.40, 0.145), (0.425, 0.132), (0.43, 0.124), (0.42, 0.117), (0.39, 0.122),
           (0.34, 0.133), (0.28, 0.142), (0.24, 0.15), (0.225, 0.16)]
    tl = tilt(sun, front=0.10, side=-0.05)

    def wave(th, t):
        _, dy = tl(th, t)
        return (1.0, dy + 0.016 * math.sin(3 * th + 0.4) * (t ** 2))

    klathe("Hat_sun", sun, "hat", head, seg=32, mod=wave, subsurf=1)
    band = [(0.246, 0.18), (0.249, 0.186), (0.247, 0.222), (0.243, 0.227)]
    klathe("Hat_sun_band", band, "petal", head, seg=40, mod=tilt(band, front=0.07, side=-0.05), subsurf=0, thick=0.005,
           closed_top=False)
    # grosse fleur sur le ruban (echo de la broche)
    fx, fy, fz = 0.19, 0.205, 0.155
    for k in range(6):
        a = 2 * math.pi * k / 6
        ksphere(f"Hat_sun_flower_{k}", 0.05, (fx + 0.058 * math.cos(a), fy + 0.058 * math.sin(a), fz + 0.04), "petal", head,
                scale=(1, 1, 0.55), seg=16)
    ksphere("Hat_sun_flower_c", 0.036, (fx, fy, fz + 0.065), "hat", head, seg=14, scale=(1, 1, 0.8))

    # melon
    bowler = [(0.0, 0.378), (0.075, 0.374), (0.14, 0.35), (0.19, 0.3), (0.215, 0.24), (0.222, 0.19), (0.23, 0.185),
              (0.3, 0.185), (0.322, 0.178), (0.324, 0.168), (0.31, 0.162), (0.23, 0.162), (0.2, 0.17)]
    bowler = fat(bowler)
    klathe("Hat_bowler", bowler, "hat_dark", head, seg=36, mod=tilt(bowler, 0.03, 0.03), subsurf=1)
    klathe("Hat_bowler_band", [(0.226, 0.19), (0.229, 0.196), (0.229, 0.228), (0.226, 0.232)], "blood", head, seg=36, subsurf=0,
           thick=0.005, closed_top=False)

    # fedora : calotte pincee
    fed = [(0.0, 0.33), (0.06, 0.327), (0.12, 0.31), (0.18, 0.285), (0.215, 0.245), (0.226, 0.2), (0.235, 0.185), (0.3, 0.18),
           (0.36, 0.17), (0.395, 0.152), (0.4, 0.142), (0.39, 0.137), (0.36, 0.142), (0.3, 0.152), (0.235, 0.16), (0.205, 0.166)]

    def fed_mod(th, t):
        _, dy = tilt(fed, 0.05, 0.02)(th, t)
        k = max(0.0, (t - 0.45) / 0.55) if t < 0.5 else 0.0
        return (1.0 - 0.1 * k * (0.5 + 0.5 * math.cos(2 * th)), dy)

    fed = fat(fed)
    klathe("Hat_fedora", fed, "top", head, seg=36, mod=fed_mod, subsurf=1)
    klathe("Hat_fedora_band", [(0.23, 0.192), (0.233, 0.198), (0.231, 0.232), (0.227, 0.236)], "blood", head, seg=36, subsurf=0,
           thick=0.005, closed_top=False)

    # haut-de-forme
    top = [(0.0, 0.52), (0.1, 0.518), (0.19, 0.51), (0.202, 0.49), (0.205, 0.3), (0.207, 0.2), (0.225, 0.19), (0.3, 0.186),
           (0.34, 0.178), (0.346, 0.169), (0.338, 0.163), (0.3, 0.168), (0.23, 0.168), (0.2, 0.174)]
    top = fat(top)
    klathe("Hat_tophat", top, "hat_dark", head, seg=36, mod=tilt(top, 0.03, 0.0), subsurf=1)
    klathe("Hat_tophat_band", [(0.207, 0.22), (0.21, 0.226), (0.21, 0.275), (0.207, 0.279)], "blood", head, seg=36, subsurf=0,
           thick=0.005, closed_top=False)
    ksphere("Hat_tophat_flower", 0.06, (0.14, 0.28, 0.16), "petal", head, scale=(1, 0.7, 1), seg=16)

    # bonnet : dome + revers cotele + pompon
    bean = [(0.0, 0.46), (0.1, 0.45), (0.19, 0.4), (0.24, 0.32), (0.26, 0.23), (0.264, 0.17), (0.258, 0.12), (0.24, 0.13),
            (0.242, 0.2), (0.225, 0.22)]
    bean = fat(bean, 1.05)
    klathe("Hat_beanie", bean, "hat", head, dz=-0.02, seg=40, mod=lambda th, t: 1.0 + (0.018 * math.cos(24 * th) if t > 0.55 else 0.0),
           subsurf=1)
    ksphere("Hat_beanie_pompom", 0.07, (0, 0.485, -0.02), "paper", head, seg=20)

    # casquette
    cap = [(0.0, 0.385), (0.09, 0.38), (0.18, 0.345), (0.235, 0.285), (0.252, 0.215), (0.256, 0.16), (0.238, 0.15), (0.222, 0.18),
           (0.2, 0.21)]
    cap = fat(cap, 1.05)
    klathe("Hat_cap", cap, "hat", head, dz=-0.015, seg=36, subsurf=1)
    ksweep("Hat_cap_visor", [(-0.16, 0.17, 0.215), (0.0, 0.168, 0.3), (0.16, 0.17, 0.215)],
           [(0.024, 0.01), (0.06, 0.01), (0.024, 0.01)], "hat_shade", head, ref=(0, 0, 1), seg=14, cap_len=0.5)
    ksphere("Hat_cap_button", 0.02, (0, 0.385, -0.015), "hat_shade", head, seg=12)


# ============================================================ ASSEMBLAGE
build_legs()
build_torsos()
build_arms()
head_p = build_head()
build_hair(head_p)
build_hats(head_p)

# ---- export ---------------------------------------------------------------
if BAKE_AO:
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    FAMILY_DETAILS = {
        "dress": ("sash", "bow", "bowtail", "bowknot", "collar", "button", "brooch"),
        "coat": ("tie",),
        "basic": ("belt", "band", "belly"),
    }

    def _family(o):
        """Variante (torso:dress, hat:bowler...) a laquelle appartient la piece, ou None pour le corps."""
        k = o.name.split("_")
        if k[0] == "Torso":
            return ("torso", k[1])
        if k[0] == "Hat":
            return ("hat", k[1])
        if k[0] == "Detail":
            for tor, names in FAMILY_DETAILS.items():
                if k[1] in names:
                    return ("torso", tor)
        return None

    def _face_noise(o):
        return o.name.startswith(("Blush", "Mouth", "Brow", "Detail_belly", "Detail_band")) or o.name.endswith("_cerne")

    body = [o for o in meshes if _family(o) is None]
    occ_body = [o for o in body if not _face_noise(o)]
    families = {}
    for o in meshes:
        f = _family(o)
        if f is not None:
            families.setdefault(f, []).append(o)
    # corps : voit la robe + le chapeau de soleil par defaut ; chaque variante : corps + elle seule
    bc.bake_vertex_ao(body, occluders=occ_body + families[("torso", "dress")] + families[("hat", "sun")], samples=16, dist=0.14)
    for f, objs in families.items():
        bc.bake_vertex_ao(objs, occluders=occ_body + objs, samples=16, dist=0.14)


glb = os.path.join(bc.ROOT, "assets", "models", "characters", "human_base.glb")
blend = os.path.join(bc.ROOT, "art", "blender", "human_base.blend")
os.makedirs(os.path.dirname(blend), exist_ok=True)
bc.export_glb(glb, rig)
bpy.ops.wm.save_as_mainfile(filepath=blend)
print("EXPORT", glb)

if BAKE_AO:
    bc.preview_use_vertex_color()

# ---- apercu : on ne garde visibles que la variante demandee ---------------
for o in bpy.data.objects:
    if o.type != "MESH" or o.name == "PreviewFloor":
        continue
    kind = o.name.split("_")[0]
    if kind == "Torso" and not o.name.startswith(f"Torso_{TORSO}"):
        o.hide_render = True
    if kind == "Hat" and not o.name.startswith(f"Hat_{HAT}"):
        o.hide_render = True
    if kind == "Detail":
        keep_detail = ((TORSO == "dress" and o.name.split("_")[1] in ("sash", "bow", "bowtail", "bowknot", "collar", "button", "brooch"))
                       or (TORSO == "basic" and o.name == "Detail_belt") or (TORSO == "coat" and o.name == "Detail_tie"))
        o.hide_render = not keep_detail
    if kind == "Hair" and o.name.startswith("Hair_bang") and HAT in ("beanie", "cap"):
        o.hide_render = True  # le chargeur masque la frange sous les couvre-chefs serres
    if kind == "Hair" and (o.name.startswith("Hair_bun") or o.name.startswith("Hair_bone")):
        o.hide_render = TORSO != "dress"
    if kind == "Blush" or o.name in ("Mouth_open", "Mouth_tongue"):
        o.hide_render = True
# humeur simulee comme CustomerActor._apply_mood : smile, inclinaison/hauteur des sourcils
MOOD = ARGS[ARGS.index("--mood") + 1] if "--mood" in ARGS else "neutral"
smile, brow_tilt, brow_up, opened = {"neutral": (0.35, 0, 0, False), "happy": (0.85, 0, 0.012, False),
                                     "bored": (-0.1, 0, -0.008, False), "angry": (-0.9, 0.55, -0.012, False),
                                     "shock": (0.0, 0, 0.02, True)}[MOOD]
mouth_o = bpy.data.objects["Mouth"]
for i in range(5):
    u = (i - 2) / 2.0
    c = smile * 0.06
    seg_o = bpy.data.objects[f"Mouth_seg_{i}"]
    base = seg_o.location.copy()
    seg_o.location = (base.x, base.y, base.z + (c * u * u - c * 0.35) * K * 0.9 - 0.0)
    seg_o.rotation_euler = (0, -math.atan(2.0 * c * u / 0.054), 0)  # roulis godot Z = -Y blender
for i, sxx in enumerate((-1, 1)):
    bo = bpy.data.objects[f"Brow_{i}"]
    bo.rotation_euler = (0, (brow_tilt if i == 0 else -brow_tilt), 0)
    bo.location.z += brow_up * K
bpy.data.objects["Mouth_open"].hide_render = not opened
bpy.data.objects["Mouth_tongue"].hide_render = not opened
if MOOD == "angry":
    for o in bpy.data.objects:
        if o.name.startswith("Blush_"):
            o.hide_render = False
out = os.path.join(bc.ROOT, "out", "blender", f"human_{TORSO}_{HAT}" + ("" if MOOD == "neutral" else f"_{MOOD}"))
os.makedirs(os.path.dirname(out), exist_ok=True)
views = {
    "front": dict(yaw=0), "three_quarter": dict(yaw=35), "side": dict(yaw=90), "back": dict(yaw=180),
    "face": dict(yaw=20, focus=(0, 1.52, 0), dist=2.4, elev=2),
}
bc.render_preview(out, views=views, res=(900, 1250), focus=(0, 0.95, 0), dist=5.6)
print("PREVIEW", out)

if "--stats" in ARGS:
    deps = bpy.context.evaluated_depsgraph_get()
    rows = []
    for o in bpy.data.objects:
        if o.type != "MESH" or o.hide_render:
            continue
        me = o.evaluated_get(deps).to_mesh()
        rows.append((sum(len(p.vertices) - 2 for p in me.polygons), o.name))
        o.evaluated_get(deps).to_mesh_clear()
    rows.sort(reverse=True)
    print("STATS total_tris_look =", sum(r[0] for r in rows), " meshes =", len(rows))
    for t, n in rows[:28]:
        print("STATS", t, n)
